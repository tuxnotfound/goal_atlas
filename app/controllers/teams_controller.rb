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

    @tournament_records = TeamTournamentRecord.for_team(@team)

    @team_awards = TournamentAward
                     .joins(:player)
                     .where(players: { nationality_team_id: @team.id })
                     .includes(:tournament, :player)
                     .order("tournaments.year DESC, award_type ASC")
                     .group_by(&:tournament)
  end
end
