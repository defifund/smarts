# Why I'm building Smarts.md

Reading smart contract docs is a fragmented chore.

To figure out what a Uniswap pool's current fee, tick, and liquidity look like, you bounce between Etherscan's Read tab, the protocol's site, and a Dune dashboard. Each tool shows you a slice. Nothing tells you, in one place, "what this contract is right now."

Tools like Mintlify go a different direction — they turn a git repo into a polished docs site. But a contract's real state doesn't live in git. It lives on-chain, and it changes every block.

What Smarts.md does is simple:

- Give every verified contract a stable URL that opens to what it looks like **right now**.
- Bake an MCP endpoint into that same URL so Claude, Cursor, and other AI tools can read its state directly.
- Treat the docs as a live projection of the contract, not a snapshot frozen at some point in time.

This is for DeFi researchers — and for the growing crowd of people who read on-chain through AI.
