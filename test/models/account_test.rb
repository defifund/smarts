require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "validates locale and provider" do
    account = Account.new(
      user: users(:one),
      provider: "x",
      handle: "@smarts",
      locale: "zh-CN",
      access_token: "token",
      access_token_secret: "secret"
    )

    assert account.valid?

    account.locale = "fr"
    refute account.valid?
    assert account.errors[:locale].any?
  end

  test "encrypts x access tokens while keeping decrypted readers usable" do
    account = Account.create!(
      user: users(:one),
      provider: "x",
      handle: "@smarts",
      locale: "en",
      access_token: "plain-token",
      access_token_secret: "plain-secret"
    )

    raw = Account.connection.select_one("SELECT access_token, access_token_secret FROM accounts WHERE id = #{account.id}")

    refute_equal "plain-token", raw["access_token"]
    refute_equal "plain-secret", raw["access_token_secret"]
    assert_equal "plain-token", account.reload.access_token
    assert_equal "plain-secret", account.reload.access_token_secret
  end

  test "allows only one account per user provider and locale" do
    Account.create!(
      user: users(:one),
      provider: "x",
      handle: "@smarts",
      locale: "en",
      access_token: "token",
      access_token_secret: "secret"
    )

    duplicate = Account.new(
      user: users(:one),
      provider: "x",
      handle: "@smarts_alt",
      locale: "en",
      access_token: "token2",
      access_token_secret: "secret2"
    )

    refute duplicate.valid?
    assert duplicate.errors[:locale].any?
  end
end
