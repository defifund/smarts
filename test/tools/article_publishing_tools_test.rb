require "test_helper"
require "tmpdir"

class ArticlePublishingToolsTest < ActiveSupport::TestCase
  test "publishing tools require token" do
    assert_equal "article publishing token is missing or invalid", ListArticleDraftsTool.payload(publish_token: "bad")[:error]
    assert_equal "article publishing token is missing or invalid", ValidateArticleDraftTool.payload(publish_token: "bad", slug: "7g")[:error]
    assert_equal "article publishing token is missing or invalid", PublishArticleTool.payload(publish_token: "bad", slug: "7g")[:error]
  end

  test "invalid token does not read drafts or publish" do
    stub_class_method(Articles::DraftReader, :call, ->(**) { raise "draft reader should not be called" }) do
      payload = ValidateArticleDraftTool.payload(publish_token: "bad", slug: "7g")
      assert_equal "article publishing token is missing or invalid", payload[:error]
    end

    stub_class_method(Articles::Publisher, :call, ->(**) { raise "publisher should not be called" }) do
      payload = PublishArticleTool.payload(publish_token: "bad", slug: "7g")
      assert_equal "article publishing token is missing or invalid", payload[:error]
    end
  end

  test "list drafts returns authorized draft payload" do
    payload = ListArticleDraftsTool.payload(publish_token: "sma_test_token_one")
    draft = payload[:drafts].find { |item| item[:slug] == "ms" }

    assert_operator payload[:count], :>=, 1
    assert draft, "expected docs/drafts/ms to be listed"
    assert_equal "company", draft[:category]
    assert_equal [ "zh-CN" ], draft[:locales]
    assert_kind_of Array, draft[:errors]
  end

  test "validate tool returns draft payload when authorized" do
    draft = Articles::DraftReader::Result.new(
      slug: "7g",
      path: Rails.root.join("docs/drafts/7g"),
      category: "product",
      subcategory: "mcp",
      locales: [ "en" ],
      errors: []
    )

    stub_class_method(Articles::DraftReader, :call, ->(**) { draft }) do
      payload = ValidateArticleDraftTool.payload(publish_token: "sma_test_token_one", slug: "7g")

      assert_equal "7g", payload[:slug]
      assert payload[:valid]
      assert_equal [ "en" ], payload[:locales]
    end
  end

  test "publish tool delegates to publisher when authorized" do
    draft = Articles::DraftReader::Result.new(slug: "7g", category: "product", subcategory: "mcp", locales: [ "en" ], errors: [])
    result = Articles::Publisher::Result.new(draft: draft, errors: [], urls: { "en" => "https://smarts.md/7g" }, dry_run: false)

    stub_class_method(Articles::Publisher, :call, ->(**kwargs) {
      assert_equal users(:one), kwargs[:user]
      assert_equal false, kwargs[:dry_run]
      assert_equal true, kwargs[:thread]
      assert_equal({}, kwargs[:tweets])
      result
    }) do
      payload = PublishArticleTool.payload(publish_token: "sma_test_token_one", slug: "7g")

      assert payload[:valid]
      assert_equal "https://smarts.md/7g", payload[:urls]["en"]
    end
  end

  test "publish tool passes scheduling options to publisher" do
    draft = Articles::DraftReader::Result.new(slug: "7g", category: "product", subcategory: "mcp", locales: [ "en" ], errors: [])
    result = Articles::Publisher::Result.new(
      draft: draft,
      errors: [],
      urls: { "en" => "https://smarts.md/7g" },
      dry_run: false,
      tweets_scheduled: { "en" => 1 },
      tweet_errors: {}
    )

    stub_class_method(Articles::Publisher, :call, ->(**kwargs) {
      assert_equal users(:one), kwargs[:user]
      assert_equal Time.zone.parse("2026-06-01T09:00:00Z"), kwargs[:published_at]
      assert_equal false, kwargs[:thread]
      assert_equal({ "en" => [ "Tweet" ] }, kwargs[:tweets])
      result
    }) do
      payload = PublishArticleTool.payload(
        publish_token: "sma_test_token_one",
        slug: "7g",
        published_at: "2026-06-01T09:00:00Z",
        thread: false,
        tweets: { "en" => [ "Tweet" ] }
      )

      assert payload[:valid]
      assert_equal({ "en" => 1 }, payload[:tweets_scheduled])
    end
  end

  test "publish tool returns validation error for invalid published_at" do
    payload = PublishArticleTool.payload(
      publish_token: "sma_test_token_one",
      slug: "7g",
      published_at: "not a time"
    )

    assert_equal false, payload[:valid]
    assert_equal [ "published_at is invalid" ], payload[:errors]
  end

  test "publish tool integration creates article from draft for authenticated user" do
    Dir.mktmpdir do |dir|
      draft_dir = Pathname(dir).join("7g")
      FileUtils.mkdir_p(draft_dir)
      draft_dir.join("meta.json").write({
        category: "product",
        subcategory: "mcp",
        title: { "en" => "MCP publishing" },
        summary: { "en" => "Publish through MCP." }
      }.to_json)
      draft_dir.join("en.md").write("# MCP publishing\n\nBody")

      stub_class_method(Articles::DraftReader, :call, ->(slug:, drafts_root: Rails.root.join("docs/drafts")) {
        Articles::DraftReader.new(slug: slug, drafts_root: dir).call
      }) do
        assert_difference "Article.count", 1 do
          payload = PublishArticleTool.payload(publish_token: "sma_test_token_one", slug: "7g")

          assert payload[:valid], payload[:errors].inspect
          assert_equal "https://smarts.md/7g", payload[:urls]["en"]
        end
      end

      article = Article.find_by!(slug: "7g")
      assert_equal users(:one), article.user
      assert_equal "MCP publishing", article.title["en"]
      assert_equal "Body", article.content["en"]
    end
  end
end
