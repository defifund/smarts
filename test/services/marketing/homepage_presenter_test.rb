require "test_helper"

class Marketing::HomepagePresenterTest < ActiveSupport::TestCase
  test "returns grouped featured items, recent articles, and top contract slugs" do
    article = Article.create!(
      slug: "1z",
      user: users(:one),
      category: "company",
      subcategory: "updates",
      title: { "en" => "Homepage article" },
      summary: { "en" => "Summary" },
      content: { "en" => "Body" },
      published_at: 1.day.ago
    )

    result = Marketing::HomepagePresenter.call(featured: MarketingController::FEATURED, recent_limit: 3, contract_limit: 50)

    assert_equal MarketingController::FEATURED.map { |f| f[:category] }.uniq.sort, result.featured_groups.keys.sort
    assert_includes result.recent_articles, article
    assert_equal 50, result.top_contract_slugs.length
    assert_equal "usdc-eth", result.top_contract_slugs.first
    assert_equal "https://smarts.md/usdc-eth", result.top_contract_urls.first
    assert_match "USDC", result.meta_description
  end

  test "localizes top contract urls when a localized locale is requested" do
    result = Marketing::HomepagePresenter.call(
      featured: MarketingController::FEATURED,
      recent_limit: 3,
      contract_limit: 1,
      locale: "zh-CN"
    )

    assert_equal "https://smarts.md/cn/usdc-eth", result.top_contract_urls.first
  end
end
