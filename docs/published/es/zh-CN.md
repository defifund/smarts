---
date: 2026-05-22
source: https://docs.etherscan.io/supported-chains, https://docs.etherscan.io/resources/rate-limits, https://etherscan.io/apis, https://docs.etherscan.io/api-reference/endpoint/getlogs, https://docs.etherscan.io/api-pro/api-pro
tags: [etherscan, api, base, analytics]
status: published
---

# Etherscan 的套餐和覆盖范围，意味着什么

如果你只是把 Etherscan 当成“查交易的网址”，它看起来很简单。

但一旦你真的要把它用于链上分析，尤其是要做 Base 上的事件、历史余额、holder 结构这些东西，套餐、链覆盖和 endpoint 分层就会直接决定你能不能跑通。

这篇不讲情绪化评价，只把官方文档里最关键的事实拆开，看清楚三件事：

1. Etherscan 现在怎么收费。
2. 哪些链在免费层可用，哪些不行。
3. 对 Base 或其他支持链的分析场景，最小需要买到哪一档。

---

## 先给结论

如果你的目标只是让 Base 上的事件分析跑起来，`Lite` 基本够用。

如果你还想做历史余额、历史总供给、holder list 这类深挖，`Standard` 才是起步档。

更具体地说：

- **Base Mainnet 在 Free tier 里不可用**
- **事件日志接口 `getLogs` 是存在的**
- **ABI / 源码 / Verify Source Code 在所有链上都可用，包括 Free tier**
- **`getLogs` 这类 Base 事件能力，对应至少要 `Lite`**
- **历史类分析很多是 PRO endpoints，需要 `Standard` 及以上**

所以，问题不是“能不能看”，而是“看到什么层级、愿意为哪一层付费”。

---

## 套餐长什么样

Etherscan 官方当前公开的月费档位是：

| Plan | Price | Calls / second | Daily calls | Coverage |
|---|---:|---:|---:|---|
| Free | $0 | 3 | 100,000 | selected chains community endpoints |
| Lite | $49/mo | 5 | 100,000 | ALL supported chains community endpoints |
| Standard | $199/mo | 10 | 200,000 | ALL supported chains community endpoints + API Pro |
| Advanced | $299/mo | 20 | 500,000 | ALL supported chains community endpoints + API Pro |
| Professional | $399/mo | 30 | 1,000,000 | ALL supported chains community endpoints + API Pro |
| Pro Plus | $899/mo | 30 | 1,500,000 | ALL supported chains community endpoints + API Pro + Address Metadata |

这里最容易误读的一点是：

- `Free` 不是“所有链都能勉强用一点”
- `Lite` 才开始是“所有支持链的 community endpoints”
- `Standard` 才开始进入 `API Pro` endpoints

这意味着你要先分清两个维度：

1. **链是否覆盖**
2. **endpoint 是否属于 PRO**

这两个维度不是一回事。

### 官方支持链一览

按 Etherscan 官方 `Supported Chains` 页面，当前支持的链可以分成两组：

**Free tier 可用**

- Ethereum Mainnet
- Sepolia Testnet
- Hoodi Testnet
- Polygon Mainnet
- Polygon Amoy Testnet
- Arbitrum One Mainnet
- Arbitrum Sepolia Testnet
- Linea Mainnet
- Linea Sepolia Testnet
- Blast Mainnet
- Blast Sepolia Testnet
- BitTorrent Chain Mainnet
- BitTorrent Chain Testnet
- Celo Mainnet
- Celo Sepolia Testnet
- Fraxtal Mainnet
- Fraxtal Hoodi Testnet
- Gnosis
- Mantle Mainnet
- Mantle Sepolia Testnet
- Memecore Mainnet
- Memecore Insectarium Testnet
- Moonbeam Mainnet
- Moonriver Mainnet
- Moonbase Alpha Testnet
- opBNB Mainnet
- opBNB Testnet
- Taiko Mainnet
- Taiko Hoodi
- XDC Mainnet
- XDC Apothem Testnet
- ApeChain Mainnet
- ApeChain Curtis Testnet
- World Mainnet
- World Sepolia Testnet
- Sonic Mainnet
- Sonic Testnet
- Unichain Mainnet
- Unichain Sepolia Testnet
- Abstract Mainnet
- Abstract Sepolia Testnet
- Berachain Mainnet
- Berachain Bepolia Testnet
- Monad Mainnet
- Monad Testnet
- HyperEVM Mainnet
- Katana Mainnet
- Katana Bokuto
- Sei Mainnet
- Sei Testnet
- Stable Mainnet
- Stable Testnet
- Plasma Mainnet
- Plasma Testnet
- MegaETH Mainnet
- MegaETH Testnet

**Paid tier 可用，但 Free tier 不可用**

- BNB Smart Chain Mainnet
- BNB Smart Chain Testnet
- Base Mainnet
- Base Sepolia Testnet
- Optimism
- OP Sepolia Testnet
- Avalanche C-Chain
- Avalanche Fuji Testnet

---

## Base 的关键限制

Etherscan 官方支持链页面里写得很清楚：

- Ethereum Mainnet 的 Free tier 可用
- **Base Mainnet 的 Free tier 是 Not Available**
- Base Sepolia 的 Free tier 也是 Not Available

这就是为什么你在 Base 上尝试拉事件时间线或 recent events 时，如果底层依赖的是 Etherscan 免费层，会直接碰墙。

这里不是“Base 没数据”，而是“Base 不在免费覆盖范围内”。

这件事对分析工作的实际影响很直接：

- 只看合约静态信息，问题不大
- 只看当前状态，也通常能做
- 一旦要拉事件流，免费层就不够了

---

## 哪些接口属于哪一层

### 1. 能做事件日志，但要看链和套餐

`getLogs` 是官方提供的事件日志接口。

它的作用很明确：

- 按 address 拉事件
- 按 topics 拉事件
- 按 block range 拉事件

这类接口是做事件时间线、recent events、事件簇分析的基础。

但对 Base 来说，问题不在于接口有没有，而在于：

- Base Mainnet 免费层不可用
- 所以至少要 `Lite`

### 2. Free 可用的主要是源码、ABI 和验证接口

官方文档明确写到：

- 合约源码
- ABI
- Verify Source Code

这些 endpoint 在所有链、所有套餐都可用，包括 Free tier。

这意味着如果你只是要确认：

- 这是不是 `FiatTokenV2_2`
- 实现合约是谁
- 函数和事件长什么样

那免费层就够。

### 3. 只要碰到历史类数据，通常就是 PRO

Etherscan 的 PRO endpoints 列表里，最常见的几项是：

- 历史 ERC20 总供给
- 历史 ERC20 账户余额
- token holder list
- token holder count
- 地址当前持仓
- 历史原生币余额

这些能力对深度分析很重要，但官方把它们放在 `Standard` 及以上。

也就是说：

- 你要看“当前状态”，免费层可能够
- 你要看“历史轨迹”，通常就要 PRO

---

## 对 Base 分析到底意味着什么

如果你要把 Base 上的事件分析写成一篇完整文章，最好先按下面这条线判断预算。

### 只做事件观察

你只想看：

- `MinterConfigured`
- `Blacklisted`
- `UnBlacklisted`
- 其他治理/配置事件

那最小预算通常是：

- **Lite**

适合写：

- 最近发生了什么
- 哪些地址被反复调参
- 有没有事件簇
- 当前是否暂停

### 做历史深挖

你还想看：

- 历史总供给
- 历史余额
- holder list
- holder count
- 某个地址在过去某个区块的持仓

那就应该直接上：

- **Standard**

因为这些能力大多属于 PRO endpoints。

---

## 最容易踩的坑

### 坑 1：把“有事件接口”误解成“免费可用”

`getLogs` 有，不代表所有链在免费层都可用。

Base Mainnet 在 Free tier 就是 Not Available。

### 坑 2：把“基础可见性”误解成“全部分析能力”

ABI、源码、verify 这些是基础可见性。

但历史余额、holder list、历史 supply 是另一层能力。

### 坑 3：以为 `Lite` 已经能覆盖全部分析

`Lite` 只保证你拿到 ALL supported chains community endpoints。

如果你后面要做的东西已经进入 PRO endpoints，还是得升级。

---

## 我会怎么配预算

如果目标只是把 Base USDC 的事件线跑通，我会先买 `Lite`。

如果目标是做完整分析稿，我会直接上 `Standard`。

原因很现实：

1. `Lite` 能验证事件流是否可用。
2. `Standard` 能避免你写到一半才发现历史类数据不够。

如果你做的是持续分析，不是一次性验证，`Standard` 往往比反复补洞更省时间。

---

## 可复现查询路径

这篇判断主要基于官方文档，复现时可以直接看这几页：

- [Supported Chains](https://docs.etherscan.io/supported-chains)
- [Rate Limits](https://docs.etherscan.io/resources/rate-limits)
- [Get Event Logs by Address](https://docs.etherscan.io/api-reference/endpoint/getlogs)
- [PRO Endpoints](https://docs.etherscan.io/api-pro/api-pro)
- [Etherscan APIs](https://etherscan.io/apis)

如果你要把它接到任何分析工作流里，最实用的判断顺序是：

1. 先确认合约信息和当前状态。
2. 再看事件日志能不能拉到。
3. 最后再决定要不要上历史类 PRO endpoints。

---

## 结论

对 Base 这类分析场景来说，Etherscan 的关键不是“贵不贵”，而是“你要哪一层数据”。

如果只是事件观察，`Lite` 是最小可用档。

如果要做历史余额、holder、historical supply 这类深度分析，`Standard` 才是起点。

这也解释了一个很实际的问题：为什么 Ethereum 侧的分析可以先跑起来，而 Base 一碰事件层就要考虑套餐。

不是分析方法变了，是基础数据层的门槛变了。
