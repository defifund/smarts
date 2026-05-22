# Polymarket 合約整體架構

> 範圍：Polygon mainnet 上的 13 份生產合約。所有論斷都基於 verified source + 鏈上 view 函式雙重讀取（block ~87,146,000）。
> 最後更新：2026-05-19

---

## 一句話定位

Polymarket 是一套**「鏈下訂單簿 + 鏈上結算」**的事件預測市場協議——它在 Gnosis ConditionalTokens（一份不可變的 ERC-1155 帳本）之上，建構了訂單撮合、資本效率包裝、預言機接入三個獨立可演化的層；使用者層用自有穩定幣 **pUSD** 統一計價，對底層 USDC.e / 原生 USDC 的遷移做了抽象。

---

## 完整合約清單

| 角色 | 合約名 | 地址 |
|---|---|---|
| **使用者層穩定幣** | pUSD (CollateralToken) | `0xc011a7e1…2dfb` |
| 二元訂單簿 v1 | CTFExchange | `0x4bfb41…982e` |
| 二元訂單簿 v2 ★ | CTFExchange | `0xe11118…996b` |
| 多結果訂單簿 v1 | NegRiskCtfExchange | `0xc5d563…f80a` |
| 多結果訂單簿 v2 ★ | CTFExchange (neg-risk 參數化) | `0xe2222d…0f59` |
| 二元路徑包裝器 | CtfCollateralAdapter | `0xada100…9718` |
| 多結果路徑包裝器 | NegRiskCtfCollateralAdapter | `0xada200…c6f1` |
| 多結果 Adapter | NegRiskAdapter | `0xd91e80…5296` |
| 多結果 Operator | NegRiskOperator | `0x71523d0f…b820` |
| **持倉帳本（信任錨）** | ConditionalTokens (Gnosis CTF) | `0x4d97dc…6045` |
| 預言機 v1 | UmaCtfAdapter (binary) | `0x71392e…03f7` |
| 預言機 v2 ★ | UmaCtfAdapter (binary) | `0x6a9d22…4f74` |
| 預言機 v3 ★ | UmaCtfAdapter (neg-risk) | `0x2f5e36…0aa9d` |

★ = 目前主路徑；舊版本仍服務歷史市場，不下線、自然衰減。

外部依賴：
- **UMA Optimistic Oracle V2** `0xee3afe…c24`（結果裁決）
- **USDC.e** `0x2791bc…4174`（二元路徑的 CTF 抵押）
- **native USDC** `0x3c499c…3359`（pUSD 的另一種背書）

---

## 分層架構圖

### v2 路徑（目前主流量）

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ USER LAYER                                                                  │
│   使用者錢包持有 pUSD                                                          │
│   pUSD ⟷ {native USDC, USDC.e} via 儲備 VAULT（鑄贖走 MINTER_ROLE）         │
└─────────────────────────────┬───────────────────────────────────────────────┘
                              │ EIP-712 簽名訂單
                              │ Polymarket operator 代發交易
   ┌──────────────────────────┴──────────────────────────────┐
   ▼                                                         ▼
┌─────────────────────────┐                   ┌──────────────────────────────┐
│ CTFExchange (binary v2) │                   │ CTFExchange (neg-risk v2)     │
│ collateral      = pUSD  │                   │ collateral      = pUSD        │
│ ctf             = 真CTF │                   │ ctf             = 真CTF       │
│ ctfCollateral   = USDC.e│                   │ ctfCollateral   = WCOL        │
│ outcomeTokenFactory:    │                   │ outcomeTokenFactory:          │
│   CtfCollateralAdapter  │                   │   NegRiskCtfCollateralAdapter │
│   0xada100…             │                   │   0xada200…                   │
└────────────┬────────────┘                   └─────────────┬────────────────┘
             │ via CtfCollateralAdapter                     │ via NegRiskCtfCollateralAdapter
             │ pUSD ⟷ USDC.e                                │ pUSD ⟷ USDC.e ⟷ WCOL
             ▼                                              ▼
                              ┌──────────────────────────────┐
                              │ NegRiskAdapter                │
                              │ ─ 擁有 WCOL (1:1 wraps USDC.e)│
                              │ ─ 是 neg-risk 問題的 CTF oracle│
                              │ ─ convertPositions 資本效率   │
                              │ ─ 有自己的 admin set          │
                              └──────────────┬────────────────┘
                                             │
   ┌─────────────────────────────────────────┴──────────────────────────────┐
   ▼                                                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ ConditionalTokens (Gnosis CTF, 0x4d97dc…6045) — 不可變信任錨                │
│ ERC-1155 outcome shares                                                     │
│ • binary path  : positions keyed by (USDC.e, conditionId)                   │
│ • neg-risk path: positions keyed by (WCOL,   conditionId)                   │
└─────────────────────────────▲───────────────────────────────────────────────┘
                              │ reportPayouts(qid, payouts[])
   ┌──────────────────────────┴─────────────────────────────────────────────┐
   │ ORACLE LAYER                                                            │
   │                                                                         │
   │  binary    ─▶ UmaCtfAdapter v1/v2 ─▶ CTF.reportPayouts (直連)           │
   │                                                                         │
   │  neg-risk  ─▶ UmaCtfAdapter v3                                          │
   │              ─▶ NegRiskOperator (CTF 介面翻譯為 NegRisk 介面)            │
   │              ─▶ NegRiskAdapter.reportOutcome                            │
   │              ─▶ CTF.reportPayouts                                       │
   │                                                                         │
   │  all       ─▶ UMA Optimistic Oracle V2                                  │
   └─────────────────────────────────────────────────────────────────────────┘
```

### v1 路徑（仍在為歷史市場服務）

v1 路徑**沒有 pUSD、沒有 CtfCollateralAdapter**，結構更原始：

```
binary v1   :  User(USDC.e) ─▶ CTFExchange v1 ─▶ CTF (collateral=USDC.e)
                              getCtf = 真 CTF, 單 collateral 直連

neg-risk v1 :  User(USDC.e) ─▶ NegRiskCtfExchange v1 ─▶ NegRiskAdapter ─▶ CTF
                                getCtf = NegRiskAdapter
                                (撮合路徑要先過 NegRiskAdapter)
```

v1 vs v2 的逐項差異見 §2.3。

---

## 各層詳細設計

### 1. 使用者層：pUSD 統一穩定幣

**為什麼存在**：Polygon 上 USDC 正在經歷 USDC.e（bridged）→ native USDC 的遷移；Polymarket 引入 pUSD 把這層差異從使用者視角隱藏。

**機制**（`CollateralToken.sol`，繼承 Solady `OwnableRoles`）：

```solidity
address public immutable USDC;    // native USDC (0x3c499c…)
address public immutable USDCE;   // bridged USDC.e (0x2791bc…)
address public immutable VAULT;   // 儲備金庫地址（不是鑄贖權限主體）

uint256 internal constant MINTER_ROLE  = _ROLE_0;  // mint / burn
uint256 internal constant WRAPPER_ROLE = _ROLE_1;  // wrap / unwrap
```

- pUSD 是普通 ERC-20，6 位小數，符號 `pUSD`
- 鑄贖權限是**兩套獨立的 role**：`MINTER_ROLE` 管 `mint`/`burn`，`WRAPPER_ROLE` 管 `wrap`/`unwrap`；owner 用 `addMinter / removeMinter / addWrapper / removeWrapper` 分配
- `VAULT` 是一個**儲備地址常數**，存放底層的 USDC / USDC.e，不是單點鑄贖主體
- 目前流通量約 `375.9M pUSD`（`totalSupply()` = `375853763516069`，截至 block 87,232,311，會隨鑄贖即時變化）
- 虛榮地址前綴 `0xc011…` = 「coll」（collateral）

**使用者視角**：無論交易二元 v2 還是 neg-risk v2 市場，使用者錢包裡都只有 pUSD。看不見 USDC.e、看不見 WCOL。v1 路徑仍然是使用者直接持 USDC.e。

### 2. 撮合層：4 個 Exchange 實例

**v2 關鍵觀察**：二元 v2 和 neg-risk v2 用的是**同一份編譯產物（合約名都叫 `CTFExchange`）**，僅建構參數不同。兩個 v2 實例 ABI 完全相同（27 view / 17 write / 16 event）。

**v1 形態不同**：二元 v1 名為 `CTFExchange`，neg-risk v1 名為 `NegRiskCtfExchange`——是 Polymarket 早期「為每種市場類型寫一份合約」留下的產物。v1 編譯器還是 `v0.8.15`，v2 已經升到 `v0.8.34`，ABI 也不同（v1 neg-risk: 31 view / 19 write / 13 event）。

#### 2.1 內部由 9 個 mixin 組合

主合約 `CTFExchange.sol` 只有 4.7 KB，幾乎不寫業務邏輯：

```
CTFExchange.sol
├── Auth.sol              ── isAdmin / isOperator 雙角色 ACL
├── Fees.sol              ── maxFeeRateBps 上限 + validateFee
├── Assets.sol            ── 4 個 immutable 資產地址（見下）
├── Trading.sol  (29 KB)  ── 核心：撮合、訂單狀態機、fillOrders/matchOrders
├── Pausable.sol          ── 全域開關
├── UserPausable.sol      ── 單使用者凍結
├── Signatures.sol        ── EIP-712 + EIP-1271 + 預批准三路簽名驗證
├── Hashing.sol           ── 訂單 hash
├── AssetOperations.sol   ── 對 CTF 的 split / merge / safeTransfer 封裝
├── PolyFactoryHelper.sol ── 算出使用者代理錢包地址（不部署，只算）
└── ERC1155TokenReceiver  ── 必備：自己能收 CTF 份額作為中轉
```

邏輯 70% 集中在 `Trading.sol`（29 KB）——讀懂撮合只需要看一個檔案。

#### 2.2 Assets.sol 四個 immutable 欄位

```solidity
address internal immutable collateral;          // 使用者出入金的 token
address internal immutable ctf;                 // ConditionalTokens
address internal immutable ctfCollateral;       // CTF 用來推 positionId 的 token
address internal immutable outcomeTokenFactory; // 包裝 collateral 與 ctfCollateral 之間的橋
```

具體值：

| 欄位 | 二元 v2 | neg-risk v2 |
|---|---|---|
| collateral | pUSD | pUSD |
| ctf | 真 CTF | 真 CTF |
| ctfCollateral | USDC.e | WCOL |
| outcomeTokenFactory | `0xada100…9718` | `0xada200…c6f1` |

**重要**：僅在 **neg-risk v2** 上，`getCtf()` 回傳真 CTF（`0x4d97dc…6045`）——NegRiskAdapter 退到 split/merge/convert/redeem 和 oracle 路徑，不在撮合熱路徑上。

**neg-risk v1 不同**：`getCtf()` 回傳 NegRiskAdapter（`0xd91e80…5296`）。撮合後的份額轉帳要先經 NegRiskAdapter 再到 CTF。

#### 2.3 v1 vs v2 是結構性升級，不是參數遷移

| | 二元 v1 | 二元 v2 | neg-risk v1 | neg-risk v2 |
|---|---|---|---|---|
| 合約名 | CTFExchange | CTFExchange | NegRiskCtfExchange | CTFExchange |
| 編譯器 | v0.8.15 | v0.8.34 | v0.8.15 | v0.8.34 |
| `getCollateral()` | USDC.e | pUSD | USDC.e | pUSD |
| `getCtf()` | 真 CTF | 真 CTF | **NegRiskAdapter** | 真 CTF |
| `getCtfCollateral()` | ❌（無此函式）| USDC.e | ❌（無此函式）| WCOL |
| `outcomeTokenFactory` | ❌ | CtfCollateralAdapter | ❌ | NegRiskCtfCollateralAdapter |

v1 → v2 的三件事：
1. 引入 pUSD 把「使用者層 token」從底層 collateral 抽象出來
2. 引入 `outcomeTokenFactory`（CtfCollateralAdapter）做 pUSD ⟷ 底層 collateral 的翻譯
3. neg-risk 撮合路徑不再走 NegRiskAdapter，直連 CTF；NegRiskAdapter 只在非撮合路徑出現

### 3. 包裝層：CtfCollateralAdapter × 2

```solidity
IConditionalTokens public immutable CONDITIONAL_TOKENS;
address public immutable COLLATERAL_TOKEN;  // pUSD
address public immutable USDCE;             // 底層 USDC.e
```

負責在 pUSD 和 CTF 實際抵押（USDC.e 或 WCOL）之間做「原子拆/合」：使用者付 pUSD → adapter 走通到 CTF 的 splitPosition → 給使用者 outcome shares。

兩條路徑有各自獨立的實例（`0xada100…` vs `0xada200…`）——結構對稱，僅指向的 ctfCollateral 不同。

### 4. 多結果支援：NegRiskAdapter + WCOL

> NegRiskAdapter 不是「撮合層的包裝器」——它是**專門服務 neg-risk 多結果市場的資本效率層 + oracle**。原始碼位於 `src/NegRiskAdapter.sol`（18.7 KB）。

#### 4.1 WCOL（WrappedCollateral）

`src/WrappedCollateral.sol` 是 NegRiskAdapter 部署並持有的 ERC-20 wrapper。**權限是單 owner 模型，不是 role-based**：

| 函式 | 存取控制 | 誰能用 |
|---|---|---|
| `unwrap(to, amount)` | `external`，無 modifier | **任何人**，燒自己的 WCOL 換回 USDC.e |
| `wrap(to, amount)` | `onlyOwner` | 只有 NegRiskAdapter |
| `mint(amount)` | `onlyOwner` | 只有 NegRiskAdapter（憑空鑄 WCOL）|
| `burn(amount)` | `onlyOwner` | 只有 NegRiskAdapter |
| `release(to, amount)` | `onlyOwner` | 只有 NegRiskAdapter（釋放底層 USDC.e 而不銷毀 WCOL）|

也就是說：普通使用者從 CTF 贖回 WCOL 後能自己 `unwrap` 拿回 USDC.e；但要把 USDC.e 包成 WCOL 必須經過 NegRiskAdapter 的 splitPosition / convertPositions 入口。owner 獨佔的 `mint` / `release` 不對稱才是 `convertPositions` 資本效率的物理基礎。

#### 4.2 MarketData 的 bytes32 packing

`src/types/MarketData.sol` 把整個市場狀態壓在一個 storage slot：

```
md[0]      = questionCount  (1 byte)
md[1]      = determined flag (1 byte)
md[2]      = result index    (1 byte)
md[3..4]   = feeBips          (2 bytes)
md[12..32] = oracle address   (20 bytes)
```

#### 4.3 NegRiskIdLib 的 ID 編碼

```
marketId   = keccak256(oracle, feeBips, metadata) & 0xFFFF...FF00
questionId = marketId | questionIndex   // 最後 1 byte 是 0..255 的 index
```

從 questionId 反推 marketId 是零成本的 `& MASK`。一個市場最多 256 個候選答案。

#### 4.4 「Negative Risk」 不變量

強制在 **oracle 報告時**，而不是撮合時（`MarketStateManager._reportOutcome`）：

```solidity
if (_outcome == true) {
    if (data.determined()) revert MarketAlreadyDetermined();
    marketData[marketId] = data.determine(questionIndex);
}
```

N 個問題裡**第二個嘗試報 YES 的會 revert**——這是整個 NegRisk 模型的核心約束。NO 可以反覆報告，YES 只能落一次。

#### 4.5 convertPositions：資本效率的核心

使用者選 K 個問題，給出它們的 NO token，換出：
- `(K-1) × _amount` 的 collateral（僅 K≥2 時）
- 其餘 `(N-K)` 個問題的 YES token

數學守恆：N 個問題裡只能有 1 個 YES 獲勝，所以從 K 個互斥的 NO 中「提取」對應抵押是無套利的。代價是放棄了「全部 K 個都判 NO」那種極不可能的世界裡的額外收益。

物理過程：adapter 暫時 `mint((N-K) × _amount)` 個 WCOL，對每個 yes-side 問題做 splitPosition；YES 給使用者、NO 燒到 `NO_TOKEN_BURN_ADDRESS`；使用者原本的 K 個 NO 也燒掉。全部 N 個 NO 永久卡在 burn 地址，對應的 USDC.e 永遠留在 CTF 內。

#### 4.6 CTF 介面對偶

NegRiskAdapter 實作了和 CTF 同名同簽的幾個函式：

```
splitPosition / mergePositions / redeemPositions
balanceOf / balanceOfBatch / safeTransferFrom
```

讓原本與 CTF 整合的程式碼**只需要把「CTF 地址」換成 NegRiskAdapter 地址**就能跑通——優雅的協議介面對偶。

### 5. 帳本層：Gnosis ConditionalTokens

整個體系的**信任錨**——Gnosis 早年開源的通用預測市場原語，Polymarket 直接複用、沒有 fork、永不升級。

四個動詞：
- `prepareCondition(oracle, questionId, outcomeSlotCount)`
- `splitPosition(collateral, parentCollectionId, conditionId, partition, amount)`
- `mergePositions(...)` / `redeemPositions(...)`
- `reportPayouts(questionId, payouts[])`（只有 condition 的 oracle 能呼叫）

四個關鍵性質：
1. ERC-1155 而不是 ERC-20——同 condition 的 outcomes 共享元資料
2. Position = collateral × condition 的笛卡爾積——支援巢狀組合事件（Polymarket 目前只用單層）
3. Oracle 綁定在 condition 註冊時——之後無法變更
4. Payout 是 numerator 向量——可以表達「100% YES」也可以「60/40」

**Polymarket 在 CTF 之上沒改帳本**，所有創新都在更上層。這是非常克制的工程決策。

### 6. 預言機層：UmaCtfAdapter × 3

> v3 原始碼：`src/UmaCtfAdapter.sol`（21.6 KB）。v1/v2 是同名合約的迭代版本，事件/函式數略少。

#### 6.1 版本分工

| 版本 | 服務的市場類型 | `ctf` 欄位指向 |
|---|---|---|
| v1 | binary | 真 CTF |
| v2 | binary | 真 CTF |
| v3 | **neg-risk** | NegRiskOperator |

v1 → v2 是真迭代（同類型）；v3 是為 neg-risk 路徑**新建的分叉**——靠 `_ctf` 建構參數指向 NegRiskOperator 來實作介面轉譯。

#### 6.2 問題生命週期（5 狀態 + 緊急通道）

```
uninitialized
    │ initialize(...) ← 完全 permissionless
    ▼
initialized + OO 已掛提案
    │ 提案在 liveness 視窗內無異議
    ▼ resolve() → settleAndGetPrice → _constructPayouts → ctf.reportPayouts
resolved

被異議第一次 → priceDisputed callback → _reset() → 重新掛 OO
被異議第二次 → OO 走 UMA DVM 全網投票
回傳 ignore price (type(int256).min) → _reset()
admin flag() → 等 2 天 → emergencyResolve(任意 payouts)
```

#### 6.3 關鍵設計

**(a) `initialize` 完全 permissionless**
任何人可以建立新市場，自選 reward token（必須在 UMA whitelist）、reward 金額、bond、liveness。Polymarket UI 只是發起方之一，鏈上不限制誰能 init。

**(b) Initializer 釘進 ancillaryData**
`questionID = keccak256(ancillaryData_with_initializer)`——同一份問題文本由不同人發起會得到不同 questionId。UMA 投票人看得到是誰發起的。

**(c) 三種 OO 價格 + 一個 ignore 哨兵**
- `0` → `[YES=0, NO=1]`（NO 贏）
- `0.5 ether` → `[1, 1]`（UNKNOWN / 50-50，neg-risk 不支援）
- `1 ether` → `[1, 0]`（YES 贏）
- `type(int256).min` → 觸發 `_reset` 重發請求

**(d) 異議只允許一次自動重置**
一個問題最多產生 2 次 OO 請求；第二次被異議就只能走 UMA DVM 全網投票。

**(e) Admin 緊急通道**
6 個 onlyAdmin 函式（flag / unflag / pause / unpause / reset / emergencyResolve），核心是 `flag` → 等滿 2 天 `EMERGENCY_SAFETY_PERIOD` → `emergencyResolve(任意 payouts)`。

**(f) BulletinBoard 鏈上公告**
`postUpdate(questionID, update)` 讓任何人附加 bytes 到一個公開 mapping。約定：只信 question creator 發布的 update。

### 7. 多結果路徑的 oracle 翻譯：NegRiskOperator

UmaCtfAdapter 呼叫的是 CTF 的 `prepareCondition / reportPayouts`；NegRiskAdapter 暴露的是 `prepareQuestion / reportOutcome`。**NegRiskOperator 是中間的介面翻譯層**：

```
UmaCtfAdapter v3
    │ prepareCondition(this, qid, 2)
    │ reportPayouts(qid, payouts)
    ▼
NegRiskOperator (0x71523d0f…b820)
    │ prepareQuestion(marketId, meta)
    │ reportOutcome(qid, outcome)
    ▼
NegRiskAdapter
    │
    ▼
CTF
```

### 8. 代理錢包旁路（貫穿使用者層與撮合層）

普通 EVM 錢包要給每筆下單簽一個 tx 上鏈——這對高頻交易完全不可用。Polymarket 的解法：

```
使用者 EOA ─簽名─▶ Polymarket Operator ─代發 tx─▶ 鏈上
                  (幫你打包付 gas)
   │
   └── 資金/部位不放在 EOA，放在智慧合約錢包裡：
       - PolyProxy: 自研輕代理（佔絕大多數）
       - PolySafe : 基於 Gnosis Safe（高淨值/機構）
```

合約層支撐：
1. **CREATE2 確定性部署**（`Create2Lib.sol` + `PolyProxyLib.sol`）——首次入金前地址就可知
2. **EIP-1271 驗簽**（`Signatures.sol`）——operator 用代理錢包地址呼叫 Exchange，Exchange 反過來問代理錢包「這個簽名是不是你 owner 簽的」

後果：**官方交易流（透過 Polymarket UI）下使用者的 pUSD 和 outcome shares 都放在代理錢包裡**，EOA 主要用於簽名而非持倉。技術上 EOA 完全可以接收 pUSD（ERC-20）或 outcome shares（ERC-1155）——只是非官方流程，UI 不會自動辨識這種持倉。Smarts 查部位時必須**兩個地址都查**：先用 `getProxyWalletAddress(eoa)` 拿到代理地址查代理錢包，再直接查 EOA 兜底。

---

## 關鍵不變量與設計取捨

### 不變量（永遠成立的事實）

1. **CTF 合約本身不可升級**——Gnosis 部署，沒人能改
2. **CTF condition 的 oracle 綁死**——註冊後無法更換
3. **NegRisk 不變量**：同一 market 內最多 1 個 question 報 YES
4. **EMERGENCY_SAFETY_PERIOD = 2 days**——admin 任何緊急動作都要等滿 2 天
5. **UMA OO 單問題最多 2 次自動請求**——第二次異議必上 DVM

### 關鍵設計取捨

| 維度 | 選擇 | 取捨 |
|---|---|---|
| 價格發現 | 鏈下訂單簿 | 撮合中心化 ↔ UX 像 CEX |
| 資產託管 | 智慧合約代理錢包 | 多一層合約風險 ↔ 使用者不必逐筆簽 tx |
| 多結果市場 | NegRiskAdapter + WCOL | 多一層抽象 ↔ 資本效率 ×N |
| 預言機 | UMA Optimistic Oracle | 委託給獨立社群 ↔ 仲裁結果可爭議 |
| 使用者層 stablecoin | 自有 pUSD | 多一層合約 ↔ 螢蔽 USDC 遷移複雜度 |
| 版本演化 | 不下線、自然衰減 | 協議表面變大 ↔ 歷史市場不被打斷 |

---

## 信任拓撲

| 角色 | 誰持有 | 能做什麼 | 限制來源 |
|---|---|---|---|
| **Admin** (Exchange) | Polymarket multisig | 改費率上限、暫停、註冊新代幣、管理 operator 集合 | 無鏈上限制（社會層）|
| **Operator** (Exchange) | Polymarket 後端地址 | 代發已簽名訂單的 matchOrders | Admin 可吊銷 |
| **Admin** (UmaAdapter) | Polymarket multisig | flag / emergencyResolve（2 天安全期）| 硬編碼 2 天 |
| **Oracle** (CTF condition) | UmaCtfAdapter / NegRiskAdapter | 寫該 condition 的 payout | 建立時綁死 |
| **UMA 提議者/異議者** | 任何質押 UMA 的人 | 提案結果、提出異議 | UMA 協議本身的經濟激勵 |
| **MINTER_ROLE** (pUSD) | 持有 ROLE_0 的地址（Polymarket controlled）| `mint` / `burn` pUSD | pUSD owner 可 grant/revoke role |
| **WRAPPER_ROLE** (pUSD) | 持有 ROLE_1 的地址（Polymarket controlled）| `wrap` / `unwrap` pUSD 與底層 USDC 互換 | pUSD owner 可 grant/revoke role |
| **VAULT** (pUSD 儲備) | 一個固定地址常數 | 存放 pUSD 背後的 USDC / USDC.e 儲備金 | 僅作為儲備地點，不持鑄贖權 |
| **Admin** (NegRiskAdapter) | 建構時 = deployer，可 `addAdmin / removeAdmin / renounceAdmin` | 呼叫 `safeTransferFrom` 替使用者搬動 CTF 部位（需使用者先 setApprovalForAll）| `onlyAdmin` modifier；NegRisk **outcome rule 本身**（同 market 最多 1 個 YES）則在 `_reportOutcome` 硬編碼不可改 |
| **NegRiskAdapter Oracle 角色** | 合約自身（寫死） | 當 oracle 報 neg-risk 問題結果 | 在 `getConditionId` 裡 hardcode `address(this)` |
| **使用者** | EOA 持有人 | 簽名授權代理錢包做任何事 | 代理錢包合約的邏輯 |

**關鍵觀察**：Polymarket 不是「完全去中心化」也不是「完全中心化」。它在每一層做了不同的信任取捨——撮合中心化、託管去中心化、帳本完全去中心化、預言機委託給獨立社群、使用者層和治理參數由 multisig 控制。

---

## 一句話總結

**底層一份不可變帳本（Gnosis CTF）+ 使用者層一份自有穩定幣（pUSD，僅 v2 路徑）+ 兩條對稱的 v2 撮合通道（binary 經 USDC.e、neg-risk 經 WCOL）+ 還在跑的兩條 v1 通道（直持 USDC.e）+ 一個 permissionless 的預言機接入層（UMA OO V2）+ 一個 2 天硬安全窗的 admin 緊急通道。**

整套設計真正的「不可改變性」只錨定在 3 個地方：
1. **CTF 合約本身**（Gnosis 部署，沒人能升級）
2. **UmaCtfAdapter 的 `EMERGENCY_SAFETY_PERIOD = 172800` 秒**（= 2 天，admin 任何緊急動作都要等滿 2 天）
3. **NegRiskAdapter 的 NegRisk outcome rule 在 `_reportOutcome` 硬編碼**（同一 market 最多 1 個 YES——合約本身可有 admin，但這條規則改不了）

其他所有層都是**可被新版本旁路**的——但舊版本永遠不下線，老市場跑老合約直到自然結算。

---

## 附錄 A：對 Smarts adapter 實作的具體啟示

1. **NegRisk 一側的所有 CTF 查詢必須用 WCOL 地址做 positionId**——別用 USDC.e。要嘛讀 NegRiskAdapter 的 `wcol()` 拿到地址，要嘛硬編碼。
2. **從 UmaCtfAdapter 的 `questions(questionID)` 能拿到完整問題狀態**——包括 ancillaryData（帶 initializer 後綴）、reward token、是否被 flag 等。這是「這個市場是真的還是騙局」最權威的鏈上來源。
3. **查使用者部位要兩個地址都查**：先 `getProxyWalletAddress(eoa)` 拿代理錢包地址查它，再直接查 EOA 兜底（非官方流程的持倉）。
4. **MarketData 的 bytes32 packing 在 UI 上要解開**——5 個欄位（questionCount / determined / result / feeBips / oracle）每一個都有意義。
5. **convertPositions 是 Polymarket 獨有的鏈上原語**，文件值得專門一頁解釋——傳統 CTF 文件裡不存在。
6. **v1 和 v2 是結構不同的 ABI**——見 §2.3 表格。查 collateral 資訊時要做版本分支：v1 沒有 `getCtfCollateral`、neg-risk v1 的 `getCtf` 回傳 NegRiskAdapter。

---

## 附錄 B：驗證狀態

| 來源 | 驗證方式 |
|---|---|
| 所有合約地址、名字、ABI 形狀 | live `get_contract_info`，block ~87,146,000 |
| 所有 view 函式回傳值 | live `read_contract_state` |
| 所有原始碼引用（Auth.sol、Fees.sol、CollateralToken.sol、UmaCtfAdapter.sol 等）| Polygon 上 verified source |
| pUSD totalSupply | live `totalSupply()` = `375853763516069` (raw, 6 decimals, block 87,232,311) |
| pUSD 價格 | **未驗證**——$1.0017 來自 CoinGecko 不是 view 函式 |
| convertPositions 數學描述 | NegRiskAdapter.sol 原始碼 + 推導，**未做鏈上壓力測試** |
| UMA OO V2 地址 | UmaCtfAdapter v3 `optimisticOracle()` |
| EMERGENCY_SAFETY_PERIOD | UmaCtfAdapter v3 原始碼常數 `2 days = 172800 秒` |

### 變更歷史

- **2026-05-19 v2**：根據 reviewer 回饋修訂——v1 vs v2 路由差異、pUSD role 模型、WCOL 權限不對稱、NegRiskAdapter 實際有 admin、EOA 持倉不再絕對、合約 verified name 校正、totalSupply 數字校正。
- **2026-05-19 v1**：首次草稿。

---

本文的所有鏈上資料，都是用 [Smarts](https://smarts.md/) 即時讀出來的——它把任何已驗證的 EVM 合約變成可查詢的 live docs。
