class TournamentsController < ApplicationController
  TOP_SCORERS_LIMIT = 10

  def index
    @tournaments = Tournament.kept
                              .includes(:winner_team)
                              .order(year: :desc)
  end

  def show
    @tournament = Tournament.kept.find_by!(year: params[:year])

    @prev_tournament = Tournament.kept.where("year < ?", @tournament.year).order(year: :desc).first
    @next_tournament = Tournament.kept.where("year > ?", @tournament.year).order(year: :asc).first

    @matches_by_stage = Match.kept
                             .where(tournament: @tournament)
                             .includes(:home_team, :away_team, :stadium)
                             .ordered_by_date
                             .group_by(&:stage)

    # Golden Boot leaderboard — own goals credit the opponent, so they must be
    # excluded or a defender's own goals could inflate (even top) the ranking.
    @top_scorers = Player
      .joins(goals: :match)
      .where(matches: { tournament_id: @tournament.id, discarded_at: nil })
      .where(goals:   { discarded_at: nil })
      .where.not(goals: { goal_type: Goal::GOAL_TYPES[:own_goal] })
      .group("players.id")
      .order(Arel.sql("COUNT(goals.id) DESC, players.name ASC"))
      .limit(TOP_SCORERS_LIMIT)
      .select("players.*, COUNT(goals.id) AS goals_count")

    @awards = @tournament.tournament_awards.includes(:player).ordered

    @bracket                 = build_bracket(@matches_by_stage)
    @group_standings         = build_group_standings(@matches_by_stage, stage_key: "group_stage")
    @group_matches           = build_group_matches(@matches_by_stage,   stage_key: "group_stage")
    @second_group_standings  = build_group_standings(@matches_by_stage, stage_key: "second_group_stage")
    @second_group_matches    = build_group_matches(@matches_by_stage,   stage_key: "second_group_stage")
  end

  private

  # Builds an ordered knockout tree: each round's matches are arranged so that
  # bracket[round][2i] and bracket[round][2i+1] both feed bracket[parent_round][i].
  # Rounds are added leftward from the final only when their match count is
  # canonical (SF=2, QF=4, R16=8); a non-canonical round (e.g. 1934/1938 QF with
  # replays) stops the climb so those matches fall back to a standalone panel.
  # Returns nil for tournaments without at least SF+F (e.g. 1974/1978).
  def build_bracket(matches_by_stage)
    # WC2026-style placeholder brackets carry source labels ("W74", "1E", …)
    # and may have no winners yet, so they can't be ordered by winner-tracing.
    # Order them structurally from the fixed match-number feeder map instead.
    return build_structured_bracket(matches_by_stage) if structured_knockout?(matches_by_stage)

    final    = matches_by_stage["final"]&.first
    semis    = dedupe_replays(matches_by_stage["semi_final"]    || [])
    quarters = dedupe_replays(matches_by_stage["quarter_final"] || [])
    r16      = dedupe_replays(matches_by_stage["round_of_16"]   || [])
    third    = matches_by_stage["third_place_playoff"]&.first

    return nil unless final

    # 1974/1978 path: the Final's two contestants came from two GS2 groups,
    # not from a knockout chain. Synthesize a "group outcome" left column so
    # the bracket still has shape.
    if semis.size != 2
      gs2_standings = build_group_standings(matches_by_stage, stage_key: "second_group_stage")
      return build_gs2_to_final_bracket(final, third, gs2_standings) if gs2_standings && gs2_standings.size == 2
      return nil
    end

    ordered_semis    = children_in_order(final, semis)
    ordered_quarters = []
    ordered_r16      = []
    rounds           = [:semi_final, :final]

    if quarters.size == 4
      ordered_quarters = ordered_semis.flat_map { |s| children_in_order(s, quarters) }
      rounds.unshift(:quarter_final)

      ordered_r16 = fit_r16_under_quarters(ordered_quarters, r16)
      if ordered_r16
        rounds.unshift(:round_of_16)
      else
        ordered_r16 = []
      end
    end

    {
      final:          final,
      third_place:    third,
      semis:          ordered_semis,    # 2 in order: [0] feeds final.home, [1] feeds final.away
      quarters:       ordered_quarters, # 4 in order: [2i, 2i+1] feed semis[i]; empty when QF isn't bracketable
      round_of_16:    ordered_r16,      # 8 entries: Match or { bye: true, team: ... }; empty when R16 isn't bracketable
      group_outcomes: [],               # only populated on the GS2→Final path
      rounds:         rounds            # left-to-right: which columns the view should render
    }
  end

  # True when the knockout matches were seeded as placeholders with source
  # labels (the WC2026 bracket) rather than as decided games with winners.
  def structured_knockout?(matches_by_stage)
    Match::KNOCKOUT_STAGES.any? do |stage|
      (matches_by_stage[stage] || []).any? { |m| m.home_source_label.present? }
    end
  end

  # Builds the ordered knockout tree from the fixed match-number feeder map by
  # expanding top-down from the Final via each side's "W##" source label. Each
  # match yields [home_feeder, away_feeder], so collecting level by level leaves
  # every round's cells already arranged as cells[2i]/cells[2i+1] → cells[i] above.
  # Returns the same shape as build_bracket, plus :round_of_32.
  def build_structured_bracket(matches_by_stage)
    final = matches_by_stage["final"]&.first
    return nil unless final

    third     = matches_by_stage["third_place_playoff"]&.first
    by_number = matches_by_stage.values_at(*Match::KNOCKOUT_STAGES).compact.flatten
                                .index_by(&:match_number)

    parent_of = { semi_final: :final, quarter_final: :semi_final,
                  round_of_16: :quarter_final, round_of_32: :round_of_16 }
    levels = { final: [final] }
    [:semi_final, :quarter_final, :round_of_16, :round_of_32].each do |round|
      levels[round] = levels[parent_of[round]].flat_map { |m| structured_feeders(m, by_number) }
    end

    expected = { round_of_32: 16, round_of_16: 8, quarter_final: 4, semi_final: 2 }
    rounds   = [:final]
    [:semi_final, :quarter_final, :round_of_16, :round_of_32].each do |r|
      break unless matches_by_stage[r.to_s]&.any? && levels[r].compact.size == expected[r]
      rounds.unshift(r)
    end

    {
      final:          final,
      third_place:    third,
      semis:          levels[:semi_final],
      quarters:       levels[:quarter_final],
      round_of_16:    levels[:round_of_16],
      round_of_32:    levels[:round_of_32],
      group_outcomes: [],
      rounds:         rounds
    }
  end

  # The two matches that feed a match's home/away sides, parsed from "W##"
  # source labels (nil for a side fed by a group position or not yet linked).
  def structured_feeders(match, by_number)
    [match&.home_source_label, match&.away_source_label].map do |label|
      label =~ /\AW(\d+)\z/ ? by_number[$1.to_i] : nil
    end
  end

  # Fits R16 matches under the 4 ordered QFs, allowing one or more byes for
  # tournaments where a team walked over (1938: Sweden, after Austria's
  # withdrawal). Returns an 8-element array of Match-or-bye, or nil when the
  # set can't be slotted (extras left over, or a QF feeder we can't trace).
  def fit_r16_under_quarters(ordered_quarters, r16)
    return nil if r16.empty?

    remaining = r16.dup
    result = ordered_quarters.flat_map do |qf|
      [qf.home_team, qf.away_team].map do |team|
        match = remaining.find { |r| r.winner_team_id == team.id }
        if match
          remaining.delete(match)
          match
        else
          { bye: true, team: team }
        end
      end
    end

    return nil if remaining.any?
    result
  end

  # 1974/1978 path: two GS2 groups, each group's winner played the Final and
  # each runner-up played the third-place match. Builds a 2-column bracket
  # with synthetic "group outcome" nodes feeding into the Final.
  def build_gs2_to_final_bracket(final, third, gs2_standings)
    groups = gs2_standings.map do |letter, rows|
      { letter: letter, winner: rows[0][:team], runner_up: rows[1]&.dig(:team) }
    end

    home_group = groups.find { |g| g[:winner].id == final.home_team_id }
    away_group = groups.find { |g| g[:winner].id == final.away_team_id }
    return nil unless home_group && away_group

    group_outcomes = [
      { team: home_group[:winner], group_letter: home_group[:letter] },
      { team: away_group[:winner], group_letter: away_group[:letter] }
    ]

    {
      final:          final,
      third_place:    third,
      semis:          [],
      quarters:       [],
      round_of_16:    [],
      group_outcomes: group_outcomes,
      rounds:         [:group_outcome, :final]
    }
  end

  # Returns { "A" => [match, match, ...], "B" => [...], ... } sorted by group letter,
  # so each group's expandable card knows which fixtures belong to it. The
  # single-group case (1950's final round, no letter) becomes the "" key so the
  # view renders one untitled table.
  def build_group_matches(matches_by_stage, stage_key: "group_stage")
    matches = matches_by_stage[stage_key] || []
    return nil if matches.empty?

    matches.group_by { |m| m.group_letter.to_s }.sort.to_h
  end

  # Computes W-D-L-GF-GA-Pts rows per group_letter from group-stage matches,
  # sorted within each group by Pts desc, GD desc, GF desc.
  # Returns { "A" => [row, row, ...], "B" => [...], ... } ordered by group letter,
  # or nil if there's no data for this stage. Each row carries an :advanced flag
  # set from "did this team play any match after this stage?" — covers
  # winner-only formats (1930/1950), top-2 (modern), the 1986-1994 best-4-3rd
  # wildcard, and 1982's GS2 winners-only-advance without hardcoding rules.
  def build_group_standings(matches_by_stage, stage_key: "group_stage")
    group_matches = matches_by_stage[stage_key] || []
    return nil if group_matches.empty?

    post_stages = case stage_key
                  when "group_stage"
                    %w[second_group_stage round_of_32 round_of_16 quarter_final semi_final third_place_playoff final]
                  when "second_group_stage"
                    %w[round_of_32 round_of_16 quarter_final semi_final third_place_playoff final]
                  else
                    []
                  end

    advancing_team_ids = post_stages.flat_map { |s| matches_by_stage[s] || [] }
                                     .flat_map { |m| [m.home_team_id, m.away_team_id] }
                                     .compact
                                     .to_set

    GroupStandings.call(group_matches).transform_values do |rows|
      rows.each { |r| r[:advanced] = advancing_team_ids.include?(r[:team].id) }
      rows
    end
  end

  # Folds knockout replays into a single slot: matches between the same pair
  # of teams collapse to the latest one (the replay that actually determined
  # the advancer). Lets 1934's QF and 1938's R16/QF read as canonical
  # 8/4/2/1 brackets instead of falling out to standalone panels.
  def dedupe_replays(matches)
    matches.sort_by(&:date).each_with_object({}) do |m, h|
      h[[m.home_team_id, m.away_team_id].sort] = m
    end.values
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
