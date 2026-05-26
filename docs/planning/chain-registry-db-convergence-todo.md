# Chain Registry DB Convergence TODO

Current state: `Chain` rows seeded from `db/seeds/chains.rb` now drive chain-facing pages, markdown exports, and sitemap entries. Curated chain contracts are seeded into `contracts` catalog fields from `db/seeds/chain_contracts.rb`. `Chains::Catalog` remains only as a compatibility adapter for view-facing chain objects.

## TODO

1. Done: make `Chain` the source for chain registry data.
   - `/chains`, `/testnets`, chain detail pages, markdown exports, and sitemap chain entries now load through `Chain.for_display` or DB-backed `Chains::Catalog.fetch`.
   - Display ordering is persisted with `chains.display_order`.

2. Done: move presentation metadata into the database.
   - `summary`, `docs_url`, `explorer_url`, `faucet_url`, and `verify_url` are first-class `chains` fields.
   - `db/seeds/chains.rb` seeds presentation fields alongside `tier` and `network_kind`.

3. Mostly done: reduce or remove `Chains::Catalog`.
   - Done: `Chains::Catalog.all` and `.fetch` now wrap persisted `Chain` records.
   - Done: curated contract list assembly reads database-backed `Contract` records.
   - Remaining: delete the adapter after views/controllers can use `Chain` records directly.

4. Done: point chain-facing surfaces at the database.
   - `/chains`, `/testnets`, `/chains/:slug`, `/chains/:slug.md`, and sitemap generation read from persisted chain data.
   - Tests seed through `Chains::Seeder.call` and assert persisted registry fields.
   - `bin/rails db:seed` / `Chains::Seeder.call` is the supported way to refresh chain data.
