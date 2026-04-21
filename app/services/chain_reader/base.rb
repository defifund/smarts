module ChainReader
  class Base
    class RpcError < StandardError; end

    @clients = {}
    @mutex = Mutex.new

    class << self
      def client_for(chain)
        @mutex.synchronize do
          @clients[chain.slug] ||= Eth::Client.create(chain.rpc_url)
        end
      end

      def eth_call_hex(chain, to:, data:)
        raw = client_for(chain).eth_call({ to: to, data: data })
        if raw.is_a?(Hash)
          if raw["error"]
            raise RpcError, "#{raw['error']['code']}: #{raw['error']['message']}"
          end
          raw["result"]
        else
          raw
        end
      end

      def selector(signature)
        "0x" + Eth::Util.keccak256(signature).unpack1("H*")[0..7]
      end

      def function_signature(fn_abi)
        types = Array(fn_abi["inputs"]).map { |i| i["type"] }.join(",")
        "#{fn_abi['name']}(#{types})"
      end

      def hex_to_bytes(hex)
        [ hex.to_s.sub(/\A0x/, "") ].pack("H*")
      end

      # Recursively builds the canonical ABI type string for an input/output hash.
      # Handles tuples (with components), tuple arrays (tuple[], tuple[N]), and
      # regular scalars. Feed this to Eth::Abi.decode/encode.
      def abi_type_string(io)
        type = io["type"].to_s
        return type unless type.start_with?("tuple")

        components = Array(io["components"])
        inner = "(" + components.map { |c| abi_type_string(c) }.join(",") + ")"
        suffix = type.sub(/\Atuple/, "")
        inner + suffix
      end
    end
  end
end
