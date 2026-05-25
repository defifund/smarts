require "test_helper"

class SeoHelperTest < ActionView::TestCase
  test "page_title falls back to default when nothing is set" do
    assert_equal SeoHelper::DEFAULT_TITLE, page_title
  end

  # Guards against shortening the title back into "too short" SEO territory.
  # The opengraph.xyz audit flagged anything under 50 chars as suboptimal
  # (truncated in SERP, weak snippet signal); over 60 gets cut off at display.
  # Locks the range without ossifying the exact wording.
  test "DEFAULT_TITLE stays within the 50-60 char SEO-optimal range" do
    len = SeoHelper::DEFAULT_TITLE.length
    assert (50..60).cover?(len),
      "DEFAULT_TITLE is #{len} chars (#{SeoHelper::DEFAULT_TITLE.inspect}); optimal is 50–60"
  end

  test "page_title appends site suffix to a custom title" do
    seo_meta title: "Foo"
    assert_equal "Foo | smarts.md", page_title
  end

  test "page_description falls back to default when nothing is set" do
    assert_equal SeoHelper::DEFAULT_DESC, page_description
  end

  test "page_description returns custom value when set" do
    seo_meta description: "Custom description"
    assert_equal "Custom description", page_description
  end

  test "page_og_type defaults to website" do
    assert_equal "website", page_og_type
  end

  test "render_social_meta emits required og and twitter tags" do
    seo_meta title: "Foo", description: "Bar", canonical: "https://smarts.md/foo"

    html = render_social_meta
    assert_match(/<meta name="description" content="Bar">/, html)
    assert_match(/<meta property="og:site_name" content="Smarts">/, html)
    assert_match(/<meta property="og:title" content="Foo \| smarts.md">/, html)
    assert_match(/<meta property="og:description" content="Bar">/, html)
    assert_match(/<meta property="og:url" content="https:\/\/smarts.md\/foo">/, html)
    assert_match(/<meta property="og:type" content="website">/, html)
    assert_match(/<meta property="og:image" content="https:\/\/smarts.md\/og-default.png">/, html)
    assert_match(/<meta name="twitter:card" content="summary_large_image">/, html)
    assert_match(/<meta name="twitter:title" content="Foo \| smarts.md">/, html)
  end
end
