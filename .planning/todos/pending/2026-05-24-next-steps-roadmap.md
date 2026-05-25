---
created: 2026-05-24T00:00:00Z
title: 下一步路线图（按 ROI 排序）
area: planning
files: []
---

# 下一步路线图（按 ROI 排序）

## 1. ✅ 修 USDT multicall bug（已完成）
`get_erc20_info` 对 USDT 类非标 ERC-20（`returns (bool)` 缺失）multicall 静默失败，一个失败毒化整个 batch。
- 详见：`2026-05-16-get-erc20-info-multicall-fails-on-usdt-style-tokens.md`
- 影响：数据可靠性基础问题，必须先修

## 2. 📣 内容驱动增长 — 批量发文章（持续）
已有发布管道 + 10 篇文章在线。围绕 curated slugs 批量产出合约解读文章：
- `docs/drafts/us/` 待发布
- 每篇自带 X thread 推广
- 当前最有效的获客手段

## 3. ✅ ai-plugin.json + ChatGPT Actions 集成（已完成）
已有 `/.well-known/mcp.json`，再加 `/.well-known/ai-plugin.json`：
- 把 MCP tools 包装成 OpenAPI schema
- 被 ChatGPT Custom GPTs 发现
- 第二个 AI 分发渠道，几乎零成本

## 4. 🏗️ Aave V3 Adapter（1 周）
Month 3 里程碑核心目标：
- curated slugs 里已有 5 个 Aave V3 Pool 地址
- adapter 还没写
- 完成后 DeFi 覆盖面从 DEX 扩展到借贷

## 5. 🔄 Refresh strategy 补全
- proxy 升级后自动检测 + AI 重跑
- 热合约自动刷新机制
- 新合约冷启动预热
- 详见：`2026-04-25-refresh-strategy-gaps-proxy-upgrade-ai-rerun-cold-start.md`

## 6. ✅ SEO + Landing page 打磨（已完成）
- Top 50 合约 sitemap
- structured data（JSON-LD）
- 合约页 meta description 自动生成
