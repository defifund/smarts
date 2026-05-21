require "test_helper"

class Auth::XControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "authorize requires valid locale" do
    get auth_x_path
    assert_response :bad_request

    get auth_x_path(locale: "fr")
    assert_response :bad_request
  end

  test "authorize redirects to x oauth and stores request tokens" do
    with_oauth_consumer(authorize_url: "https://api.twitter.com/oauth/authorize?oauth_token=req") do
      get auth_x_path(locale: "en")
    end

    assert_redirected_to "https://api.twitter.com/oauth/authorize?oauth_token=req"
    assert_equal "en", session[:x_oauth_locale]
    assert_equal "req_token", session[:x_request_token]
    assert_equal "req_secret", session[:x_request_token_secret]
  end

  test "callback creates locale account" do
    run_authorize(locale: "zh-CN")

    with_access_token(screen_name: "smarts_cn", token: "tok", secret: "sec") do
      assert_difference "users(:one).accounts.count", 1 do
        get auth_x_callback_path(oauth_verifier: "verifier")
      end
    end

    account = users(:one).accounts.find_by!(provider: "x", locale: "zh-CN")
    assert_equal "@smarts_cn", account.handle
    assert_equal "tok", account.access_token
    assert_equal "sec", account.access_token_secret
    assert_redirected_to accounts_path
  end

  test "callback updates existing locale account" do
    account = users(:one).accounts.create!(
      provider: "x",
      handle: "@old",
      locale: "en",
      access_token: "old-token",
      access_token_secret: "old-secret"
    )
    run_authorize(locale: "en")

    with_access_token(screen_name: "new_smarts", token: "new-token", secret: "new-secret") do
      assert_no_difference "users(:one).accounts.count" do
        get auth_x_callback_path(oauth_verifier: "verifier")
      end
    end

    account.reload
    assert_equal "@new_smarts", account.handle
    assert_equal "new-token", account.access_token
    assert_equal "new-secret", account.access_token_secret
  end

  test "callback redirects with alert when x oauth fails" do
    run_authorize(locale: "en")

    with_access_token_error(OAuth::Error.new("invalid_verifier")) do
      get auth_x_callback_path(oauth_verifier: "bad")
    end

    assert_redirected_to accounts_path
    assert_match "X authorization failed", flash[:alert]
  end

  private

  FakeRequestToken = Struct.new(:token, :secret, :authorize_url) do
    def get_access_token(oauth_verifier:)
      self.class.access_token.call(oauth_verifier)
    end

    class << self
      attr_accessor :access_token
    end
  end

  FakeAccessToken = Struct.new(:token, :secret, :params)

  def run_authorize(locale:)
    with_oauth_consumer do
      get auth_x_path(locale: locale)
    end
  end

  def with_oauth_consumer(authorize_url: "https://api.twitter.com/oauth/authorize?oauth_token=req_token")
    request_token = FakeRequestToken.new("req_token", "req_secret", authorize_url)
    fake_consumer = Struct.new(:request_token) do
      def get_request_token(oauth_callback:)
        request_token
      end
    end.new(request_token)

    stub_controller_oauth_consumer(fake_consumer) { yield }
  end

  def with_access_token(screen_name:, token:, secret:)
    FakeRequestToken.access_token = ->(_verifier) { FakeAccessToken.new(token, secret, { screen_name: screen_name }) }
    stub_request_token_class { yield }
  ensure
    FakeRequestToken.access_token = nil
  end

  def with_access_token_error(error)
    FakeRequestToken.access_token = ->(_verifier) { raise error }
    stub_request_token_class { yield }
  ensure
    FakeRequestToken.access_token = nil
  end

  def stub_controller_oauth_consumer(consumer)
    original = Auth::XController.instance_method(:oauth_consumer)
    Auth::XController.define_method(:oauth_consumer) { consumer }
    yield
  ensure
    Auth::XController.define_method(:oauth_consumer, original)
  end

  def stub_request_token_class
    original = OAuth.const_get(:RequestToken)
    OAuth.send(:remove_const, :RequestToken)
    OAuth.const_set(:RequestToken, FakeRequestToken)
    yield
  ensure
    OAuth.send(:remove_const, :RequestToken)
    OAuth.const_set(:RequestToken, original)
  end
end
