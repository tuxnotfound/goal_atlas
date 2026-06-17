class TeamsController < ApplicationController
  TOP_SCORERS_LIMIT = 3

  def show
    @team = Team.kept.friendly.find(params[:slug])

    # Predecessor teams (e.g. West Germany) redirect to their canonical
    # successor so /teams/west-germany funnels into /teams/germany. The
    # successor page aggregates the predecessor's history below.
    if @team.successor_team
      redirect_to team_path(@team.successor_team), status: :moved_permanently
      return
    end

    team_ids = @team.family_ids

    @goals = Goal.kept.where(scoring_team_id: team_ids)
                 .includes(:player, :video_links, match: [:home_team, :away_team, :tournament])
                 .order("matches.date DESC, goals.minute ASC")
                 .references(:match)

    @matches = Match.kept
                    .where("home_team_id IN (:ids) OR away_team_id IN (:ids)", ids: team_ids)
                    .includes(:home_team, :away_team, :tournament, :stadium)
                    .order(date: :desc)

    @tournament_records = TeamTournamentRecord.for_team(@team)

    @team_awards = TournamentAward
                     .joins(:player)
                     .where(players: { nationality_team_id: team_ids })
                     .includes(:tournament, :player)
                     .order("tournaments.year DESC, award_type ASC")
                     .group_by(&:tournament)

    # All-time top scorers — every goal the player scored *for this team*,
    # across every World Cup. Powers the parchment podium on the team page.
    @top_scorers = Player
      .joins(goals: :match)
      .where(goals:   { scoring_team_id: team_ids, discarded_at: nil })
      .where(matches: { discarded_at: nil })
      .where.not(goals: { goal_type: Goal::GOAL_TYPES[:own_goal] }) # own goals are scored by an opponent, not this team's player
      .group("players.id")
      .order(Arel.sql("COUNT(goals.id) DESC, players.name ASC"))
      .limit(TOP_SCORERS_LIMIT)
      .select("players.*, COUNT(goals.id) AS goals_count")
  end
end
