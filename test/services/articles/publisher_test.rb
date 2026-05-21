require "test_helper"
require "tmpdir"

class Articles::PublisherTest < ActiveSupport::TestCase
  test "publishes a valid draft and returns canonical URLs" do
    Dir.mktmpdir do |dir|
      write_draft(dir, slug: "7g")

      result = Articles::Publisher.call(slug: "7g", user: users(:one), drafts_root: dir, published_at: Time.utc(2026, 5, 20, 12, 0, 0))

      assert result.valid?, result.errors.inspect
      article = Article.find_by!(slug: "7g")
      assert_equal "stablecoins", article.category
      assert_equal users(:one), article.user
      assert_equal "https://smarts.md/7g", result.urls["en"]
      assert_equal "https://smarts.md/cn/7g", result.urls["zh-CN"]
      assert_equal "https://smarts.md/tw/7g", result.urls["zh-TW"]
    end
  end

  test "dry run validates without saving" do
    Dir.mktmpdir do |dir|
      write_draft(dir, slug: "8g")

      result = Articles::Publisher.call(slug: "8g", user: users(:one), drafts_root: dir, dry_run: true)

      assert result.valid?, result.errors.inspect
      assert_nil Article.find_by(slug: "8g")
    end
  end

  test "publishing without tweets does not schedule x queue posts" do
    Dir.mktmpdir do |dir|
      write_draft(dir, slug: "9g")

      assert_no_difference "XQueue::Tweet.count" do
        result = Articles::Publisher.call(slug: "9g", user: users(:one), drafts_root: dir)

        assert result.valid?, result.errors.inspect
        assert_equal({}, result.tweets_scheduled)
        assert_equal({}, result.tweet_errors)
      end
    end
  end

  test "publishing with tweets schedules no earlier than published_at" do
    Dir.mktmpdir do |dir|
      write_draft(dir, slug: "1a")
      account = create_x_account(users(:one), locale: "en")
      published_at = 3.days.from_now.change(usec: 0)

      assert_difference "XQueue::Tweet.count", 2 do
        result = Articles::Publisher.call(
          slug: "1a",
          user: users(:one),
          drafts_root: dir,
          published_at: published_at,
          tweets: { "en" => [ "First post", "Second post" ] }
        )

        assert result.valid?, result.errors.inspect
        assert_equal({ "en" => 2 }, result.tweets_scheduled)
        assert_equal({}, result.tweet_errors)
      end

      tweets = XQueue::Tweet.where(account: account).order(:thread_position)
      assert_equal [ "First post", "Second post" ], tweets.pluck(:content)
      assert tweets.all? { |tweet| tweet.scheduled_at >= published_at }
    end
  end

  test "publishes from inline meta and content without touching the filesystem" do
    result = Articles::Publisher.call(
      slug: "2c",
      user: users(:one),
      meta: {
        "category" => "company",
        "subcategory" => "positioning",
        "title" => { "en" => "Inline Title", "zh-CN" => "内联标题" },
        "summary" => { "en" => "Inline summary" }
      },
      content: {
        "en" => "# Inline Title\n\nInline English body",
        "zh-CN" => "# 内联标题\n\n内联中文正文"
      },
      published_at: Time.utc(2026, 5, 21, 12, 0, 0)
    )

    assert result.valid?, result.errors.inspect
    article = Article.find_by!(slug: "2c")
    assert_equal "company", article.category
    assert_equal "Inline English body", article.content["en"]
    assert_equal "https://smarts.md/2c", result.urls["en"]
    assert_equal "https://smarts.md/cn/2c", result.urls["zh-CN"]
  end

  test "dry run with tweets does not schedule x queue posts" do
    Dir.mktmpdir do |dir|
      write_draft(dir, slug: "1b")
      create_x_account(users(:one), locale: "en")

      assert_no_difference "XQueue::Tweet.count" do
        result = Articles::Publisher.call(
          slug: "1b",
          user: users(:one),
          drafts_root: dir,
          dry_run: true,
          tweets: { "en" => [ "Draft tweet" ] }
        )

        assert result.valid?, result.errors.inspect
        assert_equal({}, result.tweets_scheduled)
      end
    end
  end

  private

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

  def write_draft(root, slug:)
    draft_dir = Pathname(root).join(slug)
    FileUtils.mkdir_p(draft_dir)
    draft_dir.join("meta.json").write({
      category: "stablecoins",
      subcategory: "infrastructure",
      title: { "en" => "Title", "zh-CN" => "标题", "zh-TW" => "標題" },
      summary: { "en" => "Summary" }
    }.to_json)
    draft_dir.join("en.md").write("English body")
    draft_dir.join("zh-CN.md").write("简体正文")
    draft_dir.join("zh-TW.md").write("繁體正文")
  end
end
