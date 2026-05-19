module Admin
  class StadiumsController < Admin::ApplicationController
    def find_resource(param)
      Stadium.friendly.find(param)
    end
  end
end
