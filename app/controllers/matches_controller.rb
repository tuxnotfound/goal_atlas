class MatchesController < ApplicationController
  def index
    @matches = Match.kept.includes(:home_team, :away_team, :tournament, :stadium).ordered_by_date
  end

  def show
    @match = Match.kept.friendly.find(params[:slug])
    @goals = @match.goals.kept.includes(:player, :scoring_team).ordered_within_match
    @shootout_kicks = @match.shootout_kicks.kept.includes(:player, :team).ordered
  end
end
