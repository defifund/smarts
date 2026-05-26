# frozen_string_literal: true

module Chains
  module Catalog
    Contract = Struct.new(
      :chain_slug,
      :name,
      :slug,
      :address,
      :kind,
      :notes,
      keyword_init: true
    ) do
      def path(locale: I18n.locale)
        route_locale = Article.route_locale_for(locale.to_s)
        base_path = slug.present? ? "/#{slug}" : "/#{chain_slug}/#{address}"
        route_locale.present? ? "/#{route_locale}#{base_path}" : base_path
      end
    end

    Chain = Struct.new(
      :slug,
      :name,
      :chain_id,
      :tier,
      :network_kind,
      :summary,
      :docs_url,
      :explorer_url,
      :faucet_url,
      :verify_url,
      :contracts,
      keyword_init: true
    ) do
      def full?
        tier.to_s == "full"
      end

      def docs_only?
        tier.to_s == "docs_only"
      end

      def mainnet?
        network_kind.to_s == "mainnet"
      end

      def testnet?
        network_kind.to_s == "testnet"
      end

      def contract_count
        contracts.length
      end

      def slugged_contract_count
        contracts.count { |contract| contract.slug.present? }
      end

      def kind_counts
        contracts.group_by(&:kind).transform_values(&:length)
      end

      def top_kinds(limit = 2)
        kind_counts.sort_by { |kind, count| [ -count, kind ] }.first(limit)
      end

      def path(locale: I18n.locale)
        route_locale = Article.route_locale_for(locale.to_s)
        route_locale.present? ? "/#{route_locale}/chains/#{slug}" : "/chains/#{slug}"
      end
    end

    class << self
      def all
        ::Chain.for_display.map { |record| from_record(record) }
      end

      def fetch(slug)
        record = ::Chain.find_by(slug: slug)
        raise KeyError, "unknown chain: #{slug}" unless record

        from_record(record)
      end

      def from_record(record)
        Chain.new(
          slug: record.slug,
          name: record.name,
          chain_id: record.chain_id,
          tier: record.tier,
          network_kind: record.network_kind,
          summary: record.summary,
          docs_url: record.docs_url,
          explorer_url: record.explorer_url,
          faucet_url: record.faucet_url,
          verify_url: record.verify_url,
          contracts: record.contracts.for_catalog.map { |contract| contract_from_record(record, contract) }
        )
      end

      def contract_from_record(chain, record)
        Contract.new(
          chain_slug: chain.slug,
          name: record.catalog_display_name,
          slug: record.catalog_slug,
          address: record.address,
          kind: record.catalog_display_kind,
          notes: record.catalog_notes
        )
      end
    end

    DISPLAY_ORDER = ::Chain::DISPLAY_ORDER
  end
end
