class MatchesController < ApplicationController
  def index
    # Only already-played matches — excludes scheduled fixtures and the WC2026
    # knockout placeholders (which are scheduled and may not have teams yet).
    @matches = Match.kept
                    .where.not(result_type: :scheduled)
                    .includes(:home_team, :away_team, :tournament, :stadium)
                    .order(date: :desc, id: :desc)
  end

  def show
    @match = Match.kept.friendly.find(params[:slug])
    @goals = @match.goals.kept.includes(:player, :scoring_team, :goal_tags, :video_links).ordered_within_match
    @shootout_kicks = @match.shootout_kicks.kept.includes(:player, :team).ordered
    @video_links = @match.video_links.kept.active
  end
end
