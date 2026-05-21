MissionControl::Jobs.http_basic_auth_enabled = false

Rails.application.config.to_prepare do
  MissionControl::Jobs::ApplicationController.class_eval do
    include Authentication

    private

    def request_authentication
      redirect_to main_app.new_session_path
    end
  end
end
