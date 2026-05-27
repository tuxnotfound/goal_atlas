module Admin
  class StylizedPortraitsController < Admin::ApplicationController
    # POST /admin/players/:player_id/stylize_portrait
    # Synchronously generates a new stylized portrait via OpenAI gpt-image-1.
    # ~45-60s of blocking; acceptable for admin use until we wire ActiveJob.
    def create
      player = Player.friendly.find(params[:player_id])

      begin
        portrait = ::PortraitStylizer.new(player, logger: Rails.logger).generate!
      rescue => e
        redirect_to admin_player_path(player),
                    alert: "Stylize failed: #{e.class}: #{e.message.truncate(200)}"
        return
      end

      redirect_to admin_player_path(player),
                  notice: "Generated stylized portrait ##{portrait.id} for #{player.name}."
    end

    # PATCH /admin/stylized_portraits/:id/set_selected
    def set_selected
      portrait = StylizedPortrait.find(params[:id])
      StylizedPortrait.transaction do
        portrait.player.stylized_portraits.where.not(id: portrait.id).update_all(is_selected: false)
        portrait.update!(is_selected: true)
      end
      redirect_back fallback_location: admin_player_path(portrait.player),
                    notice: "Stylized portrait ##{portrait.id} selected for #{portrait.player.name}."
    end

    # DELETE /admin/stylized_portraits/:id
    def destroy
      portrait = StylizedPortrait.find(params[:id])
      player   = portrait.player
      File.delete(portrait.absolute_path) if portrait.file_exists?
      portrait.destroy!
      redirect_to admin_player_path(player),
                  notice: "Stylized portrait removed for #{player.name}."
    end
  end
end
