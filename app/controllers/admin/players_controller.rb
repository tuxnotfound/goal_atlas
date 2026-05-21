module Admin
  class PlayersController < Admin::ApplicationController
    def find_resource(param)
      Player.friendly.find(param)
    end

    def scoped_resource
      scope = Player.kept
      scope = scope.where(nationality_team_id: params[:team_id]) if params[:team_id].present?

      if params[:tournament_id].present?
        ids = player_ids_in_tournament(params[:tournament_id])
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

    private

    def player_ids_in_tournament(tournament_id)
      scorer_ids = Goal.kept.joins(:match).where(matches: { tournament_id: tournament_id }).distinct.pluck(:player_id)
      kicker_ids = ShootoutKick.kept.joins(:match).where(matches: { tournament_id: tournament_id }).distinct.pluck(:player_id)
      award_ids  = TournamentAward.where(tournament_id: tournament_id).pluck(:player_id)
      (scorer_ids + kicker_ids + award_ids).uniq
    end
  end
end
