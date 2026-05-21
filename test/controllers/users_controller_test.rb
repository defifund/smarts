require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "new renders registration form" do
    get new_user_path

    assert_response :success
    assert_match "Create account", response.body
  end

  test "create registers user, starts session, and shows api token once" do
    assert_difference "User.count", 1 do
      post users_path, params: {
        user: {
          name: "Publisher",
          email_address: "publisher@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_response :created
    assert cookies[:session_id]
    assert_match(/sma_/, response.body)

    user = User.find_by!(email_address: "publisher@example.com")
    token = response.body[/sma_[A-Za-z0-9_-]+/]
    refute_match user.api_token_digest, response.body
    assert_equal user, User.authenticate_api_token(token)

    # Each Connect MCP card embeds the publishing token directly into the
    # client setup command, so users don't have to pass `publish_token` to
    # every tool call afterward.
    assert_match "claude mcp add --scope user --transport http smarts", response.body
    assert_match "https://smarts.md/mcp", response.body
    assert_match %(--header &quot;Authorization: Bearer #{token}&quot;), response.body

    assert_match "export SMARTS_PUBLISH_TOKEN=#{token}", response.body
    assert_match "codex mcp add smarts", response.body
    assert_match "--bearer-token-env-var SMARTS_PUBLISH_TOKEN", response.body

    assert_match "amp mcp add smarts", response.body
    assert_match %(--header &quot;Authorization=Bearer #{token}&quot;), response.body
  end

  test "create re-renders form for invalid input" do
    post users_path, params: {
      user: {
        name: "",
        email_address: "bad@example.com",
        password: "password",
        password_confirmation: "different"
      }
    }

    assert_response :unprocessable_entity
    assert_match "Could not create account", response.body
    assert_nil User.find_by(email_address: "bad@example.com")
  end
end
