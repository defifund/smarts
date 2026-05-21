class Auth::XController < ApplicationController
  def authorize
    locale = params[:locale].presence
    raise ActionController::BadRequest, "locale is required" unless Article::SUPPORTED_LOCALES.include?(locale)

    request_token = oauth_consumer.get_request_token(oauth_callback: oauth_callback_url)
    session[:x_oauth_locale] = locale
    session[:x_request_token] = request_token.token
    session[:x_request_token_secret] = request_token.secret

    redirect_to request_token.authorize_url, allow_other_host: true
  end

  def callback
    locale = session.delete(:x_oauth_locale)
    request_token = OAuth::RequestToken.new(
      oauth_consumer,
      session.delete(:x_request_token),
      session.delete(:x_request_token_secret)
    )
    access_token = request_token.get_access_token(oauth_verifier: params[:oauth_verifier])
    handle = "@#{access_token.params[:screen_name]}"

    account = Current.user.accounts.find_or_initialize_by(provider: "x", locale: locale)
    account.update!(
      handle: handle,
      access_token: access_token.token,
      access_token_secret: access_token.secret
    )

    redirect_to accounts_path, notice: "Connected #{handle} for #{locale}."
  rescue OAuth::Error => e
    redirect_to accounts_path, alert: "X authorization failed: #{e.message}"
  end

  private

  def oauth_consumer
    OAuth::Consumer.new(
      Rails.application.credentials.dig(:x, :api_key),
      Rails.application.credentials.dig(:x, :api_key_secret),
      site: "https://api.twitter.com",
      request_token_path: "/oauth/request_token",
      authorize_path: "/oauth/authorize",
      access_token_path: "/oauth/access_token"
    )
  end

  def oauth_callback_url
    return ENV["X_OAUTH_CALLBACK_URL"] if ENV["X_OAUTH_CALLBACK_URL"].present?
    return auth_x_callback_url(host: "localhost", protocol: "http", port: 3000) if Rails.env.development?

    auth_x_callback_url
  end
end
