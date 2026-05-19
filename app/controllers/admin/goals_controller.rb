module Admin
  class GoalsController < Admin::ApplicationController
    def find_resource(param)
      Goal.friendly.find(param)
    end
  end
end
