require "test_helper"

class Marketing::SitemapBuilderTest < ActiveSupport::TestCase
  test "returns canonical contract, chain, and locale-specific article paths" do
    article = Article.create!(
      slug: "1z",
      user: users(:one),
      category: "company",
      subcategory: "updates",
      title: { "en" => "Sitemap article", "zh-CN" => "站点地图文章" },
      summary: { "en" => "Summary", "zh-CN" => "摘要" },
      content: { "en" => "English body", "zh-CN" => "中文正文" },
      published_at: 1.day.ago
    )

    Chains::Seeder.call
    result = Marketing::SitemapBuilder.call(contract_limit: 50)

    expected_length = 50 + article.available_locales.length + 1 + Chain.for_display.length
    assert_equal expected_length, result.entries.length
    assert_equal "https://smarts.md/usdc-eth", result.entries.first[:loc]
    urls = result.entries.map { |entry| entry[:loc] }
    assert_includes urls, "https://smarts.md/1z"
    assert_includes urls, "https://smarts.md/cn/1z"
    assert_includes urls, "https://smarts.md/chains"
    assert_includes urls, "https://smarts.md/chains/eth"
  end
end
