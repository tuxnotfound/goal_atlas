class TeamsController < ApplicationController
  def show
    @team = Team.kept.friendly.find(params[:slug])

    @goals = Goal.kept.by_team(@team)
                 .includes(:player, match: [:home_team, :away_team, :tournament])
                 .order("matches.date ASC, goals.minute ASC")
                 .references(:match)

    @matches = Match.kept
                    .where("home_team_id = :id OR away_team_id = :id", id: @team.id)
                    .includes(:home_team, :away_team, :tournament, :stadium)
                    .ordered_by_date
  end
end
