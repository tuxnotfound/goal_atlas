# Pulls WC2026 fixtures from api-football and upserts scores + result_type
# onto matching Match rows. After a match flips to a "finished" status the
# sync also fetches the goal-event timeline and upserts Goal rows + creates
# Player rows for any scorers/assists we don't already have.
#
# Usage:
#   Wc2026Sync.new.call
#
# Reads API_FOOTBALL_KEY from ENV. League id 1 = "World Cup" on api-football.
class Wc2026Sync
  LEAGUE_ID = 1
  SEASON    = 2026

  # Maps api-football fixture status `short` codes → our result_type enum.
  # NS / TBD / PST / CANC stay :scheduled (do nothing).
  STATUS_MAP = {
    "FT"   => :regulation,
    "AET"  => :after_extra_time,
    "PEN"  => :after_penalties,
    "ABD"  => :abandoned,
    "WO"   => :walkover,
    "AWD"  => :walkover
  }.freeze

  # api-football's event `detail` string → our Goal#goal_type enum.
  GOAL_TYPE_MAP = {
    "Normal Goal" => :open_play,
    "Penalty"     => :penalty,
    "Own Goal"    => :own_goal
  }.freeze

  attr_reader :stats

  def initialize(client: ApiFootballClient.new)
    @client = client
    @stats  = { fetched: 0, updated: 0, skipped: 0, goals_synced: 0, players_created: 0, no_match: [] }
  end

  def call
    tournament = Tournament.find_by!(year: SEASON)
    team_map = build_team_map  # api-football team_id => our Team
    fixtures = @client.fixtures(league: LEAGUE_ID, season: SEASON)["response"]
    @stats[:fetched] = fixtures.size

    fixtures.each do |fx|
      sync_fixture(tournament, fx, team_map)
    end

    stats
  end

  private

  def sync_fixture(tournament, fx, team_map)
    status = fx.dig("fixture", "status", "short")
    new_type = STATUS_MAP[status]
    unless new_type
      @stats[:skipped] += 1
      return
    end

    home_team = team_map[fx.dig("teams", "home", "id")]
    away_team = team_map[fx.dig("teams", "away", "id")]
    date      = Date.parse(fx.dig("fixture", "date"))

    match = Match.kept.find_by(tournament: tournament, home_team: home_team, away_team: away_team, date: date)
    match ||= Match.kept.find_by(tournament: tournament, home_team: away_team, away_team: home_team, date: date)  # in case home/away flipped

    unless match
      @stats[:no_match] << "#{date} #{home_team&.fifa_code} vs #{away_team&.fifa_code}"
      return
    end

    # No-op if we've already applied this result… unless we still need to
    # backfill the goal events for it (e.g. a previous run failed mid-flight).
    if match.result_type != "scheduled"
      sync_goals_for(match, fx, team_map) if match.goals.kept.empty?
      @stats[:skipped] += 1
      return
    end

    ft_home = fx.dig("score", "fulltime", "home")
    ft_away = fx.dig("score", "fulltime", "away")
    et_home = fx.dig("score", "extratime", "home")
    et_away = fx.dig("score", "extratime", "away")
    pen_home = fx.dig("score", "penalty", "home")
    pen_away = fx.dig("score", "penalty", "away")

    attrs = {
      result_type: new_type,
      home_score:  ft_home,
      away_score:  ft_away
    }

    if et_home && et_away
      attrs[:home_score_after_extra_time] = et_home
      attrs[:away_score_after_extra_time] = et_away
    end

    if pen_home && pen_away
      attrs[:home_penalties] = pen_home
      attrs[:away_penalties] = pen_away
    end

    attrs[:winner_team_id] = determine_winner_id(match, attrs, new_type)

    # Honour the home/away orientation in our DB even if api-football reversed it.
    if match.home_team_id != home_team.id
      attrs = flip_home_away(attrs)
    end

    match.update!(attrs)
    @stats[:updated] += 1

    # Goal events only become available once api-football has the timeline,
    # which is normally right at FT. Pull them now so the match doesn't sit
    # showing a final score with no scorer info.
    sync_goals_for(match, fx, team_map)
  end

  # Fetches goal events for one fixture and upserts a Goal row per event.
  # Idempotent: scoped to (match, period, minute, stoppage_time, scorer name) so
  # re-runs don't double-insert. Creates Player rows on the fly for any
  # scorer/assist not already in the DB.
  def sync_goals_for(match, fx, team_map)
    fixture_id = fx.dig("fixture", "id")
    return unless fixture_id

    events = @client.fixture_events(fixture_id: fixture_id)["response"]
    goal_events = events.select { |e| e["type"] == "Goal" }
    return if goal_events.empty?

    running_home = 0
    running_away = 0

    goal_events.each_with_index do |ev, idx|
      scoring_team = team_map[ev.dig("team", "id")]
      next unless scoring_team  # team mapping failure already logged

      detail     = ev["detail"].to_s
      goal_type  = GOAL_TYPE_MAP[detail] || :open_play
      minute     = ev.dig("time", "elapsed")
      stoppage   = ev.dig("time", "extra")
      next unless minute.is_a?(Integer) && minute.between?(0, 120)  # skip shootout/garbage
      period     = period_for(minute)

      # For own goals the api-football scorer plays FOR the team that conceded.
      scorer_nationality = (goal_type == :own_goal ? opponent_of(match, scoring_team) : scoring_team)

      player        = find_or_create_player(ev.dig("player", "name"), scorer_nationality)
      assist_player = ev.dig("assist", "id") && find_or_create_player(ev.dig("assist", "name"), scoring_team)

      # Running tally so score_after_goal_* reflects the state right after this goal.
      if scoring_team.id == match.home_team_id
        running_home += 1
      else
        running_away += 1
      end

      Goal.where(
        match_id:    match.id,
        period:      Goal.periods[period],
        minute:      minute,
        stoppage_time: stoppage,
        player_id:   player.id
      ).first_or_create! do |g|
        g.scoring_team        = scoring_team
        g.goal_type           = goal_type
        g.goal_order          = idx
        g.assist_player       = assist_player
        g.score_after_goal_home = running_home
        g.score_after_goal_away = running_away
        g.data_confidence     = :likely  # api-derived; admin upgrades to :verified after eyeball
      end

      @stats[:goals_synced] += 1
    end
  rescue ApiFootballClient::Error => e
    Rails.logger.warn("Wc2026Sync: goal-event fetch failed for fixture #{fixture_id}: #{e.message}")
  end

  def period_for(minute)
    case minute
    when 0..45    then :first_half
    when 46..90   then :second_half
    when 91..105  then :extra_time_first
    else               :extra_time_second
    end
  end

  def opponent_of(match, team)
    team.id == match.home_team_id ? match.away_team : match.home_team
  end

  # Player upsert: case-insensitive name match scoped to the scorer's
  # nationality team first (avoids name collisions across teams), then
  # falling back to a name-only match. New players are created with
  # nationality_team set so future syncs find them.
  def find_or_create_player(name, nationality_team)
    name = name.to_s.strip
    return nil if name.empty?

    scoped = Player.kept.where("LOWER(name) = ?", name.downcase)
    player = scoped.where(nationality_team: nationality_team).first
    player ||= scoped.where(nationality_team_id: nil).first
    player ||= scoped.first

    return player if player

    Player.create!(name: name, nationality_team: nationality_team).tap do
      @stats[:players_created] += 1
    end
  end

  def determine_winner_id(match, attrs, new_type)
    case new_type
    when :after_penalties
      attrs[:home_penalties] > attrs[:away_penalties] ? match.home_team_id : match.away_team_id
    when :after_extra_time
      et_h = attrs[:home_score_after_extra_time] || attrs[:home_score]
      et_a = attrs[:away_score_after_extra_time] || attrs[:away_score]
      next_winner_from_scores(match, et_h, et_a)
    when :regulation
      next_winner_from_scores(match, attrs[:home_score], attrs[:away_score])
    end
  end

  def next_winner_from_scores(match, home, away)
    return match.home_team_id if home > away
    return match.away_team_id if away > home
    nil  # draw — only legal in group stage
  end

  def flip_home_away(attrs)
    {
      result_type: attrs[:result_type],
      home_score:  attrs[:away_score],
      away_score:  attrs[:home_score],
      home_score_after_extra_time: attrs[:away_score_after_extra_time],
      away_score_after_extra_time: attrs[:home_score_after_extra_time],
      home_penalties: attrs[:away_penalties],
      away_penalties: attrs[:home_penalties],
      winner_team_id: attrs[:winner_team_id]
    }.compact
  end

  # api-football uses a few codes/names that differ from FIFA's. Mapping is
  # api-football code => our fifa_code. Add entries as new mismatches surface.
  CODE_ALIASES = {
    "CGO" => "COD",   # api: "Congo DR"  → ours: "DR Congo"
    "SER" => "SRB",   # api: "Serbia"     → ours: "Serbia" (matched by name anyway, but explicit)
    "COS" => "CRC",   # api: "Costa Rica" → ours: "Costa Rica"
    "CAM" => "CMR"    # api: "Cameroon"   → ours: "Cameroon"
  }.freeze

  # Returns api-football team id => Team row. Tries (1) fifa_code match, then
  # (2) the alias table, then (3) team name. Logs unresolved teams.
  def build_team_map
    api_teams = @client.teams(league: LEAGUE_ID, season: SEASON)["response"]
    our_teams_by_code = Team.where.not(fifa_code: nil).index_by(&:fifa_code)
    our_teams_by_name = Team.all.index_by(&:name)

    api_teams.each_with_object({}) do |item, map|
      t = item["team"]
      our = our_teams_by_code[t["code"]] ||
            our_teams_by_code[CODE_ALIASES[t["code"]]] ||
            our_teams_by_name[t["name"]]
      if our
        map[t["id"]] = our
      else
        Rails.logger.warn("Wc2026Sync: no DB match for api-football team #{t["id"]} (#{t["code"]} / #{t["name"]})")
      end
    end
  end
end
