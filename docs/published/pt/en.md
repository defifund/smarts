---
date: 2026-05-23
source: https://github.com/Polymarket/ctf-exchange, https://smarts.md/eth/0xe111180000d2663c0091e4f400237545b87b996b
contract: 0xe111180000d2663c0091e4f400237545b87b996b
tags: [polymarket, dex, gas-optimization, order-matching, ctf]
status: published
---

# Why COMPLEMENTARY Matches Are Cheaper on Polymarket

Every trade on Polymarket involves a contract-level choice: how to settle the order.

That choice materially affects gas cost. It affects how liquidity is distributed, how tight spreads are, and how active a market is likely to become.

Below is a walkthrough of **three settlement paths in CTFExchange V2**, and how the code implements them.

---

## The Three Paths Through CTFExchange

When two orders meet on Polymarket, the contract can settle them in three ways. Each path touches different assets, triggers different on-chain actions, and costs a different amount of gas.

### Path 1: COMPLEMENTARY - The Lowest-Cost Case

Two traders are betting on the same binary outcome, but on opposite sides.

- **Trader A** wants to BUY YES at 0.60 USDC (willing to pay 0.60 per share)
- **Trader B** wants to SELL YES at 0.60 USDC (willing to receive 0.60 per share)

When the orders cross, **there is no need to trigger mint/merge**. In this example, one side provides collateral and the other side provides the outcome token. The exchange still participates in settlement, but it avoids the extra mint/merge path and only has to route the necessary asset transfers:

```
Trader A: sends 0.60 USDC to Trader B
          receives YES tokens from Trader B

Trader B: sends YES tokens to Trader A
          receives 0.60 USDC from Trader A
```

**2 transfers total**: one for collateral, one for outcome tokens. No extra minting or merging.

**Gas cost**: roughly ~2 external calls (ERC20/ERC1155 transfers).

### Path 2: MINT - Creating New Positions

Complementary orders do not always exist. In many cases, the market needs to create new outcome tokens.

Imagine:

- **Trader A** wants to BUY YES at 0.60 USDC
- **Trader C** wants to BUY NO at 0.40 USDC

Polymarket's underlying settlement layer (Gnosis Conditional Tokens) works in pairs: when you mint one outcome token, you mint its complement at the same time.

When Trader A and Trader C meet:

```
Exchange receives:
  - 0.60 USDC from Trader A
  - 0.40 USDC from Trader C

Exchange calls MINT on Conditional Tokens:
  - Provides 1.00 USDC collateral
  - Receives 1 YES + 1 NO

Exchange then distributes:
  - YES to Trader A
  - NO to Trader C
  - Net proceeds to each trader
```

The contract **batches all MINT calls** - if five orders match at once, it mints once instead of five times.

**Gas cost**: roughly ~5 external calls (transfers + one batched mint) + conditional token overhead.

### Path 3: MERGE - Unwinding Positions

The opposite of MINT. When a trader wants to exit by selling both complementary outcomes, the exchange can call MERGE to burn them and return the collateral.

The contract also batches multiple MERGE requests into a single call instead of processing each one separately.

**Gas cost**: roughly ~5 external calls (transfers + one batched merge) + conditional token overhead.

---

## Why the Difference Matters

Numbers first:

| Settlement Type | Transfers | CTF Operations | Approx Gas (Polygon) |
|---|---|---|---|
| **COMPLEMENTARY** | 2 | 0 | 50-80K |
| **MINT** | 5-6 | 1 | 180-250K |
| **MERGE** | 5-6 | 1 | 180-250K |

A COMPLEMENTARY match costs **60-70% less gas** than a MINT or MERGE match.

If you look only at gas usage, COMPLEMENTARY is around `50k-80k`, while MINT / MERGE is around `180k-250k`. At current Polygon ecosystem token prices, the dollar cost per trade is very low and usually falls below a cent.

For frequent traders, that difference shows up in cumulative cost.

---

## The Code Architecture That Makes This Possible

CTFExchange V2's `Trading.sol` mixin contains the logic for all three paths. Here's what makes it work:

### Order Matching Dispatch

```solidity
function _deriveMatchType(Order memory takerOrder, Order memory makerOrder)
    internal pure returns (MatchType) {
    // MatchType.COMPLEMENTARY: same tokenId, opposite sides
    // MatchType.MINT: BUY + BUY
    // MatchType.MERGE: SELL + SELL
}
```

The exchange decides which settlement path applies based on order direction at match time. In logic terms: if both orders reference the same outcome token and point in opposite directions, it is COMPLEMENTARY. Otherwise, it is MINT or MERGE.

### COMPLEMENTARY Optimization

For COMPLEMENTARY matches, the contract does not need an extra mint/merge path.

```solidity
function _settleComplementary(...) internal {
    for (uint256 i = 0; i < makerOrders.length; ++i) {
        // Taker BUY ↔ Maker SELL: direct transfers both ways
        _transfer(makerOrder.maker, taker, makerOrder.tokenId, fillAmount);
        _transfer(taker, makerOrder.maker, 0, collateralProceeds);
    }
}
```

Instead of:

```
(the common path in many general-purpose DEXes)
Taker -> Exchange -> Maker
Maker -> Exchange -> Taker
```

It does this:

```
(Polymarket's direct settlement path)
Taker <-> Maker  (directly)
```

This **saves ~3 transfers per match**; the cumulative difference grows as match count increases.

### Batched CTF Operations

For MINT and MERGE, Polymarket batches all conditional token creation/burning into a single call:

```solidity
// Phase 1: validate all maker orders
for (uint256 i = 0; i < length; ++i) {
    prepared[i] = _prepareMakerOrder(...);
    if (matchType == MatchType.MINT) {
        totalMintAmount += prepared[i].takingAmount;
    }
}

// Phase 2: one batched MINT call
if (totalMintAmount > 0) _mint(conditionId, totalMintAmount);

// Phase 3: distribute proceeds
for (uint256 i = 0; i < length; ++i) {
    _distributeMintProceeds(prepared[i], ...);
}
```

If five orders need to be minted, the contract:
1. Validates all five
2. Mints all five in **one call** (1000 wei vs 5 x 1000 wei if separate)
3. Distributes proceeds

The gas savings are closer to a "fixed overhead amortized across more matches" effect: the more matches there are, the lower the average cost per match, but it is not a logarithmic relationship.

---

## The Market Topology That Emerges

These cost differences affect where liquidity tends to show up.

### In Binary Markets (Same Outcome, Opposite Side)

If Trader A (BUY YES at 0.60) meets Trader B (SELL YES at 0.60), settlement is **COMPLEMENTARY**, and gas usage lands in the lower range.

When complementary matches are more common, traders are more willing to accept tighter spreads, and liquidity is more likely to cluster.

### In Hedging Markets (Different Outcomes)

If Trader A (BUY outcome-1) meets Trader C (SELL outcome-2), settlement requires MINT, and gas usage is higher.

If you need to go through MINT, costs are higher and spreads are wider.

This cost difference comes from Polymarket's settlement structure: markets that naturally form complementary matches have lower settlement costs, so their spreads tend to be tighter; markets with less complementary flow have higher costs.

---

## The Assembly Layer

CTFExchange goes deeper. The code uses **Solidity assembly** in several critical paths to squeeze out gas:

### Packing OrderStatus Into One Storage Slot

```solidity
// Single SLOAD: read packed slot and extract both filled and remaining
bool filled;
uint256 remaining;
assembly {
    let packed := sload(status.slot)
    filled := and(packed, 0xff)
    remaining := shr(8, packed)
}
```

Instead of storing `filled` and `remaining` in separate storage slots (two SLOAD costs), the contract packs both into one 256-bit word. One SLOAD retrieves both.

### Deriving Asset IDs Without Branches

```solidity
// SIDE * tokenId, tokenId - SIDE * tokenId
// buy:  0, tokenId
// sell: tokenId, 0
assembly {
    makerAssetId := mul(side, tokenId)
    takerAssetId := sub(tokenId, makerAssetId)
}
```

Instead of `if (side == BUY) { makerAssetId = 0; } else { makerAssetId = tokenId; }`, the code uses pure arithmetic. This reduces conditional branching and control-flow overhead, which fits EVM execution better.

### Checking if All Makers Are Complementary

```solidity
assembly {
    result := 1
    let length := mload(makerOrders)
    let ptr := add(makerOrders, 0x20)
    for { let i := 0 } lt(i, length) { i := add(i, 1) } {
        let orderPtr := mload(add(ptr, shl(5, i)))
        let side := mload(add(orderPtr, 0xC0))
        if eq(side, takerSide) {
            result := 0
            break
        }
    }
}
```

This checks whether every maker is on the opposite side from the taker - a **single early exit** if any maker matches. No intermediate arrays. No extra allocations.

---

## What This Means for Traders and LPs

### For Traders

- If you trade in markets where complementary matches are likely, expect cheaper settlement and tighter spreads.
- If you trade in markets that require MINT/MERGE matches, expect higher costs and wider spreads.

Some traders break large orders into smaller ones to improve the odds of complementary matching.

### For Market Makers

On active markets, placing orders in locations that are easier to match complementarily leads to:
- Lower realized execution costs
- Tighter bid-ask spreads to compete on
- Higher volume needed to be profitable

In the same market, orders placed further away are more likely to trigger MINT/MERGE, so costs are higher and quotes are wider.

The spreads you see on Polymarket are related to the settlement-cost structure.

### For Researchers

If a market's order flow is mostly COMPLEMENTARY, you can observe:
- Mature two-sided liquidity
- Low spreads, high volume, efficiency
- Small position turnover

If a market's order flow is mostly MINT/MERGE, you can observe:
- Emerging market, one-directional flow
- Wider spreads
- Hedging-heavy activity (people unwinding, not repositioning)

Tracking settlement paths on-chain can help observe how market structure changes over time.

---

## The Cost Asymmetry That Makes Markets Work

In the end, Polymarket's three settlement paths create an implicit cost structure without needing explicit fees.

Because COMPLEMENTARY is cheaper and MINT/MERGE is more expensive, the protocol structurally favors:
- **Two-sided order flow** - orders that are already in opposite positions are rewarded with lower costs
- **Depth** - orders placed where they are likely to cross naturally are cheaper to settle
- **Round-tripping positions** - positions that flip back and forth (buy, then sell the same outcome) cost less in aggregate

These differences come from the architecture itself, not from extra charges. They reflect the computational and transfer work performed on each path.

Traders who understand this can structure orders more deliberately. Market makers who understand this can better judge where spreads will tighten or widen.

For researchers following Polymarket, these three paths provide a way to observe how the contract is being used in practice.

---

## Next Steps

To verify these patterns on-chain:

1. Query recent `OrderFilled` events from CTFExchange V2 (0xe111...b96b on Polygon)
2. For each match, first check whether the sides are the same, then use tokenId to distinguish COMPLEMENTARY from the other two types
3. Compare gas cost: you should see COMPLEMENTARY matches landing in the lower range than MINT/MERGE
4. Map gas cost to realized spread: markets with higher COMPLEMENTARY ratios should have tighter spreads

These data can be used to verify the relationship between settlement path and market structure.
