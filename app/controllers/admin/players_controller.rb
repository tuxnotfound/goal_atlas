module Admin
  class PlayersController < Admin::ApplicationController
    def find_resource(param)
      Player.friendly.find(param)
    end
  end
end
