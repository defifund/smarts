# frozen_string_literal: true

module Marketing
  class SitemapBuilder
    Result = Struct.new(:entries, keyword_init: true)

    class << self
      def call(contract_limit: 50)
        new(contract_limit: contract_limit).call
      end
    end

    def initialize(contract_limit:)
      @contract_limit = contract_limit
    end

    def call
      Result.new(
        entries: contract_entries + article_entries + chain_entries
      )
    end

    private

    def chain_entries
      I18n.with_locale(:en) do
        index_entry = {
          loc: "#{SeoHelper::SITE_URL}/chains",
          changefreq: "monthly",
          priority: "0.6"
        }

        [ index_entry, *Chain.for_display.map { |chain| chain_entry(chain) } ]
      end
    end

    def chain_entry(chain)
      {
        loc: "#{SeoHelper::SITE_URL}#{chain.path}",
        changefreq: "monthly",
        priority: chain.full? ? "0.7" : "0.5"
      }
    end

    def contract_entries
      ContractSlugResolver.canonical_slugs(@contract_limit).map do |slug|
        {
          loc: "#{SeoHelper::SITE_URL}/#{slug}",
          changefreq: "weekly",
          priority: "0.8"
        }
      end
    end

    def article_entries
      Article.published.order(published_at: :desc, slug: :desc).flat_map do |article|
        article.available_locales.map { |locale| article.public_path(locale) }
      end.uniq.map do |path|
        {
          loc: "#{SeoHelper::SITE_URL}#{path}",
          changefreq: "monthly",
          priority: "0.6"
        }
      end
    end
  end
end
