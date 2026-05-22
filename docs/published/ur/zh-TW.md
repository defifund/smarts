---
date: 2026-05-22
source: https://smarts.md/ MCP (get_governance_timeline / read_contract_state / get_contract_info)
contract: 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 (FiatTokenV2_2)
verified_block: 25148291
tags: [stablecoin, usdc, blacklist, risk, smarts]
status: draft
---

# 34 次封禁、66 次解封：USDC 黑名單到底在做什麼

合約：`0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48`（Ethereum USDC）
當前 blacklister：`0x0a06be16275b95a7d2567fbdae118b36c7da78f9`
當前 paused：`false`
樣本：最近 100 條 `risk_action` 事件，涵蓋 2026-03-27 到 2026-05-20

上一篇 USDC 合約拆解講的是「它能做什麼」：mint、burn、pause、blacklist、簽名授權、角色變更和事件監控。

這篇往前走一步，看「它最近實際做了什麼」。

如果只看 ABI，`blacklist(address)` 只是一個函數。如果看近期事件，它就是一個真實運轉中的風控面。對穩定幣研究來說，重點不是「Circle 能不能凍結地址」，而是：它什麼時候做、多久做一次、是單點事件還是批量事件、是否伴隨角色變化、系統是否同時進入暫停狀態。

---

## 先給結論

最近 100 條 USDC `risk_action` 事件裡：

| Event | Count | Meaning |
|---|---:|---|
| `Blacklisted` | 34 | 地址被加入黑名單 |
| `UnBlacklisted` | 66 | 地址被移出黑名單 |

同時：

| Signal | Current observation |
|---|---|
| `blacklister()` | `0x0a06be16275b95a7d2567fbdae118b36c7da78f9` |
| `paused()` | `false` |
| recent `role_change` | none in sampled governance timeline |
| recent `config` | dominated by `MinterConfigured` |

這說明三件事：

1. 黑名單不是一個沉睡在 ABI 裡的理論權限，而是近期仍在使用的操作面。
2. 最近樣本裡，地址級風控沒有伴隨全局暫停，`paused()` 仍為 `false`。
3. `role_change` 為空，說明這批風控動作至少在樣本範圍內沒有伴隨 blacklister / owner / pauser 等關鍵角色變更。

這裡的判斷只基於 `smarts` 拉到的 governance timeline 和 live state，不推斷鏈下執法原因，也不判斷具體地址的性質。

---

## 當前快照

`smarts` 讀取到的最新區塊是 `25148291`。

USDC 當前仍是 `FiatTokenV2_2`，實現合約為 `0x43506849d7c04f9138d1a2050bbf3a0c054402dd`。這點和上一篇合約拆解一致。

更重要的是風控狀態：

```text
blacklister() = 0x0a06be16275b95a7d2567fbdae118b36c7da78f9
paused()      = false
```

也就是說，當前樣本看到的是「地址級處置」，不是「系統級停機」。

這個區別很關鍵。`blacklist(address)` 針對具體帳戶，`pause()` 針對系統狀態。二者都屬於風控能力，但風險含義完全不同。

---

## 最近事件長什麼樣

最近幾條 `risk_action` 事件如下：

| Time (UTC) | Block | Event | Address |
|---|---:|---|---|
| 2026-05-20 20:13:59 | 25138769 | `Blacklisted` | `0x6d3ca488b86fcc12f8ce08857ef1bb8b473a9d81` |
| 2026-05-20 15:31:47 | 25137362 | `Blacklisted` | `0xf2235d55b2950a0b1317469d72d07ae65b2e27cb` |
| 2026-05-20 15:30:59 | 25137358 | `Blacklisted` | `0xac4cc4b68ea24bbfaac8fd127b67ed445accce22` |
| 2026-05-20 15:25:35 | 25137331 | `Blacklisted` | `0x4f428c11dc82388fa5136d636e613ad923eb700b` |
| 2026-05-20 15:23:11 | 25137319 | `Blacklisted` | `0x32da24ca413f3e7b53145d4737e172c3bdf81e3e` |

這幾條事件本身不能告訴我們鏈下原因。它們能告訴我們的是鏈上動作：哪些地址在什麼時間被加入黑名單。

同一個樣本裡也有大量 `UnBlacklisted`：

| Time (UTC) | Block | Event | Address |
|---|---:|---|---|
| 2026-05-12 23:56:23 | 25082467 | `UnBlacklisted` | `0x827253f62f0325a3818053f2682ebb19f89d0df2` |
| 2026-05-12 23:56:11 | 25082466 | `UnBlacklisted` | `0x7520cad39e6143297d0487ff9933399e3e43646d` |
| 2026-05-12 23:55:59 | 25082465 | `UnBlacklisted` | `0x50fe09c1e4c7debd0c3d42e63427bc49752564f7` |
| 2026-05-12 23:55:47 | 25082464 | `UnBlacklisted` | `0x3b848ac300b9e0d260e812b628b87a03d278db95` |
| 2026-05-12 23:35:35 | 25082363 | `UnBlacklisted` | `0xf9e83020cccbd1a95f0f257a5a9e3d58149762f8` |

這組事件更有意思：它說明黑名單狀態不是只有「加入」，也存在批量解除。

從監控角度看，`Blacklisted` 和 `UnBlacklisted` 應該一起看。只看新增凍結，會把系統理解成單向懲罰機制；把解除也納入，才能看到風控狀態的生命週期。

---

## 事件之後，狀態是否真的改變了

事件本身只是日誌。更嚴謹的做法是抽查事件後的 live state。

我抽查了樣本裡的兩個地址：

| Address | Recent event | Current `isBlacklisted` | Current `balanceOf` |
|---|---|---:|---:|
| `0x6d3ca488b86fcc12f8ce08857ef1bb8b473a9d81` | `Blacklisted` | `true` | `65,028.088542 USDC` |
| `0x827253f62f0325a3818053f2682ebb19f89d0df2` | `UnBlacklisted` | `false` | `197,163.882089 USDC` |

這個結果很關鍵：它把事件和當前狀態接上了。最近一條 `Blacklisted` 地址當前確實仍在黑名單裡；最近一條 `UnBlacklisted` 地址當前確實不在黑名單裡。

還要注意另一點：黑名單不是 burn，也不是把餘額清零。上面兩個地址都有非零 USDC 餘額。黑名單影響的是地址能否正常參與餘額更新和轉帳路徑，而不是直接銷毀餘額。

從原始碼看，V2.2 把餘額和黑名單狀態合併進 `balanceAndBlacklistStates`。黑名單狀態佔高位，餘額仍然保存在低 255 位。`_balanceOf` 會用 bitmask 讀出餘額，`_isBlacklisted` 會讀取高位狀態。也就是說，黑名單狀態和餘額狀態被壓進同一個 storage word，但語義上仍是兩件事。

這部分讓監控更細：看到 `Blacklisted` 後，不只要記錄事件，還可以繼續查 `isBlacklisted(address)` 和 `balanceOf(address)`。前者確認狀態，後者判斷被凍結地址上仍有多少 USDC 暴露。

---

## 事件分佈透露了什麼

最近 100 條 `risk_action` 裡，`UnBlacklisted` 數量多於 `Blacklisted`。

這不能直接解釋為「風險下降」，因為我們不知道每個地址背後的鏈下原因，也不知道這些地址最早是在什麼時候被加入黑名單。

但它至少說明一個事實：USDC 黑名單機制不是只用於新增限制，也用於狀態修正、解除或遷移後的清理。

先把樣本口徑說清楚：

| Metric | Value |
|---|---:|
| sample size | 100 `risk_action` events |
| latest event in sample | 2026-05-20 20:13:59 UTC |
| earliest event in sample | 2026-03-27 20:34:35 UTC |
| `Blacklisted` count | 34 |
| `UnBlacklisted` count | 66 |
| current `paused()` | `false` |
| sampled `role_change` | 0 |

這裡的「最近 100 條」是按 `smarts` 返回的 newest-first governance timeline 取樣，不代表 USDC 全歷史黑名單事件。它適合觀察近期行為分佈，不適合直接推導長期比例。

更具體地看，樣本裡有明顯的事件簇：

1. 2026-05-20 出現多條 `Blacklisted`，集中在 15:19 到 15:31 UTC，並在 20:13 UTC 又出現一條。
2. 2026-05-12 出現大量 `UnBlacklisted`，很多事件間隔只有幾十秒。
3. 2026-04-11 出現一組連續 `Blacklisted`。
4. 2026-04-02 到 2026-04-14 之間多次出現 `UnBlacklisted`。

把這些事件簇攤開看，會更清楚：

| Window (UTC) | Event type | Count in sample | Observation |
|---|---|---:|---|
| 2026-05-20 15:19-20:13 | `Blacklisted` | 7 | 同一天出現一組新增黑名單，其中 6 條集中在 13 分鐘內 |
| 2026-05-12 23:26-23:56 | `UnBlacklisted` | 42 | 半小時內出現大量解除黑名單事件，是樣本裡最明顯的批量操作 |
| 2026-04-11 16:04-16:08 | `Blacklisted` | 12 | 約 4 分鐘內連續加入黑名單 |
| 2026-04-02 19:07-22:22 | `UnBlacklisted` | 7 | 同日多批次解除黑名單 |
| 2026-04-14 23:22-23:24 | `UnBlacklisted` | 4 | 短時間內連續解除 |

這類簇狀分佈，比單條事件更值得監控。單條事件只能告訴你某個地址被處理；事件簇則可能說明一次批量操作、一次清單更新，或一次鏈下流程在鏈上的集中執行。

這裡仍然要保持邊界：鏈上事件只能證明「發生了什麼動作」，不能單獨證明「為什麼發生」。

---

## 黑名單和暫停不是一回事

USDC 合約裡有兩類風控能力：

| Capability | Scope | Current state / sample |
|---|---|---|
| `blacklist(address)` | 單個地址 | 最近 100 條 risk_action 裡有 34 條 `Blacklisted` |
| `unBlacklist(address)` | 單個地址 | 最近 100 條 risk_action 裡有 66 條 `UnBlacklisted` |
| `pause()` | 全局系統狀態 | 當前 `paused()` 為 `false` |
| `unpause()` | 全局系統狀態恢復 | 本次樣本重點不在 pause/unpause |

這也是上一篇 USDC 合約拆解裡最容易被誤讀的地方：暫停是系統級開關，黑名單是地址級處置。

如果 USDC 沒有暫停，但持續出現黑名單事件，說明系統沒有進入全局停機狀態，但地址級合規動作仍在發生。

對監控系統來說，這兩類信號應該分開報警：

1. `Blacklisted` / `UnBlacklisted` 是帳戶級風險動作。
2. `Pause` / `Unpause` 是系統級狀態變化。
3. `BlacklisterChanged` 是風控權限本身發生變化。

把它們混在一起，會降低信號質量。

---

## 什麼情況應該提高監控優先級

從這次樣本看，最有價值的不是單個地址被加入或移出黑名單，而是事件組合。

可以把 USDC 黑名單監控拆成三檔：

| Priority | Pattern | Why it matters |
|---|---|---|
| normal | 單條 `Blacklisted` 或 `UnBlacklisted` | 地址級處置，先記錄事件和當前狀態 |
| elevated | 短時間內多條同類事件，例如 10 到 30 分鐘內連續發生 | 可能是批量清單更新或鏈下流程集中執行 |
| high | 風控事件簇同時伴隨 `BlacklisterChanged`、`PauserChanged`、`Pause` 或異常 `MinterConfigured` | 帳戶級動作和權限 / 系統狀態變化疊加，風險語義更強 |

本文樣本裡，2026-05-12 的 42 條 `UnBlacklisted` 和 2026-04-11 的 12 條 `Blacklisted` 都屬於 elevated 級別：它們不是單點事件，而是明顯批量行為。

但它們沒有伴隨 sampled `role_change`，當前 `paused()` 也為 `false`，所以不應該把它們直接升級成系統級異常。更準確的說法是：它們是值得記錄和複核的操作簇，而不是可以單獨定性的風險結論。

---

## 角色穩定性也要一起看

只看 `Blacklisted` 還不夠。還要問：執行這些動作的權限結構有沒有變？

本次讀取裡：

```text
role_change events = none
blacklister()      = 0x0a06be16275b95a7d2567fbdae118b36c7da78f9
paused()           = false
```

這意味著，在當前樣本裡，風險動作發生時沒有看到角色變更信號。這個結論很窄，只適用於本次讀取到的治理時間線；但它很有用。

如果未來出現下面這種組合，監控優先級就應該提高：

1. `BlacklisterChanged` 後短時間內出現大量 `Blacklisted`。
2. `Pause` 發生後緊接著出現角色變更。
3. `MinterConfigured` 異常集中，同時風險動作也集中出現。
4. `UnBlacklisted` 批量發生後，相關角色也發生變化。

單個事件是日誌；事件組合才接近風險信號。

---

## 和發行配置事件放在一起看

同一時間線裡，`config` 類事件主要是 `MinterConfigured`。

最近的 `config` 樣本顯示，USDC 在持續調整多個 minter 的 allowance。例如：

| Time (UTC) | Block | Event | Summary |
|---|---:|---|---|
| 2026-05-22 01:30:11 | 25147521 | `MinterConfigured` | minter `0xfd78…d002` allowance set to `359,811,029,931,415` |
| 2026-05-21 23:24:59 | 25146896 | `MinterConfigured` | minter `0x5b61…47d7` allowance set to `1,974,523,310,448,972` |
| 2026-05-21 22:53:11 | 25146737 | `MinterConfigured` | minter `0x5b61…47d7` allowance set to `1,783,407,737,018,972` |

這些不是本文主角，但它們提供背景：USDC 的鏈上運營不只是風控動作，也包括發行額度管理。

這就是為什麼下一篇可以繼續追 `MinterConfigured`。如果說黑名單事件展示的是地址級合規操作，那麼 minter allowance 展示的是發行運營節奏。

---

## 如何復現

在 Claude Code 裡接入 `smarts`：

```bash
claude mcp add --transport http smarts https://smarts.md/mcp
```

然後問：

```text
讀取 Ethereum USDC 最近 100 條 risk_action 事件。
```

繼續追問：

```text
統計這些事件裡 Blacklisted 和 UnBlacklisted 分別有多少。
```

```text
按日期和事件類型聚合 USDC 最近 100 條 risk_action，找出事件簇。
```

```text
讀取 USDC 當前 blacklister 和 paused 狀態。
```

```text
讀取 USDC 最近的 role_change 和 config 事件，檢查是否和 risk_action 同時出現。
```

用工具接口表達，就是：

```text
get_governance_timeline(slug: "usdc-eth", category: "risk_action", limit: 100)
get_governance_timeline(slug: "usdc-eth", category: "config", limit: 50)
get_governance_timeline(slug: "usdc-eth", category: "role_change", limit: 50)
read_contract_state(slug: "usdc-eth", function_name: "blacklister")
read_contract_state(slug: "usdc-eth", function_name: "paused")
```

---

## 結尾

USDC 黑名單事件最重要的地方，不是它證明了「穩定幣可以凍結地址」。這個能力早就寫在合約裡。

真正值得看的是事件模式：新增、解除、批量、間隔、角色穩定性，以及它們和發行配置事件之間有沒有關係。

對穩定幣來說，合約函數說明「能做什麼」，事件說明「做過什麼」，角色狀態說明「誰有權做」。黑名單監控正好把這三層接在一起。

下一步最值得繼續追的是 `MinterConfigured`：USDC 的發行額度是如何被動態調整的，哪些 minter 最活躍，額度變化是否呈現固定節奏。

---

*本文所有結構和即時資料由 [smarts.md](https://smarts.md/) MCP 工具拉取核驗。*
