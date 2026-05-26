# Canonical chain registry — single source of truth.
#
# Add a new chain here, then run `bin/rails db:seed` (dev) or trigger
# `Chains::Seeder.call` (deploy hook / runner / spec setup). The seeder is
# idempotent: re-runs upsert by `slug`, never duplicates.
#
# Do NOT write per-chain data migrations. The previous pattern
# (db/migrate/*_add_<chain>_chain.rb) is deprecated; new chains belong here.

Object.send(:remove_const, :CHAIN_SEEDS) if Object.const_defined?(:CHAIN_SEEDS)

CHAIN_SEEDS = [
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
  {
    name: "Ethereum Sepolia", slug: "sepolia", chain_id: 11_155_111, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Ethereum Hoodi", slug: "hoodi", chain_id: 560_048, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Polygon Amoy", slug: "polygon-amoy", chain_id: 80_002, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Arbitrum Sepolia", slug: "arbitrum-sepolia", chain_id: 421_614, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Linea Sepolia", slug: "linea-sepolia", chain_id: 59_141, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Blast Sepolia", slug: "blast-sepolia", chain_id: 168_587_773, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Celo Sepolia", slug: "celo-sepolia", chain_id: 11_142_220, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Fraxtal Hoodi", slug: "fraxtal-hoodi", chain_id: 2_523, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Moonbeam", slug: "moonbeam", chain_id: 1_284, tier: "docs_only", network_kind: "mainnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Moonriver", slug: "moonriver", chain_id: 1_285, tier: "docs_only", network_kind: "mainnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Moonbase Alpha", slug: "moonbase", chain_id: 1_287, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "opBNB", slug: "opbnb", chain_id: 204, tier: "docs_only", network_kind: "mainnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "opBNB Testnet", slug: "opbnb-testnet", chain_id: 5_611, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "XDC Mainnet", slug: "xdc", chain_id: 50, tier: "docs_only", network_kind: "mainnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "XDC Apothem", slug: "xdc-apothem", chain_id: 51, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Unichain Sepolia", slug: "unichain-sepolia", chain_id: 1_301, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "World Chain Sepolia", slug: "world-sepolia", chain_id: 4_801, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Berachain Bepolia", slug: "berachain-bepolia", chain_id: 80_069, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Monad", slug: "monad", chain_id: 143, tier: "docs_only", network_kind: "mainnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Monad Testnet", slug: "monad-testnet", chain_id: 10_143, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "HyperEVM", slug: "hyperevm", chain_id: 999, tier: "docs_only", network_kind: "mainnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "HyperEVM Testnet", slug: "hyperevm-testnet", chain_id: 998, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Katana", slug: "katana", chain_id: 747_474, tier: "docs_only", network_kind: "mainnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Katana Bokuto", slug: "bokuto", chain_id: 737_373, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Sei", slug: "sei", chain_id: 1_329, tier: "docs_only", network_kind: "mainnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Sei Testnet", slug: "sei-testnet", chain_id: 1_328, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Stable", slug: "stable", chain_id: 988, tier: "docs_only", network_kind: "mainnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Stable Testnet", slug: "stable-testnet", chain_id: 2_201, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Plasma", slug: "plasma", chain_id: 9_745, tier: "docs_only", network_kind: "mainnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Plasma Testnet", slug: "plasma-testnet", chain_id: 9_746, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "MegaETH", slug: "megaeth", chain_id: 4_326, tier: "docs_only", network_kind: "mainnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "MegaETH Testnet", slug: "megaeth-testnet", chain_id: 6_343, tier: "docs_only", network_kind: "testnet",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },

  # ── Tier 2 — docs_only: Etherscan source/ABI only, no RPC, no live data. ─
  # Order roughly by ecosystem maturity / search demand. Etherscan V2 Free tier
  # serves `getsourcecode` / `getabi` for ALL supported chains — that's the
  # entire reason Tier 2 costs $0 to operate.
  {
    name: "Linea", slug: "linea", chain_id: 59144, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Unichain", slug: "unichain", chain_id: 130, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Berachain", slug: "berachain", chain_id: 80094, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Blast", slug: "blast", chain_id: 81457, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Sonic", slug: "sonic", chain_id: 146, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Mantle", slug: "mantle", chain_id: 5000, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Gnosis", slug: "gnosis", chain_id: 100, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Celo", slug: "celo", chain_id: 42220, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Fraxtal", slug: "fraxtal", chain_id: 252, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Taiko", slug: "taiko", chain_id: 167000, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "World Chain", slug: "world", chain_id: 480, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  },
  {
    name: "Abstract", slug: "abstract", chain_id: 2741, tier: "docs_only",
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: nil
  }
].freeze
