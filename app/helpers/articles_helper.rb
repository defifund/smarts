# frozen_string_literal: true

module ArticlesHelper
  def article_category_label(article)
    category = t("article_categories.#{article.category}", locale: @locale, default: article.category.to_s.humanize)
    return category if article.subcategory.blank?

    subcategory = t(
      "article_subcategories.#{article.category}.#{article.subcategory}",
      locale: @locale,
      default: article.subcategory.to_s.humanize
    )
    "#{category} / #{subcategory}"
  end

  def render_article_markdown(markdown)
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      filter_html: true,
      safe_links_only: true
    )
    options = {
      autolink: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      space_after_headers: true,
      strikethrough: true,
      tables: true
    }

    Redcarpet::Markdown.new(renderer, options).render(markdown.to_s).html_safe
  end
end
