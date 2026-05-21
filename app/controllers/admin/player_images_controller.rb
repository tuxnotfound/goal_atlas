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
      candidates = ::WikimediaPortraitScout.new(logger: Rails.logger).search(player_name: player.name)

      if candidates.empty?
        redirect_to admin_player_path(player), alert: "No portrait found on Wikidata for #{player.name}."
        return
      end

      c = candidates.first
      image = player.player_images.find_or_initialize_by(url: c.url)
      if image.persisted?
        redirect_to admin_player_path(player), notice: "#{player.name} already has this portrait."
        return
      end

      image.assign_attributes(
        source_url:    c.source_url,
        thumbnail_url: c.thumbnail_url,
        license:       c.license,
        license_url:   c.license_url,
        author:        c.author,
        description:   c.description,
        position:      player.player_images.maximum(:position).to_i + 1,
        is_default:    player.player_images.default.none?,
        is_active:     true,
        fetched_at:    Time.current
      )
      image.save!

      redirect_to admin_player_path(player),
                  notice: "Added portrait for #{player.name} (#{c.license})."
    end
  end
end
