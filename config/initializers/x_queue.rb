XQueue.configure do |config|
  config.api_key = Rails.application.credentials.dig(:x, :api_key)
  config.api_key_secret = Rails.application.credentials.dig(:x, :api_key_secret)

  config.delay_range = 20..40
  config.thread_delay_range = 1..5
  config.queue_name = :default
end
