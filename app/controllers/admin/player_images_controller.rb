module Admin
  class PlayerImagesController < Admin::ApplicationController
    def index
      scope = Player.kept.includes(:nationality_team, :player_images)
      scope = scope.where(nationality_team_id: params[:team_id]) if params[:team_id].present?

      if params[:tournament_id].present?
        ids = player_ids_in_tournament(params[:tournament_id])
        scope = scope.where(id: ids)
      end

      @players = scope.order(:name).to_a
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

    def set_portrait
      image = PlayerImage.find(params[:id])
      PlayerImage.transaction do
        image.player.player_images.where.not(id: image.id).update_all(is_portrait: false)
        image.update!(is_portrait: true)
      end
      redirect_back fallback_location: admin_player_image_path(image),
                    notice: "Portrait image set for #{image.player.name}."
    end

    private

    def player_ids_in_tournament(tournament_id)
      scorer_ids = Goal.kept.joins(:match).where(matches: { tournament_id: tournament_id }).distinct.pluck(:player_id)
      kicker_ids = ShootoutKick.kept.joins(:match).where(matches: { tournament_id: tournament_id }).distinct.pluck(:player_id)
      award_ids  = TournamentAward.where(tournament_id: tournament_id).pluck(:player_id)
      (scorer_ids + kicker_ids + award_ids).uniq
    end

    public

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

    # Manual escape hatch for players whose portraits the Wikimedia scout can't
    # find. Admin pastes any image URL; we add it as a regular PlayerImage so
    # it shows up in the gallery and can be selected as is_portrait / fed into
    # the stylizer like any other image.
    def add_url
      player = Player.friendly.find(params[:player_id])
      url    = params[:url].to_s.strip

      if url.blank?
        redirect_to admin_player_path(player), alert: "Image URL required."
        return
      end

      image = player.player_images.build(
        url:           url,
        thumbnail_url: url,
        description:   params[:description].presence || "Manually added by admin",
        author:        params[:author].presence,
        license:       params[:license].presence,
        is_active:     true,
        position:      (player.player_images.maximum(:position) || 0) + 1,
        fetched_at:    Time.current
      )

      if image.save
        redirect_to admin_player_path(player),
                    notice: "Added manual image ##{image.id} for #{player.name}."
      else
        redirect_to admin_player_path(player),
                    alert: "Couldn't add image: #{image.errors.full_messages.join(', ')}"
      end
    end
  end
end
