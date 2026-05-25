class Chain < ApplicationRecord
  has_many :contracts, dependent: :destroy

  # full: live state + activity + governance via RPC (Tier 1, ~6 chains)
  # docs_only: Etherscan source/ABI only — no RPC, no live data (Tier 2, long-tail EVM)
  enum :tier, { full: "full", docs_only: "docs_only" }, default: :full

  validates :name, :slug, :chain_id, :explorer_api_url, presence: true
  validates :slug, uniqueness: true
  validates :chain_id, uniqueness: true

  # User-facing display order for chain selectors and labels. Tier 1 first
  # (most-recognised brands at the top), Tier 2 follows. Adding a new chain to
  # db/seeds/chains.rb without also appending to DISPLAY_ORDER will skip the
  # chain in dropdowns — chain_registry_consistency_test catches this drift.
  DISPLAY_ORDER = %w[
    eth base bnb arbitrum optimism polygon
    linea unichain berachain blast sonic mantle gnosis celo fraxtal taiko world abstract
  ].freeze

  scope :for_display, -> { in_order_of(:slug, DISPLAY_ORDER) }

  # Hash of { slug => name } in display order. Replaces the old
  # MarketingController::CHAIN_LABELS hardcoded constant — single source of
  # truth is now Chain rows (seeded from db/seeds/chains.rb).
  def self.labels
    for_display.pluck(:slug, :name).to_h
  end

  # Gas-token symbol for each chain's native currency (shown in balance displays).
  NATIVE_SYMBOLS = {
    "eth"      => "ETH",
    "base"     => "ETH",
    "arbitrum" => "ETH",
    "optimism" => "ETH",
    "bnb"      => "BNB",
    "polygon"  => "MATIC"
  }.freeze

  def etherscan_url
    explorer_api_url
  end

  def native_symbol
    NATIVE_SYMBOLS[slug] || "ETH"
  end
end
