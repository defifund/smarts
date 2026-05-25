# Canonical chain registry — single source of truth.
#
# Add a new chain here, then run `bin/rails db:seed` (dev) or trigger
# `Chains::Seeder.call` (deploy hook / runner / spec setup). The seeder is
# idempotent: re-runs upsert by `slug`, never duplicates.
#
# Do NOT write per-chain data migrations. The previous pattern
# (db/migrate/*_add_<chain>_chain.rb) is deprecated; new chains belong here.

# ── Tier 1 — full: live state + activity + governance via RPC. ──────────
- name: "Ethereum"
  slug: "eth"
  chain_id: 1
  tier: "full"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: "https://ethereum-rpc.publicnode.com"
- name: "Base"
  slug: "base"
  chain_id: 8453
  tier: "full"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: "https://base-rpc.publicnode.com"
- name: "Arbitrum One"
  slug: "arbitrum"
  chain_id: 42161
  tier: "full"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: "https://arbitrum-one-rpc.publicnode.com"
- name: "Optimism"
  slug: "optimism"
  chain_id: 10
  tier: "full"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: "https://optimism-rpc.publicnode.com"
- name: "BNB Smart Chain"
  slug: "bnb"
  chain_id: 56
  tier: "full"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: "https://bsc-rpc.publicnode.com"
- name: "Polygon PoS"
  slug: "polygon"
  chain_id: 137
  tier: "full"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: "https://polygon-bor-rpc.publicnode.com"

# ── Tier 2 — docs_only: Etherscan source/ABI only, no RPC, no live data. ─
# Order roughly by ecosystem maturity / search demand. Etherscan V2 Free tier
# serves `getsourcecode` / `getabi` for ALL supported chains — that's the
# entire reason Tier 2 costs $0 to operate.
- name: "Linea"
  slug: "linea"
  chain_id: 59144
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
- name: "Unichain"
  slug: "unichain"
  chain_id: 130
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
- name: "Berachain"
  slug: "berachain"
  chain_id: 80094
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
- name: "Blast"
  slug: "blast"
  chain_id: 81457
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
- name: "Sonic"
  slug: "sonic"
  chain_id: 146
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
- name: "Mantle"
  slug: "mantle"
  chain_id: 5000
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
- name: "Gnosis"
  slug: "gnosis"
  chain_id: 100
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
- name: "Celo"
  slug: "celo"
  chain_id: 42220
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
- name: "Fraxtal"
  slug: "fraxtal"
  chain_id: 252
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
- name: "Taiko"
  slug: "taiko"
  chain_id: 167000
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
- name: "World Chain"
  slug: "world"
  chain_id: 480
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
- name: "Abstract"
  slug: "abstract"
  chain_id: 2741
  tier: "docs_only"
  explorer_api_url: "https://api.etherscan.io/v2/api"
  rpc_url: null
