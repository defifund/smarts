---
date: 2026-05-26
source: https://smarts.md/ MCP (get_contract_info / get_admin_risk / get_erc20_info / read_contract_state / get_contract_source / get_governance_timeline)
contract: 0x8d0d000ee44948fc98c9b98a4fa4921476f08b0d (StablecoinV2)
verified_block: 25182415
tags: [stablecoin, usd1, smart-contract, risk, smarts]
status: draft
---

# USD1 的控制棧：mint、freeze 和簽名轉帳

合約：`0x8d0d000ee44948fc98c9b98a4fa4921476f08b0d`（`StablecoinV2`）

代理實作：`0x694aa534bdef8ed63244eb902e7914e527891f08`

表面規模：`19 view / 23 write / 17 events`

當前快照：

截至區塊 `25182415`：

- `name = World Liberty Financial USD`
- `symbol = USD1`
- `decimals = 18`
- 現有供應量 = `1,922,063,260.45 USD1`
- 現價 = 約 `$0.9985087024`
- 市值 = 約 `$1,919,196,892.24`
- `paused = false`
- 治理時間線 = 總共 `1` 筆事件，只有 `Initialized(version 2)`，區塊 `24809916`

從外面看，USD1 像是一枚普通美元穩定幣。
但合約展開後能看到一套更大的控制棧。

它是一個可升級的穩定幣實作，帶有 owner 級別的 mint / burn，全套 pause / freeze 控制，凍結資金的回收路徑，以及簽名授權轉帳流程。換句話說，它不是單純的餘額表，而是一套可營運的資金系統。

真正該問的不是 USD1 能不能轉帳。
它當然能。
更重要的是：除了普通 `transfer` 之外，它還暴露了哪些路徑、誰能觸發這些路徑、哪些狀態變化會留下鏈上痕跡。

---

## 先說結論

USD1 和普通 ERC-20 的差別主要體現在三點。

1. 它有明確的管理面：`mint`、`burn`、`freeze`、`unfreeze`、`pause`、`unpause`、`drain`、`reallocate`、`recoverERC20`。
2. 它不只依賴 `approve` / `transferFrom`，還同時支援 EIP-2612 `permit` 和 EIP-3009 兩套簽名授權路徑。
3. 目前治理歷史幾乎是空的。也就是說，這份合約雖然暴露了很多權限，但在我們採樣到的視窗裡，真正發生的治理動作只有初始化，沒有持續的角色變化。

還有一個很重要的小細節：`renounceOwnership()` 是故意寫成報錯的。

這表示 owner 不是打算退出的角色，而是一個必須長期保留的控制面。

---

## 當前快照

現在的狀態很直接（截至區塊 `25182415`）：

| 項目 | 當前值 |
|---|---|
| 名稱 | `World Liberty Financial USD` |
| 符號 | `USD1` |
| 精度 | `18` |
| 供應量 | `1,922,063,260.45 USD1` |
| 價格 | 約 `$0.9985087024` |
| 市值 | 約 `$1,919,196,892.24` |
| Owner | `0xee9b1a09aedaced9dcda74964ea447feb93861c2` |
| 暫停狀態 | `false` |
| 最近治理 | 僅 `Initialized(version 2)` |

這個 owner 位址本身也是一個合約位址，不是普通 EOA。

我不會在沒有更多證據的情況下替它下結論，但至少可以確定一件事：USD1 的控制面不是直接暴露給一個普通錢包。

這和它的整體設計是匹配的。它不是一個追求「最小權限、最少功能」的簡單代幣。

---

## 控制堆疊

源碼裡最關鍵的東西很清楚。

### 1. owner 直接控制供給

`mint(uint256 amount)` 和 `burn(uint256 amount)` 都是 `onlyOwner`。

這代表發行和銷毀不是分散給很多 minter，而是直接由頂層 owner 掌握。它和很多「主 minter + 額度」式設計不一樣。

### 2. 全域暫停

合約裡有 `pause()` 和 `unpause()`，而轉帳與授權路徑都受 `whenNotPaused` 約束。

這表示它不是只有地址級凍結，沒有系統級開關。它可以直接把整條轉帳鏈路停下來。

### 3. 地址凍結

`freeze(address account)` 和 `unfreeze(address account)` 維護公開的 `frozen[address]` 映射。

轉帳和授權的內部檢查會攔住被凍結參與者。也就是說，這個凍結狀態不是擺設，真的會改變代幣行為。

### 4. 凍結資金回收

V2 版本額外加了三條管理路徑：

- `drain(address account)`
- `reallocate(address from, address to, uint256 amount)`
- `recoverERC20(address token, address recipient, uint256 amount)`

這三條路讓 USD1 更像一個「資金操作系統」，而不只是轉帳介面。

`drain` 可以把被凍結帳戶的全部餘額轉到 owner 名下。

`reallocate` 可以把被凍結源帳戶裡的資金挪到替代帳戶。

`recoverERC20` 可以把誤轉進合約的其他代幣救回去。

這已經明顯超出普通 ERC-20 的範圍。

### 5. 這個 owner 不打算被撤銷

`renounceOwnership()` 直接 revert。

這不是意外，而是刻意設計。很多合約會允許 owner 徹底退出，這份合約不會。讀風險時，這個點要放在前面看。

---

## 授權路徑

USD1 在標準 `approve / transferFrom` 之外，還掛了兩套簽名授權路徑：EIP-2612 `permit` 和 EIP-3009。也就是說它實際上有三條授權方式。

第一條是 EIP-2612。合約繼承自 OpenZeppelin 的 `ERC20PermitUpgradeable`，所以會暴露 `permit(owner, spender, value, deadline, v, r, s)`。用一次簽名替代一次鏈上的 `approve`，授權額度仍然記在 `allowance` 裡，後面還要 `transferFrom` 才能動帳。

第二條是 EIP-3009，它支援：

- `transferWithAuthorization`
- `receiveWithAuthorization`
- `cancelAuthorization` / `batchCancelAuthorization`
- `authorizationState(authorizer, nonce)`

EIP-3009 不是簽名授權額度，而是一次性的鏈下簽名直接轉帳。使用者先離線簽名，再由別人把交易提交上鏈。對 relayer、商戶收款流程，以及不想讓每個使用者都自己付 gas 的錢包 UX 來說，這很有用。

合約用 `bytes32 nonce` 跟蹤 EIP-3009 授權是否已經用掉，所以重放控制是顯式的，不是靠「大家自覺」。

差別就在這裡：

1. `approve` 是鏈上交易直接授權額度。
2. `permit` 是 EIP-2612 簽名版的 `approve`，省一次鏈上交易，仍然要配合 `transferFrom`。
3. `transferWithAuthorization` 是 EIP-3009 的一次性簽名轉帳，不走 allowance。
4. `cancelAuthorization` 和 `batchCancelAuthorization` 可以把還沒用掉的 EIP-3009 授權提前作廢。

所以 USD1 不是只會轉帳的代幣，而是帶有更豐富指令層的支付系統。

---

## 這個樣本說明了什麼

採樣到的治理時間線很安靜。

總共只有一條事件：`Initialized(version 2)`，區塊 `24809916`。

這不代表合約沒有權限，而是代表這些權限在採樣視窗裡沒有被頻繁改寫。

這個區分很重要。很多人看穩定幣，只會問「它能不能凍結、能不能暫停」。更好的問題是：這些控制權有沒有在持續被使用？如果有，是怎樣使用的？

在這個樣本裡：

1. 控制面很大。
2. 最近治理動作很少。
3. 代幣已經在運行，價格接近 1 美元，供應量也已經到數十億級別。

所以它是一個在運行中的系統，但近期並不吵雜。

---

## 應該盯什麼

如果你要認真監控 USD1，優先看這些：

- `paused()` 的變化
- `Freeze` 和 `Unfreeze`
- `FrozenAccountDrained` 和 `FrozenFundsReallocated`
- `AuthorizationUsed` 和 `AuthorizationCanceled`
- owner 位址是否變化
- 如果發生升級，implementation 是否變化

重點是：像 USD1 這樣的穩定幣，不需要很大的事件流就會產生高信號。

一次 pause、freeze、drain 或 ownership 變化，本身就足夠重要。

如果你只盯價格和供應量，你會漏掉系統行為。
如果你盯住管理面，你才會知道這到底是什麼樣的「美元系統」。

---

## 最後判斷

USD1 更像一個可控的穩定幣系統，而不只是餘額表。

它是一個可控的穩定幣系統，具備：

- owner 級別的發行和銷毀能力
- 全域暫停與地址凍結
- 凍結資金回收路徑
- EIP-2612 `permit` 與 EIP-3009 兩套簽名授權
- 故意不允許 renounce 的 owner 模型

真正的故事就在這裡。

ticker 說的是「美元代幣」。
合約說的是「可營運系統」。
