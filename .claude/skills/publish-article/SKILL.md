---
name: publish-article
description: >
  Publish a multilingual draft from docs/drafts/<slug>/ to smarts.md and, by
  default, schedule a zh-CN + en X thread in the same call. Triggers:
  "发布 <slug> 到 smarts", "发 <slug> 到 smarts", "publish <slug> to smarts",
  and the follow-up "发X" when the article was published article-only.
  Single-letter flags follow the slug (e.g. "发布 wy 到 smarts a").
---

# publish-article

A draft lives at `docs/drafts/<slug>/` with `meta.json` + one markdown file per
locale (`en.md`, `zh-CN.md`, `zh-TW.md`). Two stages; run only what the user
asks for. Cross-posting to other platforms (Pickful etc.) is **not** part of
this skill — the user decides those manually.

## Stage 1 — Publish to smarts.md (+ X by default)

When user says "发布 <slug> 到 smarts" / "发 <slug> 到 smarts" /
"publish <slug> to smarts":

**Default behavior: publish the article AND schedule a zh-CN + en 4-tweet
thread in the same `publish_article` call.** One round-trip, one confirmation.

Flags (single letters, appended after the slug or anywhere in the line —
combinable, e.g. "发布 wy 到 smarts s c"):

| Flag | Meaning |
|---|---|
| `a` | Article only — skip tweets entirely. |
| `s` | Single tweet per locale (hook + URL), not a thread. |
| `c` | Restrict tweets to zh-CN only. |
| `e` | Restrict tweets to en only. |

Notes:
- `a` overrides `s` / `c` / `e` (no tweets means locale/form don't matter).
- `c` and `e` together = both locales = same as no flag.
- Article always publishes in every locale present in `meta.json` regardless
  of flags. Flags only affect the tweets.

Flow:
1. Read `docs/drafts/<slug>/meta.json` and every `<locale>.md`.
2. Validate inline with `mcp__smarts__validate_article_draft` — pass `slug`,
   `meta`, and `content` (locale → markdown body).
3. Unless `a` is set, draft tweets for the locales selected by `c` / `e`
   (default: both zh-CN and en). Default shape per locale is a 4-tweet
   thread:
   - T1: the pain (concrete, no jargon)
   - T2: how the existing answer falls short
   - T3: what Smarts.md does instead
   - T4: who it's for + the article URL (`https://smarts.md/<slug>` for en,
     `https://smarts.md/cn/<slug>` for zh-CN, `https://smarts.md/tw/<slug>`
     for zh-TW)
   For `s` (single), collapse to one line: hook + URL.
4. Show the tweet draft to the user before sending. One confirmation covers
   both the article and the tweets — don't ask twice.
5. Call `mcp__smarts__publish_article` with `slug`, `meta`, `content`, and
   (when tweeting) `tweets: { "<locale>": [...] }` + `thread: true` (omit or
   set `false` for `s`).
6. Report per-locale URLs and `tweets_scheduled` / `tweet_errors`.

Why pass `meta` + `content` inline: the server only sees its own
`docs/drafts/` directory, which won't contain a draft that lives only in this
repo. Inline mode is always safe.

Each tweet ≤ 280 characters. URL counts as ~23 chars in X's algorithm.

## Stage 2 — Schedule X after the fact

When the article was published with `a` and the user later says "发X" /
"发推" / "send X posts": run step 3-6 from Stage 1 with the same `slug` /
`meta` / `content`. The same `s` / `c` / `e` flags apply here. The tool is
idempotent on content — only `tweets_scheduled` changes.

## Style rules

- Tweets are user-facing — no agent internals ("called N MCP tools",
  "validated draft", etc.). Speak as Bob, not as the tool.
- Titles: no formulaic `X：最简介绍` / `X: A Guide`. Use the title already in
  `meta.json`.
- Don't over-confirm. Default flow is publish + X in one call; show the tweet
  draft once and proceed unless user objects. Only ask about locale/form when
  the user's modifier is ambiguous.

## When *not* to run this skill

- Editing or reviewing a draft (read the files directly).
- `mcp__smarts__list_article_drafts` only returns server-side drafts; local
  drafts live under `docs/drafts/`. Use `ls` for the local list.
- Polymarket / contract / on-chain queries — those are unrelated tools.
