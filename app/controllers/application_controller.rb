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
    locale_key = cookies[:locale].presence
    resolved = LOCALE_MAP[locale_key] || "en"
    I18n.locale = resolved
  end

  def mcp_endpoint_url
    return "#{request.base_url}/mcp" if local_mcp_host?

    MCP_ENDPOINT_URL
  end

  def local_mcp_host?
    Rails.env.development? || request.host == "127.0.0.1" || request.host == "localhost" || request.host.ends_with?(".localhost")
  end
end
