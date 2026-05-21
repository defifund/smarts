# frozen_string_literal: true

# Rack wrapper around `MCP::Server::Transports::StreamableHTTPTransport`.
# Reads an optional `Authorization: Bearer <token>` header, authenticates
# the publishing user, and stashes it on `Current.mcp_user` so per-request
# tool calls can read it without threading args through the MCP gem.
#
# Auth is optional at this layer — read-only tools (contract info, etc.)
# work without a token. Tools that require a publisher check
# `Current.mcp_user` themselves and return an error payload when absent.
class McpBearerAuth
  BEARER_PATTERN = /\ABearer\s+(?<token>\S+)\z/i

  def initialize(app)
    @app = app
  end

  def call(env)
    if (token = extract_bearer(env["HTTP_AUTHORIZATION"]))
      Current.mcp_user = User.authenticate_api_token(token)
    end

    @app.call(env)
  end

  private

  def extract_bearer(header)
    return nil if header.blank?

    match = header.match(BEARER_PATTERN)
    match && match[:token]
  end
end
