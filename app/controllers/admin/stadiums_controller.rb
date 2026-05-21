module Admin
  class StadiumsController < Admin::ApplicationController
    def find_resource(param)
      Stadium.friendly.find(param)
    end

    def scoped_resource
      scope = Stadium.kept

      if params[:tournament_id].present?
        ids = Match.kept.where(tournament_id: params[:tournament_id]).distinct.pluck(:stadium_id).compact
        scope = scope.where(id: ids)
      end

      scope
    end

    def order
      @order ||= Administrate::Order.new(
        params.fetch(:order, "name"),
        params.fetch(:direction, "asc")
      )
    end
  end
end
