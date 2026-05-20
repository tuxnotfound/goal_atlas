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
  end
end
