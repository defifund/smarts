# Canonical chain registry — single source of truth.
#
# Add a new chain here, then run `bin/rails db:seed` (dev) or trigger
# `Chains::Seeder.call` (deploy hook / runner / spec setup). The seeder is
# idempotent: re-runs upsert by `slug`, never duplicates.
#
# Do NOT write per-chain data migrations. The previous pattern
# (db/migrate/*_add_<chain>_chain.rb) is deprecated; new chains belong here.

[
  # ── Tier 1 — full: live state + activity + governance via RPC. ──────────
  {
    name: "Ethereum", slug: "eth", chain_id: 1, tier: "full",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: "https://ethereum-rpc.publicnode.com"
  },
  {
    name: "Base", slug: "base", chain_id: 8453, tier: "full",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: "https://base-rpc.publicnode.com"
  },
  {
    name: "Arbitrum One", slug: "arbitrum", chain_id: 42161, tier: "full",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: "https://arbitrum-one-rpc.publicnode.com"
  },
  {
    name: "Optimism", slug: "optimism", chain_id: 10, tier: "full",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: "https://optimism-rpc.publicnode.com"
  },
  {
    name: "BNB Smart Chain", slug: "bnb", chain_id: 56, tier: "full",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: "https://bsc-rpc.publicnode.com"
  },
  {
    name: "Polygon PoS", slug: "polygon", chain_id: 137, tier: "full",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: "https://polygon-bor-rpc.publicnode.com"
  },

  # ── Tier 2 — docs_only: Etherscan source/ABI only, no RPC, no live data. ─
  {
    name: "Linea", slug: "linea", chain_id: 59144, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  }
]
