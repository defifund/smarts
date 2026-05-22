require "test_helper"
require "tmpdir"

class ArticlePublishingToolsTest < ActiveSupport::TestCase
  setup do
    Current.mcp_user = users(:one)
  end

  teardown do
    Current.mcp_user = nil
  end

  # Redirect Articles::DraftReader.list_summaries to a tmpdir for the
  # duration of the block. Tests populate the tmpdir with fixture drafts
  # instead of relying on docs/drafts/ existing on disk.
  def with_drafts_root
    Dir.mktmpdir do |dir|
      original = Articles::DraftReader.method(:list_summaries)
      stub_class_method(Articles::DraftReader, :list_summaries, ->(**) {
        original.call(drafts_root: dir)
      }) do
        yield dir
      end
    end
  end

  test "publishing tools require an authenticated publisher on Current" do
    Current.mcp_user = nil

    expected = "Authorization: Bearer <publish_token> header is missing or invalid"

    assert_equal expected, ListArticleDraftsTool.payload[:error]
    assert_equal expected, ValidateArticleDraftTool.payload(slug: "7g")[:error]
    assert_equal expected, PublishArticleTool.payload(slug: "7g")[:error]
  end

  test "unauthenticated requests never reach readers or publisher" do
    Current.mcp_user = nil
    expected = "Authorization: Bearer <publish_token> header is missing or invalid"

    stub_class_method(Articles::DraftReader, :call, ->(**) { raise "draft reader should not be called" }) do
      assert_equal expected, ValidateArticleDraftTool.payload(slug: "7g")[:error]
    end

    stub_class_method(Articles::Publisher, :call, ->(**) { raise "publisher should not be called" }) do
      assert_equal expected, PublishArticleTool.payload(slug: "7g")[:error]
    end
  end

  test "list drafts returns authorized draft payload" do
    with_drafts_root do |dir|
      draft_dir = Pathname(dir).join("ms")
      FileUtils.mkdir_p(draft_dir)
      draft_dir.join("meta.json").write({
        category: "company",
        subcategory: "positioning",
        title: { "zh-CN" => "Smarts.md 增长战略" },
        summary: { "zh-CN" => "我们如何在市场中定位和增长 Smarts.md" }
      }.to_json)
      draft_dir.join("zh-CN.md").write("# Smarts.md 增长战略\n\nBody")

      payload = ListArticleDraftsTool.payload
      draft = payload[:drafts].find { |item| item[:slug] == "ms" }

      assert_operator payload[:count], :>=, 1
      assert draft, "expected ms draft to be listed"
      assert_equal "company", draft[:category]
      assert_equal [ "zh-CN" ], draft[:locales]
      assert_kind_of Array, draft[:errors]
    end
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
      payload = ValidateArticleDraftTool.payload(slug: "7g")

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
      payload = PublishArticleTool.payload(slug: "7g")

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
        slug: "7g",
        published_at: "2026-06-01T09:00:00Z",
        thread: false,
        tweets: { "en" => [ "Tweet" ] }
      )

      assert payload[:valid]
      assert_equal({ "en" => 1 }, payload[:tweets_scheduled])
    end
  end

  test "publish tool passes nil published_at when caller does not provide one" do
    draft = Articles::DraftReader::Result.new(slug: "7g", category: "product", subcategory: "mcp", locales: [ "en" ], errors: [])
    result = Articles::Publisher::Result.new(draft: draft, errors: [], urls: { "en" => "https://smarts.md/7g" }, dry_run: false)

    stub_class_method(Articles::Publisher, :call, ->(**kwargs) {
      assert_nil kwargs[:published_at]
      result
    }) do
      PublishArticleTool.payload(slug: "7g")
    end
  end

  test "publish tool returns validation error for invalid published_at" do
    payload = PublishArticleTool.payload(
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
          payload = PublishArticleTool.payload(slug: "7g")

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
