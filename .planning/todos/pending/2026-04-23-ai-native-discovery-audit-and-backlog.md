---
created: 2026-04-23T11:23:18.299Z
title: AI-native discovery audit and backlog
area: general
files:
  - public/robots.txt
  - public/llms.txt (new)
  - app/views/layouts/application.html.erb
  - app/views/contracts/show.html.erb
  - app/controllers/contracts_controller.rb
  - config/routes.rb:32
---

## Problem

Goal: let Claude / AI agents discover and use smarts.md without manual setup.

Audited current state against "how would Claude find smarts" on 2026-04-23 with Claude. Core finding: **Claude does not auto-discover or auto-install MCP servers.** The realistic discovery paths are:

1. **SEO + WebFetch hitting contract doc pages** — primary traffic, users ask Claude about a contract, Claude web-searches, lands on `smarts.md/eth/0x...`, uses content to answer.
2. **Human developers finding us on an MCP directory** and manually configuring `mcp.smarts.md` in their Claude Code / client.

"One MCP endpoint per contract" is a product narrative, not a discovery mechanism — clients will never auto-install per-contract endpoints.

### Audit (2026-04-23)

| Item | Status |
|---|---|
| MCP server `/mcp/sse` | shipped |
| `.well-known/mcp.json` manifest | shipped (`routes.rb:32`) |
| Smithery directory | submitted |
| Per-contract MCP reference card | shipped (`_mcp_info.html.erb`) |
| `llms.txt` | MISSING |
| OpenGraph / JSON-LD / Twitter meta | MISSING |
| `sitemap.xml` | MISSING |
| `robots.txt` | default-only; AI crawlers not explicitly allowed |
| Glama listing | not submitted |
| Official MCP Registry | not submitted |
| Markdown variant of contract pages (`/eth/0x....md`) | MISSING |

## Solution

Prioritized backlog (P1 is starting now in a separate session; this todo tracks the remaining P2/P3 plus the "done" record).

### P1 — in progress (do first, ≤1h each)

1. `public/llms.txt` — AI crawler site map; list purpose, URL patterns, MCP endpoint, tools.
2. Submit to Glama (`glama.ai/mcp/servers`) — GitHub repo URL, auto-indexed; also bridges into official MCP Registry's superset. **Manual action by Bob.**
3. `robots.txt` — explicit allow for GPTBot / ClaudeBot / PerplexityBot / Google-Extended; link sitemap.

### P2 — next week (1–3h each)

4. OpenGraph + JSON-LD on contract pages (contract name, protocol, TVL, address). Check `application.html.erb` / `show.html.erb` — currently no meta tags beyond title.
5. Dynamic sitemap — either add `sitemap_generator` gem (needs approval per CLAUDE.md "no new gems without confirmation") or hand-roll a `GET /sitemap.xml` controller. List all known Contracts, updated daily.
6. `.md` variant of contract pages (`smarts.md/eth/0x....md`) — branch in `ContractsController#show` on `format`, return markdown. Claude WebFetch parses markdown far better than HTML.

### P3 — when convenient

7. Submit to official MCP Registry (`github.com/modelcontextprotocol/servers` PR).

### Explicitly not doing

- Cursor Directory — wrong fit (their spec targets Cursor runtime, our dynamic per-contract model doesn't map).
- MCP.so — issue-based, static display, low ROI compared to Glama.
- Large-scale SEO content — wait until Month 2 when protocol coverage broadens.

## Reconsider if

- MCP protocol adds auto-discovery (e.g., `.well-known/mcp-servers` client convention) — then per-contract endpoints become addressable and the whole calculus changes.
- Anthropic / OpenAI ship native "fetch MCP server from URL" in their clients — same effect.
- Traffic analytics show a different primary discovery path than SEO + directory.
