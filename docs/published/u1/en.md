---
date: 2026-05-26
source: https://smarts.md/ MCP (get_contract_info / get_admin_risk / get_erc20_info / read_contract_state / get_contract_source / get_governance_timeline)
contract: 0x8d0d000ee44948fc98c9b98a4fa4921476f08b0d (StablecoinV2)
verified_block: 25182415
tags: [stablecoin, usd1, smart-contract, risk, smarts]
status: draft
---

# USD1's Control Stack: Minting, Freezing, and Signed Transfers

Contract: `0x8d0d000ee44948fc98c9b98a4fa4921476f08b0d` (`StablecoinV2`)

Proxy implementation: `0x694aa534bdef8ed63244eb902e7914e527891f08`

Surface area: `19 view / 23 write / 17 events`

Current snapshot:

As of block `25182415`:

- `name = World Liberty Financial USD`
- `symbol = USD1`
- `decimals = 18`
- live supply = `1,922,063,260.45 USD1`
- live price = about `$0.9985087024`
- market cap = about `$1.919B`
- `paused = false`
- governance timeline = `1` event total, only `Initialized(version 2)` at block `24809916`

USD1 looks like a simple dollar token from the outside. The contract shows a wider control stack underneath.

It is an upgradeable stablecoin implementation with owner-only minting, global pause control, address freezing, frozen-funds recovery paths, and signature-based transfer flows. That is enough to make it a control system, not just a balance ledger.

The important question is not whether USD1 can transfer. It can.
The question is which paths exist beside plain `transfer`, who can trigger them, and what kind of state changes leave a trace.

---

## Bottom Line First

USD1 differs from a plain ERC-20 in three ways.

1. It has an explicit admin surface: `mint`, `burn`, `freeze`, `unfreeze`, `pause`, `unpause`, `drain`, `reallocate`, and `recoverERC20`.
2. It has two signature-based authorization layers beyond `approve` / `transferFrom`: EIP-2612 `permit` and EIP-3009 style signed transfers.
3. The current governance history is almost empty. That matters because the contract has a lot of power exposed, but the sampled window shows only initialization, not active role churn.

One small but important detail: `renounceOwnership()` is intentionally unsupported. The owner role is meant to stay live.

That tells you this is not designed as a hands-off token. It is designed as an operable stablecoin system.

---

## Current Snapshot

The live read is straightforward:

| Field | Current value |
|---|---|
| Name | `World Liberty Financial USD` |
| Symbol | `USD1` |
| Decimals | `18` |
| Supply | `1,922,063,260.45 USD1` |
| Price | `$0.9985087024` |
| Market cap | `$1,919,196,892.24` |
| Owner | `0xee9b1a09aedaced9dcda74964ea447feb93861c2` |
| Paused | `false` |
| Recent governance | only `Initialized(version 2)` |

The owner address is itself a contract address, not a plain EOA. I am not inferring what that contract is from the data I have here; I am only noting that the control plane is already one step removed from a normal wallet.

That fits the rest of the design. USD1 is not trying to look like a minimal retail token.

---

## The Control Stack

The source code is the clearest signal.

### 1. Owner-only monetary control

`mint(uint256 amount)` and `burn(uint256 amount)` are both `onlyOwner`.

That means supply operations are not distributed to minters or delegated roles in the way many other stablecoins are. The top-level owner has direct power over issuance and destruction.

### 2. Global pause

`pause()` and `unpause()` exist, and the transfer / approval paths are guarded by `whenNotPaused`.

So the contract can be halted as a whole. This is not an isolated blacklist-only design.

### 3. Address freezing

`freeze(address account)` and `unfreeze(address account)` manage the public `frozen[address]` mapping.

The transfer and approval hooks block frozen participants. The freeze check applies not just to the source or destination, but also to the caller path the contract cares about.

That means the freeze state is not decorative. It changes how the token behaves.

### 4. Frozen-funds recovery

The V2 implementation adds three more admin paths:

- `drain(address account)`
- `reallocate(address from, address to, uint256 amount)`
- `recoverERC20(address token, address recipient, uint256 amount)`

These are the functions that make USD1 feel like an operating system for funds, not just a transfer primitive.

`drain` can move the full balance of a frozen account into owner custody.

`reallocate` can move value out of a frozen source into a replacement account.

`recoverERC20` can rescue other tokens held by the contract.

That is a much broader control surface than a plain ERC-20.

### 5. Ownership is intentionally sticky

`renounceOwnership()` reverts.

This is a deliberate design choice. Some contracts let the owner disappear. This one does not. If you are reading the risk model, that is a signal worth keeping in view.

---

## The Authorization Path

The most important non-standard feature is the signature layer.

USD1 supports:

- `permit`
- `transferWithAuthorization`
- `receiveWithAuthorization`
- `cancelAuthorization`
- `batchCancelAuthorization`
- `authorizationState(authorizer, nonce)`

This is a separate set of flows from the normal ERC-20 `approve` / `transferFrom` pattern.

The practical effect is that USD1 can support both signed allowance setup and signed payment instructions. The holder signs intent off-chain, and someone else can submit the transaction later. That is useful for relayers, merchant flows, and wallet UX that does not want to force every user to submit a gas-paying transaction directly.

The contract also tracks used authorizations by `bytes32 nonce`, which makes replay control explicit.

That is the real difference here:

1. `approve` sets an allowance.
2. `permit` is EIP-2612's signature-based `approve`; it saves one on-chain transaction, but still needs `transferFrom` later.
3. `transferWithAuthorization` authorizes one transfer without using allowance.
4. `cancelAuthorization` and `batchCancelAuthorization` can kill unused EIP-3009 authorizations before they are consumed.

So USD1 is not just a token. It is a payment system with a richer instruction layer.

---

## What The Sample Says

The sampled governance timeline is quiet.

There is only one recorded event: `Initialized(version 2)` at block `24809916`.

That does not mean the contract has no power.
It means the power has not been actively reshuffled in the sampled window.

This is a useful distinction. Many people look at a live stablecoin and ask whether it has admin controls. The better question is whether those controls are being exercised, and if so, how often and in what pattern.

In this sample:

1. The control surface is broad.
2. The recent governance trail is minimal.
3. The token is live, priced close to one dollar, and already at multi-billion supply.

So the contract is operational, but not recently noisy.

---

## What To Watch

If you want to monitor USD1 properly, watch these things first:

- `paused()` changes
- `Freeze` and `Unfreeze` events
- `FrozenAccountDrained` and `FrozenFundsReallocated`
- `AuthorizationUsed` and `AuthorizationCanceled`
- owner address changes
- implementation changes if the proxy is upgraded

The key point is that a stablecoin like this does not need a giant event stream to matter. A single pause, freeze, drain, or ownership shift is already a high-signal event.

If you only track supply and price, you miss the system behavior.
If you track the admin surface, you see what kind of money system this really is.

---

## Final Read

USD1 is a controllable stablecoin implementation, not just a balance ledger.

It is a controllable stablecoin implementation with:

- direct owner-side monetary powers
- global pause and address freeze controls
- frozen-funds recovery paths
- EIP-2612 `permit` and EIP-3009 signed authorization flows
- an intentionally non-renounceable ownership model

That combination is the real story.

The ticker says "dollar token."
The contract says "operated system."
