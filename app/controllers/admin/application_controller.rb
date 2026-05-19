# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_admin

    private

    # Opt-in HTTP Basic Auth gated by an env var.
    #
    # - When ADMIN_PASSWORD is unset (typical local dev): admin is open.
    # - When ADMIN_PASSWORD is set (deployed environments): the prompt fires
    #   and ADMIN_USERNAME / ADMIN_PASSWORD must match.
    def authenticate_admin
      return if ENV["ADMIN_PASSWORD"].blank?

      authenticate_or_request_with_http_basic("Goal Atlas Admin") do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(username, ENV["ADMIN_USERNAME"].to_s) &
          ActiveSupport::SecurityUtils.secure_compare(password, ENV["ADMIN_PASSWORD"].to_s)
      end
    end
  end
end
