module Admin
  class TeamsController < Admin::ApplicationController
    # Teams use FriendlyId slugs in URLs, so admin links look like /admin/teams/argentina.
    def find_resource(param)
      Team.friendly.find(param)
    end

    def scoped_resource
      scope = Team.kept

      if params[:tournament_id].present?
        ids = Match.kept.where(tournament_id: params[:tournament_id])
                       .pluck(:home_team_id, :away_team_id)
                       .flatten.uniq
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
