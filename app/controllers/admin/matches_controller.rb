module Admin
  class MatchesController < Admin::ApplicationController
    def find_resource(param)
      Match.friendly.find(param)
    end
  end
end
