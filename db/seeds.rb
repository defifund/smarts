chains = [
  {
    name: "Ethereum", slug: "eth", chain_id: 1,
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: "https://ethereum-rpc.publicnode.com"
  },
  {
    name: "Base", slug: "base", chain_id: 8453,
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: "https://base-rpc.publicnode.com"
  },
  {
    name: "Arbitrum One", slug: "arbitrum", chain_id: 42161,
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: "https://arbitrum-one-rpc.publicnode.com"
  },
  {
    name: "Optimism", slug: "optimism", chain_id: 10,
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: "https://optimism-rpc.publicnode.com"
  },
  {
    name: "Polygon PoS", slug: "polygon", chain_id: 137,
    explorer_api_url: "https://api.etherscan.io/v2/api",
    rpc_url: "https://polygon-bor-rpc.publicnode.com"
  }
]

chains.each do |attrs|
  chain = Chain.find_or_initialize_by(slug: attrs[:slug])
  chain.update!(attrs)
end

puts "Seeded #{Chain.count} chains"
