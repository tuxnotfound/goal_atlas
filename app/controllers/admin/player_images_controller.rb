module Admin
  class PlayerImagesController < Admin::ApplicationController
    def index
      @players = Player.kept
                       .includes(:nationality_team, :player_images)
                       .order(:name)
                       .to_a

      @counts = {
        total:       @players.size,
        with_image:  @players.count { |p| p.player_images.any? },
        with_default: @players.count { |p| p.player_images.any?(&:is_default?) }
      }

      render :index_by_player
    end

    def set_default
      image = PlayerImage.find(params[:id])
      PlayerImage.transaction do
        image.player.player_images.where.not(id: image.id).update_all(is_default: false)
        image.update!(is_default: true)
      end
      redirect_back fallback_location: admin_player_image_path(image),
                    notice: "Default image set for #{image.player.name}."
    end

    def scout
      player = Player.friendly.find(params[:player_id])
      result = ::PlayerImageImporter.new(player, logger: Rails.logger).import!

      if result.candidates.empty?
        redirect_to admin_player_path(player), alert: "No portraits found for #{player.name}."
        return
      end

      redirect_to admin_player_path(player),
                  notice: "Scouted #{result.candidates.size} candidate(s) for #{player.name}; #{result.added.size} new, #{result.tournament_tags} tournament tag(s)."
    end
  end
end
