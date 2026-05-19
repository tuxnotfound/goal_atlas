module Admin
  class TeamsController < Admin::ApplicationController
    # Teams use FriendlyId slugs in URLs, so admin links look like /admin/teams/argentina.
    def find_resource(param)
      Team.friendly.find(param)
    end
  end
end
