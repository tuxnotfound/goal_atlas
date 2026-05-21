module Admin
  class PlayerImagesController < Admin::ApplicationController
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
      candidates = ::WikimediaPortraitScout.new(logger: Rails.logger).search(player_name: player.name, max: 8)
      created = 0
      candidates.each_with_index do |c, i|
        image = player.player_images.find_or_initialize_by(url: c.url)
        next unless image.new_record?
        image.assign_attributes(
          source_url:    c.source_url,
          thumbnail_url: c.thumbnail_url,
          license:       c.license,
          license_url:   c.license_url,
          author:        c.author,
          description:   c.description,
          position:      player.player_images.maximum(:position).to_i + 1 + i,
          is_default:    player.player_images.default.none? && i == 0,
          is_active:     true,
          fetched_at:    Time.current
        )
        image.save!
        created += 1
      end
      redirect_to admin_player_path(player),
                  notice: "Scouted #{candidates.size} candidate(s) for #{player.name}; #{created} new."
    end
  end
end
