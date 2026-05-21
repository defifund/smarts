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

  private

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
