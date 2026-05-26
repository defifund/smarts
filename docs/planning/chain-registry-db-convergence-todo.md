# Chain Registry DB Convergence TODO

Current state: `Chain` rows seeded from `db/seeds/chains.rb` hold the core registry, while `Chains::Catalog` still drives `/chains`, `/testnets`, chain markdown, and sitemap entries. This creates duplicated chain data and drift risk.

## TODO

1. Make `Chain` the single source for chain registry data.
   - Load `/chains`, `/testnets`, chain detail pages, and sitemap chain entries from `Chain.for_display`.
   - Keep ordering in one place, preferably on the persisted registry or a small display-order field.

2. Move presentation metadata into the database.
   - Add fields or a structured metadata store for `summary`, `docs_url`, `explorer_url`, `faucet_url`, and `verify_url`.
   - Seed these fields from `db/seeds/chains.rb`.
   - Keep `tier` and `network_kind` as first-class columns.

3. Reduce or remove `Chains::Catalog`.
   - First make it a thin adapter over `Chain` records if views still need the existing interface.
   - Then move contract list assembly to database-backed `Contract` records or a separate contract catalog service.
   - Delete duplicated chain definitions from `Chains::Catalog` once callers no longer depend on them.

4. Point chain-facing surfaces at the database.
   - Update `/chains`, `/testnets`, `/chains/:slug`, `/chains/:slug.md`, and sitemap generation to read from persisted chain data.
   - Update tests so registry consistency is checked against the database seed path, not a parallel in-memory catalog.
   - Run `bin/rails db:seed` / `Chains::Seeder.call` as the supported way to refresh chain data.
