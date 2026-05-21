# Aggregates a team's performance across one tournament — record, GF/GA,
# deepest stage reached, and final placement (champion / runner-up / etc.).
#
# Used by the public team page to build a "career" table without each row
# needing a separate DB query.
class TeamTournamentRecord
  STAGE_DEPTH = [
    :final, :third_place_playoff, :semi_final,
    :quarter_final, :round_of_16, :round_of_32,
    :second_group_stage, :group_stage
  ].freeze

  attr_reader :team, :tournament

  def initialize(team, tournament, matches: nil)
    @team       = team
    @tournament = tournament
    @matches    = matches
  end

  # Returns an Array<TeamTournamentRecord> for every tournament the team has
  # any match in, ordered chronologically. Issues two queries total regardless
  # of how many tournaments the team appeared in.
  def self.for_team(team)
    matches = Match.kept
                   .where("home_team_id = :id OR away_team_id = :id", id: team.id)
                   .includes(:tournament)
                   .ordered_by_date
                   .to_a

    by_tournament = matches.group_by(&:tournament)
    by_tournament
      .sort_by { |t, _| t.year }
      .map { |tournament, ms| new(team, tournament, matches: ms) }
  end

  def matches
    @matches ||= Match.kept.where(tournament: tournament)
                      .where("home_team_id = :id OR away_team_id = :id", id: team.id)
                      .ordered_by_date.to_a
  end

  def matches_played = matches.size
  def wins   = matches.count { |m| m.winner_team_id == team.id }
  def losses = matches.count { |m| m.winner_team_id.present? && m.winner_team_id != team.id }
  def draws  = matches_played - wins - losses

  def goals_for
    matches.sum { |m| score_for_team(m, team.id) }
  end

  def goals_against
    matches.sum { |m| score_for_team(m, opponent_id(m)) }
  end

  def goal_difference = goals_for - goals_against

  def finish_label
    return "Champions"    if tournament.winner_team_id      == team.id
    return "Runners-up"   if tournament.runner_up_team_id   == team.id
    return "Third place"  if tournament.third_place_team_id == team.id
    return "Fourth place" if tournament.fourth_place_team_id == team.id

    case deepest_stage
    when :semi_final         then "Semi-finals"
    when :quarter_final      then "Quarter-finals"
    when :round_of_16        then "Round of 16"
    when :round_of_32        then "Round of 32"
    when :second_group_stage then "Second group stage"
    when :group_stage        then "Group stage"
    end
  end

  # Returns the deepest stage symbol the team reached in this tournament.
  def deepest_stage
    played = matches.map { |m| m.stage.to_sym }.to_set
    STAGE_DEPTH.find { |s| played.include?(s) }
  end

  def champion?     = tournament.winner_team_id      == team.id
  def runner_up?    = tournament.runner_up_team_id   == team.id
  def podium?       = champion? || runner_up? ||
                       tournament.third_place_team_id  == team.id ||
                       tournament.fourth_place_team_id == team.id

  private

  def score_for_team(match, team_id)
    home = match.home_score_after_extra_time || match.home_score
    away = match.away_score_after_extra_time || match.away_score
    match.home_team_id == team_id ? home : away
  end

  def opponent_id(match)
    match.home_team_id == team.id ? match.away_team_id : match.home_team_id
  end
end
