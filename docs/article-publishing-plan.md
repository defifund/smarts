# Multilingual Article Publishing Plan

## Goals

- Build a minimal multilingual article system inside Smarts.
- Use articles as a marketing surface for Smarts: stablecoins, on-chain risk, Polymarket, MCP, agent workflows, and product narratives.
- Keep public URLs extremely short and stable.
- Publish through MCP tools, not a generic API, so Smarts dogfoods its own agent-native interface.
- Do not extract a gem yet. Implement inside Smarts first, then extract once the second real consumer proves the shared shape.

## Non-Goals For V1

- No full CMS UI.
- No X publishing integration yet.
- No category in the public URL.
- No complex taxonomy, nested categories, tags, authors, series, or editorial workflow.
- No ordinary public/private article publish API unless a non-agent integration later requires it.

## URL Design

Public article URLs:

- English/default: `/:slug`
- Localized: `/:locale/:slug`

Examples:

- `/7g`
- `/cn/7g`
- `/tw/7g`

Slug rules:

- Exactly two characters.
- Lowercase letters and digits only: `[a-z0-9]{2}`.
- No uppercase letters.
- User will avoid conflicts with future application paths.

Reserved article slugs:

```ruby
RESERVED_SLUGS = %w[
  up
  ai
  go
  to
  my
  me
  in
  on
]
```

Notes:

- `/up` is already used by Rails health check.
- `/ai` is reserved for a future AI/product entry.
- `/my` is reserved for user-owned workspace/assets.
- `/me` is reserved for profile or identity.
- `/go` and `/to` are reserved for redirects, campaigns, or deeplinks.
- `/in` and `/on` are reserved for sign-in/onboarding/connect flows.
- Locale route aliases do not need to be reserved for routing safety because localized articles have two path segments, for example `/cn/7g`.

Route priority:

- Explicit system routes stay before article routes.
- Article short route comes before the existing contract slug route.
- Existing contract slugs are long and constrained by `ContractSlugs::ROUTE_PATTERN`, so two-character article slugs should not collide with them.

## Locale Design

Supported locales for V1:

```ruby
SUPPORTED_LOCALES = %w[
  en
  zh-TW
  zh-CN
]
```

V1 language scope:

- `en`: English.
- `zh-CN`: Simplified Chinese.
- `zh-TW`: Traditional Chinese for Taiwan and Hong Kong audiences.

Canonical public routes:

- `en`: `/:slug`
- `zh-CN`: `/cn/:slug`
- `zh-TW`: `/tw/:slug`

Route-to-locale map:

```ruby
LOCALE_ROUTE_MAP = {
  "cn" => "zh-CN",
  "tw" => "zh-TW"
}
```

Use short route aliases publicly, but keep standard locale keys internally for SEO, hreflang, translation management, and future compatibility.

Fallback order:

- Requested locale.
- English.
- Any available locale.

Route aliases:

- `/zh/:slug` may later redirect to `/cn/:slug` for convenience.
- `/zh-CN/:slug` may later redirect to `/cn/:slug`.
- `/zh-TW/:slug` may later redirect to `/tw/:slug`.
- V1 canonical localized URLs should use short aliases `cn` and `tw`, while stored locale keys remain `zh-CN` and `zh-TW`.

## User And Account Model

Use Rails 8 built-in authentication, not Devise.

V1 includes:

- Sign in through Rails 8 sessions.
- User registration through `UsersController`.
- Password reset through Rails 8 signed password reset tokens.
- API token shown once after registration or rotation.

`User` fields:

```ruby
name:string
email_address:string
password_digest:string
api_token_prefix:string
api_token_digest:string
timestamps
```

Rules:

- `email_address` and `password_digest` follow Rails 8 authentication conventions.
- MCP publishing uses a plain `publish_token` parameter, but the database stores only `api_token_prefix` and `api_token_digest`.
- Plain API tokens are generated once, shown once, and never stored.
- API token format should use a recognizable prefix, for example `sma_...`.
- Authentication finds candidates by `api_token_prefix`, then verifies with BCrypt.

`Account` fields:

```ruby
user_id:references
provider:string
handle:string
locale:string
access_token:string
access_token_secret:string
timestamps
```

Rules:

- `provider` is `x` for V1.
- `locale` must be one of `en`, `zh-CN`, `zh-TW`.
- A user can have one account per provider + locale.
- `access_token` and `access_token_secret` are encrypted with Active Record Encryption.
- They remain convenient to use: `account.access_token` returns the decrypted value for `x_queue`.

Future `x_queue` usage:

```ruby
account = article.user.accounts.find_by!(provider: "x", locale: locale)

XQueue::Scheduler.thread(
  texts: tweets,
  account: account,
  source: article
)
```

## Data Model

Add `Article`.

Fields:

```ruby
user_id:references
slug:string
category:string
subcategory:string
title:jsonb
summary:jsonb
content:jsonb
published_at:datetime
timestamps
```

Indexes:

- Unique index on `slug`.
- Index on `category`.
- Index on `[category, subcategory]`.
- Index on `published_at`.

Validations:

- `user` is required.
- `slug` matches `[a-z0-9]{2}`.
- `slug` is not in `RESERVED_SLUGS`.
- `category` is present and included in allowed categories.
- `subcategory` is optional, but if present it must be allowed under the selected category.
- `title` has at least English or Chinese.
- `content` has at least English or Chinese.

Publishing scope:

```ruby
Article.published.where("published_at <= ?", Time.current)
```

## Category Design

Use a lightweight two-level category model to give the article system more editorial structure without creating a CMS.

Rules:

- `category` is the top-level editorial pillar.
- `subcategory` is optional and refines the article inside that pillar.
- Neither `category` nor `subcategory` is part of the public URL.
- Category keys are internal identifiers.
- Display labels are translated at render time.
- Category and subcategory can later drive article lists, related articles, landing pages, and SEO clusters.

Initial allowed categories:

```ruby
CATEGORIES = %w[
  product
  stablecoins
  risk
  markets
  guides
  company
]
```

Initial allowed subcategories:

```ruby
SUBCATEGORIES = {
  "product" => %w[mcp tools workflows releases],
  "stablecoins" => %w[issuers reserves payments regulation infrastructure],
  "risk" => %w[admin-controls upgrades governance incidents compliance],
  "markets" => %w[polymarket prediction-markets liquidity resolution odds],
  "guides" => %w[setup integrations examples playbooks],
  "company" => %w[positioning updates roadmap]
}
```

Validation:

```ruby
subcategory.blank? || SUBCATEGORIES.fetch(category, []).include?(subcategory)
```

This keeps the data model flexible without making V1 depend on a full taxonomy system.

Example labels:

```yaml
en:
  article_categories:
    stablecoins: "Stablecoins"
  article_subcategories:
    stablecoins:
      infrastructure: "Infrastructure"
zh:
  article_categories:
    stablecoins: "稳定币"
  article_subcategories:
    stablecoins:
      infrastructure: "基础设施"
```

## Draft File Structure

Drafts live in the repo:

```text
docs/drafts/7g/
  meta.json
  en.md
  zh-CN.md
  zh-TW.md
```

Published source files may later be moved or copied to:

```text
docs/published/7g/
  meta.json
  en.md
  zh-CN.md
  zh-TW.md
```

Example `meta.json`:

```json
{
  "category": "stablecoins",
  "subcategory": "infrastructure",
  "title": {
    "en": "Coinbase and Custom Stablecoins",
    "zh-CN": "Coinbase 与定制稳定币",
    "zh-TW": "Coinbase 與客製化穩定幣"
  },
  "summary": {
    "en": "A concise summary.",
    "zh-CN": "一段简短摘要。",
    "zh-TW": "一段簡短摘要。"
  }
}
```

Markdown rules:

- Each locale uses one Markdown file.
- If the first line is a level-one heading, the publisher may strip it because title comes from `meta.json`.
- Body Markdown is stored in `content`.

## Services

Add service objects under `app/services/articles`.

`Articles::DraftReader`

- Reads `docs/drafts/:slug`.
- Parses `meta.json`.
- Loads locale Markdown files.
- Strips optional first `# Heading`.
- Validates missing files, unsupported locales, invalid category, invalid slug, and empty content.
- Returns structured validation errors.

`Articles::Publisher`

- Uses `DraftReader`.
- Creates or updates `Article`.
- Sets `published_at`.
- Returns public URLs for available locales.
- Optionally supports dry-run validation.
- V1 can leave draft files in place; moving to `docs/published` can be added after the workflow stabilizes.

## MCP Publishing Tools

Publishing should use MCP, not a normal API.

Reasoning:

- Smarts is an MCP-native product, so article publishing should dogfood the product surface.
- Agent clients such as Codex and Claude can publish without custom HTTP integration.
- Tool schemas provide a cleaner contract than an ad hoc API.
- Business logic remains in service objects, so a future API or UI can reuse the same code if needed.

Add tools:

```text
list_article_drafts
validate_article_draft
publish_article
```

Security:

- These tools are exposed through the public MCP server, so V1 requires a user-scoped publishing token.
- Each publishing tool takes `publish_token`.
- `publish_token` authenticates against `User.api_token_prefix` + `User.api_token_digest`.
- Missing or invalid token returns an error and performs no read/write publishing action.
- Published articles store `article.user_id`.

Tool behavior:

- `list_article_drafts`: lists draft slugs and detected locales/categories.
- `validate_article_draft`: validates one draft and returns blocking errors/warnings.
- `publish_article`: validates then creates/updates the article and returns URLs.

Example return URLs:

```text
https://smarts.md/7g
https://smarts.md/cn/7g
https://smarts.md/tw/7g
```

## Rendering

Add `ArticlesController#show`.

Behavior:

- Find only published articles.
- Resolve locale from route params.
- Fallback to English, then any available locale.
- Render title, category label, summary, date, and Markdown body.
- Add canonical URL.
- Add basic SEO metadata.

V1 page style:

- Reuse Smarts visual language.
- Keep article page readable and fast.
- Avoid building an index page until there are enough articles.

## Tests

Add coverage for:

- `Article` slug validation.
- Reserved slugs.
- Category validation.
- Locale fallback.
- Published scope.
- Article routes:
  - `/:slug`
  - `/:locale/:slug`
  - `/up` remains health check.
- Draft reader validation.
- Publisher create/update behavior.
- MCP tool payloads.
- Existing contract slug route remains unaffected.

Run:

```bash
bin/rails test
```

## Extraction Strategy

Do not create a gem first.

Recommended path:

1. Implement in Smarts.
2. Publish real Smarts articles through MCP.
3. If another project needs the same workflow, extract only stable pieces:
   - `Article` engine/migrations
   - draft reader
   - publisher
   - MCP tools or adapters
   - route helpers
4. Keep project-specific marketing copy, categories, styling, and SEO outside the gem.

Extraction target:

- A Rails engine/gem is plausible later.
- The first implementation should stay app-local to avoid freezing the wrong abstraction.

## Later Options

- Article index page.
- Category landing pages.
- Related articles.
- Hreflang tags.
- Author metadata.
- X publishing through `x_queue`.
- Scheduled publishing.
- Draft-to-published file moves.
- Admin UI.
- Analytics per article/category.
