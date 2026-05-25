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

    def self.call
      new.call
    end

    def call
      data = load_chain_data
      data.each do |attrs|
        chain = Chain.find_or_initialize_by(slug: attrs[:slug])
        chain.update!(attrs)
      end
      data.length
    end

    private

    def load_chain_data
      eval(SEED_PATH.read, binding, SEED_PATH.to_s)
    end
  end
end
