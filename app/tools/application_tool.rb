# frozen_string_literal: true

# Base class for all MCP tools, on top of the official `mcp` gem
# (modelcontextprotocol/ruby-sdk).
#
# Subclasses define their business logic in `self.payload(**args)`,
# returning a plain Ruby Hash. The base class's `self.call` wraps that
# hash in the `MCP::Tool::Response` shape required by the SDK,
# JSON-encoding the payload as a single text content block — that's how
# MCP clients (Claude, Cursor, …) feed structured tool output back to
# the LLM.
#
# Splitting `payload` from `call` keeps the SDK plumbing in one place
# and lets tests assert against the underlying Hash directly without
# unwrapping protocol envelopes.
class ApplicationTool < MCP::Tool
  class << self
    # MCP SDK entry point. Subclasses don't override this — they
    # implement `payload` instead. We accept `server_context:` to match
    # the SDK contract but currently ignore it (no per-request state).
    def call(server_context: nil, **args)
      text_response(payload(**args))
    end

    # Subclasses implement this and return a plain Hash.
    def payload(**)
      raise NotImplementedError, "#{name} must implement self.payload(**args)"
    end

    # Wraps a plain Hash (or already-built Response) into the
    # MCP::Tool::Response shape required by the SDK.
    def text_response(hash)
      return hash if hash.is_a?(MCP::Tool::Response)

      MCP::Tool::Response.new([ { type: "text", text: hash.to_json } ])
    end

    # Resolves a tool's contract input (either a slug OR chain+address) to a
    # [chain_record, contract] pair. Returns an error hash on any failure —
    # callers should short-circuit when the result is a Hash.
    #
    # Slug wins when both are supplied (friendlier than erroring on conflict).
    def resolve_contract(chain: nil, address: nil, slug: nil)
      if slug.present?
        lookup = ContractSlugs.resolve(slug)
        return { error: "unknown slug: #{slug}" } unless lookup

        chain_slug, address = lookup
      else
        return { error: "either `slug` or both `chain` + `address` required" } if chain.blank? || address.blank?

        chain_slug = chain
      end

      chain_record = Chain.find_by(slug: chain_slug)
      return { error: "unknown chain: #{chain_slug}" } unless chain_record

      normalized_address = address.to_s.downcase
      contract = Contract.find_by(chain: chain_record, address: normalized_address)
      unless contract
        return { error: "contract not indexed — visit https://smarts.md/#{chain_slug}/#{normalized_address} first" }
      end

      [ chain_record, contract ]
    end
  end
end
