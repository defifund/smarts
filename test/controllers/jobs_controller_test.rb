require "test_helper"

class JobsControllerTest < ActionDispatch::IntegrationTest
  test "jobs dashboard requires authentication" do
    get "/jobs"

    assert_redirected_to "/session/new"
  end

  test "jobs dashboard rejects non-admin users" do
    sign_in_as(users(:two))

    get "/jobs"

    assert_redirected_to "/?server_id=async"
  end

  test "jobs dashboard is reachable for admin users" do
    sign_in_as(users(:one))

    get "/jobs"

    assert_response :success
    assert_match "Queues", response.body
  end
end
