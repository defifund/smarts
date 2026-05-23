require "test_helper"

class Admin::ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @article = Article.create!(
      slug: "2a",
      user: users(:one),
      category: "guides",
      subcategory: "examples",
      title: { "en" => "Admin article" },
      summary: { "en" => "Summary" },
      content: { "en" => "Body" },
      published_at: nil
    )
  end

  test "requires authentication" do
    get admin_articles_path

    assert_redirected_to new_session_path
  end

  test "rejects non-admin users" do
    sign_in_as(users(:two))

    get admin_articles_path

    assert_redirected_to root_path
  end

  test "lists all article statuses for admin users" do
    Article.create!(
      slug: "2b",
      user: users(:one),
      category: "guides",
      subcategory: "examples",
      title: { "en" => "Published article" },
      summary: { "en" => "Summary" },
      content: { "en" => "Body" },
      published_at: 1.hour.ago
    )

    Article.create!(
      slug: "2c",
      user: users(:one),
      category: "guides",
      subcategory: "examples",
      title: { "en" => "Scheduled article" },
      summary: { "en" => "Summary" },
      content: { "en" => "Body" },
      published_at: 1.hour.from_now
    )

    sign_in_as(users(:one))

    get admin_articles_path

    assert_response :success
    assert_match "draft", response.body
    assert_match "published", response.body
    assert_match "scheduled", response.body
  end

  test "admin can edit article status and localized content" do
    sign_in_as(users(:one))

    patch admin_article_path(@article), params: {
      article: {
        slug: "2a",
        category: "guides",
        subcategory: "examples",
        publication_status: "published",
        published_at: "",
        title: { "en" => "Updated title" },
        summary: { "en" => "Updated summary" },
        content: { "en" => "Updated body" }
      }
    }

    assert_redirected_to admin_articles_path
    @article.reload
    assert_equal "published", @article.publication_status
    assert_equal "Updated title", @article.title_for("en")
    assert @article.published_at.present?
  end
end
