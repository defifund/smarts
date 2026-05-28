# Smarts 現已覆蓋 50 條 EVM 鏈：從以太坊到長尾生態的完整地圖

2026 年 5 月，我們達成了一個里程碑：**Smarts 正式支援 50 條 EVM 鏈**。

這不是一個虛榮數字。這意味著，無論開發者是在 Ethereum、Base、Arbitrum 這樣的主流 L2 上工作，還是在 Berachain、Monad、HyperEVM 這樣的新興生態裡實驗，他們都能在一個地方查詢已驗證合約的原始碼、ABI 和 AI 生成的函式說明。在 6 條主流鏈上，還能讀取即時鏈上狀態、近期事件和治理風險。

## 地圖的構成

我們的 50 條鏈不是平等的。它們分為兩層：

**第一層：6 條主流鏈（Tier 1）**——完整能力
- Ethereum、Base、Arbitrum One、Optimism、BNB Smart Chain、Polygon PoS
- 這些鏈支援 **live state** 查詢：任何 view 函式的即時值、近期事件、治理活動、admin 風險分析
- 開發者和 AI agent 可以秒級取得「這個池子現在的價格是多少」、「Aave 的風險參數是什麼」

**第二層：44 條其他鏈（Tier 2）**——原始碼 + ABI

**Mainnet（23 條）：**
Linea、Unichain、Berachain、Blast、Sonic、Mantle、Gnosis、Celo、Fraxtal、Taiko、World Chain、Abstract、Moonbeam、Moonriver、opBNB、XDC、Monad、HyperEVM、Katana、Sei、Stable、Plasma、MegaETH

**測試網（21 條）：**
Ethereum Sepolia、Hoodi、Polygon Amoy、Arbitrum Sepolia、Linea Sepolia、Blast Sepolia、Celo Sepolia、Fraxtal Hoodi、Moonbase Alpha、opBNB Testnet、XDC Apothem、Unichain Sepolia、World Chain Sepolia、Berachain Bepolia、Monad Testnet、HyperEVM Testnet、Katana Bokuto、Sei Testnet、Stable Testnet、Plasma Testnet、MegaETH Testnet

這一層不透過 RPC 查鏈上即時狀態，而是直接從 Etherscan 讀取已驗證合約的原始碼和 ABI。

## 為什麼要覆蓋長尾

傳統的合約文件工具有一個隱含假設：只有頭部協議值得關注。

Etherscan 本身驗證了數百萬個合約，但 95% 的使用者只查 Top 100。文件平台（Mintlify）要求每個專案方手寫文件，所以它們多半只存在於已融資的協議。

但現實中，**長尾是活躍的**。

新興 L2（Berachain、Monad、Sonic）上有創新的 DeFi 原語。Unichain、World Chain 這樣的垂直鏈吸引了特定社群的開發者。Farcaster、Lens 生態的合約需要審計。一個 AI agent 或研究員想全景理解某個市場時，需要的不是「只有 6 條大鏈」，而是「整個 EVM 的完整可訪問性」。

Smarts 讓這成為可能。開發者不再需要在 6 條鏈上用 Etherscan，在 Linea 上又換一個工具。**一個 MCP 端點，50 條鏈的統一查詢介面。**

## 這對 AI 改變了什麼

Smarts 最強的地方，不在網頁介面，而在 MCP。

當開發者在 Claude Code 或 Cursor 裡問：「Base 上這個 Uniswap V3 池子的價格和流動性是多少？」Claude 可以直接呼叫 Smarts 的 MCP 工具返回即時資料和函式說明。不需要：
- 查 Etherscan
- 手讀 Solidity
- 再問 Claude「幫我理解這段程式碼」

**50 條鏈的支援**意味著這個工作流覆蓋了 EVM 全生態的文件入口。在 Sonic 上研究 DeFi？在 Celo 上審計 RWA？在 Abstract 上學 AA？Claude 可以直接讀取已驗證原始碼、ABI 和函式說明；在 Tier 1 鏈上，還可以繼續讀取即時狀態和事件。

## 技術上的槓桿

為什麼 Smarts 能跨越 50 條鏈？

關鍵在於**分層設計**的槓桿：
- 6 條主流鏈需要 RPC 成本和維護。但這 6 條鏈覆蓋了主流 DeFi 流動性和最高頻的合約查詢場景。
- 其餘 44 條鏈從 Etherscan 讀取已驗證合約的原始碼和 ABI，新增鏈的主要成本是登記鏈配置和驗證索引流程。

這是競爭對手做不到的。Etherscan 是中心化服務，Mintlify 需要每個團隊手寫，Dune 需要開發者自己寫 SQL。只有純 AI + 鏈上查詢的組合，才能在這樣的規模裡覆蓋整個生態。

## 接下來

50 條鏈是現狀。但這只是開始。

我們已經支援了 Uniswap V3 和通用 ERC-20/ERC-721 的完整適配器。接下來正在為 Polymarket、更多 DEX 和借貸協議構建專屬適配器。這些適配器會讓合約文件從「給我看原始碼和 ABI」升級到「給我看這個池的即時交易費、這個期權市場的當前賠率」。

長期看，**Smarts 的目標是成為 EVM 生態的統一知識庫**——不只是文件，而是任何人（開發者、研究員、AI agent）理解任何合約的最快路徑。

50 條鏈只是這個願景的基礎設施。真正的價值，會在接下來的協議適配器和 AI 工作流優化裡體現。

---

**在 Smarts 上看看：** 從 [https://smarts.md/usdc-eth](https://smarts.md/usdc-eth) 開始，或者在任何支援的 50 條鏈上試試。

**在 Claude Code 裡用：** 在 [https://mcp.smarts.md/](https://mcp.smarts.md/) 安裝 Smarts MCP server，問 Claude 已驗證合約的原始碼、ABI 和函式問題；在 Tier 1 鏈上，還可以繼續查詢即時狀態、事件和風險。
