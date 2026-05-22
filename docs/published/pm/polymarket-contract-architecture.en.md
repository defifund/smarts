# Polymarket Contract Architecture

> Scope: 13 production contracts on Polygon mainnet. Every claim is grounded in verified source + on-chain view function reads (block ~87,146,000).
> Last updated: 2026-05-19

---

## One-Sentence Positioning

Polymarket is an **"off-chain order book + on-chain settlement"** event prediction market protocol — on top of Gnosis ConditionalTokens (an immutable ERC-1155 ledger), it builds three independently evolvable layers: order matching, capital-efficiency wrapping, and oracle integration. The user layer uses Polymarket's own stablecoin **pUSD** as the unit of account, abstracting away the underlying USDC.e / native USDC migration.

---

## Complete Contract Inventory

| Role | Contract Name | Address |
|---|---|---|
| **User-layer stablecoin** | pUSD (CollateralToken) | `0xc011a7e1…2dfb` |
| Binary order book v1 | CTFExchange | `0x4bfb41…982e` |
| Binary order book v2 ★ | CTFExchange | `0xe11118…996b` |
| Multi-outcome order book v1 | NegRiskCtfExchange | `0xc5d563…f80a` |
| Multi-outcome order book v2 ★ | CTFExchange (neg-risk parameterized) | `0xe2222d…0f59` |
| Binary path wrapper | CtfCollateralAdapter | `0xada100…9718` |
| Multi-outcome path wrapper | NegRiskCtfCollateralAdapter | `0xada200…c6f1` |
| Multi-outcome Adapter | NegRiskAdapter | `0xd91e80…5296` |
| Multi-outcome Operator | NegRiskOperator | `0x71523d0f…b820` |
| **Position ledger (trust anchor)** | ConditionalTokens (Gnosis CTF) | `0x4d97dc…6045` |
| Oracle v1 | UmaCtfAdapter (binary) | `0x71392e…03f7` |
| Oracle v2 ★ | UmaCtfAdapter (binary) | `0x6a9d22…4f74` |
| Oracle v3 ★ | UmaCtfAdapter (neg-risk) | `0x2f5e36…0aa9d` |

★ = current main path; older versions still serve historical markets — not deprecated, just naturally winding down.

External dependencies:
- **UMA Optimistic Oracle V2** `0xee3afe…c24` (outcome adjudication)
- **USDC.e** `0x2791bc…4174` (CTF collateral for the binary path)
- **native USDC** `0x3c499c…3359` (the other backing for pUSD)

---

## Layered Architecture Diagram

### v2 path (current main traffic)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ USER LAYER                                                                  │
│   User wallet holds pUSD                                                    │
│   pUSD ⟷ {native USDC, USDC.e} via reserve VAULT (mint/redeem = MINTER_ROLE)│
└─────────────────────────────┬───────────────────────────────────────────────┘
                              │ EIP-712 signed orders
                              │ Polymarket operator submits txs
   ┌──────────────────────────┴──────────────────────────────┐
   ▼                                                         ▼
┌─────────────────────────┐                   ┌──────────────────────────────┐
│ CTFExchange (binary v2) │                   │ CTFExchange (neg-risk v2)     │
│ collateral      = pUSD  │                   │ collateral      = pUSD        │
│ ctf             = real  │                   │ ctf             = real CTF    │
│ ctfCollateral   = USDC.e│                   │ ctfCollateral   = WCOL        │
│ outcomeTokenFactory:    │                   │ outcomeTokenFactory:          │
│   CtfCollateralAdapter  │                   │   NegRiskCtfCollateralAdapter │
│   0xada100…             │                   │   0xada200…                   │
└────────────┬────────────┘                   └─────────────┬────────────────┘
             │ via CtfCollateralAdapter                     │ via NegRiskCtfCollateralAdapter
             │ pUSD ⟷ USDC.e                                │ pUSD ⟷ USDC.e ⟷ WCOL
             ▼                                              ▼
                              ┌──────────────────────────────┐
                              │ NegRiskAdapter                │
                              │ ─ owns WCOL (1:1 wraps USDC.e)│
                              │ ─ CTF oracle for neg-risk Qs  │
                              │ ─ convertPositions efficiency │
                              │ ─ has its own admin set       │
                              └──────────────┬────────────────┘
                                             │
   ┌─────────────────────────────────────────┴──────────────────────────────┐
   ▼                                                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ ConditionalTokens (Gnosis CTF, 0x4d97dc…6045) — immutable trust anchor      │
│ ERC-1155 outcome shares                                                     │
│ • binary path  : positions keyed by (USDC.e, conditionId)                   │
│ • neg-risk path: positions keyed by (WCOL,   conditionId)                   │
└─────────────────────────────▲───────────────────────────────────────────────┘
                              │ reportPayouts(qid, payouts[])
   ┌──────────────────────────┴─────────────────────────────────────────────┐
   │ ORACLE LAYER                                                            │
   │                                                                         │
   │  binary    ─▶ UmaCtfAdapter v1/v2 ─▶ CTF.reportPayouts (direct)         │
   │                                                                         │
   │  neg-risk  ─▶ UmaCtfAdapter v3                                          │
   │              ─▶ NegRiskOperator (translates CTF iface to NegRisk iface) │
   │              ─▶ NegRiskAdapter.reportOutcome                            │
   │              ─▶ CTF.reportPayouts                                       │
   │                                                                         │
   │  all       ─▶ UMA Optimistic Oracle V2                                  │
   └─────────────────────────────────────────────────────────────────────────┘
```

### v1 path (still serving historical markets)

The v1 path has **no pUSD, no CtfCollateralAdapter** — the structure is more primitive:

```
binary v1   :  User(USDC.e) ─▶ CTFExchange v1 ─▶ CTF (collateral=USDC.e)
                              getCtf = real CTF, single collateral, direct

neg-risk v1 :  User(USDC.e) ─▶ NegRiskCtfExchange v1 ─▶ NegRiskAdapter ─▶ CTF
                                getCtf = NegRiskAdapter
                                (matching path must hop through NegRiskAdapter)
```

v1 vs v2 item-by-item differences in §2.3.

---

## Per-Layer Detailed Design

### 1. User layer: the pUSD unified stablecoin

**Why it exists**: USDC on Polygon is going through a USDC.e (bridged) → native USDC migration; Polymarket introduced pUSD to hide this distinction from the user's perspective.

**Mechanism** (`CollateralToken.sol`, inherits Solady `OwnableRoles`):

```solidity
address public immutable USDC;    // native USDC (0x3c499c…)
address public immutable USDCE;   // bridged USDC.e (0x2791bc…)
address public immutable VAULT;   // reserve vault address (not a mint/redeem authority)

uint256 internal constant MINTER_ROLE  = _ROLE_0;  // mint / burn
uint256 internal constant WRAPPER_ROLE = _ROLE_1;  // wrap / unwrap
```

- pUSD is a plain ERC-20, 6 decimals, symbol `pUSD`
- Mint/redeem permission is **two independent roles**: `MINTER_ROLE` controls `mint`/`burn`, `WRAPPER_ROLE` controls `wrap`/`unwrap`; owner assigns via `addMinter / removeMinter / addWrapper / removeWrapper`
- `VAULT` is a **reserve address constant** holding the underlying USDC / USDC.e — not a single-point mint/redeem authority
- Current circulation is ~`375.9M pUSD` (`totalSupply()` = `375853763516069`, as of block 87,232,311, changes in real time with mint/redeem)
- Vanity address prefix `0xc011…` = "coll" (collateral)

**User perspective**: whether trading binary v2 or neg-risk v2 markets, the user wallet holds only pUSD. USDC.e is invisible. WCOL is invisible. The v1 path still has users holding USDC.e directly.

### 2. Matching layer: 4 Exchange instances

**v2 key observation**: binary v2 and neg-risk v2 use **the same compiled artifact (both contracts are named `CTFExchange`)** with only constructor params differing. The two v2 instance ABIs are identical (27 view / 17 write / 16 event).

**v1 looks different**: binary v1 is named `CTFExchange`, neg-risk v1 is named `NegRiskCtfExchange` — a legacy of Polymarket's early "one contract per market type" approach. v1 still uses compiler `v0.8.15`; v2 has moved to `v0.8.34`, with a different ABI (v1 neg-risk: 31 view / 19 write / 13 event).

#### 2.1 Internally composed of 9 mixins

The main contract `CTFExchange.sol` is only 4.7 KB and contains almost no business logic:

```
CTFExchange.sol
├── Auth.sol              ── isAdmin / isOperator dual-role ACL
├── Fees.sol              ── maxFeeRateBps cap + validateFee
├── Assets.sol            ── 4 immutable asset addresses (below)
├── Trading.sol  (29 KB)  ── core: matching, order state machine, fillOrders/matchOrders
├── Pausable.sol          ── global kill switch
├── UserPausable.sol      ── single-user freeze
├── Signatures.sol        ── EIP-712 + EIP-1271 + pre-approval triple sig verify
├── Hashing.sol           ── order hash
├── AssetOperations.sol   ── wraps CTF split / merge / safeTransfer
├── PolyFactoryHelper.sol ── computes user proxy wallet address (no deploy, just compute)
└── ERC1155TokenReceiver  ── required: can receive CTF shares as a hop
```

70% of the logic lives in `Trading.sol` (29 KB) — to understand matching you only need to read one file.

#### 2.2 Four immutable fields in Assets.sol

```solidity
address internal immutable collateral;          // token users deposit/withdraw
address internal immutable ctf;                 // ConditionalTokens
address internal immutable ctfCollateral;       // token CTF uses to derive positionId
address internal immutable outcomeTokenFactory; // bridge between collateral and ctfCollateral
```

Concrete values:

| Field | binary v2 | neg-risk v2 |
|---|---|---|
| collateral | pUSD | pUSD |
| ctf | real CTF | real CTF |
| ctfCollateral | USDC.e | WCOL |
| outcomeTokenFactory | `0xada100…9718` | `0xada200…c6f1` |

**Important**: only on **neg-risk v2**, `getCtf()` returns the real CTF (`0x4d97dc…6045`) — NegRiskAdapter steps back to the split/merge/convert/redeem and oracle paths, not the matching hot path.

**neg-risk v1 differs**: `getCtf()` returns NegRiskAdapter (`0xd91e80…5296`). Share transfers after matching must go through NegRiskAdapter before reaching CTF.

#### 2.3 v1 vs v2 is a structural upgrade, not a parameter migration

| | binary v1 | binary v2 | neg-risk v1 | neg-risk v2 |
|---|---|---|---|---|
| Contract name | CTFExchange | CTFExchange | NegRiskCtfExchange | CTFExchange |
| Compiler | v0.8.15 | v0.8.34 | v0.8.15 | v0.8.34 |
| `getCollateral()` | USDC.e | pUSD | USDC.e | pUSD |
| `getCtf()` | real CTF | real CTF | **NegRiskAdapter** | real CTF |
| `getCtfCollateral()` | ❌ (no such fn) | USDC.e | ❌ (no such fn) | WCOL |
| `outcomeTokenFactory` | ❌ | CtfCollateralAdapter | ❌ | NegRiskCtfCollateralAdapter |

Three things changed v1 → v2:
1. Introduced pUSD to abstract the "user-layer token" away from the underlying collateral
2. Introduced `outcomeTokenFactory` (CtfCollateralAdapter) to translate pUSD ⟷ underlying collateral
3. The neg-risk matching path no longer goes through NegRiskAdapter, it connects directly to CTF; NegRiskAdapter only appears on non-matching paths

### 3. Wrapping layer: CtfCollateralAdapter × 2

```solidity
IConditionalTokens public immutable CONDITIONAL_TOKENS;
address public immutable COLLATERAL_TOKEN;  // pUSD
address public immutable USDCE;             // underlying USDC.e
```

Responsible for atomic split/merge between pUSD and CTF's actual collateral (USDC.e or WCOL): user pays pUSD → adapter routes to CTF's splitPosition → user receives outcome shares.

The two paths have separate instances (`0xada100…` vs `0xada200…`) — structurally symmetric, differing only in which ctfCollateral they point at.

### 4. Multi-outcome support: NegRiskAdapter + WCOL

> NegRiskAdapter is not "a wrapper around the matching layer" — it is **a capital-efficiency layer + oracle specifically serving neg-risk multi-outcome markets**. Source at `src/NegRiskAdapter.sol` (18.7 KB).

#### 4.1 WCOL (WrappedCollateral)

`src/WrappedCollateral.sol` is an ERC-20 wrapper deployed and owned by NegRiskAdapter. **Permissions are single-owner, not role-based**:

| Function | Access control | Who can call |
|---|---|---|
| `unwrap(to, amount)` | `external`, no modifier | **anyone** — burn your WCOL to get USDC.e back |
| `wrap(to, amount)` | `onlyOwner` | NegRiskAdapter only |
| `mint(amount)` | `onlyOwner` | NegRiskAdapter only (mints WCOL from thin air) |
| `burn(amount)` | `onlyOwner` | NegRiskAdapter only |
| `release(to, amount)` | `onlyOwner` | NegRiskAdapter only (release underlying USDC.e without burning WCOL) |

In other words: a regular user who redeems WCOL from CTF can `unwrap` it themselves to get USDC.e back; but wrapping USDC.e into WCOL must go through NegRiskAdapter's splitPosition / convertPositions entry points. The asymmetry of owner-only `mint` / `release` is the physical basis of `convertPositions` capital efficiency.

#### 4.2 MarketData's bytes32 packing

`src/types/MarketData.sol` packs the entire market state into a single storage slot:

```
md[0]      = questionCount  (1 byte)
md[1]      = determined flag (1 byte)
md[2]      = result index    (1 byte)
md[3..4]   = feeBips          (2 bytes)
md[12..32] = oracle address   (20 bytes)
```

#### 4.3 NegRiskIdLib's ID encoding

```
marketId   = keccak256(oracle, feeBips, metadata) & 0xFFFF...FF00
questionId = marketId | questionIndex   // last 1 byte is the 0..255 index
```

Recovering marketId from questionId is a zero-cost `& MASK`. A market has at most 256 candidate answers.

#### 4.4 The "Negative Risk" invariant

Enforced at **oracle report time**, not match time (`MarketStateManager._reportOutcome`):

```solidity
if (_outcome == true) {
    if (data.determined()) revert MarketAlreadyDetermined();
    marketData[marketId] = data.determine(questionIndex);
}
```

Among N questions, **the second attempt to report YES reverts** — this is the core constraint of the entire NegRisk model. NO can be reported repeatedly; YES can land only once.

#### 4.5 convertPositions: the heart of capital efficiency

User picks K questions, hands over their NO tokens, gets back:
- `(K-1) × _amount` of collateral (only when K≥2)
- YES tokens for the remaining `(N-K)` questions

Mathematical conservation: among N questions exactly 1 YES can win, so "extracting" the corresponding collateral from K mutually exclusive NOs is arbitrage-free. The cost is forgoing the extra payoff in the extremely unlikely world where "all K turn out NO".

The physical process: the adapter temporarily `mint((N-K) × _amount)` WCOL, does splitPosition on each yes-side question; YES tokens to the user, NO tokens burned to `NO_TOKEN_BURN_ADDRESS`; the user's original K NOs are also burned. All N NOs are permanently stuck at the burn address; the corresponding USDC.e stays inside CTF forever.

#### 4.6 CTF interface duality

NegRiskAdapter implements several functions with the same name and signature as CTF:

```
splitPosition / mergePositions / redeemPositions
balanceOf / balanceOfBatch / safeTransferFrom
```

Code originally integrated with CTF can **just swap the "CTF address" for the NegRiskAdapter address** and work — an elegant protocol interface duality.

### 5. Ledger layer: Gnosis ConditionalTokens

The **trust anchor** of the whole system — Gnosis's open-source general prediction-market primitive from years ago. Polymarket reuses it directly, no fork, no upgrades, ever.

Four verbs:
- `prepareCondition(oracle, questionId, outcomeSlotCount)`
- `splitPosition(collateral, parentCollectionId, conditionId, partition, amount)`
- `mergePositions(...)` / `redeemPositions(...)`
- `reportPayouts(questionId, payouts[])` (only the condition's oracle can call)

Four key properties:
1. ERC-1155 not ERC-20 — outcomes within the same condition share metadata
2. Position = Cartesian product of collateral × condition — supports nested composite events (Polymarket currently only uses single layer)
3. Oracle is bound at condition registration — cannot be changed later
4. Payout is a numerator vector — can express "100% YES" or "60/40"

**Polymarket did not change the ledger on top of CTF**; all innovation is in higher layers. A very disciplined engineering decision.

### 6. Oracle layer: UmaCtfAdapter × 3

> v3 source: `src/UmaCtfAdapter.sol` (21.6 KB). v1/v2 are iterative versions of the same-named contract, with slightly fewer events/functions.

#### 6.1 Version split

| Version | Market type served | `ctf` field points to |
|---|---|---|
| v1 | binary | real CTF |
| v2 | binary | real CTF |
| v3 | **neg-risk** | NegRiskOperator |

v1 → v2 is a true iteration (same type); v3 is a **new fork built for the neg-risk path** — interface translation is achieved by pointing `_ctf` constructor param at NegRiskOperator.

#### 6.2 Question lifecycle (5 states + emergency channel)

```
uninitialized
    │ initialize(...) ← fully permissionless
    ▼
initialized + OO has hung a proposal
    │ proposal goes uncontested within liveness window
    ▼ resolve() → settleAndGetPrice → _constructPayouts → ctf.reportPayouts
resolved

disputed once → priceDisputed callback → _reset() → re-hang OO
disputed twice → OO escalates to UMA DVM full-network vote
returns ignore price (type(int256).min) → _reset()
admin flag() → wait 2 days → emergencyResolve(any payouts)
```

#### 6.3 Key design

**(a) `initialize` is fully permissionless**
Anyone can create a new market, choosing reward token (must be on UMA's whitelist), reward amount, bond, liveness. The Polymarket UI is just one of many possible initiators; on-chain there's no restriction on who can init.

**(b) Initializer is pinned into ancillaryData**
`questionID = keccak256(ancillaryData_with_initializer)` — the same question text initiated by different parties yields different questionIds. UMA voters can see who initiated it.

**(c) Three OO prices + one ignore sentinel**
- `0` → `[YES=0, NO=1]` (NO wins)
- `0.5 ether` → `[1, 1]` (UNKNOWN / 50-50, not supported under neg-risk)
- `1 ether` → `[1, 0]` (YES wins)
- `type(int256).min` → triggers `_reset` to re-emit the request

**(d) Disputes allow only one automatic reset**
A question produces at most 2 OO requests; the second dispute can only go to a UMA DVM full-network vote.

**(e) Admin emergency channel**
6 onlyAdmin functions (flag / unflag / pause / unpause / reset / emergencyResolve). The core is `flag` → wait the full 2 days `EMERGENCY_SAFETY_PERIOD` → `emergencyResolve(any payouts)`.

**(f) BulletinBoard on-chain announcements**
`postUpdate(questionID, update)` lets anyone append bytes to a public mapping. Convention: trust only updates posted by the question creator.

### 7. Oracle translation for the multi-outcome path: NegRiskOperator

UmaCtfAdapter calls CTF's `prepareCondition / reportPayouts`; NegRiskAdapter exposes `prepareQuestion / reportOutcome`. **NegRiskOperator is the interface translation layer in between**:

```
UmaCtfAdapter v3
    │ prepareCondition(this, qid, 2)
    │ reportPayouts(qid, payouts)
    ▼
NegRiskOperator (0x71523d0f…b820)
    │ prepareQuestion(marketId, meta)
    │ reportOutcome(qid, outcome)
    ▼
NegRiskAdapter
    │
    ▼
CTF
```

### 8. Proxy-wallet bypass (cuts across the user and matching layers)

A regular EVM wallet must sign and submit a tx for every order — completely unusable for high-frequency trading. Polymarket's solution:

```
User EOA ─signs─▶ Polymarket Operator ─submits tx─▶ chain
                  (bundles for you, pays gas)
   │
   └── Funds/positions don't sit in the EOA — they sit in a smart contract wallet:
       - PolyProxy: in-house light proxy (the vast majority)
       - PolySafe : based on Gnosis Safe (HNW / institutional)
```

Contract-layer support:
1. **CREATE2 deterministic deployment** (`Create2Lib.sol` + `PolyProxyLib.sol`) — the address is known before first deposit
2. **EIP-1271 signature verification** (`Signatures.sol`) — the operator calls the Exchange using the proxy wallet's address; the Exchange asks the proxy wallet back, "is this signature signed by your owner?"

Consequence: **under the official trading flow (via the Polymarket UI), the user's pUSD and outcome shares all sit in the proxy wallet**, with the EOA used primarily for signing rather than for holding. Technically the EOA can perfectly well receive pUSD (ERC-20) or outcome shares (ERC-1155) — it's just an unofficial flow, and the UI won't auto-recognize such holdings. When Smarts looks up positions, it must **query both addresses**: first use `getProxyWalletAddress(eoa)` to obtain the proxy address and query the proxy wallet, then query the EOA directly as a fallback.

---

## Key Invariants and Design Trade-offs

### Invariants (facts that always hold)

1. **The CTF contract itself is non-upgradeable** — deployed by Gnosis, nobody can change it
2. **A CTF condition's oracle is bound for life** — cannot be swapped after registration
3. **NegRisk invariant**: at most 1 question per market can report YES
4. **EMERGENCY_SAFETY_PERIOD = 2 days** — any admin emergency action must wait the full 2 days
5. **UMA OO: at most 2 automatic requests per question** — a second dispute must go to DVM

### Key trade-offs

| Dimension | Choice | Trade-off |
|---|---|---|
| Price discovery | off-chain order book | centralized matching ↔ CEX-like UX |
| Asset custody | smart-contract proxy wallets | extra contract risk ↔ user doesn't sign each tx |
| Multi-outcome markets | NegRiskAdapter + WCOL | extra abstraction ↔ capital efficiency ×N |
| Oracle | UMA Optimistic Oracle | delegated to an independent community ↔ arbitration outcome can be contested |
| User-layer stablecoin | own pUSD | extra contract ↔ shields users from USDC migration complexity |
| Version evolution | don't retire, decay naturally | larger protocol surface ↔ historical markets aren't broken |

---

## Trust Topology

| Role | Who holds it | What they can do | Source of limit |
|---|---|---|---|
| **Admin** (Exchange) | Polymarket multisig | change fee rate cap, pause, register new tokens, manage operator set | no on-chain limit (social layer) |
| **Operator** (Exchange) | Polymarket backend address | submit matchOrders for already-signed orders | Admin can revoke |
| **Admin** (UmaAdapter) | Polymarket multisig | flag / emergencyResolve (2-day safety period) | 2 days hard-coded |
| **Oracle** (CTF condition) | UmaCtfAdapter / NegRiskAdapter | write payouts for that condition | bound for life at creation |
| **UMA proposer/disputer** | anyone staking UMA | propose outcomes, raise disputes | UMA protocol's own economic incentives |
| **MINTER_ROLE** (pUSD) | addresses holding ROLE_0 (Polymarket controlled) | `mint` / `burn` pUSD | pUSD owner can grant/revoke role |
| **WRAPPER_ROLE** (pUSD) | addresses holding ROLE_1 (Polymarket controlled) | `wrap` / `unwrap` pUSD ⟷ underlying USDC | pUSD owner can grant/revoke role |
| **VAULT** (pUSD reserves) | a fixed address constant | holds USDC / USDC.e reserves backing pUSD | reserve location only, no mint/redeem authority |
| **Admin** (NegRiskAdapter) | at construction = deployer; `addAdmin / removeAdmin / renounceAdmin` | call `safeTransferFrom` to move user CTF positions (user must setApprovalForAll first) | `onlyAdmin` modifier; the NegRisk **outcome rule itself** (≤1 YES per market) is hard-coded in `_reportOutcome` and immutable |
| **NegRiskAdapter Oracle role** | the contract itself (hard-coded) | act as oracle reporting neg-risk question outcomes | `getConditionId` hard-codes `address(this)` |
| **User** | EOA holder | sign authorizations for the proxy wallet to do anything | proxy wallet contract's logic |

**Key observation**: Polymarket is neither "fully decentralized" nor "fully centralized". It makes different trust trade-offs at each layer — matching centralized, custody decentralized, ledger fully decentralized, oracle delegated to an independent community, user layer and governance parameters controlled by a multisig.

---

## One-Sentence Summary

**One immutable ledger at the bottom (Gnosis CTF) + one self-issued stablecoin at the user layer (pUSD, v2 path only) + two symmetric v2 matching channels (binary via USDC.e, neg-risk via WCOL) + two v1 channels still running (holding USDC.e directly) + one permissionless oracle integration layer (UMA OO V2) + one admin emergency channel with a 2-day hard safety window.**

The real "immutability" of the entire design is anchored in only 3 places:
1. **The CTF contract itself** (Gnosis-deployed, nobody can upgrade)
2. **UmaCtfAdapter's `EMERGENCY_SAFETY_PERIOD = 172800` seconds** (= 2 days, any admin emergency action must wait the full 2 days)
3. **NegRiskAdapter's NegRisk outcome rule hard-coded in `_reportOutcome`** (≤1 YES per market — the contract itself may have admins, but this rule cannot be changed)

All other layers are **bypassable by new versions** — but the old versions are never retired; old markets run on old contracts until they settle naturally.

---

## Appendix A: Concrete implications for Smarts adapter implementation

1. **All CTF queries on the NegRisk side must use the WCOL address for positionId** — don't use USDC.e. Either read `wcol()` from NegRiskAdapter to get the address, or hard-code it.
2. **`questions(questionID)` on UmaCtfAdapter returns the full question state** — including ancillaryData (with initializer suffix), reward token, whether it's been flagged, etc. This is the most authoritative on-chain source for "is this market real or a scam".
3. **Querying user positions requires checking two addresses**: first `getProxyWalletAddress(eoa)` to get the proxy wallet address and query it, then query the EOA directly as a fallback (for unofficial-flow holdings).
4. **MarketData's bytes32 packing should be unpacked in the UI** — each of the 5 fields (questionCount / determined / result / feeBips / oracle) carries meaning.
5. **convertPositions is a Polymarket-unique on-chain primitive**, worth a dedicated documentation page — it doesn't exist in traditional CTF docs.
6. **v1 and v2 are structurally different ABIs** — see the §2.3 table. Querying collateral info must branch on version: v1 has no `getCtfCollateral`; neg-risk v1's `getCtf` returns NegRiskAdapter.

---

## Appendix B: Verification status

| Source | Verification method |
|---|---|
| All contract addresses, names, ABI shapes | live `get_contract_info`, block ~87,146,000 |
| All view function return values | live `read_contract_state` |
| All source references (Auth.sol, Fees.sol, CollateralToken.sol, UmaCtfAdapter.sol, etc.) | verified source on Polygon |
| pUSD totalSupply | live `totalSupply()` = `375853763516069` (raw, 6 decimals, block 87,232,311) |
| pUSD price | **unverified** — $1.0017 comes from CoinGecko, not a view function |
| convertPositions math description | NegRiskAdapter.sol source + derivation, **no on-chain stress test** |
| UMA OO V2 address | UmaCtfAdapter v3 `optimisticOracle()` |
| EMERGENCY_SAFETY_PERIOD | UmaCtfAdapter v3 source constant `2 days = 172800 seconds` |

### Change history

- **2026-05-19 v2**: revisions per reviewer feedback — v1 vs v2 routing differences, pUSD role model, WCOL permission asymmetry, NegRiskAdapter actually has admins, EOA holdings no longer absolute, contract verified name corrections, totalSupply number correction.
- **2026-05-19 v1**: first draft.

---

Every piece of on-chain data in this article was pulled live with [Smarts](https://smarts.md/) — it turns any verified EVM contract into queryable live docs.
