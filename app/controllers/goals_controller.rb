class GoalsController < ApplicationController
  def show
    @goal = Goal.kept.includes(:goal_tags).friendly.find(params[:slug])
    @match = @goal.match
    @tournament = @match.tournament
    @scorer = @goal.player
    @scoring_team = @goal.scoring_team
    @opponent_team = @goal.opponent_team

    @video_links = @goal.video_links.kept.active
  end
end
