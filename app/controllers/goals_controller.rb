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

    scope = scope.joins(:match).references(:match).order("matches.date DESC, goals.minute ASC")
    @goal_count = scope.size
    @pagy, @goals = pagy(scope, limit: 50)

    @goal_types  = Goal.goal_types.keys
    @tags        = GoalTag.order(:name)
    @tournaments = Tournament.kept.order(year: :desc)

    # Stage filter is contextual to a tournament — without a selected tournament
    # we'd be offering knockout rounds that don't even exist for some years.
    # When a tournament is selected we only surface the stages it actually had.
    @selected_tournament = Tournament.kept.find_by(year: params[:tournament]) if params[:tournament].present?
    @stages = if @selected_tournament
                stage_order = Match.stages.keys
                @selected_tournament.matches.kept.distinct.pluck(:stage).sort_by { |s| stage_order.index(s) || 99 }.reverse
              else
                []
              end
  end

  def show
    @goal = Goal.kept.includes(:goal_tags).friendly.find(params[:slug])
    @match = @goal.match
    @tournament = @match.tournament
    @scorer = @goal.player
    @scoring_team = @goal.scoring_team
    @opponent_team = @goal.opponent_team

    @video_links = @goal.video_links.kept.active
    @match_video_links = @match.video_links.kept.active
  end
end
