module Admin
  class TournamentsController < Admin::ApplicationController
    # Tournament#to_param returns the year, so admin links look like
    # /admin/tournaments/2022. Look up by year, not primary key.
    def find_resource(param)
      Tournament.find_by!(year: param)
    end
  end
end
