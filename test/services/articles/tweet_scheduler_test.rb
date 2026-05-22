require "test_helper"

class Articles::TweetSchedulerTest < ActiveSupport::TestCase
  test "schedules locale tweets as a thread no earlier than article published_at" do
    article = create_article(slug: "2a", published_at: 2.days.from_now.change(usec: 0))
    account = create_x_account(users(:one), locale: "en")

    result = Articles::TweetScheduler.call(
      article: article,
      user: users(:one),
      tweets: { "en" => [ "One", "Two" ] }
    )

    assert result.valid?, result.errors.inspect
    assert_equal({ "en" => 2 }, result.scheduled)

    tweets = XQueue::Tweet.where(account: account).order(:thread_position)
    assert_equal 2, tweets.size
    assert_equal [ "One", "Two" ], tweets.pluck(:content)
    assert_equal [ 1, 2 ], tweets.pluck(:thread_position)
    assert tweets.first.thread_id.present?
    assert_equal 1, tweets.distinct.count(:thread_id)
    assert tweets.all? { |tweet| tweet.scheduled_at >= article.published_at }
  end

  test "schedules independent tweets when thread is false" do
    article = create_article(slug: "2b", published_at: 1.day.from_now.change(usec: 0))
    account = create_x_account(users(:one), locale: "zh-CN")

    result = Articles::TweetScheduler.call(
      article: article,
      user: users(:one),
      tweets: { "zh-CN" => [ "第一条", "第二条" ] },
      thread: false
    )

    assert result.valid?, result.errors.inspect
    assert_equal({ "zh-CN" => 2 }, result.scheduled)

    tweets = XQueue::Tweet.where(account: account).order(:scheduled_at)
    assert_equal 2, tweets.size
    assert_equal [ nil, nil ], tweets.pluck(:thread_id)
    assert tweets.all? { |tweet| tweet.scheduled_at >= article.published_at }
  end

  test "returns per-locale errors for missing account and unsupported locale" do
    article = create_article(slug: "2c")

    result = Articles::TweetScheduler.call(
      article: article,
      user: users(:one),
      tweets: {
        "zh-TW" => [ "繁體貼文" ],
        "fr" => [ "Bonjour" ]
      }
    )

    assert_equal({}, result.scheduled)
    assert_equal "missing x account for zh-TW", result.errors["zh-TW"]
    assert_equal "unsupported locale", result.errors["fr"]
  end

  test "with explicit at: schedules tweets at that exact time even when account queue has later items" do
    article = create_article(slug: "2e", published_at: 1.day.from_now)
    account = create_x_account(users(:one), locale: "en")
    later = 2.days.from_now.change(usec: 0)
    XQueue::Tweet.create!(content: "later", account: account, status: :scheduled, scheduled_at: later)

    target = 6.hours.from_now.change(usec: 0)
    result = Articles::TweetScheduler.call(
      article: article,
      user: users(:one),
      tweets: { "en" => [ "T1", "T2" ] },
      at: target
    )

    assert result.valid?, result.errors.inspect
    new_tweets = XQueue::Tweet.where(account: account, content: [ "T1", "T2" ])
    assert_equal 2, new_tweets.size
    assert new_tweets.all? { |t| t.scheduled_at == target }, new_tweets.map(&:scheduled_at).inspect
  end

  test "ignores blank tweets and non-hash tweet payloads" do
    article = create_article(slug: "2d")
    create_x_account(users(:one), locale: "en")

    assert_no_difference "XQueue::Tweet.count" do
      blank_result = Articles::TweetScheduler.call(article: article, user: users(:one), tweets: { "en" => [ "", "  " ] })
      invalid_result = Articles::TweetScheduler.call(article: article, user: users(:one), tweets: "not a hash")

      assert blank_result.valid?
      assert invalid_result.valid?
    end
  end

  private

  def create_article(slug:, published_at: Time.current)
    Article.create!(
      user: users(:one),
      slug: slug,
      category: "product",
      subcategory: "mcp",
      title: { "en" => "Title" },
      summary: { "en" => "Summary" },
      content: { "en" => "Body" },
      published_at: published_at
    )
  end

  def create_x_account(user, locale:)
    Account.create!(
      user: user,
      provider: "x",
      handle: "smarts_#{locale.downcase.delete("-")}",
      locale: locale,
      access_token: "token-#{locale}",
      access_token_secret: "secret-#{locale}"
    )
  end
end
