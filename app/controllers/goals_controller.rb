class GoalsController < ApplicationController
  RELATED_LIMIT = 8

  def show
    @goal = Goal.kept.friendly.find(params[:slug])
    @match = @goal.match
    @tournament = @match.tournament
    @scorer = @goal.player
    @scoring_team = @goal.scoring_team
    @opponent_team = @goal.opponent_team

    base = Goal.kept.where.not(id: @goal.id).includes(:player, :scoring_team, match: :tournament)

    @related_by_player     = base.by_player(@scorer).limit(RELATED_LIMIT)
    @related_by_team       = base.by_team(@scoring_team).limit(RELATED_LIMIT)
    @related_by_tournament = base.in_tournament(@tournament).limit(RELATED_LIMIT)
    @related_vs_opponent   = base.against_team(@opponent_team).limit(RELATED_LIMIT)

    @video_links = @goal.video_links.kept.active
  end
end
