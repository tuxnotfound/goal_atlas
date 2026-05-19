module Admin
  class GoalTagsController < Admin::ApplicationController
    def find_resource(param)
      GoalTag.friendly.find(param)
    end
  end
end
