---
created: 2026-05-25T21:04:04.762Z
title: Token metadata enricher for Tier 2 chains
area: general
files:
  - app/helpers/contracts_helper.rb:241
  - app/models/chain.rb
  - app/services/chain_reader/view_caller.rb
  - app/services/protocol_adapters/generic_erc20_adapter.rb
  - db/seeds/chains.rb
---

## Problem

On docs_only (Tier 2) chains — currently Linea, soon Sonic / Berachain / Unichain / Blast / Gnosis / Mantle / etc. — ERC-20 contract pages render the Solidity class name in the H1 instead of the token symbol/brand name.

Concrete example from real-world UAT:
- URL: `/linea/0xa219439258ca9da29e9cc4ce5596924745e12b93` (Linea USDT)
- H1 shows: `CustomBridgedToken` (Solidity class name)
- Expected: `USDT` (token symbol)

**Why this happens**: `app/helpers/contracts_helper.rb:241` `contract_display_name` falls back through this chain: `protocol_adapter.display_name → live_value("symbol()") → live_value("name()") → contract.name`. On Tier 1 chains we call `symbol()` / `name()` via RPC to upgrade to the brand name. Tier 2 chains have no RPC (by design — see [[chain-tier-policy]] in CLAUDE.md), so `live_value(...)` is always nil and we fall through to `contract.name`, which is the raw Solidity class name from Etherscan.

**Etherscan V2 `tokeninfo` end­point is API Pro only** — confirmed tested 2026-05-25; Free tier returns "Sorry, it looks like you are trying to access an API Pro endpoint." So we can't lean on Etherscan for this metadata on Free tier.

## Solution

**Plan B (deferred from current PR `feat/chain-tier-field`)**: a `TokenMetadataEnricher` background job that, for any docs_only ERC-20 contract, hits a **public RPC once** to fetch `symbol()`, `name()`, `decimals()`, and persists them to the Contract row. Subsequent renders use the persisted values — no live RPC dependency at request time.

**Rationale**: token metadata is immutable (or near-immutable — even on a `symbol()` rebrand it's a once-in-a-protocol-lifetime event). A one-shot enrichment per contract is acceptable on Tier 2 because it's not live state — it's metadata that gets cached forever. This doesn't violate the "Tier 2 zero-RPC at request time" architectural intent.

### Implementation sketch

1. **Schema**: add `contract.token_symbol`, `contract.token_name`, `contract.token_decimals` (or single `token_metadata` jsonb).
2. **Public RPCs per chain**: add `metadata_rpc_url` column to `chains` (or repurpose `rpc_url` and remove the `nil` constraint for docs_only). Populate in `db/seeds/chains.rb`:
   - Linea: `https://rpc.linea.build`
   - Sonic: `https://rpc.soniclabs.com`
   - Berachain: `https://rpc.berachain.com`
   - Unichain: `https://mainnet.unichain.org`
   - Blast: `https://rpc.blast.io`
   - Gnosis: `https://rpc.gnosischain.com`
3. **Job**: `TokenMetadataEnricherJob.perform_later(contract.id)` enqueued on first `find_or_fetch_contract` success for docs_only ERC-20s. Use existing `ChainReader::Multicall3Client` if Multicall3 is deployed on the chain (most have it at the canonical `0xcA11...CA11`).
4. **Helper update**: `contract_display_name` reads `@contract.token_symbol.presence` before falling through to `@contract.name`.
5. **Tier guard**: keep `check_full_tier` enforcement on _live_ tools (`read_contract_state`, `get_erc20_info`, etc.) — they still need real-time data. The enricher is the only exception, and it runs async, not on the request path.

### Timing

Do this **after** finishing the Tier 2 chain rollout (Sonic / Berachain / Unichain / Blast / Gnosis / Mantle and any others). Reasons:
- Test the enricher across 6+ chains in one go.
- Confirm Multicall3 deployment on each (avoid per-chain special cases).
- Don't block the current Tier 2 rollout PR on a feature that's nice-to-have rather than blocking.

Acceptable interim UX: H1 shows Solidity class name; users see Linea USDT as `CustomBridgedToken`. Ugly but honest.

### Related

- [[brand-overlay-mechanism-for-curated-display-name]] — different problem (manual brand overrides for Tier 1 rebrands like MATIC→POL), but lives in the same `contract_display_name` resolver. Both touch `app/helpers/contracts_helper.rb:241`; coordinate when changing the resolution order.
