require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get accounts_path

    assert_redirected_to new_session_path
  end

  test "shows x account connection status for supported locales" do
    sign_in_as(users(:one))
    users(:one).accounts.create!(
      provider: "x",
      handle: "@smarts",
      locale: "en",
      access_token: "token",
      access_token_secret: "secret"
    )

    get accounts_path

    assert_response :success
    assert_match "X accounts", response.body
    assert_match "@smarts", response.body
    assert_match "zh-CN", response.body
    assert_match "zh-TW", response.body
  end

  test "my page links to accounts and admin tools for admin users" do
    sign_in_as(users(:one))

    get my_path

    assert_response :success
    assert_match "Accounts", response.body
    assert_match "Article admin", response.body
    assert_match "Jobs", response.body
    assert_match "Sign out", response.body
  end
end
