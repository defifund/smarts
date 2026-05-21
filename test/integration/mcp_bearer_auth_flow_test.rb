require "test_helper"

# End-to-end check that an `Authorization: Bearer <publish_token>` header
# on a POST to /mcp authenticates the publisher and reaches the article
# tool with `Current.mcp_user` populated. Exercises the real Rack stack:
# Rails middleware → McpBearerAuth → MCP transport → tool dispatch.
class McpBearerAuthFlowTest < ActionDispatch::IntegrationTest
  test "list_article_drafts succeeds with valid Bearer token" do
    body = post_mcp(
      method: "tools/call",
      params: { name: "list_article_drafts", arguments: {} },
      bearer: "sma_test_token_one"
    )

    assert_response :success

    payload = JSON.parse(body.dig("result", "content", 0, "text"))
    assert_kind_of Integer, payload["count"]
    assert_operator payload["count"], :>=, 1
    assert(payload["drafts"].any? { |d| d["slug"] == "ms" })
  end

  test "list_article_drafts returns auth error without Bearer token" do
    body = post_mcp(
      method: "tools/call",
      params: { name: "list_article_drafts", arguments: {} },
      bearer: nil
    )

    payload = JSON.parse(body.dig("result", "content", 0, "text"))
    assert_equal "Authorization: Bearer <publish_token> header is missing or invalid", payload["error"]
  end

  test "list_article_drafts returns auth error with invalid Bearer token" do
    body = post_mcp(
      method: "tools/call",
      params: { name: "list_article_drafts", arguments: {} },
      bearer: "bogus"
    )

    payload = JSON.parse(body.dig("result", "content", 0, "text"))
    assert_equal "Authorization: Bearer <publish_token> header is missing or invalid", payload["error"]
  end

  private

  # POSTs a single JSON-RPC message to the MCP endpoint and parses the
  # JSON-RPC envelope. Returns the parsed Hash body.
  def post_mcp(method:, params:, bearer:)
    headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json, text/event-stream"
    }
    headers["Authorization"] = "Bearer #{bearer}" if bearer

    payload = { jsonrpc: "2.0", id: 1, method: method, params: params }

    post "/mcp", params: payload.to_json, headers: headers
    JSON.parse(response.body)
  end
end
