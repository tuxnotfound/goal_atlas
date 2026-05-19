class GoalsController < ApplicationController
  FILTER_PARAMS = %i[type tag stage tournament].freeze

  def index
    scope = Goal.kept.includes(:player, :scoring_team, :goal_tags, match: :tournament)

    if params[:type].present? && Goal.goal_types.key?(params[:type])
      scope = scope.where(goal_type: params[:type])
    end

    if params[:stage].present? && Match.stages.key?(params[:stage])
      scope = scope.joins(:match).where(matches: { stage: params[:stage] })
    end

    if params[:tournament].present?
      tournament = Tournament.find_by(year: params[:tournament])
      scope = scope.in_tournament(tournament) if tournament
    end

    if params[:tag].present?
      tag = GoalTag.find_by(slug: params[:tag])
      scope = scope.joins(:goal_taggings).where(goal_taggings: { goal_tag_id: tag.id }) if tag
    end

    @goals = scope.joins(:match).references(:match).order("matches.date ASC, goals.minute ASC")
    @goal_count = @goals.size

    @goal_types  = Goal.goal_types.keys
    @stages      = Match.stages.keys.reverse
    @tags        = GoalTag.order(:name)
    @tournaments = Tournament.kept.order(year: :desc)
  end

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
