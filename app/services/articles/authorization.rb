# frozen_string_literal: true

module Articles
  module Authorization
    module_function

    def authenticate(token)
      User.authenticate_api_token(token)
    end

    def error_payload
      { error: "article publishing token is missing or invalid" }
    end
  end
end
