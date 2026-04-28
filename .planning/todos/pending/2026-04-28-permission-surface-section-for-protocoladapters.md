---
created: 2026-04-28T01:39:13.100Z
title: Permission Surface section for ProtocolAdapters
area: general
files:
  - app/services/protocol_adapters/base.rb
  - app/services/protocol_adapters/uniswap_v3_adapter.rb
  - app/services/protocol_adapters/generic_erc20_adapter.rb
  - app/services/chain_reader/
  - app/views/contracts/
  - app/mcp/tools/
---

## Problem

聊到 USDC 谁能 blacklist 用户余额时引出的想法。当前每个合约文档页把所有函数平铺列出，"谁能单方面冻结/暂停/铸币/替换角色" 这种关键风险信息埋在 30 个函数里，用户找不到。

这是 Smarts 相对 Etherscan / Mintlify 的差异化点：合约级专家文档应该把权限/风险面作为一等公民呈现，而不是让用户自己拼。USDC 这种例子尤其典型——用户问"谁能冻结我的余额"，答案明明是结构化的（blacklister / pauser / owner 三个角色），却没有任何文档把它做成卡片。

**优先级低**：Month 1-3 主线（单合约打通 → 协议识别 → MCP server → 扩展）都不需要这个。是质量提升项不是 MVP 必需。等主线跑通、有了真实用户反馈后再决定。

## Solution

### 数据形状（不进 PG，只是 adapter 计算结果，缓存 Solid Cache）

用 Ruby 3.2+ `Data.define` 做不可变值对象 `ProtocolAdapters::Permission`：

- `title` — 人话，如 "Freeze any holder's balance"
- `severity` — `:critical | :high | :medium | :info`
- `role_name` — 如 "blacklister"
- `holder_address` + `holder_kind` — `:eoa | :gnosis_safe | :timelock | :contract | :unknown`
- `actions` — 函数签名数组
- `changed_by` — 另一个 role_name，**只递归一层**
- `description` — 可选 AI 生成

### Base 接口扩展

```ruby
def permission_surface
  []  # 默认空——adapter 不实现就不渲染整个 section
end
```

### 三层来源策略（覆盖率与精度平衡）

- **L1 通用模式** — 检测 OZ Ownable / AccessControl、EIP-1967 proxy admin、Pausable。写在 `ChainReader::PermissionScanner` 里所有 adapter 共用。覆盖 80%+ 合约。
- **L2 协议适配** — 每个 adapter 手写自己懂的角色：
  - FiatToken (USDC/USDT)：blacklister / pauser / masterMinter / owner
  - AaveV3：从 ACLManager 读 POOL_ADMIN / EMERGENCY_ADMIN / RISK_ADMIN
  - UniswapV3Pool：显式输出一条 `:info` "无管理员"——这本身是核心卖点
- **L3 AI 启发兜底** — 把 ABI 里非 view 的"看起来像 admin"函数喂给 LLM。**严格安全栏**：默认只能输出 `:medium`，`:critical` 必须 L1/L2 给。

### Holder kind 检测

新建 `ChainReader::HolderClassifier`，并发 `eth_getCode`（不能进 Multicall3 aggregate）+ 比对已知 bytecode hash 库（Gnosis Safe、OZ Timelock Controller 等）。

### UI

`app/views/contracts/_permission_surface.html.erb`，挂在 show.html.erb 顶部紧跟 overview。

- adapter 返回空数组 → 整块不渲染（**不要写 "无权限"——会误导**，可能只是没适配）
- 任何 `:critical` 项默认展开 + 红边
- 折叠态一行：`[severity dot] {title} — held by {holder_kind} {short_addr}`

### MCP tool

新增 `app/mcp/tools/get_permission_surface.rb`（`Tools::GetPermissionSurface(chain, address)`），AI agent 一次拿全风险评估所需信息。这是相对 Etherscan 真正差异化的点。

### 缓存

| 内容 | TTL | Key |
|---|---|---|
| 角色定义（abi 解析常量） | 30 天 | `perms:def:{abi_hash}` |
| 当前 holder address | 60 秒 | `perms:holders:{chain}:{addr}` |
| holder_kind 分类 | 1 天 | `holder_kind:{chain}:{addr}` |
| AI description | 7 天 | `perms:ai_desc:{abi_hash}:{prompt_v}` |

### 90 天落地节奏（如果决定做）

- **Month 1**：Base 接口 + L1 Scanner (Ownable/Pausable/EIP-1967) + UI partial + UniswapV3 那条 `:info` "无管理员" 规则
- **Month 2**：HolderClassifier + FiatTokenAdapter (USDC/USDT) + MCP tool
- **Month 3**：L3 AI fallback 进 GenericErc20Adapter + AaveV3Adapter L2 演示

### 提前点出的坑

1. **Severity 是主观的**：blacklist 对 stablecoin 是 `:info`（合规默认），对号称 permissionless 的 DEX 是 `:critical`。**适配器有最终发言权**，别在 Base 固化。
2. L3 容易把所有 `onlyOwner` 标成 critical，必须 prompt 限制 + schema 校验。
3. `changed_by` 只显示一层，否则 owner→owner→owner 无限循环。
4. `eth_getCode` 不能进 Multicall3 aggregate，HolderClassifier 用并发普通 RPC，注意 Alchemy 速率。
5. **代理合约**：L1 的 EIP-1967 admin 检测必须先于 Ownable，否则 `owner()` 可能返回 implementation 的 owner 而非 proxy admin——最常见误报来源。
