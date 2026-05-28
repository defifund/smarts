# Smarts Now Covers 50 EVM Chains: A Full Map From Ethereum to the Long Tail

In May 2026, we reached a milestone: **Smarts now officially supports 50 EVM chains**.

This is not a vanity number. It means that whether developers are working on mainstream L2s like Ethereum, Base, and Arbitrum, or experimenting in emerging ecosystems like Berachain, Monad, and HyperEVM, they can query verified contract source code, ABIs, and AI-generated function explanations in one place. On the 6 mainstream chains, they can also read live on-chain state, recent events, and governance risk.

## The Map

The 50 chains are not all treated the same. They are split into two tiers:

**Tier 1: 6 mainstream chains** -- full capability
- Ethereum, Base, Arbitrum One, Optimism, BNB Smart Chain, Polygon PoS
- These chains support **live state** queries: real-time values for view functions, recent events, governance activity, and admin risk analysis
- Developers and AI agents can quickly answer questions like "What is this pool's current price?" or "What are Aave's current risk parameters?"

**Tier 2: 44 other chains** -- source code + ABI

**Mainnets (23):**
Linea, Unichain, Berachain, Blast, Sonic, Mantle, Gnosis, Celo, Fraxtal, Taiko, World Chain, Abstract, Moonbeam, Moonriver, opBNB, XDC, Monad, HyperEVM, Katana, Sei, Stable, Plasma, MegaETH

**Testnets (21):**
Ethereum Sepolia, Hoodi, Polygon Amoy, Arbitrum Sepolia, Linea Sepolia, Blast Sepolia, Celo Sepolia, Fraxtal Hoodi, Moonbase Alpha, opBNB Testnet, XDC Apothem, Unichain Sepolia, World Chain Sepolia, Berachain Bepolia, Monad Testnet, HyperEVM Testnet, Katana Bokuto, Sei Testnet, Stable Testnet, Plasma Testnet, MegaETH Testnet

This tier does not use RPC for live on-chain state. It reads verified contract source code and ABIs directly from Etherscan.

## Why Cover the Long Tail

Traditional contract documentation tools carry an implicit assumption: only top protocols are worth documenting.

Etherscan has verified millions of contracts, but 95% of users only look at the Top 100. Documentation platforms like Mintlify require each project team to write their own docs, so they mostly exist for funded protocols.

But the long tail is active.

Emerging L2s such as Berachain, Monad, and Sonic have new DeFi primitives. Vertical chains like Unichain and World Chain attract developers from specific communities. Contracts in the Farcaster and Lens ecosystems need review. When an AI agent or researcher wants to understand a market end to end, the answer is not "only the 6 big chains." It is full accessibility across the EVM ecosystem.

Smarts makes this possible. Developers no longer need one workflow for Etherscan on 6 chains and another tool for Linea. **One MCP endpoint gives a unified query interface across 50 chains.**

## What This Changes for AI

The strongest part of Smarts is not the web interface. It is MCP.

When a developer asks Claude Code or Cursor, "What is the price and liquidity of this Uniswap V3 pool on Base?" Claude can call Smarts MCP tools directly and return live data plus function explanations. No need to:
- Open Etherscan
- Read Solidity manually
- Ask Claude again to explain the code

**Support for 50 chains** means this workflow covers the documentation entry point for the whole EVM ecosystem. Researching DeFi on Sonic? Auditing RWA contracts on Celo? Learning account abstraction on Abstract? Claude can read verified source code, ABIs, and function explanations directly; on Tier 1 chains, it can also continue into live state and events.

## The Technical Leverage

Why can Smarts span 50 chains?

The leverage comes from a **tiered design**:
- The 6 mainstream chains require RPC cost and maintenance, but they cover mainstream DeFi liquidity and the highest-frequency contract query scenarios.
- The other 44 chains read verified source code and ABIs from Etherscan. The main cost of adding a chain is registering the chain configuration and validating the indexing flow.

This is hard for competitors to replicate. Etherscan is a centralized service. Mintlify requires every team to write docs manually. Dune requires developers to write SQL. Only the combination of AI and on-chain querying can cover the ecosystem at this scale.

## What's Next

50 chains are the current state. But this is only the beginning.

We already support full adapters for Uniswap V3 and generic ERC-20/ERC-721 contracts. Next, we are building dedicated adapters for Polymarket, more DEXs, and lending protocols. These adapters will upgrade contract documentation from "show me the source code and ABI" to "show me this pool's live trading fee" or "show me this options market's current odds."

Long term, **Smarts aims to become the unified knowledge base for the EVM ecosystem**: not just documentation, but the fastest path for anyone -- developers, researchers, and AI agents -- to understand any contract.

50 chains are the infrastructure for that vision. The real value will show up in the next protocol adapters and AI workflow improvements.

---

**Try Smarts:** Start with [https://smarts.md/usdc-eth](https://smarts.md/usdc-eth), or try any supported contract on any of the 50 chains.

**Use it in Claude Code:** Install the Smarts MCP server at [https://mcp.smarts.md/](https://mcp.smarts.md/) and ask Claude about verified contract source code, ABIs, and functions. On Tier 1 chains, you can also query live state, events, and risk.
