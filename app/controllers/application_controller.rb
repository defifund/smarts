class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  MCP_ENDPOINT_URL = "https://smarts.md/mcp".freeze

  LOCALE_MAP = { "cn" => "zh-CN", "tw" => "zh-TW", "en" => "en" }.freeze

  before_action :set_locale

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :mcp_endpoint_url

  private

  def set_locale
    route_locale = request.path_parameters[:locale].presence
    locale_key = route_locale || cookies[:locale].presence
    resolved =
      if route_locale.present?
        LOCALE_MAP[route_locale] || "en"
      else
        LOCALE_MAP[locale_key] || "en"
      end

    I18n.locale = resolved

    return unless route_locale.present? && LOCALE_MAP.key?(route_locale)

    cookies[:locale] = {
      value: route_locale,
      path: "/",
      expires: 1.year.from_now,
      same_site: :lax
    }
  end

  def mcp_endpoint_url
    return "#{request.base_url}/mcp" if local_mcp_host?

    MCP_ENDPOINT_URL
  end

  def local_mcp_host?
    Rails.env.development? || request.host == "127.0.0.1" || request.host == "localhost" || request.host.ends_with?(".localhost")
  end
end
