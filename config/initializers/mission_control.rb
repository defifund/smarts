MissionControl::Jobs.http_basic_auth_enabled = false

Rails.application.config.to_prepare do
  MissionControl::Jobs::ApplicationController.class_eval do
    include Authentication
    before_action :require_admin_access

    private

    def request_authentication
      redirect_to main_app.new_session_path
    end

    def require_admin_access
      return if Current.user&.admin?

      redirect_to main_app.root_path, alert: "Admin access required."
    end
  end
end
