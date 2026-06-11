# All Administrate controllers inherit from this. Auth is enforced here so
# every /admin/* route requires (a) a valid session and (b) an admin user.
module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication

    before_action :require_admin

    private

    def require_admin
      return if Current.user&.admin?
      reset_session
      redirect_to new_session_path, alert: "Admin access required."
    end
  end
end
