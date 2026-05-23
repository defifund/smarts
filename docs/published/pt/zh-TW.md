---
date: 2026-05-23
source: https://github.com/Polymarket/ctf-exchange, https://smarts.md/eth/0xe111180000d2663c0091e4f400237545b87b996b
contract: 0xe111180000d2663c0091e4f400237545b87b996b
tags: [polymarket, dex, gas-optimization, order-matching, ctf]
status: published
---

# 為什麼 COMPLEMENTARY 匹配在 Polymarket 上更便宜

Polymarket 上的每一筆交易，在合約層都會遇到一個選擇：要怎麼結算。

這個選擇會明顯影響最終的 gas 成本。它會影響流動性的分布、點差的緊度，也會影響市場的活躍度。

下面整理的是 **CTFExchange V2 中三條結算路徑**，以及代碼如何實作這些路徑。

---

## 三條穿過 CTFExchange 的路徑

兩個訂單在 Polymarket 相遇時，合約可以用三種方式結算。每種方式觸及不同的資產、不同的鏈上操作、不同的 gas 成本。

### 路徑 1：COMPLEMENTARY - 最低成本的情況

兩個交易者押注同一個二元事件，但方向相反。

- **交易者 A** 想以 0.60 USDC 買入 YES（願意付 0.60 每份）
- **交易者 B** 想以 0.60 USDC 賣出 YES（願意收 0.60 每份）

訂單相交時，**不需要額外觸發 mint/merge**。在這個例子裡，一方提供 collateral，另一方提供 outcome token。交換機制仍會參與結算，但不需要額外的 mint/merge 路徑，只要編排必要的資產轉移：

```
交易者 A：發送 0.60 USDC 給交易者 B
          從交易者 B 接收 YES tokens

交易者 B：發送 YES tokens 給交易者 A
          從交易者 A 接收 0.60 USDC
```

**總共 2 次轉帳**：一次抵押品，一次 outcome tokens。無需額外的 minting / merging。

**Gas 成本**：粗略估算為 ~2 個外部調用（ERC20/ERC1155 轉帳）。

### 路徑 2：MINT - 創建新頭寸

互補的訂單並不總是存在。很多情況下，市場需要創建新的 outcome tokens。

想像：

- **交易者 A** 想以 0.60 USDC 買入 YES
- **交易者 C** 想以 0.40 USDC 買入 NO

Polymarket 的底層結算層（Gnosis Conditional Tokens）是成對運作的：mint 一個 outcome token 時，會同時 mint 它的 complement。

當交易者 A 和 C 相遇時：

```
交換機制收到：
  - 0.60 USDC（來自買家 A）
  - 0.40 USDC（來自買家 C）

交換機制調用 Conditional Tokens 的 MINT：
  - 提供 1.00 USDC 抵押品
  - 接收 1 份 YES + 1 份 NO

交換機制然後分配：
  - YES 給交易者 A
  - NO 給交易者 C
  - 淨收益給各自的交易者
```

合約會 **批次處理所有 MINT 調用** — 如果五個訂單同時匹配，合約 mint 一次而非五次。

**Gas 成本**：粗略估算為 ~5 次外部調用（轉帳 + 一次批次 mint）+ conditional token 開銷。

### 路徑 3：MERGE - 平倉頭寸

MINT 的反面。當交易者想通過同時賣出互補的兩個 outcome 來退出時，交換機制可以調用 MERGE 將它們銷毀並返還抵押品。

合約也會把多個 MERGE 請求批次處理成一次調用，而不是每筆都單獨 merge。

**Gas 成本**：粗略估算為 ~5 次外部調用（轉帳 + 一次批次 merge）+ conditional token 開銷。

---

## 為什麼這個差異那麼重要

數字先說：

| 結算類型 | 轉帳次數 | CTF 操作 | 約 Gas（Polygon） |
|---|---|---|---|
| **COMPLEMENTARY** | 2 | 0 | 50–80K |
| **MINT** | 5–6 | 1 | 180–250K |
| **MERGE** | 5–6 | 1 | 180–250K |

COMPLEMENTARY 匹配的 gas 成本 **比 MINT/MERGE 低 60–70%**。

如果只看 gas 使用量，COMPLEMENTARY 約為 `50k–80k`，MINT / MERGE 約為 `180k–250k`。按當前 Polygon 生態原生代幣價格換算，單筆美元成本會非常低，通常可忽略到分以下的量級。

對頻繁交易的人來說，這種差異會體現在累積成本上。

---

## 使這一切成為可能的代碼架構

CTFExchange V2 的 `Trading.sol` mixin 包含了三條路徑的所有邏輯。以下是使它運作的關鍵：

### 訂單匹配分發

```solidity
function _deriveMatchType(Order memory takerOrder, Order memory makerOrder)
    internal pure returns (MatchType) {
    // MatchType.COMPLEMENTARY: 相同 tokenId，相反方向
    // MatchType.MINT: BUY + BUY
    // MatchType.MERGE: SELL + SELL
}
```

交換機制在匹配時會根據訂單方向決定結算路徑。邏輯上：如果兩個訂單都引用同一個 outcome token 且方向相反，就是 COMPLEMENTARY；否則是 MINT 或 MERGE。

### COMPLEMENTARY 優化

對於 COMPLEMENTARY 匹配，合約不需要額外的 mint/merge 路徑。

```solidity
function _settleComplementary(...) internal {
    for (uint256 i = 0; i < makerOrders.length; ++i) {
        // Taker BUY ↔ Maker SELL: 雙向直接轉帳
        _transfer(makerOrder.maker, taker, makerOrder.tokenId, fillAmount);
        _transfer(taker, makerOrder.maker, 0, collateralProceeds);
    }
}
```

而不是：

```
（很多通用 DEX 的常見路徑）
Taker -> Exchange -> Maker
Maker -> Exchange -> Taker
```

它這樣做：

```
（Polymarket 的直接結算路徑）
Taker <-> Maker  （直接）
```

這 **每次匹配節省 ~3 次轉帳**；匹配數量增加時，累積差異會更明顯。

### 批次處理 CTF 操作

對於 MINT 和 MERGE，Polymarket 把所有 conditional token 的創建/銷毀合併成一次調用：

```solidity
// 第一階段：驗證所有 maker orders
for (uint256 i = 0; i < length; ++i) {
    prepared[i] = _prepareMakerOrder(...);
    if (matchType == MatchType.MINT) {
        totalMintAmount += prepared[i].takingAmount;
    }
}

// 第二階段：一次批次 MINT 調用
if (totalMintAmount > 0) _mint(conditionId, totalMintAmount);

// 第三階段：分配收益
for (uint256 i = 0; i < length; ++i) {
    _distributeMintProceeds(prepared[i], ...);
}
```

如果五個訂單需要 mint，合約：
1. 驗證全部五個
2. 在 **一次調用中** mint 全部（1000 wei vs 5 × 1000 wei 如果分開）
3. 分配收益

Gas 節省更接近「固定開銷被攤薄」的效果：匹配越多，單筆平均成本越低，但不是對數關係。

---

## 由此產生的市場拓撲

這些成本差異會影響流動性分布。

### 在二元市場（相同 outcome，相反方向）

如果交易者 A（買 YES @ 0.60）遇到交易者 B（賣 YES @ 0.60），結算是 **COMPLEMENTARY**，對應的 gas 使用量通常落在較低區間。

當互補匹配占比更高時，交易者更容易接受更小的點差，流動性也更容易聚集。

### 在對沖市場（不同 outcomes）

如果交易者 A（買 outcome-1）遇到交易者 C（賣 outcome-2），結算需要 MINT，gas 使用量通常更高。

如果需要走 MINT，成本會更高，點差也會更寬。

這個成本差異來自 Polymarket 的結算結構：更容易形成互補匹配的市場，結算成本更低，因此點差往往更緊；互補流動較少的市場成本更高。

---

## 匯編層

CTFExchange 還會更深。代碼在幾個關鍵路徑中使用 **Solidity assembly** 來壓榨 gas：

### 將 OrderStatus 打包到一個存儲槽

```solidity
// 單次 SLOAD：讀取打包槽並同時提取 filled 和 remaining
bool filled;
uint256 remaining;
assembly {
    let packed := sload(status.slot)
    filled := and(packed, 0xff)
    remaining := shr(8, packed)
}
```

不是在兩個分開的存儲槽中存儲 `filled` 和 `remaining`（兩次 SLOAD 成本），合約把兩者打包成一個 256 位的字。一次 SLOAD 同時檢索兩者。

### 無分支地推導資產 ID

```solidity
// SIDE * tokenId, tokenId - SIDE * tokenId
// buy:  0, tokenId
// sell: tokenId, 0
assembly {
    makerAssetId := mul(side, tokenId)
    takerAssetId := sub(tokenId, makerAssetId)
}
```

與其 `if (side == BUY) { makerAssetId = 0; } else { makerAssetId = tokenId; }`，代碼使用純算術。這樣可以減少條件分支和控制流開銷，更適合 EVM 的執行模型。

### 檢查所有 Maker 是否都是 Complementary

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

這檢查每個 maker 是否與 taker 方向相反 — **單次早期退出**，如果任何 maker 匹配。無中間陣列。無額外分配。

---

## 對交易者和 LP 的含義

### 對交易者來說

- 在你期望互補訂單匹配的市場上交易，預期廉價結算、緊點差。
- 在匹配需要 MINT/MERGE 的市場上交易，預期更高的成本和更寬的點差。

一些交易者會把大訂單拆開，以提高互補匹配的機率。

### 對做市商來說

在活躍市場裡，放在更容易被互補匹配到的位置，會帶來：
- 較低的實現執行成本
- 更緊的買賣點差來競爭
- 更高的成交量才能盈利

在同一市場裡，位置更遠的訂單更容易觸發 MINT/MERGE，因此成本更高，報價也會更寬。

Polymarket 上看到的點差，與結算路徑成本結構有關。

### 對研究者來說

如果一個市場的訂單流主要是 COMPLEMENTARY，可以觀察到：
- 成熟的雙向流動性
- 低點差、高成交、高效
- 小頭寸輪轉

如果一個市場的訂單流主要是 MINT/MERGE，可以觀察到：
- 新興市場、單向流
- 擴大的點差
- 對沖密集活動（人們平倉、不是重新定位）

在鏈上追蹤結算路徑，可以幫助觀察市場結構的變化。

---

## 使市場運作的成本不對稱性

最後，Polymarket 的三條結算路徑形成了一個隱性的成本差異結構，並不需要額外顯式費用。

由於 COMPLEMENTARY 更便宜、MINT/MERGE 更貴，協議在結構上會偏向：
- **雙向訂單流** - 已是相反頭寸的訂單因更低成本而獲得獎勵
- **深度** - 放在可能自然相交的地方的訂單結算成本更低
- **頭寸回轉** - 來回翻轉（買入後賣出相同 outcome）的頭寸總體成本較低

這些差異來自架構本身，而不是額外收費。它們反映了不同路徑上的計算和轉帳工作量。

理解這一點的交易者，可以更有針對性地安排訂單。理解這一點的做市商，可以更好地判斷點差如何變化。

對於關注 Polymarket 的研究者，這三條路徑提供了一個觀察合約使用方式的切入點。

---

## 後續步驟

要在鏈上驗證這些模式：

1. 從 CTFExchange V2（Polygon 上的 0xe111...b96b）查詢最近的 `OrderFilled` 事件
2. 對於每個匹配，先看 side 是否同向，再用 tokenId 區分 COMPLEMENTARY 與其他兩類
3. 比較 gas 成本：你應該看到 COMPLEMENTARY 匹配大致低於 MINT/MERGE
4. 將 gas 成本映射到實現點差：COMPLEMENTARY 率較高的市場點差更緊

這些數據可以用來驗證結算路徑與市場結構之間的關係。
