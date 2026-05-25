require "test_helper"

class ApplicationToolTest < ActiveSupport::TestCase
  setup do
    @docs_chain = Chain.create!(
      name: "Linea", slug: "linea", chain_id: 59144,
      explorer_api_url: "https://api.etherscan.io/v2/api",
      tier: "docs_only"
    )
    @contract = contracts(:uni_token)
  end

  test "check_full_tier returns nil for full chains" do
    assert_nil ApplicationTool.check_full_tier(chains(:ethereum))
  end

  test "check_full_tier returns error hash for docs_only chains" do
    result = ApplicationTool.check_full_tier(@docs_chain)
    assert_match(/linea/, result[:error])
    assert_match(/docs-only/, result[:error])
    assert_match(/get_contract_info|get_contract_source/, result[:error])
  end

  test "resolve_contract with require_full: true rejects docs_only chains" do
    docs_contract = Contract.create!(
      chain: @docs_chain,
      address: "0x" + "1" * 40,
      name: "FakeToken"
    )
    result = ApplicationTool.resolve_contract(
      chain: "linea", address: docs_contract.address, require_full: true
    )
    assert result.is_a?(Hash)
    assert_match(/docs-only/, result[:error])
  end

  test "resolve_contract with require_full: false allows docs_only chains" do
    docs_contract = Contract.create!(
      chain: @docs_chain,
      address: "0x" + "2" * 40,
      name: "FakeToken"
    )
    result = ApplicationTool.resolve_contract(
      chain: "linea", address: docs_contract.address, require_full: false
    )
    assert result.is_a?(Array)
    assert_equal @docs_chain, result[0]
    assert_equal docs_contract, result[1]
  end

  test "resolve_contract with require_full: true still works on full chains" do
    result = ApplicationTool.resolve_contract(
      chain: "eth", address: @contract.address, require_full: true
    )
    assert result.is_a?(Array)
    assert_equal chains(:ethereum), result[0]
  end
end
