# Computes the all-time World Cup leaderboards shown on the /records page —
# player and team rankings across every tournament in the archive.
#
# Two judgment calls baked in here, both matching how the rest of the site
# already behaves:
#   * Predecessor nations are folded into their canonical successor (West &
#     East Germany count toward Germany, Czechoslovakia toward Czech Republic,
#     Zaire toward DR Congo) so the team boards read as one continuous nation,
#     exactly like the team pages do via Team#family_ids.
#   * Scheduled-but-unplayed fixtures (the pre-loaded 2026 0-0 matches) are
#     excluded from every match-based team stat so future games don't inflate
#     "matches played"/"goals scored".
#
# Player goals exclude own goals (an own goal credits the opponent, never the
# scorer) — consistent with the Golden Boot leaderboards elsewhere. Team goals
# are summed from authoritative match scores (extra-time aware), so own goals
# correctly land with the team that benefited.
#
# Each board issues a small, constant number of queries; the whole page is a
# handful of grouped aggregates plus two id-keyed entity loads.
class AllTimeRecords
  DEFAULT_LIMIT = 10
  SCHEDULED     = Match::RESULT_TYPES[:scheduled]
  OWN_GOAL      = Goal::GOAL_TYPES[:own_goal]

  Board = Struct.new(:key, :title, :note, :entries, keyword_init: true)
  Entry = Struct.new(:entity, :count, keyword_init: true)

  def initialize(limit: DEFAULT_LIMIT)
    @limit = limit
  end

  def player_boards
    @player_boards ||= [
      board(:participations, "Most tournaments played",
            "Squad appearances at the World Cup", participation_entries),
      board(:titles, "Most tournaments won",
            "World Cups won with their nation", player_title_entries),
      board(:goals, "Most goals",
            "Career World Cup goals (own goals excluded)", player_goal_entries),
      board(:hat_tricks, "Most hat-tricks",
            "Matches with three or more goals", hat_trick_entries)
    ]
  end

  def team_boards
    @team_boards ||= [
      board(:matches, "Most matches played",
            "World Cup matches contested", team_match_entries),
      board(:wins, "Most matches won",
            "World Cup matches won", team_win_entries),
      board(:goals, "Most goals scored",
            "Goals scored across every World Cup", team_goal_entries),
      board(:presences, "Most tournaments played",
            "World Cups the nation appeared in", team_presence_entries),
      board(:titles, "Most tournaments won",
            "World Cup titles", team_title_entries)
    ]
  end

  private

  attr_reader :limit

  def board(key, title, note, entries)
    Board.new(key: key, title: title, note: note, entries: entries)
  end

  # ---- Player boards -----------------------------------------------------

  def participation_entries
    ranked_players(
      Player.kept.joins(:tournament_participations),
      count: "COUNT(tournament_participations.id)"
    )
  end

  def player_title_entries
    ranked_players(
      Player.kept
            .joins(tournament_participations: :tournament)
            .where(tournaments: { discarded_at: nil })
            .where("tournaments.winner_team_id = players.nationality_team_id"),
      count: "COUNT(tournament_participations.id)"
    )
  end

  def player_goal_entries
    ranked_players(
      Player.kept
            .joins(goals: :match)
            .where(goals: { discarded_at: nil }, matches: { discarded_at: nil })
            .where.not(goals: { goal_type: OWN_GOAL }),
      count: "COUNT(goals.id)"
    )
  end

  # A hat-trick is three or more goals (own goals excluded) by one player in a
  # single match. Count the qualifying (player, match) pairs, then tally per
  # player. The instance set is tiny, so the per-player fold runs in Ruby.
  def hat_trick_entries
    instances = Goal.kept
                    .where.not(goal_type: OWN_GOAL)
                    .joins(:match).where(matches: { discarded_at: nil })
                    .group(:player_id, :match_id)
                    .having("COUNT(*) >= 3")
                    .count

    counts = Hash.new(0)
    instances.each_key { |(player_id, _match_id)| counts[player_id] += 1 }

    players = Player.kept.where(id: counts.keys).preload(:nationality_team).index_by(&:id)
    entries_from(counts, players)
  end

  # Runs a grouped COUNT over `relation`, ordering by the count then name, and
  # returns the top `limit` players as Entry rows with nationality preloaded.
  def ranked_players(relation, count:)
    players = relation
              .group("players.id")
              .order(Arel.sql("#{count} DESC, players.name ASC"))
              .limit(limit)
              .preload(:nationality_team)
              .select("players.*, #{count} AS stat_count")

    players.map { |p| Entry.new(entity: p, count: p.stat_count.to_i) }
  end

  # ---- Team boards -------------------------------------------------------

  def team_match_entries
    counts = Hash.new(0)
    played_matches.pluck(:home_team_id, :away_team_id).each do |home_id, away_id|
      counts[canonical_id[home_id]] += 1
      counts[canonical_id[away_id]] += 1
    end
    team_entries(counts)
  end

  def team_win_entries
    counts = Hash.new(0)
    played_matches.where.not(winner_team_id: nil).pluck(:winner_team_id).each do |winner_id|
      counts[canonical_id[winner_id]] += 1
    end
    team_entries(counts)
  end

  def team_goal_entries
    counts = Hash.new(0)
    columns = %i[home_team_id away_team_id home_score away_score
                 home_score_after_extra_time away_score_after_extra_time]
    played_matches.pluck(*columns).each do |home_id, away_id, hs, as, hs_et, as_et|
      counts[canonical_id[home_id]] += (hs_et || hs)
      counts[canonical_id[away_id]] += (as_et || as)
    end
    team_entries(counts)
  end

  def team_presence_entries
    tournaments = Hash.new { |h, k| h[k] = Set.new }
    played_matches.pluck(:tournament_id, :home_team_id, :away_team_id).each do |tid, home_id, away_id|
      tournaments[canonical_id[home_id]] << tid
      tournaments[canonical_id[away_id]] << tid
    end
    team_entries(tournaments.transform_values(&:size))
  end

  def team_title_entries
    counts = Hash.new(0)
    Tournament.kept.where.not(winner_team_id: nil).pluck(:winner_team_id).each do |winner_id|
      counts[canonical_id[winner_id]] += 1
    end
    team_entries(counts)
  end

  def team_entries(counts)
    teams = Team.kept.where(id: counts.keys).index_by(&:id)
    entries_from(counts, teams)
  end

  # Played, non-discarded matches — excludes the pre-loaded scheduled fixtures
  # so unplayed games never count toward a team's all-time totals.
  def played_matches
    Match.kept.where.not(result_type: SCHEDULED)
  end

  # Maps every team id to its canonical (successor) team id so predecessor
  # nations fold into the team they became. Chains are a single hop in the
  # data (predecessor -> canonical), so no recursive resolution is needed.
  def canonical_id
    @canonical_id ||= Team.pluck(:id, :successor_team_id)
                          .to_h { |id, successor_id| [id, successor_id || id] }
  end

  # Turns a { entity_id => count } hash into the top `limit` Entry rows,
  # dropping ids whose entity wasn't loaded (e.g. a discarded canonical team),
  # ordered by count desc then name asc.
  def entries_from(counts, entities_by_id)
    counts.filter_map do |id, count|
      entity = entities_by_id[id]
      Entry.new(entity: entity, count: count) if entity
    end.sort_by { |e| [-e.count, e.entity.name] }.first(limit)
  end
end
