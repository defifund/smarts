---
created: 2026-04-21T19:08:57.360Z
title: Swap Month 3 roadmap — Aave V3 → Uniswap V4 hooks adapter
area: planning
files:
  - CLAUDE.md
  - app/services/protocol_adapters/
---

## Problem

CLAUDE.md Month 3 currently lists **Aave V3** as the next protocol adapter after Uniswap V3. Hypothesis surfaced 2026-04-21: the more strategic Month 3 is **Uniswap V4 hooks**, not Aave V3. Decision must be made before Month 3 execution begins or sunk cost starts compounding.

Market data (April 2026, pulled 2026-04-21):

| | Uniswap V3 | Uniswap V4 |
|---|---|---|
| TVL | $1.587B | $657M |
| Daily avg volume | $25.3M | $9.4M |
| Trade share | 60% | 30% |
| Cumulative volume since launch | — | $100B+ |

V3 still dominates in absolute terms (~2.4–2.7× V4), so "latest = most demand" doesn't hold for integration volume. The real argument for V4 is the **hooks long tail**:

- ~**100 new hooks deployed per day**
- **2,500+** custom liquidity pools using hooks (V4 has 4,689 pools total — ~53% hook-enabled)
- No systematic third-party documentation infrastructure exists for hooks yet
- Every hook is a distinct contract with distinct logic — exactly Smarts' long-tail + AI-queryable wheelhouse

Leading production hooks already ≥$1B cumulative volume each:
- **Bunni v2** — dynamic LP, ETH-USDC 1.1 pool on Base does $80M / 30d on $27k TVL
- **EulerSwap** — V4 hook + Euler lending vault combo
- **Angstrom (Sorella)** — batch-auction MEV protection
- **Arrakis** — ML-driven concentrated liquidity management

## Solution

**Reasoning for the swap (unless a counter-argument surfaces before Month 3):**

Technical:
1. V3 adapter work (tick math, concentrated liquidity, pool state reading) partially transfers to V4 (per-pool contract → singleton + PoolKey indexing). Aave is lending, zero business-layer reuse.
2. V4 hooks match `ProtocolAdapters::base_adapter`'s extension shape natively — each hook is a third-party contract, aligns with eventual "scan chain → auto-classify" roadmap.
3. Existing MCP tool `get_uniswap_v3_pool` ports cheaply to `get_uniswap_v4_pool`; a new `get_uniswap_v4_hook` completes the V4 coverage.

Strategic:
4. Timing window: V4 hooks ecosystem forming *now*. Entering Month 3 (≈3 months out) catches the wave; 6 months risks 2–3 competitors established. Aave V3 is 3+ years stable — no window urgency.
5. Audience concentration: V3 users → V4 hook devs are the same DEX-first Web3 engineer persona. Adding Aave splits MVP audience across AMM + lending.
6. Narrative velocity: V4 + hooks is weekly news; Aave V3 is stable infra, low traction for Build-in-Public content.

Costs being accepted:
- MVP ships without lending coverage — weakens "full DeFi docs platform" story.
- V4 spec still evolving; Aave V3 is frozen.
- Aave V3 has more off-the-shelf reader/subgraph references; V4 hooks is more greenfield engineering.

**Concrete action when Month 3 approaches:**

1. Edit CLAUDE.md — replace Month 3 "Aave V3" entries in the 90-day milestones table with "Uniswap V4 hooks adapter". Demote Aave V3 to Month 4+ or remove from MVP.
2. Update the supported-protocols table (Month 1–3 section) accordingly.
3. Scope the V4 adapter as: (a) PoolManager singleton reader, (b) hooks registry + per-hook classification, (c) adapter-per-popular-hook for Bunni/EulerSwap/Angstrom/Arrakis at minimum, (d) generic hook fallback for the long tail.
4. Add MCP tools: `get_uniswap_v4_pool`, `get_uniswap_v4_hook`.

**Decision gate**: reconfirm the swap at the start of Month 3 by re-checking V4 TVL / volume / hook-count growth rate. If V3 is somehow still growing faster than V4 by then, revisit.
