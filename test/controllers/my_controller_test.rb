require "test_helper"

class MyControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get my_path

    assert_redirected_to new_session_path
  end

  test "shows accounts and sign out for regular users" do
    sign_in_as(users(:two))

    get my_path

    assert_response :success
    assert_match "My", response.body
    assert_match "X accounts", response.body
    assert_match "Sign out", response.body
    refute_match "Article admin", response.body
    refute_match "Jobs", response.body
  end

  test "shows admin tools for admin users" do
    sign_in_as(users(:one))

    get my_path

    assert_response :success
    assert_match "Article admin", response.body
    assert_match "Jobs", response.body
    assert_match "Accounts", response.body
  end
end
