require "test_helper"

class Marketing::SitemapBuilderTest < ActiveSupport::TestCase
  test "returns canonical contract, chain, and locale-specific article paths" do
    Article.create!(
      slug: "1z",
      user: users(:one),
      category: "company",
      subcategory: "updates",
      title: { "en" => "Sitemap article", "zh-CN" => "站点地图文章" },
      summary: { "en" => "Summary", "zh-CN" => "摘要" },
      content: { "en" => "English body", "zh-CN" => "中文正文" },
      published_at: 1.day.ago
    )

    result = Marketing::SitemapBuilder.call(contract_limit: 50)

    assert_equal 71, result.entries.length
    assert_equal "https://smarts.md/usdc-eth", result.entries.first[:loc]
    assert_includes result.entries.map { |entry| entry[:loc] }, "https://smarts.md/1z"
    assert_includes result.entries.map { |entry| entry[:loc] }, "https://smarts.md/cn/1z"
    assert_includes result.entries.map { |entry| entry[:loc] }, "https://smarts.md/chains"
    assert_includes result.entries.map { |entry| entry[:loc] }, "https://smarts.md/chains/eth"
  end
end
