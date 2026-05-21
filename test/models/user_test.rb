require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "authenticates api token by prefix and digest" do
    assert_equal users(:one), User.authenticate_api_token("sma_test_token_one")
    assert_nil User.authenticate_api_token("sma_test_token_wrong")
  end

  test "rotates api token and returns the only visible plain token" do
    token = users(:one).rotate_api_token!

    assert token.start_with?("sma_")
    assert_equal users(:one), User.authenticate_api_token(token)
    assert_nil User.authenticate_api_token("sma_test_token_one")
  end
end
