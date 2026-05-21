require "test_helper"

class ArticlesHelperTest < ActionView::TestCase
  test "renders markdown with tables through redcarpet" do
    html = render_article_markdown(<<~MARKDOWN)
      ## Heading

      | 渠道 | 优先级 |
      | --- | --- |
      | X | 5/5 |
    MARKDOWN

    assert_includes html, "<h2>Heading</h2>"
    assert_includes html, "<table>"
    assert_includes html, "<th>渠道</th>"
    assert_includes html, "<td>5/5</td>"
  end

  test "filters raw html" do
    html = render_article_markdown("<script>alert('x')</script>\n\n**safe**")

    refute_includes html, "<script>"
    assert_includes html, "<strong>safe</strong>"
  end
end
