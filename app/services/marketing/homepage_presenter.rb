# frozen_string_literal: true

module Marketing
  class HomepagePresenter
    Result = Struct.new(:featured_groups, :recent_articles, :top_contract_slugs, :top_contract_urls, :meta_description, keyword_init: true)

    class << self
      def call(featured:, recent_limit: 3, contract_limit: 50, locale: I18n.locale)
        new(featured: featured, recent_limit: recent_limit, contract_limit: contract_limit, locale: locale).call
      end
    end

    def initialize(featured:, recent_limit:, contract_limit:, locale:)
      @featured = featured
      @recent_limit = recent_limit
      @contract_limit = contract_limit
      @locale = locale
    end

    def call
      top_contract_slugs = ContractSlugs.canonical_slugs(@contract_limit)
      route_locale = Article.route_locale_for(@locale.to_s)

      Result.new(
        featured_groups: @featured.group_by { |f| f[:category] },
        recent_articles: Article.published.order(published_at: :desc).limit(@recent_limit),
        top_contract_slugs: top_contract_slugs,
        top_contract_urls: top_contract_slugs.map do |slug|
          path = route_locale.present? ? "/#{route_locale}/#{slug}" : "/#{slug}"
          "#{SeoHelper::SITE_URL}#{path}"
        end,
        meta_description: Seo::Copy.homepage(featured_items: @featured.first(4))
      )
    end
  end
end
