require "test_helper"
require "tmpdir"

class Articles::DraftReaderTest < ActiveSupport::TestCase
  test "reads valid multilingual draft and strips first heading" do
    Dir.mktmpdir do |dir|
      draft_dir = Pathname(dir).join("7g")
      FileUtils.mkdir_p(draft_dir)
      draft_dir.join("meta.json").write({
        category: "stablecoins",
        subcategory: "infrastructure",
        title: { "en" => "Title", "zh-CN" => "标题", "zh-TW" => "標題" },
        summary: { "en" => "Summary" }
      }.to_json)
      draft_dir.join("en.md").write("# Title\n\nEnglish body")
      draft_dir.join("zh-CN.md").write("# 标题\n\n简体正文")

      result = Articles::DraftReader.call(slug: "7g", drafts_root: dir)

      assert result.valid?, result.errors.inspect
      assert_equal "stablecoins", result.category
      assert_equal "infrastructure", result.subcategory
      assert_equal %w[en zh-CN], result.locales
      assert_equal "English body", result.content["en"]
    end
  end

  test "reports invalid category and unsupported locale" do
    Dir.mktmpdir do |dir|
      draft_dir = Pathname(dir).join("7g")
      FileUtils.mkdir_p(draft_dir)
      draft_dir.join("meta.json").write({ category: "bad", title: { "en" => "Title" } }.to_json)
      draft_dir.join("fr.md").write("French body")

      result = Articles::DraftReader.call(slug: "7g", drafts_root: dir)

      refute result.valid?
      assert_includes result.errors, "category is unsupported: bad"
      assert_includes result.errors, "unsupported locale file: fr.md"
    end
  end

  test "from_payload builds a valid result without touching the filesystem" do
    result = Articles::DraftReader.from_payload(
      slug: "7g",
      meta: {
        "category" => "stablecoins",
        "subcategory" => "infrastructure",
        "title" => { "en" => "Title", "zh-CN" => "标题" },
        "summary" => { "en" => "Summary" }
      },
      content: {
        "en" => "# Title\n\nEnglish body",
        "zh-CN" => "# 标题\n\n简体正文"
      }
    )

    assert result.valid?, result.errors.inspect
    assert_nil result.path
    assert_equal "stablecoins", result.category
    assert_equal "infrastructure", result.subcategory
    assert_equal %w[en zh-CN], result.locales
    assert_equal "English body", result.content["en"]
    assert_equal "简体正文", result.content["zh-CN"]
  end

  test "from_payload reports unsupported locale and empty content" do
    result = Articles::DraftReader.from_payload(
      slug: "7g",
      meta: { "category" => "stablecoins", "title" => { "en" => "Title" } },
      content: { "fr" => "ignored", "en" => "" }
    )

    refute result.valid?
    assert_includes result.errors, "unsupported locale: fr"
    assert_includes result.errors, "en content is empty"
  end

  test "reports unsupported locale in meta and invalid json" do
    Dir.mktmpdir do |dir|
      draft_dir = Pathname(dir).join("7g")
      FileUtils.mkdir_p(draft_dir)
      draft_dir.join("meta.json").write("{ not json")
      draft_dir.join("en.md").write("English body")

      result = Articles::DraftReader.call(slug: "7g", drafts_root: dir)

      refute result.valid?
      assert result.errors.any? { |error| error.start_with?("meta.json is invalid JSON") }
    end

    Dir.mktmpdir do |dir|
      draft_dir = Pathname(dir).join("8g")
      FileUtils.mkdir_p(draft_dir)
      draft_dir.join("meta.json").write({
        category: "guides",
        subcategory: "setup",
        title: { "fr" => "Titre" }
      }.to_json)
      draft_dir.join("en.md").write("English body")

      result = Articles::DraftReader.call(slug: "8g", drafts_root: dir)

      refute result.valid?
      assert_includes result.errors, "unsupported locale in meta: fr"
    end
  end
end
