require "test_helper"
require "ostruct"

class Seo::CopyTest < ActiveSupport::TestCase
  test "homepage copy includes curated item labels when present" do
    description = Seo::Copy.homepage(featured_items: [
      { symbol: "USDC" },
      { name: "Uniswap V3" }
    ])

    assert_match "USDC", description
    assert_match "Uniswap V3", description
    assert_match "AI agent", description
  end

  test "contract copy switches between classification-aware and generic text" do
    classification = OpenStruct.new(display_name: "ERC-20 Token")

    with_classification = Seo::Copy.contract(
      contract_name: "USD Coin",
      chain_name: "Ethereum",
      classification: classification,
      address: "0xa0b8"
    )
    generic = Seo::Copy.contract(
      contract_name: "Thing",
      chain_name: "Ethereum",
      classification: nil,
      address: "0xabc"
    )

    assert_match "USD Coin (ERC-20 Token)", with_classification
    assert_match "Thing at 0xabc on Ethereum", generic
  end
end
