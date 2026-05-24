# 合约页 — 静态壳 + 实时岛 PLAN.md

> 分支：待定（建议 `feat/contract-shell-islands`）
> 状态：**未开始 — 只是设计**
> 范围：把 `ContractsController#show` 拆成长缓存的 HTML 壳 + Turbo Frame 化的实时数据 / tab endpoint，每个 endpoint 有自己的 HTTP TTL
> 最后更新：2026-05-23

---

## 为什么需要

目前 `ContractsController#show` 全部在服务端一次性渲染：合约元数据、ABI/docs、源码、ERC-20 实时条（supply/price/market cap/block #）、近期事件完整列表、治理时间线。整个页面又重又不可缓存——"as of Block #N · just now" 时间戳和价格跟不变的源码挤在同一个响应里。

我们想要两个都拿到：
- **结构性内容走 CDN 缓存**（热门合约 Cloudflare HIT → origin 压力几乎为零）
- **实时数据不撒谎**，"just now" 真的是 just now

标准方案：长缓存的 HTML 壳；Turbo Frame 异步加载实时 + 重内容，各自挂自己的短缓存 endpoint。每一块拿到的 TTL 都跟它的实际刷新频率匹配。

---

## 范围决策（动手前锁定）

| 决策 | 选择 | 理由 |
|---|---|---|
| 哪些 tab 懒加载 | 只 Live Activity + Governance（Docs、Source 不动） | Docs/Source 在合约验证后基本不变——留在壳里。Activity/Governance 是重查询，刷新频率也不同。 |
| ERC-20 实时条（supply/price/market cap/block #） | 抽成独立 frame + 独立 endpoint | 现在塞在壳里；抽出去之后壳可以大胆长缓存，"just now" 也能保持诚实。 |
| Tab 数据加载方式 | Stimulus 监听 tab 点击，设置 `frame.src`（不用 `loading=lazy`） | `loading=lazy` 只在可见时触发——对默认隐藏的 tab 没用。一次性预取所有 tab 又违背了懒加载的初衷。 |
| 首屏可见的 tab（Docs） | 仍然内联渲染在壳里 | 避免默认视图首屏多一次 roundtrip。 |
| 缓存失效机制 | 壳走 ETag + `must-revalidate` | origin 跑一个轻量 freshness 校验；Cloudflare 收到 304 直接出缓存 body。不用接入 purge API。 |
| 登录态 nav 渲染 | 接受缓存版里看到的是 "Sign in" | 跟 `feat/page-cache-home-articles` 一样的折中。后续：检测到 auth cookie 时切 `Cache-Control: private`。 |
| 防止布局抖动 | 骨架占位，尺寸跟最终内容一致 | 实时条数字、tab 面板必须有，否则数字进来时页面会跳。 |
| `turbo_stream_from @contract` 订阅 | 保留不动 | 已有的后台 job 触发 morph 刷新机制还在；跟 HTTP 缓存正交。 |

---

## 架构概览

```
GET /:slug 或 /:chain/:address              ←  长缓存（~6h），带 ETag，public
  └─ 只渲染壳：
       header（name、chain badge、地址、classification）
       MCP info 卡片
       protocol_adapter 介绍（如有）
       admin_risk 面板
       tab radios（Docs 可见，Activity/Governance/Source = 空 frame）
       Docs partial（静态，放在壳里）

GET /:slug/live                              ←  短缓存（max-age=30, SWR=60）
  └─ Turbo Frame：ERC-20 实时条
       supply、price、market cap、block #N、"just now"

GET /:slug/activity                          ←  cache=30s
  └─ Turbo Frame：Live Activity tab 内容
       解码后的近期事件

GET /:slug/governance                        ←  cache=1h
  └─ Turbo Frame：Governance tab 内容
       治理时间线（基本只追加历史）

GET /:slug/source                            ←  cache=12h（或合并进壳）
  └─ Turbo Frame：Source tab 内容
       文件索引 + 当前选中文件
```

说明：
- 所有 endpoint 同时支持 slug 和 chain/address 两种 URL 形式。
- Source tab 是否懒加载有讨论空间——内容完全不变，但文件可能很大；懒加载能让壳更小。

---

## 缓存 TTL 汇总

| Endpoint | `Cache-Control` | 理由 |
|---|---|---|
| `#show`（壳） | `public, max-age=21600, must-revalidate` + ETag | 结构性 HTML——name、地址、ABI 派生 docs、admin risk——很少变；AI docs 是 7 天周期重生成 |
| `#live`（ERC-20 条） | `public, max-age=30, stale-while-revalidate=60` | 价格 / 供应量 / 区块头——刷新短；SWR 防 origin 峰值 |
| `#activity` | `public, max-age=30, stale-while-revalidate=60` | 事件——比链头稍滞后 |
| `#governance` | `public, max-age=3600` | 历史时间线；只有新的治理事件才变化（很少） |
| `#source` | `public, max-age=43200` | 验证过的源码就是不可变的 |

壳的 ETag 用 `[contract.id, contract.abi_hash, contract.docs_version, classification.id]`。任一变化都通过 304 即时失效，无需 purge。

---

## 实施阶段

### Phase 1 — 把 ERC-20 实时条抽成 Turbo Frame
- 新 action：`ContractsController#live`（或独立的 `Contracts::LiveController#show`）
- 新路由：`GET /:slug/live`（+ chain/address 兜底）
- 把 ERC-20 实时条的渲染从壳里搬到 `_live.html.erb` partial，外面包 `<turbo-frame id="contract_live">`
- 壳里渲染一个带 `src=` 的空 frame，首屏就 fetch（这一块就是要 eager——首屏可见区域）
- `expires_in 30.seconds, public: true, stale_while_revalidate: 60`
- 空 frame 状态有骨架占位（灰色横条，宽度跟最终内容一致）

### Phase 2 — 三个 tab 懒加载（Activity + Governance + Source）
- 新 action：`#activity`、`#governance`、`#source` 挂在 `ContractsController`（或 namespace 化）
- 路由：`GET /:slug/{activity,governance,source}`
- 各自只渲染对应 partial，外面包 `<turbo-frame id="contract_{name}">`
- 改 `show.html.erb`：tab radios 保留，但三个懒加载 tab 的 panel 变成空 Turbo Frame（不再有 eager `<%= render %>`）
- Stimulus `contract-tabs` controller：监听 `input` 变化，把对应 frame 的 `src` 设到懒加载 endpoint（每个 tab 只 fetch 一次——记录已加载状态）
- 各 tab 按上表 `expires_in`
- 每个空 frame 都有骨架

### Phase 3 — 壳长缓存 + ETag
- 把 `#show` action 里的实时 fetch（`load_live_values`、`load_recent_events`、`load_governance_timeline`）全部移除
- 留在壳里的：classification、adapter、admin_risk
- 在 `#show` 最后加 `fresh_when etag: [@contract, @contract.abi_hash, @contract.docs_version, @classification&.id], public: true`
- 加 `expires_in 6.hours, public: true, must_revalidate: true`
- `enqueue_ai_enrichment_if_needed` 保留——已经是后台 job，不阻塞响应

### Phase 4 — Loading UX + 测试
- 骨架占位尺寸跟最终内容一致（防布局抖动）
- frame 加载时 `aria-busy="true"` → CSS dim/spinner
- 每个新 endpoint 的 controller 测试（响应状态、Cache-Control header、内容）
- 集成测试：渲染 `/usdc-eth` 壳，断言 frame 都在 + 懒加载 URL 正确
- 手动 smoke：打开 `/usdc-eth`，验证壳先出来、实时数字 ~500ms 内进来、tab 点击才去拉

---

## 不在范围内

- **登录态感知的缓存**（Vary on auth）—— 接受缓存版里看到 "Sign in"。后续再做。
- **Cloudflare purge API** —— ETag + must-revalidate 已经够用；避免引入 `CF_API_TOKEN` 依赖。
- **事件 / 治理时间线分页** —— 那是另一个扩展性问题，不属于这次重构。
- **预热热门合约缓存** —— `WarmupCacheJob` 在 CLAUDE.md 目标架构里已经规划；将来有需要时让它去刷新懒加载 endpoint 即可。
- **实时条 SSE 推送** —— `turbo_stream_from @contract` 已经覆盖了后台 job 触发的更新。不要加每秒轮询。

---

## 待定问题

1. Source tab 懒加载还是合并到壳？大合约的文件索引（USDC ~10 个文件）不大，但完整源码内容可能 50KB+。**暂定：懒加载，12h 缓存。**
2. `/eth/0xabc...` 十六进制路由 vs 规范 `/usdc-eth` slug——重定向到 canonical 之后，懒加载 endpoint 的 cache key 要不要也对应清掉？**暂定：每个 endpoint 走同一个 `resolve_chain_and_address` helper 做 canonicalize；重定向就是 301，有自己的缓存。**
3. Phase 1 单独发还是 1-3 打包一个 PR？**暂定：Phase 1 单独发，先验证 pattern + 量一下 CDN 命中率，再决定要不要继续做 tab。**
