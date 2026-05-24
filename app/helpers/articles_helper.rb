# frozen_string_literal: true

module ArticlesHelper
  class HeaderCollectingRenderer < Redcarpet::Render::HTML
    attr_reader :headers

    def initialize(options = {})
      super(options)
      @headers = []
    end

    def table(header, body)
      %(<div class="overflow-x-auto -mx-4 px-4"><table>#{header}#{body}</table></div>)
    end

    def header(text, level)
      # Generate slug from header text, supporting both Latin and CJK characters
      slug = text.strip.parameterize(separator: '-').presence || "heading-#{@headers.length}"
      @headers << { text: text, level: level, slug: slug }
      "<h#{level} id=\"#{slug}\">#{text}</h#{level}>"
    end
  end

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
    renderer = HeaderCollectingRenderer.new(
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

    markdown_instance = Redcarpet::Markdown.new(renderer, options)
    html = markdown_instance.render(markdown.to_s).html_safe
    @article_headers = renderer.headers

    html
  end

  def render_table_of_contents
    return "" unless @article_headers.present?

    toc_html = "<nav class=\"space-y-1.5\">"
    @article_headers.each do |header|
      margin_class = case header[:level]
                     when 2 then "ml-0"
                     when 3 then "ml-4"
                     else "ml-8"
                     end
      toc_html += "<a href=\"##{header[:slug]}\" "
      toc_html += "class=\"block text-sm text-gray-600 hover:text-blue-700 hover:font-medium transition #{margin_class}\">"
      toc_html += "#{header[:text]}</a>"
    end
    toc_html += "</nav>"

    toc_html.html_safe
  end
end
