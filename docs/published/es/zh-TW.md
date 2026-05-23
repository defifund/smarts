---
date: 2026-05-22
source: https://docs.etherscan.io/supported-chains, https://docs.etherscan.io/resources/rate-limits, https://etherscan.io/apis, https://docs.etherscan.io/api-reference/endpoint/getlogs, https://docs.etherscan.io/api-pro/api-pro
tags: [etherscan, api, base, analytics]
status: published
---

# Etherscan 的方案和覆蓋範圍，意味著什麼

如果你只是把 Etherscan 當成「查交易的網站」，它看起來很簡單。

但一旦你真的要把它用在鏈上分析，尤其是要做 Base 上的事件、歷史餘額、holder 結構這些東西，方案、鏈覆蓋和 endpoint 分層會直接決定你的流程能不能跑通。

這篇不做情緒化評價，只把官方文件裡最關鍵的事實拆開，看清楚三件事：

1. Etherscan 現在怎麼收費。
2. 哪些鏈在免費層可用，哪些不行。
3. 對 Base 或其他支援鏈的分析場景，最小需要買到哪一檔。

---

## 先給結論

如果你的目標只是讓 Base 上的事件分析跑起來，`Lite` 基本夠用。

如果你還想做歷史餘額、歷史總供給、holder list 這類深挖，`Standard` 才是起步檔。

更具體地說：

- **Base Mainnet 在 Free tier 裡不可用**
- **事件日誌接口 `getLogs` 是存在的**
- **ABI / 源碼 / Verify Source Code 在所有鏈上都可用，包括 Free tier**
- **`getLogs` 這類 Base 事件能力，對應至少要 `Lite`**
- **很多歷史類分析是 PRO endpoints，需要 `Standard` 及以上**

所以，問題不是「能不能看」，而是「能看到什麼層級、願意為哪一層付費」。

---

## 方案長什麼樣

Etherscan 官方目前公開的月費檔位是：

| Plan | Price | Calls / second | Daily calls | Coverage |
|---|---:|---:|---:|---|
| Free | $0 | 3 | 100,000 | selected chains community endpoints |
| Lite | $49/mo | 5 | 100,000 | ALL supported chains community endpoints |
| Standard | $199/mo | 10 | 200,000 | ALL supported chains community endpoints + API Pro |
| Advanced | $299/mo | 20 | 500,000 | ALL supported chains community endpoints + API Pro |
| Professional | $399/mo | 30 | 1,000,000 | ALL supported chains community endpoints + API Pro |
| Pro Plus | $899/mo | 30 | 1,500,000 | ALL supported chains community endpoints + API Pro + Address Metadata |

這裡最容易誤讀的一點是：

- `Free` 不是「所有鏈都能勉強用一點」
- `Lite` 才開始是「所有支援鏈的 community endpoints」
- `Standard` 才開始進入 `API Pro` endpoints

這代表你要先分清兩個維度：

1. 鏈是否覆蓋
2. endpoint 是否屬於 PRO

這兩件事不是同一回事。

### 官方支援鏈一覽

按 Etherscan 官方 `Supported Chains` 頁面，現在支援的鏈可以分成兩組：

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

## Base 的關鍵限制

Etherscan 官方支援鏈頁面寫得很清楚：

- Ethereum Mainnet 的 Free tier 可用
- **Base Mainnet 的 Free tier 是 Not Available**
- Base Sepolia 的 Free tier 也不是可用

這就是為什麼你在 Base 上嘗試拉事件時間線或 recent events 時，如果底層依賴的是 Etherscan 免費層，就會直接撞牆。

這裡不是「Base 沒資料」，而是「Base 不在免費覆蓋範圍內」。

這件事對分析工作的實際影響很直接：

- 只看合約靜態資訊，問題不大
- 只看目前狀態，也通常能做
- 一旦要拉事件流，免費層就不夠了

---

## 哪些接口屬於哪一層

### 1. 能做事件日誌，但要看鏈和方案

`getLogs` 是 Etherscan 的事件日誌接口。

它的作用很清楚：

- 按 address 拉事件
- 按 topics 拉事件
- 按 block range 拉事件

這類接口是做事件時間線、recent events、事件簇分析的基礎。

但對 Base 來說，問題不在於接口有沒有，而在於：

- Base Mainnet Free tier 不可用
- 所以至少要 `Lite`

### 2. Free 可用的主要是來源碼、ABI 和驗證接口

官方文件明確寫到：

- 合約源碼
- ABI
- Verify Source Code

這些 endpoint 在所有鏈、所有方案都可用，包括 Free tier。

這代表如果你只是要確認：

- 這是不是 `FiatTokenV2_2`
- 實現合約是誰
- 函式和事件長什麼樣

那免費層就夠。

### 3. 一旦碰到歷史類資料，通常就是 PRO

Etherscan 的 PRO endpoints 裡，最常見的幾項是：

- 歷史 ERC20 總供給
- 歷史 ERC20 帳戶餘額
- token holder list
- token holder count
- 地址當前持倉
- 歷史原生幣餘額

這些能力對深度分析很重要，但官方把它們放在 `Standard` 及以上。

也就是說：

- 你要看「目前狀態」，免費層可能夠
- 你要看「歷史軌跡」，通常就要 PRO

---

## 對 Base 分析到底意味著什麼

如果你要把 Base 上的事件分析寫成一篇完整文章，最好先按下面這條線判斷預算。

### 只做事件觀察

你只想看：

- `MinterConfigured`
- `Blacklisted`
- `UnBlacklisted`
- 其他治理 / 配置事件

那最小預算通常是：

- **Lite**

適合寫：

- 最近發生了什麼
- 哪些地址被反覆調參
- 有沒有事件簇
- 目前是否暫停

### 做歷史深挖

你還想看：

- 歷史總供給
- 歷史餘額
- holder list
- holder count
- 某個地址在過去某個區塊的持倉

那就應該直接上：

- **Standard**

因為這些能力大多屬於 PRO endpoints。

---

## 最容易踩的坑

### 坑 1：把「有事件接口」誤解成「免費可用」

`getLogs` 有，不代表所有鏈在免費層都可用。

Base Mainnet 在 Free tier 就是 Not Available。

### 坑 2：把「基礎可見性」誤解成「全部分析能力」

ABI、源碼、verify 這是基礎可見性。

但歷史餘額、holder list、歷史 supply 是另一層能力。

### 坑 3：以為 `Lite` 已經能覆蓋全部分析

`Lite` 只保證你拿到 ALL supported chains community endpoints。

如果你後面要做的東西已經進入 PRO endpoints，還是得升級。

---

## 我會怎麼配預算

如果目標只是把 Base USDC 的事件線跑通，我會先買 `Lite`。

如果目標是做完整分析稿，我會直接上 `Standard`。

原因很現實：

1. `Lite` 能驗證事件流是否可用。
2. `Standard` 能避免你寫到一半才發現歷史類資料不夠。

如果你做的是持續分析，不是一次性驗證，`Standard` 往往比反覆補洞更省時間。

---

## 可復現查詢路徑

這篇判斷主要基於官方文件，復現時可以直接看這幾頁：

- [Supported Chains](https://docs.etherscan.io/supported-chains)
- [Rate Limits](https://docs.etherscan.io/resources/rate-limits)
- [Get Event Logs by Address](https://docs.etherscan.io/api-reference/endpoint/getlogs)
- [PRO Endpoints](https://docs.etherscan.io/api-pro/api-pro)
- [Etherscan APIs](https://etherscan.io/apis)

如果你要把它接到任何分析工作流裡，最實用的判斷順序是：

1. 先確認合約資訊和目前狀態。
2. 再看事件日誌能不能拉到。
3. 最後再決定要不要上歷史類 PRO endpoints。

---

## 結論

對 Base 這類分析場景來說，Etherscan 的關鍵不是「貴不貴」，而是「你要哪一層資料」。

如果只是事件觀察，`Lite` 是最小可用檔。

如果要做歷史餘額、holder、historical supply 這類深度分析，`Standard` 才是起點。

這也解釋了一個很實際的問題：為什麼 Ethereum 端的分析可以先跑起來，而 Base 一碰事件層就要考慮方案。

不是分析方法變了，是基礎資料層的門檻變了。
