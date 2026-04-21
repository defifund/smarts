RubyLLM.configure do |config|
  config.anthropic_api_key = Rails.application.credentials.dig(:anthropic, :api_key) ||
                             ENV["ANTHROPIC_API_KEY"]
  config.openai_api_key    = Rails.application.credentials.dig(:openai, :api_key) ||
                             ENV["OPENAI_API_KEY"]
end
