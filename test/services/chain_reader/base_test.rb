require "test_helper"

class ChainReader::BaseTest < ActiveSupport::TestCase
  setup do
    @chain = chains(:ethereum)
  end

  test "selector computes 4-byte function selector" do
    assert_equal "0x18160ddd", ChainReader::Base.selector("totalSupply()")
    assert_equal "0x70a08231", ChainReader::Base.selector("balanceOf(address)")
    assert_equal "0xa9059cbb", ChainReader::Base.selector("transfer(address,uint256)")
  end

  test "function_signature joins name + input types" do
    fn = { "name" => "balanceOf", "inputs" => [ { "type" => "address" } ] }
    assert_equal "balanceOf(address)", ChainReader::Base.function_signature(fn)
  end

  test "function_signature handles zero-arg functions" do
    fn = { "name" => "totalSupply", "inputs" => [] }
    assert_equal "totalSupply()", ChainReader::Base.function_signature(fn)
  end

  test "function_signature tolerates missing inputs key" do
    fn = { "name" => "name" }
    assert_equal "name()", ChainReader::Base.function_signature(fn)
  end

  test "hex_to_bytes strips 0x prefix and packs hex" do
    assert_equal "\x12\x34".b, ChainReader::Base.hex_to_bytes("0x1234")
    assert_equal "\x12\x34".b, ChainReader::Base.hex_to_bytes("1234")
  end

  test "eth_call_hex extracts result from JSON-RPC response hash" do
    fake = FakeRpcClient.new({ "jsonrpc" => "2.0", "id" => 1, "result" => "0xdeadbeef" })
    stub_class_method(ChainReader::Base, :client_for, ->(_chain) { fake }) do
      out = ChainReader::Base.eth_call_hex(@chain, to: "0xabc", data: "0x123")
      assert_equal "0xdeadbeef", out
    end
  end

  test "eth_call_hex raises RpcError on error field" do
    fake = FakeRpcClient.new({ "error" => { "code" => -32000, "message" => "missing trie node" } })
    stub_class_method(ChainReader::Base, :client_for, ->(_chain) { fake }) do
      err = assert_raises(ChainReader::Base::RpcError) do
        ChainReader::Base.eth_call_hex(@chain, to: "0xabc", data: "0x123")
      end
      assert_match(/-32000/, err.message)
      assert_match(/missing trie node/, err.message)
    end
  end

  test "eth_call_hex accepts raw string response (non-hash client)" do
    fake = FakeRpcClient.new("0xcafe")
    stub_class_method(ChainReader::Base, :client_for, ->(_chain) { fake }) do
      assert_equal "0xcafe", ChainReader::Base.eth_call_hex(@chain, to: "0xabc", data: "0x123")
    end
  end

  class FakeRpcClient
    def initialize(response)
      @response = response
    end

    def eth_call(_params)
      @response
    end
  end
end
