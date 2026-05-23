---
date: 2026-05-22
source: https://smarts.md/mcp, https://smarts.md/univ3-usdc-weth-eth
tags: [uniswap-v3, dex, live-activity, mcp, smarts]
status: published
---

# Inside a DEX's Second-by-Second Flow: Ask Claude to Read Uniswap V3

## Start With One Question

A trader wants to understand the real-time state of the Uniswap USDC/WETH pool around 1 PM. She does not just want the price. There are already plenty of dashboards for that. What she really wants to know is:

> “Is this pool active right now? Who is trading? Are recent fills mostly whales or smaller orders? What are bots doing? Is the liquidity deep enough?”

The traditional path is to open Dune and run a query, or to check a trading terminal and read a volume bar. Those views are usually aggregated or retrospective. The question here is different: **what is happening right now?**

That is why we built smarts.md. You can ask Claude directly:

> “What has been happening recently in the USDC/WETH pool? Who is trading, how large are the fills, and are any large addresses active?”

Within seconds, Claude can use the smarts.md MCP tools to query live onchain data and return the current price, recent trades, main participant addresses, and liquidity depth.

---

## The Data Speaks

We pulled **100 Swap events** from this pool over a 37-minute window, from 2026-05-22 12:47 to 13:24 UTC. These were real onchain trades, not aggregated metrics. The query filtered only for the `Swap` event type.

Reproduction method: use the smarts.md MCP tool `get_recent_events` against `univ3-usdc-weth-eth`, with `event_name=Swap` and `limit=100`. The address classifications below are inferred from trading frequency, amount patterns, and call paths. They are not onchain identity labels.

### Who Is Trading?

**Inferred participant types**:

- **Likely market maker or MEV bot**: address `0xbdb...` appeared in 15+ trades, with regular sizing patterns such as repeated 298 USDC swaps. That looks more like automated rebalancing than manual trading.
- **Likely active rebalancing address**: address `0x4c8...` appeared frequently, with trade sizes ranging from a few hundred to tens of thousands of USDC. This looks like position adjustment.
- **Router paths**: some trades came through common Uniswap frontend or aggregator-style addresses such as `0x68b...` and `0xe59...`. That suggests both user orders and automated routing were flowing through the pool.
- **Likely arbitrage or scanning behavior**: one address sent 10+ trades within a minute, with sizes between $10 and $1,000. That looks like rapid tick scanning or spread detection.

In this sample, the automated trading footprint is strong. This does not look like a pool driven only by a few whale orders. It looks more like a high-frequency market maintained by routers, market-making strategies, and small arbitrage activity.

### Trade Size Distribution

| Trade size | Count | Interpretation |
|---|---:|---|
| **$100K to $200K** | ~5 | The largest trades in the sample |
| **$10K to $100K** | ~30 | Common mid-sized trades |
| **$1K to $10K** | ~40 | Likely market-making rebalance, arbitrage, or scanning behavior |
| **< $1K** | ~25 | Very small liquidity checks |

The largest trade was 162,926 USDC, roughly $163K. But it was only one of a small number of large trades during the 37-minute window. Most trades were between $1K and $50K, with an average size of only a few thousand dollars.

This looks less like a pure whale pool and more like **a market shaped by user orders, routers, and high-frequency automated strategies together**.

### How Stable Was the Price?

Across these 100 trades, the ETH price stayed mostly within **$2,070 to $2,074**, a range of roughly **0.2%**.

Onchain, this appeared as small `tick` movements between 199,670 and 199,677. Each swap moved the tick, but the next trade quickly pulled it back.

**What does that mean?** At least during this sample window, visible price impact was small. Combined with the pool's active liquidity, this suggests strong capacity for common small and mid-sized trades.

### How Frequent Were Trades?

100 trades / 37 minutes = **one trade every 22 seconds on average**.

The distribution was uneven:

- Peak minute, for example around 13:03: 7 trades.
- Slower minutes: 3 to 4 trades.

This is high-frequency, but not extreme. It suggests the pool had steady trading demand and active market-making support.

---

## What the Data Shows

1. **What a healthy AMM pool looks like**

Automated market makers and routers keep participating; very small trades clear without friction; price remains stable. This USDC/WETH sample window showed those characteristics.

2. **What bots are doing**

They may be rebalancing positions, indicated by repeated fixed-size trades. They may be arbitraging, indicated by second-level bursts. They may also be monitoring liquidity, where tiny swaps are used to test price differences.

3. **What traders can learn**

Want to enter a larger position? This pool had strong capacity during the sample window, but you still need to check live slippage. Want a better fill? Periods with dense automated trading, such as 12:59 to 13:05, may have more active liquidity. Looking for arbitrage? Tick movement helps identify pressure points.

---

## Why This Matters

Traditional data tools usually give you:

- Aggregated data, such as “volume over the past hour.”
- Historical analysis, such as “last week's volume compared with this week.”
- Secondhand indicators, such as “a site says liquidity is good.”

smarts.md + Claude gives you:

- **Near-real-time raw trade flow**: direct reads from onchain events.
- **Full addresses and event parameters**: who called, how large, how often.
- **Market microstructure**: price stability, depth, and bot participation.

That matters for:

- **Traders**: understand when liquidity is deepest.
- **LPs**: see how their liquidity is used and where fees come from.
- **Researchers**: access first-party raw data for onchain microstructure.
- **Developers**: build automated strategies on top of live trade flow.

With one question to Claude, you can connect contract state, recent events, and key parameters. That is the core promise of smarts.md: **make the live state of contracts visible and understandable to everyone**.

---

Next time you want to understand what is happening right now in a DEX pool, lending protocol, or any EVM contract, you do not need to dig through data, write a query, and wait. Ask Claude. Read smarts.md.

The data can answer in real time.

---

**Data snapshot**:

- Pool: Uniswap V3 USDC/WETH 0.05% (Ethereum)
- Window: 2026-05-22 12:47 to 13:24 UTC
- Sample: 100 consecutive Swap events
- Snapshot price: 1 WETH = $2,072 USDC
- Snapshot TVL: $100.7M
