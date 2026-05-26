module Chains
  # Idempotent upsert for the chain registry. Reads canonical chain attributes
  # from db/seeds/chains.rb and applies them via find_or_initialize_by + update!
  # so re-running is safe (no duplicates, but metadata changes are picked up).
  #
  # Called from:
  #   - db/seeds.rb              (`bin/rails db:seed` in dev / CI)
  #   - Kamal deploy hook        (production sync without ad-hoc migrations)
  #   - bin/rails runner ...     (manual reseed in prod or staging)
  class Seeder
    SEED_PATH = Rails.root.join("db/seeds/chains.rb")
    CONTRACT_SEED_PATH = Rails.root.join("db/seeds/chain_contracts.rb")

    def self.call
      new.call
    end

    def call
      data = load_chain_data
      data.each_with_index do |attrs, index|
        chain = Chain.find_or_initialize_by(slug: attrs[:slug])
        display_order = Chain::DISPLAY_ORDER.index(attrs[:slug]) || index
        chain.update!(
          {
            summary: "",
            docs_url: nil,
            explorer_url: nil,
            faucet_url: nil,
            verify_url: nil
          }.merge(attrs).merge(display_order: display_order)
        )
      end
      seed_contracts
      data.length
    end

    private

    def load_chain_data
      load(SEED_PATH)
      CHAIN_SEEDS
    end

    def seed_contracts
      load(CONTRACT_SEED_PATH)
      CHAIN_CONTRACT_SEEDS.each do |attrs|
        chain = Chain.find_by!(slug: attrs.fetch(:chain_slug))
        contract = Contract.find_or_initialize_by(chain: chain, address: attrs.fetch(:address).downcase)
        contract.update!(
          catalog_name: attrs.fetch(:name),
          catalog_slug: attrs[:slug],
          catalog_kind: attrs.fetch(:kind),
          catalog_notes: attrs[:notes],
          catalog_order: attrs.fetch(:display_order)
        )
      end
      seed_contract_slugs
    end

    def seed_contract_slugs
      CONTRACT_SLUG_SEEDS.each do |attrs|
        chain = Chain.find_by!(slug: attrs.fetch(:chain_slug))
        contract = Contract.find_or_initialize_by(chain: chain, address: attrs.fetch(:address).downcase)
        contract.catalog_slug = attrs.fetch(:slug)
        contract.save!
      end
    end
  end
end
