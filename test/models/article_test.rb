require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "validates two-character lowercase slug" do
    article = build_article(slug: "A1")

    refute article.valid?
    assert_includes article.errors[:slug], "must be exactly two lowercase letters or digits"
  end

  test "rejects reserved slugs" do
    Article::RESERVED_SLUGS.each do |slug|
      article = build_article(slug: slug)

      refute article.valid?, "expected #{slug.inspect} to be reserved"
      assert article.errors[:slug].any?
    end
  end

  test "validates subcategory belongs to category" do
    article = build_article(category: "stablecoins", subcategory: "mcp")

    refute article.valid?
    assert_includes article.errors[:subcategory], "is not allowed for stablecoins"
  end

  test "falls back from missing requested locale to English" do
    article = build_article(content: { "en" => "English body" }, title: { "en" => "English title" })

    assert_equal "en", article.locale_for("zh-TW")
    assert_equal "/9z", article.public_path("en")
    assert_equal "/cn/9z", article.public_path("zh-CN")
    assert_equal "/tw/9z", article.public_path("zh-TW")
  end

  test "published scope excludes future and draft records" do
    published = create_article!(slug: "p1", published_at: 1.day.ago)
    create_article!(slug: "f1", published_at: 1.day.from_now)
    create_article!(slug: "d1", published_at: nil)

    assert_equal [ published ], Article.published.to_a
  end

  private

  def build_article(**attrs)
    Article.new({
      slug: "9z",
      user: users(:one),
      category: "stablecoins",
      subcategory: "infrastructure",
      title: { "en" => "Title" },
      summary: { "en" => "Summary" },
      content: { "en" => "Body" },
      published_at: Time.current
    }.merge(attrs))
  end

  def create_article!(**attrs)
    build_article(**attrs).tap(&:save!)
  end
end
