---
date: 2026-05-22
source: https://docs.etherscan.io/supported-chains, https://docs.etherscan.io/resources/rate-limits, https://etherscan.io/apis, https://docs.etherscan.io/api-reference/endpoint/getlogs, https://docs.etherscan.io/api-pro/api-pro
tags: [etherscan, api, base, analytics]
status: draft
---

# What Etherscan's Pricing and Coverage Mean for Base Analytics

If you only treat Etherscan as a site for checking transactions, it looks simple.

But once you actually want to use it for onchain analysis, especially for things like events, historical balances, and holder structure on Base, the pricing tier, chain coverage, and endpoint tiers directly determine whether your workflow can run at all.

This piece does not try to make a sentimental judgment. It only breaks down the most important facts from the official docs and makes three things clear:

1. How Etherscan charges now.
2. Which chains are available on the free tier and which are not.
3. For Base or other supported chains, what the minimum paid tier is for analysis.

---

## Bottom Line First

If your goal is only to get event analysis on Base working, `Lite` is basically enough.

If you also want historical balances, historical total supply, holder lists, and other deeper analysis, `Standard` is the starting tier.

More specifically:

- **Base Mainnet is not available on the Free tier**
- **The event log endpoint `getLogs` exists**
- **ABI / source / Verify Source Code are available on all chains, including the Free tier**
- **Base event access through `getLogs` requires at least `Lite`**
- **Many historical analysis endpoints are PRO endpoints and require `Standard` or above**

So the question is not "can I look at it?" but "what level can I see, and which level am I willing to pay for?"

---

## What the Plans Look Like

Etherscan's currently public monthly plans are:

| Plan | Price | Calls / second | Daily calls | Coverage |
|---|---:|---:|---:|---|
| Free | $0 | 3 | 100,000 | selected chains community endpoints |
| Lite | $49/mo | 5 | 100,000 | ALL supported chains community endpoints |
| Standard | $199/mo | 10 | 200,000 | ALL supported chains community endpoints + API Pro |
| Advanced | $299/mo | 20 | 500,000 | ALL supported chains community endpoints + API Pro |
| Professional | $399/mo | 30 | 1,000,000 | ALL supported chains community endpoints + API Pro |
| Pro Plus | $899/mo | 30 | 1,500,000 | ALL supported chains community endpoints + API Pro + Address Metadata |

The easiest point to misunderstand here is:

- `Free` does not mean "all chains are barely usable"
- `Lite` is the point where "all supported chains community endpoints" begins
- `Standard` is the point where `API Pro` endpoints begin

That means you need to separate two dimensions first:

1. Whether the chain is covered
2. Whether the endpoint is a PRO endpoint

Those are not the same thing.

### Official Supported Chains

According to Etherscan's official `Supported Chains` page, the current supported chains can be split into two groups:

**Available on the Free tier**

- Ethereum Mainnet
- Sepolia Testnet
- Hoodi Testnet
- Polygon Mainnet
- Polygon Amoy Testnet
- Arbitrum One Mainnet
- Arbitrum Sepolia Testnet
- Linea Mainnet
- Linea Sepolia Testnet
- Blast Mainnet
- Blast Sepolia Testnet
- BitTorrent Chain Mainnet
- BitTorrent Chain Testnet
- Celo Mainnet
- Celo Sepolia Testnet
- Fraxtal Mainnet
- Fraxtal Hoodi Testnet
- Gnosis
- Mantle Mainnet
- Mantle Sepolia Testnet
- Memecore Mainnet
- Memecore Insectarium Testnet
- Moonbeam Mainnet
- Moonriver Mainnet
- Moonbase Alpha Testnet
- opBNB Mainnet
- opBNB Testnet
- Taiko Mainnet
- Taiko Hoodi
- XDC Mainnet
- XDC Apothem Testnet
- ApeChain Mainnet
- ApeChain Curtis Testnet
- World Mainnet
- World Sepolia Testnet
- Sonic Mainnet
- Sonic Testnet
- Unichain Mainnet
- Unichain Sepolia Testnet
- Abstract Mainnet
- Abstract Sepolia Testnet
- Berachain Mainnet
- Berachain Bepolia Testnet
- Monad Mainnet
- Monad Testnet
- HyperEVM Mainnet
- Katana Mainnet
- Katana Bokuto
- Sei Mainnet
- Sei Testnet
- Stable Mainnet
- Stable Testnet
- Plasma Mainnet
- Plasma Testnet
- MegaETH Mainnet
- MegaETH Testnet

**Available on paid tiers, but not on the Free tier**

- BNB Smart Chain Mainnet
- BNB Smart Chain Testnet
- Base Mainnet
- Base Sepolia Testnet
- Optimism
- OP Sepolia Testnet
- Avalanche C-Chain
- Avalanche Fuji Testnet

---

## The Key Base Limitation

Etherscan's official supported chain page is explicit:

- Ethereum Mainnet is available on the Free tier
- **Base Mainnet is Not Available on the Free tier**
- Base Sepolia is also Not Available on the Free tier

That is why if you try to pull an event timeline or recent events on Base through a workflow that depends on Etherscan's free tier, you will hit a wall immediately.

The issue is not "Base has no data." The issue is "Base is outside the free coverage."

The practical impact on analysis is straightforward:

- Static contract info is usually fine
- Current state is also usually fine
- As soon as you need event streams, the free tier is no longer enough

---

## Which Endpoints Belong to Which Layer

### 1. Event logs are possible, but chain and plan matter

`getLogs` is Etherscan's event log endpoint.

Its purpose is clear:

- Pull events by address
- Pull events by topics
- Pull events by block range

This is the foundation for event timelines, recent events, and event-cluster analysis.

But for Base, the question is not whether the endpoint exists. It is:

- Base Mainnet is not available on the Free tier
- So you need at least `Lite`

### 2. The Free tier mainly covers source, ABI, and verification endpoints

The official docs clearly state that:

- Contract source code
- ABI
- Verify Source Code

are available across all chains and all plans, including the Free tier.

That means if all you need is to confirm things like:

- Is this `FiatTokenV2_2`?
- What is the implementation contract?
- What do the functions and events look like?

then the free tier is enough.

### 3. Once you need historical data, you are usually in PRO territory

The most common Etherscan PRO endpoints include:

- Historical ERC20 total supply
- Historical ERC20 account balance
- Token holder list
- Token holder count
- Current token holdings by address
- Historical native coin balance

These capabilities matter for deep analysis, but Etherscan places them at `Standard` and above.

So:

- If you want "current state," the free tier may be enough
- If you want "historical trajectory," you usually need PRO

---

## What This Means for Base Analysis

If you want to write a full article about Base event analysis, it helps to decide the budget first.

### If you only want event observation

If you only want to watch:

- `MinterConfigured`
- `Blacklisted`
- `UnBlacklisted`
- other governance or config events

then the minimum budget is usually:

- **Lite**

This is enough for writing about:

- What happened recently
- Which addresses keep getting reconfigured
- Whether there are event clusters
- Whether the system is currently paused

### If you want historical deep dives

If you also want to see:

- Historical total supply
- Historical balances
- Holder lists
- Holder counts
- An address's holdings at a past block

then you should start directly with:

- **Standard**

because most of those capabilities are PRO endpoints.

---

## The Most Common Mistakes

### Pitfall 1: Mistaking "there is an event endpoint" for "it is free to use"

`getLogs` exists, but that does not mean all chains are available on the free tier.

Base Mainnet is not available on the Free tier.

### Pitfall 2: Mistaking "basic visibility" for "full analysis ability"

ABI, source, and verify are basic visibility.

Historical balances, holder lists, and historical supply are another layer.

### Pitfall 3: Thinking `Lite` already covers everything

`Lite` only guarantees access to ALL supported chains community endpoints.

If what you need is already in PRO endpoints, you still need to upgrade.

---

## How I Would Budget It

If the only goal is to get the Base USDC event line running, I would buy `Lite` first.

If the goal is to produce a complete analysis article, I would go straight to `Standard`.

The reason is practical:

1. `Lite` lets you verify whether the event stream works.
2. `Standard` prevents you from discovering halfway through that historical data is missing.

If you are doing ongoing analysis rather than a one-off check, `Standard` is often cheaper than repeatedly patching gaps.

---

## Reproducible Query Path

This judgment is based mainly on the official docs, so to reproduce it, you can go directly to these pages:

- [Supported Chains](https://docs.etherscan.io/supported-chains)
- [Rate Limits](https://docs.etherscan.io/resources/rate-limits)
- [Get Event Logs by Address](https://docs.etherscan.io/api-reference/endpoint/getlogs)
- [PRO Endpoints](https://docs.etherscan.io/api-pro/api-pro)
- [Etherscan APIs](https://etherscan.io/apis)

If you want to plug this into any analysis workflow, the most practical decision order is:

1. Confirm the contract info and current state first.
2. Then check whether event logs can be pulled.
3. Only then decide whether you need PRO endpoints for historical data.

---

## Conclusion

For analysis scenarios like Base, the key question with Etherscan is not "is it expensive?" but "which layer of data do you need?"

If you only need event observation, `Lite` is the minimum usable tier.

If you need historical balances, holders, or historical supply, `Standard` is the starting point.

That also explains a very practical difference: why Ethereum-side analysis can get started quickly, while Base forces you to think about the plan as soon as you touch event data.

The analysis method did not change. The threshold on the underlying data layer did.
