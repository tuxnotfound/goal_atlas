# Pulls WC2026 fixtures from api-football and upserts scores + result_type
# onto matching Match rows. After a match flips to a "finished" status the
# sync also:
#   * fetches the goal-event timeline — upserts Goal rows + creates Player
#     rows for any scorers/assists we don't already have; and
#   * fetches the lineups — records a TournamentParticipation for every player
#     who appeared and is ALREADY in our DB, so non-scoring squad members
#     (who leave no goal/assist trace) still count toward participation stats.
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
    @stats  = { fetched: 0, updated: 0, skipped: 0, goals_synced: 0,
                players_created: 0, participations_synced: 0, no_match: [] }
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
    api_date  = Date.parse(fx.dig("fixture", "date"))

    # api-football's date is UTC, ours is local-venue date. A late-night
    # local kickoff (e.g. 9pm CDT) rolls into the next UTC day, so we widen
    # the lookup to a 3-day window centred on the api date.
    date_range = (api_date - 1)..(api_date + 1)

    match = Match.kept.find_by(tournament: tournament, home_team: home_team, away_team: away_team, date: date_range)
    match ||= Match.kept.find_by(tournament: tournament, home_team: away_team, away_team: home_team, date: date_range)

    unless match
      @stats[:no_match] << "#{date} #{home_team&.fifa_code} vs #{away_team&.fifa_code}"
      return
    end

    # No-op if we've already applied this result… unless we still need to
    # backfill the goal events for it (e.g. a previous run failed mid-flight).
    if match.result_type != "scheduled"
      sync_goals_for(match, fx, team_map) if match.goals.kept.empty?
      sync_participations_for(match, fx, team_map)
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
    sync_participations_for(match, fx, team_map)
  end

  # After a match is played, record a TournamentParticipation for every player
  # who appeared in either lineup and is ALREADY in our database. Non-scorers
  # leave no goal/assist trace, so without this they'd never count toward the
  # "tournaments played" stat. We never create Player rows here — only squad
  # members we already curate get linked, matching the historical "existing
  # players only" participation policy.
  #
  # api-football's lineups give abbreviated names ("C. Ronaldo"), so matching
  # an existing row needs the /players detail call that expands them. To avoid
  # spending one of those on each of the ~25 debutants per match who aren't in
  # our DB at all, we first cheaply check (locally) that the name's surname is
  # even present in that nation's roster — see match_squad_member.
  #
  # `lineups_synced_at` guards re-runs: the 15-minute sync would otherwise
  # re-pull every finished fixture's lineup forever. We stamp it on any
  # successful fetch (so a genuinely empty lineup isn't retried) but leave it
  # unset on an API error, so a transient failure (incl. a rate-limit 429) is
  # retried next run.
  def sync_participations_for(match, fx, team_map)
    return if match.lineups_synced_at?

    fixture_id = fx.dig("fixture", "id")
    return unless fixture_id

    lineups = @client.fixture_lineups(fixture_id: fixture_id)["response"]

    Array(lineups).each do |lineup|
      team = team_map[lineup.dig("team", "id")]
      next unless team

      roster = Array(lineup["startXI"]) + Array(lineup["substitutes"])
      roster.each do |slot|
        info = slot["player"]
        next unless info

        player = match_squad_member(info["id"], info["name"], team)
        next unless player

        record = TournamentParticipation
                 .where(player_id: player.id, tournament_id: match.tournament_id)
                 .first_or_create!
        @stats[:participations_synced] += 1 if record.previously_new_record?
      end
    end

    match.update_column(:lineups_synced_at, Time.current)
  rescue ApiFootballClient::Error => e
    Rails.logger.warn("Wc2026Sync: lineup fetch failed for fixture #{fixture_id}: #{e.message}")
  end

  # Resolves a lineup entry to an existing Player, spending an api /players
  # detail call ONLY when worthwhile. Matches the persistent id for free, then
  # gates the (expensive) name resolution behind a local check that the
  # abbreviated lineup name's surname actually appears in this nation's roster.
  # Debutants we don't track have no matching surname, so they cost no API call.
  def match_squad_member(api_id, lineup_name, team)
    if api_id && (existing = Player.kept.find_by(api_football_player_id: api_id))
      return existing
    end

    tokens = normalize_name(lineup_name).split
    return nil if tokens.empty? || tokens.none? { |t| squad_surnames(team).include?(t) }

    find_existing_player(api_id, lineup_name, team)
  end

  # Normalized name tokens of every player already on this nation's roster
  # (plus teamless players), memoised per run. Used to skip detail lookups for
  # lineup names whose surname we've never recorded.
  def squad_surnames(team)
    (@squad_surnames ||= {})[team.id] ||=
      Player.kept.where(nationality_team_id: [team.id, nil])
            .pluck(:name)
            .flat_map { |name| normalize_name(name).split }
            .to_set
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

      player        = find_or_create_player(ev.dig("player", "id"), ev.dig("player", "name"), scorer_nationality)
      assist_player = ev.dig("assist", "id") && find_or_create_player(ev.dig("assist", "id"), ev.dig("assist", "name"), scoring_team)

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

  # Player upsert: link an existing row (see find_existing_player) or, only
  # when no match is found, create a fresh one with the best canonical name we
  # can compute. Used for scorers/assists, who must always end up as a Player.
  def find_or_create_player(api_id, short_name, nationality_team)
    return nil if short_name.to_s.strip.empty?

    existing = find_existing_player(api_id, short_name, nationality_team)
    return existing if existing

    info = api_id ? player_details_cached(api_id) : nil
    Player.create!(
      name: info&.dig(:display_name).presence || info&.dig(:api_name).presence || short_name,
      birth_date: info&.dig(:birth_date),
      nationality_team: nationality_team,
      api_football_player_id: api_id
    ).tap { @stats[:players_created] += 1 }
  end

  # Lookup half of the player upsert — returns an existing Player or nil,
  # NEVER creating one. Used directly for lineup participants (we only link
  # squad members already in our DB). Order:
  #   1. exact lookup by api_football_player_id (persistent ID — bulletproof)
  #   2. name fallback (diacritic + case insensitive) trying every plausible
  #      form so existing rows (Messi, Ronaldo, etc.) get linked instead of
  #      duplicated. On match we backfill api_football_player_id so step 1
  #      catches them next time.
  def find_existing_player(api_id, short_name, nationality_team)
    return nil if short_name.to_s.strip.empty?

    # Step 1 — persistent ID
    if api_id && (existing = Player.kept.find_by(api_football_player_id: api_id))
      return existing
    end

    info = api_id ? player_details_cached(api_id) : nil

    # Step 2 — name fallback. Only forms that uniquely identify the player —
    # the expanded display name ("Lionel Messi"), the short broadcast name
    # ("L. Messi"), api-football's curated `name` ("Cristiano Ronaldo"), and the
    # firstname+lastname computed form. display_name goes first because it's the
    # canonical known name our existing rows are stored under, so it links
    # legends already in the DB instead of duplicating them. We intentionally
    # exclude firstname alone because common compound first names like "Roberto
    # Carlos" collide with unrelated legends.
    names_to_try = [
      info&.dig(:display_name),
      short_name,
      info&.dig(:api_name),
      info&.dig(:computed_name)
    ].compact.map(&:to_s).map(&:strip).reject(&:empty?).uniq

    names_to_try.each do |n|
      existing = lookup_player_by_name(n, nationality_team)
      next unless existing
      # Backfill the ID so this player is matched directly next time. Don't
      # clobber a different id already set (could indicate a name collision
      # with a different real person).
      if api_id && existing.api_football_player_id.blank?
        existing.update!(api_football_player_id: api_id)
      end
      return existing
    end

    nil
  end

  # Diacritic + case insensitive name match scoped to the player's
  # nationality_team plus teamless players. Cross-team matches are NEVER
  # returned — "Roberto Carlos" in BRA must not be matched as MEX's
  # "Roberto Alvarado" when api-football lists his firstname as "Roberto
  # Carlos". If the player isn't in the right team's roster (or teamless)
  # we create a new row.
  def lookup_player_by_name(name, nationality_team)
    target = normalize_name(name)
    return nil if target.empty? || nationality_team.nil?

    candidates = Player.kept.where(nationality_team_id: [nationality_team.id, nil]).to_a
    candidates.find { |p| normalize_name(p.name) == target }
  end

  # Strip diacritics + lowercase + squeeze whitespace. "García Hernández" →
  # "garcia hernandez", so it matches "Garcia Hernandez".
  def normalize_name(str)
    str.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase.gsub(/\s+/, " ").strip
  end

  # Memoised /players?id=N. Returns a hash with both the api-football "name"
  # (often the common short form like "Cristiano Ronaldo") and a computed
  # firstname-lastname form for cases like Spanish double surnames.
  def player_details_cached(api_id)
    @player_info_cache ||= {}
    return @player_info_cache[api_id] if @player_info_cache.key?(api_id)

    @player_info_cache[api_id] = fetch_player_details(api_id)
  end

  def fetch_player_details(api_id)
    payload = @client.player_details(id: api_id, season: SEASON)
    p = payload["response"]&.first&.dig("player")
    return nil unless p

    api_name    = p["name"].to_s.strip
    first_token = p["firstname"].to_s.strip.split.first
    last_name   = p["lastname"].to_s.strip
    computed    = [first_token, last_name].reject { |s| s.to_s.empty? }.join(" ") # firstname + full lastname

    # api-football's `name` is the common/known form, but usually abbreviates the
    # given name to an initial ("L. Messi", "E. Haaland", "V. van Dijk"). Expand
    # that leading initial back to the real first name and we get the name people
    # actually use — and, crucially, the SAME string our existing rows are stored
    # under, so the name-match in step 2 links instead of spawning a "Lionel
    # Messi Cuccittini" twin:
    #   "L. Messi"      + firstname "Lionel Andrés" -> "Lionel Messi"
    #   "E. Haaland"    + firstname "Erling"        -> "Erling Haaland"
    #   "Aymen Hussein" (no initial)                -> "Aymen Hussein" (as-is)
    # `name` also already drops middle names buried in the lastname field
    # ("Braut Haaland", "dos Santos Aveiro") that firstname+lastname can't. Only
    # when `name` is blank do we fall back to firstname + full lastname.
    name_tokens = api_name.split
    lead_inits  = name_tokens.take_while { |t| t.match?(/\A\p{Lu}\.\z/) }
    display =
      if lead_inits.any?
        [first_token, name_tokens.drop(lead_inits.size).join(" ")].reject { |s| s.to_s.empty? }.join(" ")
      elsif !api_name.empty?
        api_name
      else
        computed
      end
    birth = p.dig("birth", "date")

    {
      api_name:      api_name.presence,                     # e.g. "L. Messi", "Cristiano Ronaldo"
      computed_name: computed.presence,                     # firstname + full lastname
      display_name:  display.presence,                      # best name for a new row
      firstname:     p["firstname"].to_s.strip.presence,    # for extra-loose match
      lastname_full: p["lastname"].to_s.strip.presence,
      birth_date:    (Date.parse(birth) rescue nil)
    }
  rescue ApiFootballClient::Error => e
    Rails.logger.warn("Wc2026Sync: player_details lookup failed for api_id=#{api_id}: #{e.message}")
    nil
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
