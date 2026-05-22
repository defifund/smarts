require "test_helper"

class McpBearerAuthTest < ActiveSupport::TestCase
  teardown do
    Current.mcp_user = nil
  end

  test "valid Bearer token resolves Current.mcp_user before downstream runs" do
    captured = nil
    downstream = ->(_env) {
      captured = Current.mcp_user
      [ 200, {}, [] ]
    }

    middleware = McpBearerAuth.new(downstream)

    middleware.call(env_with("Bearer sma_test_token_one"))

    assert_equal users(:one), captured
  end

  test "missing header leaves Current.mcp_user nil" do
    downstream = ->(_env) { [ 200, {}, [] ] }

    McpBearerAuth.new(downstream).call(env_with(nil))

    assert_nil Current.mcp_user
  end

  test "invalid token leaves Current.mcp_user nil without raising" do
    downstream = ->(_env) { [ 200, {}, [] ] }

    McpBearerAuth.new(downstream).call(env_with("Bearer bogus"))

    assert_nil Current.mcp_user
  end

  test "non-bearer authorization schemes are ignored" do
    downstream = ->(_env) { [ 200, {}, [] ] }

    McpBearerAuth.new(downstream).call(env_with("Basic foo:bar"))

    assert_nil Current.mcp_user
  end

  test "bearer scheme parsing is case-insensitive" do
    downstream = ->(_env) { [ 200, {}, [] ] }

    McpBearerAuth.new(downstream).call(env_with("bearer sma_test_token_one"))

    assert_equal users(:one), Current.mcp_user
  end

  private

  def env_with(authorization)
    env = { "REQUEST_METHOD" => "POST" }
    env["HTTP_AUTHORIZATION"] = authorization if authorization
    env
  end
end
