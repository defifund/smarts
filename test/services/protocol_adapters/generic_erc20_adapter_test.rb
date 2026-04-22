require "test_helper"

class ProtocolAdapters::GenericErc20AdapterTest < ActiveSupport::TestCase
  # Full ERC-20 ABI covering the 6 required selectors plus name/decimals.
  ERC20_ABI = [
    { "type" => "function", "name" => "name",         "inputs" => [],                                                                                       "outputs" => [ { "type" => "string" } ],  "stateMutability" => "view" },
    { "type" => "function", "name" => "symbol",       "inputs" => [],                                                                                       "outputs" => [ { "type" => "string" } ],  "stateMutability" => "view" },
    { "type" => "function", "name" => "decimals",     "inputs" => [],                                                                                       "outputs" => [ { "type" => "uint8" } ],   "stateMutability" => "view" },
    { "type" => "function", "name" => "totalSupply",  "inputs" => [],                                                                                       "outputs" => [ { "type" => "uint256" } ], "stateMutability" => "view" },
    { "type" => "function", "name" => "balanceOf",    "inputs" => [ { "name" => "a", "type" => "address" } ],                                               "outputs" => [ { "type" => "uint256" } ], "stateMutability" => "view" },
    { "type" => "function", "name" => "transfer",     "inputs" => [ { "name" => "to", "type" => "address" }, { "name" => "v", "type" => "uint256" } ],      "outputs" => [ { "type" => "bool" } ],    "stateMutability" => "nonpayable" },
    { "type" => "function", "name" => "transferFrom", "inputs" => [ { "name" => "f", "type" => "address" }, { "name" => "t", "type" => "address" }, { "name" => "v", "type" => "uint256" } ], "outputs" => [ { "type" => "bool" } ], "stateMutability" => "nonpayable" },
    { "type" => "function", "name" => "approve",      "inputs" => [ { "name" => "s", "type" => "address" }, { "name" => "v", "type" => "uint256" } ],      "outputs" => [ { "type" => "bool" } ],    "stateMutability" => "nonpayable" },
    { "type" => "function", "name" => "allowance",    "inputs" => [ { "name" => "o", "type" => "address" }, { "name" => "s", "type" => "address" } ],      "outputs" => [ { "type" => "uint256" } ], "stateMutability" => "view" }
  ].freeze

  USDC_ADDRESS = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"

  setup do
    @chain = chains(:ethereum)
    @contract = Contract.new(chain: @chain, address: USDC_ADDRESS, abi: ERC20_ABI)
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  # ---------- matches? ----------

  test "matches? returns true when the ABI contains all 6 ERC-20 selectors" do
    assert ProtocolAdapters::GenericErc20Adapter.matches?(@contract)
  end

  test "matches? returns false when ABI is missing one of the required functions" do
    abi_without_allowance = ERC20_ABI.reject { |f| f["name"] == "allowance" }
    c = Contract.new(chain: @chain, address: USDC_ADDRESS, abi: abi_without_allowance)

    refute ProtocolAdapters::GenericErc20Adapter.matches?(c)
  end

  test "matches? returns false when ABI is nil or empty" do
    refute ProtocolAdapters::GenericErc20Adapter.matches?(Contract.new(chain: @chain, address: "0xabc", abi: nil))
    refute ProtocolAdapters::GenericErc20Adapter.matches?(Contract.new(chain: @chain, address: "0xabc", abi: []))
  end

  # ---------- panel_data: happy path ----------

  test "panel_data returns formatted supply, price, market cap, issuer for a known token" do
    adapter = ProtocolAdapters::GenericErc20Adapter.new(@contract)

    metadata_stub = lambda do |chain:, calls:|
      [
        ChainReader::Multicall3Client::Result.new(success: true, values: [ "USD Coin" ]),
        ChainReader::Multicall3Client::Result.new(success: true, values: [ "USDC" ]),
        ChainReader::Multicall3Client::Result.new(success: true, values: [ 6 ]),
        ChainReader::Multicall3Client::Result.new(success: true, values: [ 55_046_395_721_805_492 ])
      ]
    end
    price_stub = ->(chain:, addresses:) { { addresses.first.downcase => { "price" => 1.0 } } }

    stub_class_method(ChainReader::Multicall3Client, :call, metadata_stub) do
      stub_class_method(DefiLlamaClient, :fetch_prices, price_stub) do
        data = adapter.panel_data

        assert_equal "USD Coin", data[:name]
        assert_equal "USDC", data[:symbol]
        assert_equal 6, data[:decimals]
        assert_equal "55,046,395,721.80 USDC", data[:total_supply_formatted]
        assert_equal 1.0, data[:price_usd]
        assert_equal 55_046_395_721.81, data[:market_cap_usd]
        assert_equal "Circle", data[:issuer][:name]
      end
    end
  end

  # ---------- panel_data: degradation ----------

  test "panel_data returns {error:} when metadata multicall fails to produce symbol/decimals" do
    adapter = ProtocolAdapters::GenericErc20Adapter.new(@contract)
    all_failed = lambda do |chain:, calls:|
      Array.new(calls.length) { ChainReader::Multicall3Client::Result.new(success: false, error: "reverted") }
    end

    stub_class_method(ChainReader::Multicall3Client, :call, all_failed) do
      data = adapter.panel_data
      assert_equal "could not read token metadata", data[:error]
    end
  end

  test "panel_data omits price and market cap when DefiLlama raises" do
    adapter = ProtocolAdapters::GenericErc20Adapter.new(@contract)

    metadata_stub = lambda do |chain:, calls:|
      [
        ChainReader::Multicall3Client::Result.new(success: true, values: [ "USD Coin" ]),
        ChainReader::Multicall3Client::Result.new(success: true, values: [ "USDC" ]),
        ChainReader::Multicall3Client::Result.new(success: true, values: [ 6 ]),
        ChainReader::Multicall3Client::Result.new(success: true, values: [ 1_000_000 * 10**6 ])
      ]
    end
    down = ->(**_) { raise DefiLlamaClient::Error, "DefiLlama down" }

    stub_class_method(ChainReader::Multicall3Client, :call, metadata_stub) do
      stub_class_method(DefiLlamaClient, :fetch_prices, down) do
        data = adapter.panel_data
        assert_nil data[:price_usd]
        assert_nil data[:market_cap_usd]
        assert_equal "1,000,000 USDC", data[:total_supply_formatted]
      end
    end
  end

  test "panel_data still renders when name() reverts (some tokens use bytes32 name)" do
    adapter = ProtocolAdapters::GenericErc20Adapter.new(@contract)
    stub_multi = lambda do |chain:, calls:|
      [
        ChainReader::Multicall3Client::Result.new(success: false, error: "reverted"),
        ChainReader::Multicall3Client::Result.new(success: true,  values: [ "FOO" ]),
        ChainReader::Multicall3Client::Result.new(success: true,  values: [ 18 ]),
        ChainReader::Multicall3Client::Result.new(success: true,  values: [ 100 * 10**18 ])
      ]
    end
    no_price = ->(**_) { {} }

    stub_class_method(ChainReader::Multicall3Client, :call, stub_multi) do
      stub_class_method(DefiLlamaClient, :fetch_prices, no_price) do
        data = adapter.panel_data
        assert_nil data[:name]
        assert_equal "FOO", data[:symbol]
        assert_equal "100 FOO", data[:total_supply_formatted]
      end
    end
  end

  # ---------- issuer lookup ----------

  test "lookup_issuer returns nil for an unknown address" do
    random_contract = Contract.new(chain: @chain, address: "0x#{SecureRandom.hex(20)}", abi: ERC20_ABI)
    adapter = ProtocolAdapters::GenericErc20Adapter.new(random_contract)
    assert_nil adapter.send(:lookup_issuer)
  end

  test "lookup_issuer returns Circle for USDC on Ethereum" do
    adapter = ProtocolAdapters::GenericErc20Adapter.new(@contract)
    issuer = adapter.send(:lookup_issuer)
    assert_equal "Circle", issuer[:name]
  end

  test "lookup_issuer returns nil for USDC address on the wrong chain" do
    base_contract = Contract.new(chain: chains(:base), address: USDC_ADDRESS, abi: ERC20_ABI)
    adapter = ProtocolAdapters::GenericErc20Adapter.new(base_contract)
    assert_nil adapter.send(:lookup_issuer)
  end

  # ---------- format_supply edge cases ----------

  test "format_supply returns nil for missing raw or decimals" do
    adapter = ProtocolAdapters::GenericErc20Adapter.new(@contract)
    assert_nil adapter.send(:format_supply, nil, 6, "USDC")
    assert_nil adapter.send(:format_supply, 1000, nil, "USDC")
  end

  test "format_supply handles zero-decimal tokens cleanly" do
    adapter = ProtocolAdapters::GenericErc20Adapter.new(@contract)
    assert_equal "42 CULT", adapter.send(:format_supply, 42, 0, "CULT")
  end
end
