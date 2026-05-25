class Chain < ApplicationRecord
  has_many :contracts, dependent: :destroy

  # full: live state + activity + governance via RPC (Tier 1, ~6 chains)
  # docs_only: Etherscan source/ABI only — no RPC, no live data (Tier 2, long-tail EVM)
  enum :tier, { full: "full", docs_only: "docs_only" }, default: :full

  validates :name, :slug, :chain_id, :explorer_api_url, presence: true
  validates :slug, uniqueness: true
  validates :chain_id, uniqueness: true

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
