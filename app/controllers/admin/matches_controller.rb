module Admin
  class MatchesController < Admin::ApplicationController
    def find_resource(param)
      Match.friendly.find(param)
    end

    def scoped_resource
      scope = Match.kept
      scope = scope.where(tournament_id: params[:tournament_id]) if params[:tournament_id].present?
      scope = scope.where(stage: params[:stage]) if params[:stage].present?
      scope
    end

    def order
      @order ||= Administrate::Order.new(
        params.fetch(:order, "date"),
        params.fetch(:direction, "asc")
      )
    end
  end
end
