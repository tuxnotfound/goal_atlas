module Admin
  class GoalsController < Admin::ApplicationController
    def find_resource(param)
      Goal.friendly.find(param)
    end

    def scoped_resource
      scope = Goal.kept.joins(:match)
      scope = scope.where(matches: { tournament_id: params[:tournament_id] }) if params[:tournament_id].present?
      scope = scope.where(match_id: params[:match_id]) if params[:match_id].present?
      scope
    end

    def order
      @order ||= Administrate::Order.new(
        params.fetch(:order, "minute"),
        params.fetch(:direction, "asc")
      )
    end
  end
end
