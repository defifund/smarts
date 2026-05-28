# Smarts 现已覆盖 50 条 EVM 链：从以太坊到长尾生态的完整地图

2026 年 5 月，我们达成了一个里程碑：**Smarts 正式支持 50 条 EVM 链**。

这不是一个虚荣数字。这意味着，无论开发者在以太坊、Base、Arbitrum 这样的主流 L2 上工作，还是在 Berachain、Monad、HyperEVM 这样的新兴生态里实验，他们都能在一个地方查询已验证合约的源码、ABI 和 AI 生成的函数说明。在 6 条主流链上，还能读取实时链上状态、近期事件和治理风险。

## 地图的构成

我们的 50 条链不是平等的。它们分为两层：

**第一层：6 条主流链（Tier 1）**——完整能力
- Ethereum、Base、Arbitrum One、Optimism、BNB Smart Chain、Polygon PoS
- 这些链支持 **live state** 查询：任何 view 函数的实时值、近期事件、治理活动、admin 风险分析
- 开发者和 AI agent 可以秒级获取"这个池子现在的价格是多少"、"Aave 的风险参数是什么"

**第二层：44 条其他链（Tier 2）**——源码 + ABI

**Mainnet（23 条）：**
Linea、Unichain、Berachain、Blast、Sonic、Mantle、Gnosis、Celo、Fraxtal、Taiko、World Chain、Abstract、Moonbeam、Moonriver、opBNB、XDC、Monad、HyperEVM、Katana、Sei、Stable、Plasma、MegaETH

**测试网（21 条）：**
Ethereum Sepolia、Hoodi、Polygon Amoy、Arbitrum Sepolia、Linea Sepolia、Blast Sepolia、Celo Sepolia、Fraxtal Hoodi、Moonbase Alpha、opBNB Testnet、XDC Apothem、Unichain Sepolia、World Chain Sepolia、Berachain Bepolia、Monad Testnet、HyperEVM Testnet、Katana Bokuto、Sei Testnet、Stable Testnet、Plasma Testnet、MegaETH Testnet

这一层不走 RPC 查链上状态，而是直接从 Etherscan 读取已验证合约的源码和 ABI。

## 为什么要覆盖长尾

传统的合约文档工具有一个隐含假设：只有头部协议值得关注。

Etherscan 本身验证了数百万合约，但 95% 的用户只查 Top 100。文档平台（Mintlify）要求每个项目方手写文档，所以它们只存在于已融资的协议。

但现实中，**长尾是活跃的**。

新兴 L2（Berachain、Monad、Sonic）上有创新的 DeFi 原语。Unichain、World Chain 这样的垂直链吸引了特定社区的开发者。Farcaster、Lens 生态的合约需要审计。一个 AI agent 或研究员想全景理解某个市场时，需要的不是"只有 6 条大链"，而是"整个 EVM 的完整可访问性"。

Smarts 让这成为可能。开发者不再需要在 6 条链上用 Etherscan，在 Linea 上又换一个工具。**一个 MCP 端点，50 条链的统一查询接口。**

## 这对 AI 改变了什么

Smarts 最强的地方，不在网页界面，而在 MCP。

当开发者在 Claude Code 或 Cursor 里问："Base 上这个 Uniswap V3 池子的价格和流动性是多少？"——Claude 可以直接调 Smarts 的 MCP 工具返回实时数据和函数说明。不需要:
- 查 Etherscan
- 手读 Solidity
- 再问 Claude "帮我理解这段代码"

**50 条链的支持**意味着这个工作流覆盖了 EVM 全生态的文档入口。在 Sonic 上研究 DeFi？在 Celo 上审计 RWA？在 Abstract 上学 AA？Claude 可以直接读取已验证源码、ABI 和函数说明；在 Tier 1 链上，还可以继续读取实时状态和事件。

## 技术上的杠杆

为什么 Smarts 能跨越 50 条链？

关键在于**分层设计**的杠杆：
- 6 条主流链需要 RPC 成本和维护。但这 6 条链覆盖了主流 DeFi 流动性和最高频的合约查询场景。
- 其余 44 条链从 Etherscan 读取已验证合约的源码和 ABI，新增链的主要成本是登记链配置和验证索引流程。

这是竞争对手做不到的。Etherscan 是中心化服务，Mintlify 需要每个团队手写，Dune 需要开发者自己写 SQL。只有纯 AI + 链上查询的组合，才能在这样的规模里覆盖整个生态。

## 接下来

50 条链是现状。但这只是开始。

我们已经支持了 Uniswap V3 和通用 ERC-20/ERC-721 的完整适配器。接下来正在为 Polymarket、更多 DEX 和借贷协议构建专属适配器。这些适配器会让合约文档从"给我看源码和 ABI"升级到"给我看这个池的实时交易费、这个期权市场的当前赔率"。

长期看，**Smarts 的目标是成为 EVM 生态的统一知识库**——不仅是文档，而是任何人（开发者、研究员、AI agent）理解任何合约的最快路径。

50 条链只是这个愿景的基础设施。真正的价值，会在接下来的协议适配器和 AI 工作流优化里体现。

---

**在 Smarts 上看看：** 从 [https://smarts.md/usdc-eth](https://smarts.md/usdc-eth) 开始，或者在任何支持的 50 条链上试试。

**在 Claude Code 里用：** 在 [https://mcp.smarts.md/](https://mcp.smarts.md/) 安装 Smarts MCP server，问 Claude 已验证合约的源码、ABI 和函数问题；在 Tier 1 链上，还可以继续查询实时状态、事件和风险。
