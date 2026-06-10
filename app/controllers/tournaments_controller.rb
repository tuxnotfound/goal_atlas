class TournamentsController < ApplicationController
  TOP_SCORERS_LIMIT = 10

  def index
    @tournaments = Tournament.kept
                              .includes(:winner_team)
                              .order(year: :desc)
  end

  def show
    @tournament = Tournament.kept.find_by!(year: params[:year])

    @matches_by_stage = Match.kept
                             .where(tournament: @tournament)
                             .includes(:home_team, :away_team, :stadium)
                             .ordered_by_date
                             .group_by(&:stage)

    @top_scorers = Player
      .joins(goals: :match)
      .where(matches: { tournament_id: @tournament.id, discarded_at: nil })
      .where(goals:   { discarded_at: nil })
      .group("players.id")
      .order(Arel.sql("COUNT(goals.id) DESC, players.name ASC"))
      .limit(TOP_SCORERS_LIMIT)
      .select("players.*, COUNT(goals.id) AS goals_count")

    @awards = @tournament.tournament_awards.includes(:player).ordered

    @bracket = build_bracket(@matches_by_stage)
    @group_standings = build_group_standings(@matches_by_stage)
    @group_matches   = build_group_matches(@matches_by_stage)
  end

  private

  # Builds an ordered knockout tree: each round's matches are arranged so that
  # bracket[round][2i] and bracket[round][2i+1] both feed bracket[parent_round][i].
  # Returns nil if the tournament doesn't have a complete R16-based knockout phase.
  def build_bracket(matches_by_stage)
    final    = matches_by_stage["final"]&.first
    semis    = matches_by_stage["semi_final"]    || []
    quarters = matches_by_stage["quarter_final"] || []
    r16      = matches_by_stage["round_of_16"]   || []
    third    = matches_by_stage["third_place_playoff"]&.first

    return nil unless final && semis.size == 2 && quarters.size == 4 && r16.size == 8

    ordered_semis    = children_in_order(final, semis)
    ordered_quarters = ordered_semis.flat_map    { |s| children_in_order(s, quarters) }
    ordered_r16      = ordered_quarters.flat_map { |q| children_in_order(q, r16) }

    {
      final:       final,
      third_place: third,
      semis:       ordered_semis,        # 2 in order: [0] feeds final.home, [1] feeds final.away
      quarters:    ordered_quarters,     # 4 in order: [2i, 2i+1] feed semis[i]
      round_of_16: ordered_r16           # 8 in order: [2i, 2i+1] feed quarters[i]
    }
  end

  # Returns { "A" => [match, match, ...], "B" => [...], ... } sorted by group letter,
  # so each group's expandable card knows which fixtures belong to it.
  def build_group_matches(matches_by_stage)
    group_stage_matches = matches_by_stage["group_stage"] || []
    return nil if group_stage_matches.empty?

    group_stage_matches
      .group_by(&:group_letter)
      .reject { |k, _| k.blank? }
      .sort
      .to_h
  end

  # Computes W-D-L-GF-GA-Pts rows per group_letter from group_stage matches,
  # sorted within each group by Pts desc, GD desc, GF desc.
  # Returns { "A" => [row, row, ...], "B" => [...], ... } ordered by group letter,
  # or nil if there's no group-stage data on this tournament.
  def build_group_standings(matches_by_stage)
    group_matches = matches_by_stage["group_stage"] || []
    return nil if group_matches.empty?

    groups = Hash.new { |h, k| h[k] = {} }

    group_matches.each do |match|
      letter = match.group_letter.presence
      next unless letter

      [[match.home_team, match.home_score, match.away_score],
       [match.away_team, match.away_score, match.home_score]].each do |team, gf, ga|
        row = (groups[letter][team.id] ||= {
          team: team, p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0
        })
        row[:p]  += 1
        row[:gf] += gf
        row[:ga] += ga

        if match.winner_team_id == team.id
          row[:w]   += 1
          row[:pts] += 3
        elsif match.winner_team_id.present?
          row[:l] += 1
        else
          row[:d]   += 1
          row[:pts] += 1
        end
      end
    end

    groups.transform_values do |rows|
      rows.values.sort_by { |r| [-r[:pts], -(r[:gf] - r[:ga]), -r[:gf], r[:team].name] }
    end.sort.to_h
  end

  # Returns [child_whose_winner_is_parent.home_team, child_whose_winner_is_parent.away_team].
  # Falls back to slotting any leftover child if a winner-team match isn't found
  # (covers data gaps without crashing the page).
  def children_in_order(parent, pool)
    remaining = pool.dup
    home_child = remaining.find { |c| c.winner_team_id == parent.home_team_id }
    remaining.delete(home_child) if home_child
    away_child = remaining.find { |c| c.winner_team_id == parent.away_team_id }
    remaining.delete(away_child) if away_child

    [home_child || remaining.shift, away_child || remaining.shift]
  end
end
