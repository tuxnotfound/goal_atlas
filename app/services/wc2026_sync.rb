# Pulls WC2026 fixtures from api-football and upserts scores + result_type
# onto the matching Match rows in our DB.
#
# Scope (v1): scores, winner, result_type. Goals/scorers are still entered
# via /admin/matches because mapping api-football player IDs → our Player IDs
# isn't safe to automate during the tournament.
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

  attr_reader :stats

  def initialize(client: ApiFootballClient.new)
    @client = client
    @stats  = { fetched: 0, updated: 0, skipped: 0, no_match: [] }
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

    # No-op if we've already applied this result.
    if match.result_type != "scheduled"
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

  # Returns api-football team id => Team row. Matches on fifa_code (= api-football
  # `code`) so the rare team without a fifa_code falls back to name match.
  def build_team_map
    api_teams = @client.teams(league: LEAGUE_ID, season: SEASON)["response"]
    our_teams_by_code = Team.where.not(fifa_code: nil).index_by(&:fifa_code)
    our_teams_by_name = Team.all.index_by(&:name)

    api_teams.each_with_object({}) do |item, map|
      t = item["team"]
      our = our_teams_by_code[t["code"]] || our_teams_by_name[t["name"]]
      if our
        map[t["id"]] = our
      else
        Rails.logger.warn("Wc2026Sync: no DB match for api-football team #{t["id"]} (#{t["code"]} / #{t["name"]})")
      end
    end
  end
end
