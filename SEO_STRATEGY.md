# Smarts SEO 战略（AI + 传统）

> 2026-05-24 整理，与 Bob 深入讨论中
> 核心定位：AI 原生文档发现 + 传统 SEO 并行

---

## 概览

Smarts 有两条 SEO 跑道：

1. **AI SEO**（主线）：AI agent 和开发者通过 MCP 自然发现 smarts.md
2. **传统 SEO**（辅线）：Google / 搜索引擎带来的品牌和长尾流量

两条线都重要，但优先级和时间表不同。

---

## 传统 SEO 战略

### 域名矩阵

| 域名 | 角色 | SEO 策略 |
|---|---|---|
| `smarts.md` | 品牌主入口 | 品牌词 + 通用词：`smart contract docs`、`live contract docs` |
| `smartcontract.md` | SEO 关键词站 | 301 重定向到 smarts.md，捕获`"smart contract"` 搜索量 |
| `chains.md` | 平台延展 | 暂无 SEO 优先（内容少） |

### 页面内容优化

#### 合约详情页

每个合约页面 (`smarts.md/eth/0x1f98...`) 的标题和描述需要优化：

**标题标签**（`<title>`）
```
[协议名] [关键参数] - Live Docs | Smarts
示例：
- "Uniswap V3 USDC/WETH (0.05%) Pool - Live Docs"
- "Aave V3 USDC - Live Lending Pool | Smarts"
```

**Meta Description**
```
自动生成，包含关键数据：
"Real-time state for [协议]. TVL: $XXX, 24h Volume: $YYY, Fees: $ZZZ.
View live functions, events, and admin risks."
```

**H1 层级**
```html
<h1>
  [协议名] [合约类型] on [链名]
  <br>
  <small>Address: 0x... | Live data from blockchain</small>
</h1>
```

#### 聚合页面（缺失，需要建）

| 页面 | URL 模式 | 内容 |
|---|---|---|
| 协议概览 | `/protocols/uniswap-v3` | 所有 Uni V3 池排行（TVL、交易量、费率） |
| 协议列表 | `/protocols` | 所有支持的协议 + 各自的池数、总 TVL |
| 链视图 | `/chains/ethereum` | Ethereum 上的所有 live 合约 |
| 趋势 | `/trending` | 24h 最活跃的合约、新增合约 |

#### 独特内容（与 Etherscan 差异化）

Etherscan 有的东西，Google 已经给了排名。我们要做 Etherscan **没有**的：

1. **实时 Gas 分析**
   - 标题：`Gas Cost Analysis: [合约]`
   - 内容：过去 100 次调用的平均 gas、cost 范围、最贵的函数
   - 数据来源：事件日志 + ChainReader

2. **权限风险看板**
   - 标题：`Admin & Risk Profile: [合约]`
   - 内容：owner 权限、upgradeable 状态、升级历史、黑名单
   - 这是原创内容，Etherscan 不提供 structured risk view

3. **事件日志 Timeline**
   - 标题：`Recent Activity: [合约]`
   - 内容：最近 50 笔交互的可读 timeline（谁、什么时候、做了什么）
   - 数据来源：event decoder + 链上时间戳

4. **协议对比**
   - 标题：`Uniswap V3 vs Uniswap V4 Fees & Execution`
   - 内容：同一代币对在 V3 和 V4 的费率对比、TVL 对比

### 内部链接策略

构建信息架构的"脊椎"：

```
/protocols (所有协议)
  ├─ /protocols/uniswap-v3 (协议详情)
  │   ├─ [Pool 1] (合约页面)
  │   ├─ [Pool 2]
  │   └─ → [all pools ranking]
  │
  ├─ /protocols/aave-v3 (协议详情)
  │   └─ [Lending markets]
  │
  └─ /chains (按链聚合)
       ├─ /chains/ethereum
       ├─ /chains/base
       └─ [所有池汇总页]
```

**链接策略**：
- 合约页 → 协议页（"Back to all [Protocol] pools"）
- 协议页 → 链视图（"View [Protocol] on other chains"）
- 链视图 → 协议页（"View all protocols on this chain"）
- 热门合约互链（如 USDC/WETH + WETH/USDC）

### 技术 SEO

#### Schema Markup（JSON-LD）

```json
{
  "@context": "https://schema.org",
  "@type": "APIReference",
  "name": "Uniswap V3 USDC/WETH Pool",
  "url": "https://smarts.md/eth/0x1f98431c8ad98523631ae4a59f267346ea31394f",
  "description": "Real-time live docs...",
  "provider": {
    "@type": "Organization",
    "name": "Smarts",
    "url": "https://smarts.md"
  },
  "documentation": "https://smarts.md/eth/0x1f98.../functions"
}
```

#### Core Web Vitals

- **LCP** (Largest Contentful Paint): 合约名称和 TVL 数字秒级加载
- **FID** (First Input Delay): live data 刷新不阻塞页面交互
- **CLS** (Cumulative Layout Shift): 实时数据注入不晃动

#### Robots & Crawlability

```robots.txt
User-agent: *
Allow: /
Allow: /eth/*
Allow: /base/*
Disallow: /admin
Disallow: /mcp  # MCP server 不需要被索引
```

页面需要 canonical tag（避免 `/eth/0x1f98` 和 `/eth/0x1F98` 重复）。

---

## AI SEO 战略（主线）

### 核心思想

开发者不再用 Google 搜"Uniswap V3 USDC/WETH 的 swap 函数签名"，而是在 Claude Code 里问：
```
我想调用 Uniswap V3 USDC/WETH 池的 swap 函数。
费率是多少？当前价格是多少？
```

Claude 调用 smarts.md 的 MCP → 返回实时数据 + 函数详情 → 开发者获得答案。

**这种发现模式里，smarts.md 就是"AI 的首选文档"。**

### MCP 作为 AI SEO 的核心

#### 当前实现

在 `app/tools/` 里有：
- `get_contract_info_tool.rb`
- `get_contract_source_tool.rb`
- `read_contract_state_tool.rb`
- `get_erc20_info_tool.rb`
- `get_recent_events_tool.rb`
- `get_uniswap_v3_pool_tool.rb`
- `get_polymarket_market_tool.rb`
- ...

#### 优化方向

1. **工具描述要精确**
   ```ruby
   # 好例子
   description: "Get live USDC/WETH pool state on Ethereum: current price, TVL, fee tier, ticks"
   
   # 不够精确
   description: "Get pool info"  # ❌ AI 不知道这个工具适用于什么场景
   ```

2. **参数要清晰**
   ```ruby
   input_schema(
     properties: {
       chain: { 
         type: "string", 
         description: "Chain: eth, base, arbitrum, optimism, polygon"
       },
       address: { 
         type: "string",
         description: "Contract address (0x prefixed)"
       }
     }
   )
   ```

3. **返回值要结构化**
   - 不返回纯文本，返回有字段的 JSON
   - 包含"下一步"提示（e.g., "See live events at smarts.md/eth/0x..."）

#### MCP 发现机制

- **官方注册**：是否能在 Smithery / Claude 官方 MCP Registry 注册 `smarts.md` MCP？
- **文档链接**：README / landing page 需要明确说"如何在 Claude Code / Cursor 里使用"
- **示例 prompt**：
  ```
  你可以通过以下方式使用 Smarts MCP：
  
  添加 MCP server：
  - Claude Code: 配置 ~/.claude/mcp-servers.json
  - Cursor: 配置 ~/.cursor/mcp-servers.json
  
  示例提问：
  - "查一下 Base 上 USDC/USDT 池的当前状态"
  - "比较 Ethereum 和 Base 上 USDC 的 lending 利率"
  - "Aave V3 的风险指标是什么"
  ```

### 页面结构优化（对 AI 友好）

#### 问题 1：AI 能否快速提取"合约地址"？

当 Claude 在文章里写到"Uniswap V3 USDC/WETH 池"时，它怎么知道地址是多少？

**解决方案**：在页面 HTML 中加 structured data
```html
<div data-contract-chain="ethereum" data-contract-address="0x1f98431c8ad98523631ae4a59f267346ea31394f">
  Uniswap V3 USDC/WETH Pool
</div>
```

或用 JSON-LD 的 `sameAs` 字段：
```json
"sameAs": "ethereum:0x1f98431c8ad98523631ae4a59f267346ea31394f"
```

#### 问题 2：AI 如何理解函数的风险和限制？

Etherscan 显示 ABI，但 AI 看不出来"这个函数有什么风险"。

**解决方案**：在 ruby_llm enrichment 时加风险标签
```ruby
# app/services/contract_document/ai_enricher.rb

def classify_function(function)
  # 不仅生成文档，也生成风险标签
  classification = RubyLLM.chat(model: "haiku",
    prompt: "这个函数 #{function.signature} 在 DeFi 合约中的风险是什么？[re-entrancy / overflow / slippage / ...]"
  )
  
  # 存储在 db 并暴露给 MCP
  function.update(risk_tags: classification)
end
```

然后 MCP 工具返回：
```json
{
  "function": "swap",
  "signature": "swap(...)",
  "risk_tags": ["slippage", "re-entrancy risk"],
  "recommended_checks": "Use slippage parameters, check allowance before calling"
}
```

#### 问题 3：AI 是否能发现 smarts 上的内容？

如果 Claude 的知识库里没有"smarts.md"的内容，它怎么知道调用 MCP？

**解决方案**：在公开场合（ProductHunt、Twitter、文章）提及 smarts.md，让 Claude 的训练集里有这个信息。但短期内不依赖这个——**直接教用户如何配置 MCP server**。

### 内容自动生成（AI 杠杆）

对每个新导入的合约，自动生成"AI 可能问到"的问题和答案：

```ruby
# app/jobs/generate_ai_faq_job.rb

def perform(contract_id)
  contract = Contract.find(contract_id)
  
  faq = RubyLLM.chat(
    model: "sonnet",
    prompt: <<~PROMPT
      给这个合约生成 5 个开发者最常问的问题和答案：
      
      合约: #{contract.name}
      协议: #{contract.protocol.name}
      类型: #{contract.contract_type}
      
      问题应该覆盖：
      1. 函数调用 (signature, 参数说明)
      2. 当前状态 (TVL, 利率等)
      3. 风险 (owner 权限, upgradeable)
      4. 成本 (gas, 费率)
      5. 与其他合约的对比
      
      格式：JSON array of {question, answer}
    PROMPT
  )
  
  contract.update(ai_faq: faq)
end
```

页面上显示这些 FAQ，也可被搜索引擎和 AI 索引。

---

## 优先级和时间表

### 现在（Month 1-2）必做

- [ ] 每个合约页面自动生成 `<title>` 和 `<meta description>`
- [ ] 添加 JSON-LD schema（APIReference）
- [ ] 测试：Claude Code 中能否调用 smarts.md 的 MCP
- [ ] Landing page 加"如何在 Claude Code 里使用"的说明文档
- [ ] MCP 工具的 description 字段重写（更精确）

### Month 2-3 高优先级

- [ ] 建立聚合页面（`/protocols`, `/chains`, `/trending`）
- [ ] 内部链接架构（合约 → 协议 → 链视图）
- [ ] 继续把 `/chains` 的 docs-only 页面做目录化收敛，减少首屏噪音
- [ ] 丰富各个链的合约信息，补更高信号的摘要、代表性协议和覆盖质量说明
- [ ] 添加"权限风险看板"原创内容
- [ ] AI FAQ 自动生成 + 页面展示
- [ ] 向 ProductHunt / Hacker News / Twitter 发布，重点强调"live"和"从 Claude Code 调用"

### Month 4+ 低优先级

- [ ] "Gas 成本分析"深度内容
- [ ] "协议对比"文章（Uni V3 vs V4 等）
- [ ] 官方 MCP Registry 注册（如果有的话）
- [ ] SEO 文章（"如何读智能合约文档"、"DeFi 风险识别指南"）

---

## 关键指标

### 传统 SEO
- 每个合约页的自然搜索流量（Google Search Console）
- `smartcontract.md` 的搜索量（301 重定向后）
- 协议页的排名（`site:smarts.md uniswap v3`）

### AI SEO
- 在 Claude Code 中被调用的 MCP 请求数
- 用户从 MCP 继续访问 smarts.md 网站的比例
- MCP 工具的文档在 AI 模型输出中被正确引用的频率

### 混合指标
- ProductHunt 或 Twitter 上的提及数
- 被 AI 文章/博客引用的次数

---

## 潜在陷阱

### ❌ 不要做

1. **关键词堆砌** — `smart contract docs`, `live docs`, `blockchain documentation` 都写在 title 里
   - → 用 1-2 关键词，优先"产品信息"（协议名、地址）

2. **自动生成垃圾内容** — 为每个合约自动生成"SEO 文章"
   - → 内容必须有真实价值（原创分析、风险评估）

3. **忽视 AI SEO** — 以为 Google 就够了
   - → 在 AI 时代，被 Claude/GPT 发现和被 Google 发现一样重要

4. **MCP 功能与网站功能重复** — MCP 全能，网站就沦为"冗余"
   - → 网站专注于"阅读体验"和"深度内容"，MCP 专注于"快速查询"

### ⚠️ 注意

- **Etherscan 竞争** — 他们的 SEO 很强。与其比排名，不如强调"live + AI 优先"的独特性
- **内容新鲜度** — 合约页面的数据是 live，但文本描述可能过时。定期（每周）重新生成 AI 描述
- **多语言 SEO** — 暂时不考虑（MVP 英文优先），但后续可以用 i18n 扩展到中文、日文

---

## 参考与工具

### 工具
- Google Search Console（监测排名和点击率）
- Semrush / Ahrefs（竞争对手分析，可选）
- Chrome DevTools Lighthouse（Core Web Vitals）

### 竞争对手
- Etherscan（传统 SEO 强，AI 友好性弱）
- Dune Analytics（数据驱动，SEO 一般）
- DefiLlama（流动性数据，但不做合约文档）

### 相关文章（待研究）
- Google: "How to Optimize for AI Search" (2025-2026)
- "MCP Best Practices for Discovery" (Anthropic/Smithery)

---

_本文档将根据实际执行情况持续更新。_
