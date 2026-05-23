---
date: 2026-05-23
source: https://github.com/Polymarket/ctf-exchange, https://smarts.md/eth/0xe111180000d2663c0091e4f400237545b87b996b
contract: 0xe111180000d2663c0091e4f400237545b87b996b
tags: [polymarket, dex, gas-optimization, order-matching, ctf]
status: published
---

# Polymarket 订单成本拆解：为什么 COMPLEMENTARY 匹配省 gas

Polymarket 上的每一笔交易，在合约层都面临一个隐形选择：如何结算。

这个选择会明显影响最终的 gas 成本。它会影响流动性的分布、点差的紧度，也会影响市场的活跃度。

下面整理的是 **CTFExchange V2 中三条结算路径**，以及代码如何实现这些路径。

---

## 三条穿过 CTFExchange 的路径

两个订单在 Polymarket 相遇时，合约可以用三种方式结算。每种方式触及不同的资产、不同的链上操作、不同的 gas 成本。

### 路径 1：COMPLEMENTARY — 最省成本的情况

两个交易者押注同一个二元事件，但方向相反。

- **交易者 A** 想以 0.60 USDC 买入 YES（愿意付 0.60 每份）
- **交易者 B** 想以 0.60 USDC 卖出 YES（愿意收 0.60 每份）

订单相交时，**不需要额外触发 mint/merge**。在这个例子里，一方提供 collateral，另一方提供 outcome token。交换机制参与结算，但避免了 mint/merge 的额外链上操作，只需要编排必要的资产转移：

```
交易者 A：发送 0.60 USDC 给交易者 B
          从交易者 B 接收 YES tokens

交易者 B：发送 YES tokens 给交易者 A
          从交易者 A 接收 0.60 USDC
```

**总共 2 次转账**：一次抵押品，一次 outcome tokens。无需额外的 minting / merging。

**Gas 成本**：粗略估算为 ~2 个外部调用（ERC20/ERC1155 转账）。

### 路径 2：MINT — 创建新头寸

互补的订单并不总是存在。很多情况下，市场需要创建新的 outcome tokens。

想象：

- **交易者 A** 想以 0.60 USDC 买入 YES
- **交易者 C** 想以 0.40 USDC 买入 NO

Polymarket 的底层结算层（Gnosis Conditional Tokens）是成对工作的：mint 一个 outcome token 时，会同时 mint 它的 complement。

当交易者 A 和 C 相遇时：

```
交换机制收到：
  - 0.60 USDC（来自买家 A）
  - 0.40 USDC（来自买家 C）

交换机制调用 Conditional Tokens 的 MINT：
  - 提供 1.00 USDC 抵押品
  - 接收 1 份 YES + 1 份 NO

交换机制然后分配：
  - YES 给交易者 A
  - NO 给交易者 C
  - 净收益给各自的交易者
```

合约会 **批量处理所有 MINT 调用** — 如果五个订单同时匹配，合约 mint 一次而非五次。

**Gas 成本**：粗略估算为 ~5 次外部调用（转账 + 一次批处理 mint）+ conditional token 开销。

### 路径 3：MERGE — 平仓头寸

MINT 的反面。当交易者想通过同时卖出互补的两个 outcome 来退出时，交换机制可以调用 MERGE 将它们销毁并返还抵押品。

合约也会把多个 MERGE 请求批量处理成一次调用，而不是每笔都单独 merge。

**Gas 成本**：粗略估算为 ~5 次外部调用（转账 + 一次批处理 merge）+ conditional token 开销。

---

## 为什么这个差异那么重要

数字说话：

| 结算类型 | 转账次数 | CTF 操作 | 约 Gas（Polygon） |
|---|---|---|---|
| **COMPLEMENTARY** | 2 | 0 | 50–80K |
| **MINT** | 5–6 | 1 | 180–250K |
| **MERGE** | 5–6 | 1 | 180–250K |

COMPLEMENTARY 匹配的 gas 成本 **比 MINT/MERGE 低 60–70%**。

如果只看 gas 使用量，COMPLEMENTARY 约为 `50k–80k`，MINT / MERGE 约为 `180k–250k`。按当前 Polygon 生态的原生代币价格换算，单笔美元成本会非常低，通常可以忽略到分的量级以下。

对频繁交易的人来说，这种差异会体现在累计成本上。

---

## 使这一切成为可能的代码架构

CTFExchange V2 的 `Trading.sol` mixin 包含了三条路径的所有逻辑。以下是使其工作的关键：

### 订单匹配分发

```solidity
function _deriveMatchType(Order memory takerOrder, Order memory makerOrder) 
    internal pure returns (MatchType) {
    // MatchType.COMPLEMENTARY: 相同 tokenId，相反方向
    // MatchType.MINT: BUY + BUY
    // MatchType.MERGE: SELL + SELL
}
```

交换机制在匹配时会根据订单方向决定结算路径。逻辑上：如果两个订单都引用同一个 outcome token 且方向相反，就是 COMPLEMENTARY；否则是 MINT 或 MERGE。

### COMPLEMENTARY 优化

对于 COMPLEMENTARY 匹配，合约不需要额外的 mint/merge 路径。

```solidity
function _settleComplementary(...) internal {
    for (uint256 i = 0; i < makerOrders.length; ++i) {
        // Taker BUY ↔ Maker SELL: 双向直接转账
        _transfer(makerOrder.maker, taker, makerOrder.tokenId, fillAmount); 
        _transfer(taker, makerOrder.maker, 0, collateralProceeds);
    }
}
```

而不是：

```
（很多通用 DEX 的常见路径）
Taker → Exchange → Maker
Maker → Exchange → Taker
```

它这样做：

```
（Polymarket 的直接结算路径）
Taker ⟷ Maker  （直接）
```

这 **每次匹配节省 ~3 次转账**；匹配数量增加时，累计差异会更明显。

### 批处理 CTF 操作

对于 MINT 和 MERGE，Polymarket 把所有 conditional token 的创建/销毁合并成一次调用：

```solidity
// 第一阶段：验证所有 maker orders
for (uint256 i = 0; i < length; ++i) {
    prepared[i] = _prepareMakerOrder(...);
    if (matchType == MatchType.MINT) {
        totalMintAmount += prepared[i].takingAmount;
    }
}

// 第二阶段：一次批处理 MINT 调用
if (totalMintAmount > 0) _mint(conditionId, totalMintAmount);

// 第三阶段：分配收益
for (uint256 i = 0; i < length; ++i) {
    _distributeMintProceeds(prepared[i], ...);
}
```

如果五个订单需要 mint，合约：
1. 验证全部五个
2. 在 **一次调用中** mint 全部（1000 wei vs 5 × 1000 wei 如果分开）
3. 分配收益

Gas 节省更接近“固定开销被摊薄”的效果：匹配越多，单笔平均成本越低，但不是对数关系。

---

## 由此产生的市场拓扑

这些成本差异会影响流动性分布。

### 在二元市场（相同 outcome，相反方向）

如果交易者 A（买 YES @ 0.60）遇到交易者 B（卖 YES @ 0.60），结算是 **COMPLEMENTARY**，对应的 gas 使用量通常落在较低区间。

当互补匹配占比更高时，交易者更容易接受更小的点差，流动性也更容易聚集。

### 在对冲市场（不同 outcomes）

如果交易者 A（买 outcome-1）遇到交易者 C（卖 outcome-2），结算需要 MINT，gas 使用量通常更高。

如果需要走 MINT，成本会更高，点差也会更宽。

这个成本差异来自 Polymarket 的结算结构：更容易形成互补匹配的市场，结算成本更低，因此点差往往更紧；互补流动较少的市场成本更高。

---

## 汇编层

CTFExchange 还会更深。代码在几个关键路径中使用 **Solidity assembly** 来压榨 gas：

### 将 OrderStatus 打包到一个存储槽

```solidity
// 单次 SLOAD：读取打包槽并同时提取 filled 和 remaining
bool filled;
uint256 remaining;
assembly {
    let packed := sload(status.slot)
    filled := and(packed, 0xff)
    remaining := shr(8, packed)
}
```

不是在两个分开的存储槽中存储 `filled` 和 `remaining`（两次 SLOAD 成本），合约把两者打包成一个 256 位的字。一次 SLOAD 同时检索两者。

### 无分支地推导资产 ID

```solidity
// SIDE * tokenId, tokenId - SIDE * tokenId
// buy:  0, tokenId
// sell: tokenId, 0
assembly {
    makerAssetId := mul(side, tokenId)
    takerAssetId := sub(tokenId, makerAssetId)
}
```

与其 `if (side == BUY) { makerAssetId = 0; } else { makerAssetId = tokenId; }`，代码使用纯算术。这样可以减少条件分支和控制流开销，更适合 EVM 的执行模型。

### 检查所有 Maker 是否都是 Complementary

```solidity
assembly {
    result := 1
    let length := mload(makerOrders)
    let ptr := add(makerOrders, 0x20)
    for { let i := 0 } lt(i, length) { i := add(i, 1) } {
        let orderPtr := mload(add(ptr, shl(5, i)))
        let side := mload(add(orderPtr, 0xC0))
        if eq(side, takerSide) {
            result := 0
            break
        }
    }
}
```

这检查每个 maker 是否与 taker 方向相反 — **单次早期退出**，如果任何 maker 匹配。无中间数组。无额外分配。

---

## 对交易者和 LP 的含义

### 对交易者来说

- 在你期望互补订单匹配的市场上交易？预期廉价结算、紧点差。
- 在匹配需要 MINT/MERGE 的市场上交易，预期更高的成本和更宽的点差。

一些交易者会把大订单拆开，以提高互补匹配的概率。

### 对做市商来说

在活跃市场里，放在更容易被互补匹配到的位置，会带来：
- 较低的实现执行成本
- 更紧的买卖点差来竞争
- 更高的成交量才能盈利

在同一市场里，位置更远的订单更容易触发 MINT/MERGE，因此成本更高，报价也会更宽。

Polymarket 上看到的点差，与结算路径成本结构有关。

### 对研究者来说

如果一个市场的订单流主要是 COMPLEMENTARY，可以观察到：
- 成熟的双向流动性
- 低点差、高成交、高效
- 小头寸轮转

如果一个市场的订单流主要是 MINT/MERGE，可以观察到：
- 新兴市场、单向流
- 扩大的点差
- 对冲密集活动（人们平仓、不是重新定位）

在链上追踪结算路径，可以帮助观察市场结构的变化。

---

## 使市场运作的成本不对称性

最后，Polymarket 的三条结算路径形成了一个隐性的成本差异结构，并不需要额外显式费用。

由于 COMPLEMENTARY 更便宜、MINT/MERGE 更贵，协议在结构上会偏向：
- **双向订单流** — 已是相反头寸的订单因更低成本而获得奖励
- **深度** — 放在可能自然相交的地方的订单结算成本更低
- **头寸回转** — 来回翻转（买入后卖出相同 outcome）的头寸总体成本较低

这些差异来自架构本身，而不是额外收费。它们反映了不同路径上的计算和转账工作量。

理解这一点的交易者，可以更有针对性地安排订单。理解这一点的做市商，可以更好地判断点差如何变化。

对于关注 Polymarket 的研究者，这三条路径提供了一个观察合约使用方式的切入点。

---

## 后续步骤

要在链上验证这些模式：

1. 从 CTFExchange V2（Polygon 上的 0xe111...b96b）查询最近的 `OrderFilled` 事件
2. 对于每个匹配，先看 side 是否同向，再用 tokenId 区分 COMPLEMENTARY 与其他两类
3. 比较 gas 成本：你应该看到 COMPLEMENTARY 匹配大致低于 MINT/MERGE
4. 将 gas 成本映射到实现点差：COMPLEMENTARY 率较高的市场点差更紧

这些数据可以用来验证结算路径与市场结构之间的关系。
