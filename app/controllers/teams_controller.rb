class TeamsController < ApplicationController
  TOP_SCORERS_LIMIT = 3

  def show
    @team = Team.kept.friendly.find(params[:slug])

    @goals = Goal.kept.by_team(@team)
                 .includes(:player, match: [:home_team, :away_team, :tournament])
                 .order("matches.date DESC, goals.minute ASC")
                 .references(:match)

    @matches = Match.kept
                    .where("home_team_id = :id OR away_team_id = :id", id: @team.id)
                    .includes(:home_team, :away_team, :tournament, :stadium)
                    .order(date: :desc)

    @tournament_records = TeamTournamentRecord.for_team(@team)

    @team_awards = TournamentAward
                     .joins(:player)
                     .where(players: { nationality_team_id: @team.id })
                     .includes(:tournament, :player)
                     .order("tournaments.year DESC, award_type ASC")
                     .group_by(&:tournament)

    # All-time top scorers — every goal the player scored *for this team*,
    # across every World Cup. Powers the parchment podium on the team page.
    @top_scorers = Player
      .joins(goals: :match)
      .where(goals:   { scoring_team_id: @team.id, discarded_at: nil })
      .where(matches: { discarded_at: nil })
      .group("players.id")
      .order(Arel.sql("COUNT(goals.id) DESC, players.name ASC"))
      .limit(TOP_SCORERS_LIMIT)
      .select("players.*, COUNT(goals.id) AS goals_count")
  end
end
