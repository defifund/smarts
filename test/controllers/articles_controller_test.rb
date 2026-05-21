require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "renders default English article at short slug" do
    Article.create!(
      slug: "7g",
      user: users(:one),
      category: "product",
      subcategory: "mcp",
      title: { "en" => "Agent docs" },
      summary: { "en" => "Short summary" },
      content: { "en" => "## Section\n\nBody with **bold** text." },
      published_at: Time.current
    )

    get "/7g"

    assert_response :success
    assert_match "Agent docs", response.body
    assert_match "Product / MCP", response.body
    assert_match "Body with", response.body
    assert_match %r{<link rel="canonical" href="[^"]*/7g">}, response.body
  end

  test "renders Simplified Chinese article through cn alias" do
    Article.create!(
      slug: "8g",
      user: users(:one),
      category: "stablecoins",
      subcategory: "infrastructure",
      title: { "en" => "English", "zh-CN" => "简体标题" },
      summary: { "zh-CN" => "简体摘要" },
      content: { "en" => "English body", "zh-CN" => "简体正文" },
      published_at: Time.current
    )

    get "/cn/8g"

    assert_response :success
    assert_match "简体标题", response.body
    assert_match "简体正文", response.body
    assert_match %r{<link rel="canonical" href="[^"]*/cn/8g">}, response.body
  end

  test "renders Traditional Chinese article through tw alias" do
    Article.create!(
      slug: "9g",
      user: users(:one),
      category: "stablecoins",
      subcategory: "infrastructure",
      title: { "en" => "English", "zh-TW" => "繁體標題" },
      summary: { "zh-TW" => "繁體摘要" },
      content: { "en" => "English body", "zh-TW" => "繁體正文" },
      published_at: Time.current
    )

    get "/tw/9g"

    assert_response :success
    assert_match "繁體標題", response.body
    assert_match "繁體正文", response.body
  end

  test "falls back to English when localized content is missing" do
    Article.create!(
      slug: "4g",
      user: users(:one),
      category: "guides",
      subcategory: "setup",
      title: { "en" => "English title" },
      summary: { "en" => "English summary" },
      content: { "en" => "English body" },
      published_at: Time.current
    )

    get "/tw/4g"

    assert_response :success
    assert_match "English title", response.body
    assert_match %r{<link rel="canonical" href="[^"]*/4g">}, response.body
  end

  test "up remains the Rails health check route" do
    get "/up"

    assert_response :success
    refute_match "Article", response.body
  end

  test "unsupported locale alias does not match article route" do
    Article.create!(
      slug: "5g",
      user: users(:one),
      category: "guides",
      subcategory: "setup",
      title: { "en" => "English title" },
      summary: { "en" => "English summary" },
      content: { "en" => "English body" },
      published_at: Time.current
    )

    get "/zh/5g"

    assert_response :not_found
  end

  test "draft article does not render" do
    Article.create!(
      slug: "6g",
      user: users(:one),
      category: "guides",
      subcategory: "setup",
      title: { "en" => "Draft title" },
      summary: { "en" => "Draft summary" },
      content: { "en" => "Draft body" },
      published_at: nil
    )

    get "/6g"

    assert_response :not_found
  end

  test "future article does not render" do
    Article.create!(
      slug: "3g",
      user: users(:one),
      category: "guides",
      subcategory: "setup",
      title: { "en" => "Future title" },
      summary: { "en" => "Future summary" },
      content: { "en" => "Future body" },
      published_at: 1.day.from_now
    )

    get "/3g"

    assert_response :not_found
  end
end
