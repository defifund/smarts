# Chains are registered via the canonical Chains::Seeder. The chain list lives
# in db/seeds/chains.rb (single source of truth). Do NOT inline chain data here
# — keep this file as a thin orchestrator.
seeded = Chains::Seeder.call
puts "Seeded #{seeded} chains (total: #{Chain.count})"

# -----------------------------------------------------------------------------
# Protocol templates: for recognising common contract kinds by their ABI
# selectors. Keep ordered by priority (lower = more specific).
# -----------------------------------------------------------------------------

def sel(sig)
  ChainReader::Base.selector(sig)
end

templates = [
  {
    protocol_key: "uniswap_v3_pool",
    display_name: "Uniswap V3 Pool",
    description: "Concentrated-liquidity AMM pool (Uniswap V3 or a bytecode-compatible fork).",
    match_type: "required_selectors",
    priority: 10,
    required_selectors: [
      sel("factory()"),
      sel("token0()"),
      sel("token1()"),
      sel("fee()"),
      sel("slot0()"),
      sel("tickSpacing()"),
      sel("liquidity()")
    ]
  },
  {
    protocol_key: "erc721",
    display_name: "ERC-721 NFT",
    description: "Non-fungible token collection.",
    match_type: "required_selectors",
    priority: 50,
    required_selectors: [
      sel("balanceOf(address)"),
      sel("ownerOf(uint256)"),
      sel("approve(address,uint256)"),
      sel("getApproved(uint256)"),
      sel("setApprovalForAll(address,bool)"),
      sel("isApprovedForAll(address,address)"),
      sel("transferFrom(address,address,uint256)"),
      sel("safeTransferFrom(address,address,uint256)")
    ]
  },
  {
    protocol_key: "erc20",
    display_name: "ERC-20 Token",
    description: "Fungible token following the ERC-20 standard.",
    match_type: "required_selectors",
    priority: 100,
    required_selectors: [
      sel("totalSupply()"),
      sel("balanceOf(address)"),
      sel("transfer(address,uint256)"),
      sel("transferFrom(address,address,uint256)"),
      sel("approve(address,uint256)"),
      sel("allowance(address,address)")
    ]
  }
]

templates.each do |attrs|
  tmpl = ProtocolTemplate.find_or_initialize_by(protocol_key: attrs[:protocol_key])
  tmpl.update!(attrs)
end

puts "Seeded #{ProtocolTemplate.count} protocol templates"
