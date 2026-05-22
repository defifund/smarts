# Polymarket 合约整体架构

> 范围：Polygon mainnet 上的 13 份生产合约。所有论断都基于 verified source + 链上 view 函数双重读取（block ~87,146,000）。
> 最后更新：2026-05-19

---

## 一句话定位

Polymarket 是一套**"链下订单簿 + 链上结算"**的事件预测市场协议——它在 Gnosis ConditionalTokens（一份不可变的 ERC-1155 账本）之上，构建了订单撮合、资本效率包装、预言机接入三个独立可演化的层；用户层用自有稳定币 **pUSD** 统一计价，对底层 USDC.e / 原生 USDC 的迁移做了抽象。

---

## 完整合约清单

| 角色 | 合约名 | 地址 |
|---|---|---|
| **用户层稳定币** | pUSD (CollateralToken) | `0xc011a7e1…2dfb` |
| 二元订单簿 v1 | CTFExchange | `0x4bfb41…982e` |
| 二元订单簿 v2 ★ | CTFExchange | `0xe11118…996b` |
| 多结果订单簿 v1 | NegRiskCtfExchange | `0xc5d563…f80a` |
| 多结果订单簿 v2 ★ | CTFExchange (neg-risk 参数化) | `0xe2222d…0f59` |
| 二元路径包装器 | CtfCollateralAdapter | `0xada100…9718` |
| 多结果路径包装器 | NegRiskCtfCollateralAdapter | `0xada200…c6f1` |
| 多结果 Adapter | NegRiskAdapter | `0xd91e80…5296` |
| 多结果 Operator | NegRiskOperator | `0x71523d0f…b820` |
| **持仓账本（信任锚）** | ConditionalTokens (Gnosis CTF) | `0x4d97dc…6045` |
| 预言机 v1 | UmaCtfAdapter (binary) | `0x71392e…03f7` |
| 预言机 v2 ★ | UmaCtfAdapter (binary) | `0x6a9d22…4f74` |
| 预言机 v3 ★ | UmaCtfAdapter (neg-risk) | `0x2f5e36…0aa9d` |

★ = 当前主路径；旧版本仍服务历史市场，不下线、自然衰减。

外部依赖：
- **UMA Optimistic Oracle V2** `0xee3afe…c24`（结果裁决）
- **USDC.e** `0x2791bc…4174`（二元路径的 CTF 抵押）
- **native USDC** `0x3c499c…3359`（pUSD 的另一种背书）

---

## 分层架构图

### v2 路径（当前主流量）

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ USER LAYER                                                                  │
│   用户钱包持有 pUSD                                                          │
│   pUSD ⟷ {native USDC, USDC.e} via 储备 VAULT（铸赎走 MINTER_ROLE）         │
└─────────────────────────────┬───────────────────────────────────────────────┘
                              │ EIP-712 签名订单
                              │ Polymarket operator 代发交易
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
                              │ ─ 拥有 WCOL (1:1 wraps USDC.e)│
                              │ ─ 是 neg-risk 问题的 CTF oracle│
                              │ ─ convertPositions 资本效率   │
                              │ ─ 有自己的 admin set          │
                              └──────────────┬────────────────┘
                                             │
   ┌─────────────────────────────────────────┴──────────────────────────────┐
   ▼                                                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ ConditionalTokens (Gnosis CTF, 0x4d97dc…6045) — 不可变信任锚                │
│ ERC-1155 outcome shares                                                     │
│ • binary path  : positions keyed by (USDC.e, conditionId)                   │
│ • neg-risk path: positions keyed by (WCOL,   conditionId)                   │
└─────────────────────────────▲───────────────────────────────────────────────┘
                              │ reportPayouts(qid, payouts[])
   ┌──────────────────────────┴─────────────────────────────────────────────┐
   │ ORACLE LAYER                                                            │
   │                                                                         │
   │  binary    ─▶ UmaCtfAdapter v1/v2 ─▶ CTF.reportPayouts (直连)           │
   │                                                                         │
   │  neg-risk  ─▶ UmaCtfAdapter v3                                          │
   │              ─▶ NegRiskOperator (CTF 接口翻译为 NegRisk 接口)            │
   │              ─▶ NegRiskAdapter.reportOutcome                            │
   │              ─▶ CTF.reportPayouts                                       │
   │                                                                         │
   │  all       ─▶ UMA Optimistic Oracle V2                                  │
   └─────────────────────────────────────────────────────────────────────────┘
```

### v1 路径（仍在为历史市场服务）

v1 路径**没有 pUSD、没有 CtfCollateralAdapter**，结构更原始：

```
binary v1   :  User(USDC.e) ─▶ CTFExchange v1 ─▶ CTF (collateral=USDC.e)
                              getCtf = 真 CTF, 单 collateral 直连

neg-risk v1 :  User(USDC.e) ─▶ NegRiskCtfExchange v1 ─▶ NegRiskAdapter ─▶ CTF
                                getCtf = NegRiskAdapter
                                (撮合路径要先过 NegRiskAdapter)
```

v1 vs v2 的逐项差异见 §2.3。

---

## 各层详细设计

### 1. 用户层：pUSD 统一稳定币

**为什么存在**：Polygon 上 USDC 正在经历 USDC.e（bridged）→ native USDC 的迁移；Polymarket 引入 pUSD 把这层差异从用户视角隐藏。

**机制**（`CollateralToken.sol`，继承 Solady `OwnableRoles`）：

```solidity
address public immutable USDC;    // native USDC (0x3c499c…)
address public immutable USDCE;   // bridged USDC.e (0x2791bc…)
address public immutable VAULT;   // 储备金库地址（不是铸赎权限主体）

uint256 internal constant MINTER_ROLE  = _ROLE_0;  // mint / burn
uint256 internal constant WRAPPER_ROLE = _ROLE_1;  // wrap / unwrap
```

- pUSD 是普通 ERC-20，6 位小数，符号 `pUSD`
- 铸赎权限是**两套独立的 role**：`MINTER_ROLE` 管 `mint`/`burn`，`WRAPPER_ROLE` 管 `wrap`/`unwrap`；owner 用 `addMinter / removeMinter / addWrapper / removeWrapper` 分配
- `VAULT` 是一个**储备地址常量**，存放底层的 USDC / USDC.e，不是单点铸赎主体
- 当前流通量约 `375.9M pUSD`（`totalSupply()` = `375853763516069`，截至 block 87,232,311，会随铸赎实时变化）
- 虚荣地址前缀 `0xc011…` = "coll"（collateral）

**用户视角**：无论交易二元 v2 还是 neg-risk v2 市场，用户钱包里都只有 pUSD。看不见 USDC.e、看不见 WCOL。v1 路径仍然是用户直接持 USDC.e。

### 2. 撮合层：4 个 Exchange 实例

**v2 关键观察**：二元 v2 和 neg-risk v2 用的是**同一份编译产物（合约名都叫 `CTFExchange`）**，仅构造参数不同。两个 v2 实例 ABI 完全相同（27 view / 17 write / 16 event）。

**v1 形态不同**：二元 v1 名为 `CTFExchange`，neg-risk v1 名为 `NegRiskCtfExchange`——是 Polymarket 早期"为每种市场类型写一份合约"留下的产物。v1 编译器还是 `v0.8.15`，v2 已经升到 `v0.8.34`，ABI 也不同（v1 neg-risk: 31 view / 19 write / 13 event）。

#### 2.1 内部由 9 个 mixin 组合

主合约 `CTFExchange.sol` 只有 4.7 KB，几乎不写业务逻辑：

```
CTFExchange.sol
├── Auth.sol              ── isAdmin / isOperator 双角色 ACL
├── Fees.sol              ── maxFeeRateBps 上限 + validateFee
├── Assets.sol            ── 4 个 immutable 资产地址（见下）
├── Trading.sol  (29 KB)  ── 核心：撮合、订单状态机、fillOrders/matchOrders
├── Pausable.sol          ── 全局开关
├── UserPausable.sol      ── 单用户冻结
├── Signatures.sol        ── EIP-712 + EIP-1271 + 预批准三路签名验证
├── Hashing.sol           ── 订单 hash
├── AssetOperations.sol   ── 对 CTF 的 split / merge / safeTransfer 封装
├── PolyFactoryHelper.sol ── 算出用户代理钱包地址（不部署，只算）
└── ERC1155TokenReceiver  ── 必备：自己能收 CTF 份额作为中转
```

逻辑 70% 集中在 `Trading.sol`（29 KB）——读懂撮合只需要看一个文件。

#### 2.2 Assets.sol 四个 immutable 字段

```solidity
address internal immutable collateral;          // 用户出入金的 token
address internal immutable ctf;                 // ConditionalTokens
address internal immutable ctfCollateral;       // CTF 用来推 positionId 的 token
address internal immutable outcomeTokenFactory; // 包装 collateral 与 ctfCollateral 之间的桥
```

具体值：

| 字段 | 二元 v2 | neg-risk v2 |
|---|---|---|
| collateral | pUSD | pUSD |
| ctf | 真 CTF | 真 CTF |
| ctfCollateral | USDC.e | WCOL |
| outcomeTokenFactory | `0xada100…9718` | `0xada200…c6f1` |

**重要**：仅在 **neg-risk v2** 上，`getCtf()` 返回真 CTF（`0x4d97dc…6045`）——NegRiskAdapter 退到 split/merge/convert/redeem 和 oracle 路径，不在撮合热路径上。

**neg-risk v1 不同**：`getCtf()` 返回 NegRiskAdapter（`0xd91e80…5296`）。撮合后的份额转账要先经 NegRiskAdapter 再到 CTF。

#### 2.3 v1 vs v2 是结构性升级，不是参数迁移

| | 二元 v1 | 二元 v2 | neg-risk v1 | neg-risk v2 |
|---|---|---|---|---|
| 合约名 | CTFExchange | CTFExchange | NegRiskCtfExchange | CTFExchange |
| 编译器 | v0.8.15 | v0.8.34 | v0.8.15 | v0.8.34 |
| `getCollateral()` | USDC.e | pUSD | USDC.e | pUSD |
| `getCtf()` | 真 CTF | 真 CTF | **NegRiskAdapter** | 真 CTF |
| `getCtfCollateral()` | ❌（无此函数）| USDC.e | ❌（无此函数）| WCOL |
| `outcomeTokenFactory` | ❌ | CtfCollateralAdapter | ❌ | NegRiskCtfCollateralAdapter |

v1 → v2 的三件事：
1. 引入 pUSD 把"用户层 token"从底层 collateral 抽象出来
2. 引入 `outcomeTokenFactory`（CtfCollateralAdapter）做 pUSD ⟷ 底层 collateral 的翻译
3. neg-risk 撮合路径不再走 NegRiskAdapter，直连 CTF；NegRiskAdapter 只在非撮合路径出现

### 3. 包装层：CtfCollateralAdapter × 2

```solidity
IConditionalTokens public immutable CONDITIONAL_TOKENS;
address public immutable COLLATERAL_TOKEN;  // pUSD
address public immutable USDCE;             // 底层 USDC.e
```

负责在 pUSD 和 CTF 实际抵押（USDC.e 或 WCOL）之间做"原子拆/合"：用户付 pUSD → adapter 走通到 CTF 的 splitPosition → 给用户 outcome shares。

两条路径有各自独立的实例（`0xada100…` vs `0xada200…`）——结构对称，仅指向的 ctfCollateral 不同。

### 4. 多结果支持：NegRiskAdapter + WCOL

> NegRiskAdapter 不是"撮合层的包装器"——它是**专门服务 neg-risk 多结果市场的资本效率层 + oracle**。源码位于 `src/NegRiskAdapter.sol`（18.7 KB）。

#### 4.1 WCOL（WrappedCollateral）

`src/WrappedCollateral.sol` 是 NegRiskAdapter 部署并持有的 ERC-20 wrapper。**权限是单 owner 模型，不是 role-based**：

| 函数 | 访问控制 | 谁能用 |
|---|---|---|
| `unwrap(to, amount)` | `external`，无 modifier | **任何人**，烧自己的 WCOL 换回 USDC.e |
| `wrap(to, amount)` | `onlyOwner` | 只有 NegRiskAdapter |
| `mint(amount)` | `onlyOwner` | 只有 NegRiskAdapter（凭空铸 WCOL）|
| `burn(amount)` | `onlyOwner` | 只有 NegRiskAdapter |
| `release(to, amount)` | `onlyOwner` | 只有 NegRiskAdapter（释放底层 USDC.e 而不销毁 WCOL）|

也就是说：普通用户从 CTF 赎回 WCOL 后能自己 `unwrap` 拿回 USDC.e；但要把 USDC.e 包成 WCOL 必须经过 NegRiskAdapter 的 splitPosition / convertPositions 入口。owner 独占的 `mint` / `release` 不对称才是 `convertPositions` 资本效率的物理基础。

#### 4.2 MarketData 的 bytes32 packing

`src/types/MarketData.sol` 把整个市场状态压在一个 storage slot：

```
md[0]      = questionCount  (1 byte)
md[1]      = determined flag (1 byte)
md[2]      = result index    (1 byte)
md[3..4]   = feeBips          (2 bytes)
md[12..32] = oracle address   (20 bytes)
```

#### 4.3 NegRiskIdLib 的 ID 编码

```
marketId   = keccak256(oracle, feeBips, metadata) & 0xFFFF...FF00
questionId = marketId | questionIndex   // 最后 1 字节是 0..255 的 index
```

从 questionId 反推 marketId 是零成本的 `& MASK`。一个市场最多 256 个候选答案。

#### 4.4 "Negative Risk" 不变量

强制在 **oracle 报告时**，而不是撮合时（`MarketStateManager._reportOutcome`）：

```solidity
if (_outcome == true) {
    if (data.determined()) revert MarketAlreadyDetermined();
    marketData[marketId] = data.determine(questionIndex);
}
```

N 个问题里**第二个尝试报 YES 的会 revert**——这是整个 NegRisk 模型的核心约束。NO 可以反复报告，YES 只能落一次。

#### 4.5 convertPositions：资本效率的核心

用户选 K 个问题，给出它们的 NO token，换出：
- `(K-1) × _amount` 的 collateral（仅 K≥2 时）
- 其余 `(N-K)` 个问题的 YES token

数学守恒：N 个问题里只能有 1 个 YES 获胜，所以从 K 个互斥的 NO 中"提取"对应抵押是无套利的。代价是放弃了"全部 K 个都判 NO"那种极不可能的世界里的额外收益。

物理过程：adapter 临时 `mint((N-K) × _amount)` 个 WCOL，对每个 yes-side 问题做 splitPosition；YES 给用户、NO 烧到 `NO_TOKEN_BURN_ADDRESS`；用户原本的 K 个 NO 也烧掉。全部 N 个 NO 永久卡在 burn 地址，对应的 USDC.e 永远留在 CTF 内。

#### 4.6 CTF 接口对偶

NegRiskAdapter 实现了和 CTF 同名同签的几个函数：

```
splitPosition / mergePositions / redeemPositions
balanceOf / balanceOfBatch / safeTransferFrom
```

让原本与 CTF 集成的代码**只需要把"CTF 地址"换成 NegRiskAdapter 地址**就能跑通——优雅的协议接口对偶。

### 5. 账本层：Gnosis ConditionalTokens

整个体系的**信任锚**——Gnosis 早年开源的通用预测市场原语，Polymarket 直接复用、没有 fork、永不升级。

四个动词：
- `prepareCondition(oracle, questionId, outcomeSlotCount)`
- `splitPosition(collateral, parentCollectionId, conditionId, partition, amount)`
- `mergePositions(...)` / `redeemPositions(...)`
- `reportPayouts(questionId, payouts[])`（只有 condition 的 oracle 能调）

四个关键性质：
1. ERC-1155 而不是 ERC-20——同 condition 的 outcomes 共享元数据
2. Position = collateral × condition 的笛卡尔积——支持嵌套组合事件（Polymarket 当前只用单层）
3. Oracle 绑定在 condition 注册时——之后无法变更
4. Payout 是 numerator 向量——可以表达"100% YES"也可以"60/40"

**Polymarket 在 CTF 之上没改账本**，所有创新都在更上层。这是非常克制的工程决策。

### 6. 预言机层：UmaCtfAdapter × 3

> v3 源码：`src/UmaCtfAdapter.sol`（21.6 KB）。v1/v2 是同名合约的迭代版本，事件/函数数略少。

#### 6.1 版本分工

| 版本 | 服务的市场类型 | `ctf` 字段指向 |
|---|---|---|
| v1 | binary | 真 CTF |
| v2 | binary | 真 CTF |
| v3 | **neg-risk** | NegRiskOperator |

v1 → v2 是真迭代（同类型）；v3 是为 neg-risk 路径**新建的分叉**——靠 `_ctf` 构造参数指向 NegRiskOperator 来实现接口转译。

#### 6.2 问题生命周期（5 状态 + 紧急通道）

```
uninitialized
    │ initialize(...) ← 完全 permissionless
    ▼
initialized + OO 已挂提案
    │ 提案在 liveness 窗口内无异议
    ▼ resolve() → settleAndGetPrice → _constructPayouts → ctf.reportPayouts
resolved

被异议第一次 → priceDisputed callback → _reset() → 重新挂 OO
被异议第二次 → OO 走 UMA DVM 全网投票
返回 ignore price (type(int256).min) → _reset()
admin flag() → 等 2 天 → emergencyResolve(任意 payouts)
```

#### 6.3 关键设计

**(a) `initialize` 完全 permissionless**
任何人可以创建新市场，自选 reward token（必须在 UMA whitelist）、reward 金额、bond、liveness。Polymarket UI 只是发起方之一，链上不限制谁能 init。

**(b) Initializer 钉进 ancillaryData**
`questionID = keccak256(ancillaryData_with_initializer)`——同一份问题文本由不同人发起会得到不同 questionId。UMA 投票人看得到是谁发起的。

**(c) 三种 OO 价格 + 一个 ignore 哨兵**
- `0` → `[YES=0, NO=1]`（NO 赢）
- `0.5 ether` → `[1, 1]`（UNKNOWN / 50-50，neg-risk 不支持）
- `1 ether` → `[1, 0]`（YES 赢）
- `type(int256).min` → 触发 `_reset` 重发请求

**(d) 异议只允许一次自动重置**
一个问题最多产生 2 次 OO 请求；第二次被异议就只能走 UMA DVM 全网投票。

**(e) Admin 紧急通道**
6 个 onlyAdmin 函数（flag / unflag / pause / unpause / reset / emergencyResolve），核心是 `flag` → 等满 2 天 `EMERGENCY_SAFETY_PERIOD` → `emergencyResolve(任意 payouts)`。

**(f) BulletinBoard 链上公告**
`postUpdate(questionID, update)` 让任何人附加 bytes 到一个公开 mapping。约定：只信 question creator 发布的 update。

### 7. 多结果路径的 oracle 翻译：NegRiskOperator

UmaCtfAdapter 调的是 CTF 的 `prepareCondition / reportPayouts`；NegRiskAdapter 暴露的是 `prepareQuestion / reportOutcome`。**NegRiskOperator 是中间的接口翻译层**：

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

### 8. 代理钱包旁路（贯穿用户层与撮合层）

普通 EVM 钱包要给每笔下单签一个 tx 上链——这对高频交易完全不可用。Polymarket 的解法：

```
用户 EOA ─签名─▶ Polymarket Operator ─代发 tx─▶ 链上
                  (帮你打包付 gas)
   │
   └── 资金/头寸不放在 EOA，放在智能合约钱包里：
       - PolyProxy: 自研轻代理（占绝大多数）
       - PolySafe : 基于 Gnosis Safe（高净值/机构）
```

合约层支撑：
1. **CREATE2 确定性部署**（`Create2Lib.sol` + `PolyProxyLib.sol`）——首次入金前地址就可知
2. **EIP-1271 验签**（`Signatures.sol`）——operator 用代理钱包地址调 Exchange，Exchange 反过来问代理钱包"这个签名是不是你 owner 签的"

后果：**官方交易流（通过 Polymarket UI）下用户的 pUSD 和 outcome shares 都放在代理钱包里**，EOA 主要用于签名而非持仓。技术上 EOA 完全可以接收 pUSD（ERC-20）或 outcome shares（ERC-1155）——只是非官方流程，UI 不会自动识别这种持仓。Smarts 查头寸时必须**两个地址都查**：先用 `getProxyWalletAddress(eoa)` 拿到代理地址查代理钱包，再直接查 EOA 兜底。

---

## 关键不变量与设计取舍

### 不变量（永远成立的事实）

1. **CTF 合约本身不可升级**——Gnosis 部署，没人能改
2. **CTF condition 的 oracle 绑死**——注册后无法更换
3. **NegRisk 不变量**：同一 market 内最多 1 个 question 报 YES
4. **EMERGENCY_SAFETY_PERIOD = 2 days**——admin 任何紧急动作都要等满 2 天
5. **UMA OO 单问题最多 2 次自动请求**——第二次异议必上 DVM

### 关键设计取舍

| 维度 | 选择 | 取舍 |
|---|---|---|
| 价格发现 | 链下订单簿 | 撮合中心化 ↔ UX 像 CEX |
| 资产托管 | 智能合约代理钱包 | 多一层合约风险 ↔ 用户不必逐笔签 tx |
| 多结果市场 | NegRiskAdapter + WCOL | 多一层抽象 ↔ 资本效率 ×N |
| 预言机 | UMA Optimistic Oracle | 委托给独立社区 ↔ 仲裁结果可争议 |
| 用户层 stablecoin | 自有 pUSD | 多一层合约 ↔ 屏蔽 USDC 迁移复杂度 |
| 版本演化 | 不下线、自然衰减 | 协议表面变大 ↔ 历史市场不被打断 |

---

## 信任拓扑

| 角色 | 谁持有 | 能做什么 | 限制来源 |
|---|---|---|---|
| **Admin** (Exchange) | Polymarket multisig | 改费率上限、暂停、注册新代币、管理 operator 集合 | 无链上限制（社会层）|
| **Operator** (Exchange) | Polymarket 后端地址 | 代发已签名订单的 matchOrders | Admin 可吊销 |
| **Admin** (UmaAdapter) | Polymarket multisig | flag / emergencyResolve（2 天安全期）| 硬编码 2 天 |
| **Oracle** (CTF condition) | UmaCtfAdapter / NegRiskAdapter | 写该 condition 的 payout | 创建时绑死 |
| **UMA 提议者/异议者** | 任何质押 UMA 的人 | 提案结果、提出异议 | UMA 协议本身的经济激励 |
| **MINTER_ROLE** (pUSD) | 持有 ROLE_0 的地址（Polymarket controlled）| `mint` / `burn` pUSD | pUSD owner 可 grant/revoke role |
| **WRAPPER_ROLE** (pUSD) | 持有 ROLE_1 的地址（Polymarket controlled）| `wrap` / `unwrap` pUSD 与底层 USDC 互换 | pUSD owner 可 grant/revoke role |
| **VAULT** (pUSD 储备) | 一个固定地址常量 | 存放 pUSD 背后的 USDC / USDC.e 储备金 | 仅作为储备地点，不持铸赎权 |
| **Admin** (NegRiskAdapter) | 构造时 = deployer，可 `addAdmin / removeAdmin / renounceAdmin` | 调 `safeTransferFrom` 替用户搬动 CTF 头寸（需用户先 setApprovalForAll）| `onlyAdmin` modifier；NegRisk **outcome rule 本身**（同 market 最多 1 个 YES）则在 `_reportOutcome` 硬编码不可改 |
| **NegRiskAdapter Oracle 角色** | 合约自身（写死） | 当 oracle 报 neg-risk 问题结果 | 在 `getConditionId` 里 hardcode `address(this)` |
| **用户** | EOA 持有人 | 签名授权代理钱包做任何事 | 代理钱包合约的逻辑 |

**关键观察**：Polymarket 不是"完全去中心化"也不是"完全中心化"。它在每一层做了不同的信任取舍——撮合中心化、托管去中心化、账本完全去中心化、预言机委托给独立社区、用户层和治理参数由 multisig 控制。

---

## 一句话总结

**底层一份不可变账本（Gnosis CTF）+ 用户层一份自有稳定币（pUSD，仅 v2 路径）+ 两条对称的 v2 撮合通道（binary 经 USDC.e、neg-risk 经 WCOL）+ 还在跑的两条 v1 通道（直持 USDC.e）+ 一个 permissionless 的预言机接入层（UMA OO V2）+ 一个 2 天硬安全窗的 admin 紧急通道。**

整套设计真正的"不可改变性"只锚定在 3 个地方：
1. **CTF 合约本身**（Gnosis 部署，没人能升级）
2. **UmaCtfAdapter 的 `EMERGENCY_SAFETY_PERIOD = 172800` 秒**（= 2 天，admin 任何紧急动作都要等满 2 天）
3. **NegRiskAdapter 的 NegRisk outcome rule 在 `_reportOutcome` 硬编码**（同一 market 最多 1 个 YES——合约本身可有 admin，但这条规则改不了）

其他所有层都是**可被新版本旁路**的——但旧版本永远不下线，老市场跑老合约直到自然结算。

---

## 附录 A：对 Smarts adapter 实现的具体启示

1. **NegRisk 一侧的所有 CTF 查询必须用 WCOL 地址做 positionId**——别用 USDC.e。要么读 NegRiskAdapter 的 `wcol()` 拿到地址，要么硬编码。
2. **从 UmaCtfAdapter 的 `questions(questionID)` 能拿到完整问题状态**——包括 ancillaryData（带 initializer 后缀）、reward token、是否被 flag 等。这是"这个市场是真的还是骗局"最权威的链上来源。
3. **查用户头寸要两个地址都查**：先 `getProxyWalletAddress(eoa)` 拿代理钱包地址查它，再直接查 EOA 兜底（非官方流程的持仓）。
4. **MarketData 的 bytes32 packing 在 UI 上要解开**——5 个字段（questionCount / determined / result / feeBips / oracle）每一个都有意义。
5. **convertPositions 是 Polymarket 独有的链上原语**，文档值得专门一页解释——传统 CTF 文档里不存在。
6. **v1 和 v2 是结构不同的 ABI**——见 §2.3 表格。查 collateral 信息时要做版本分支：v1 没有 `getCtfCollateral`、neg-risk v1 的 `getCtf` 返回 NegRiskAdapter。

---

## 附录 B：验证状态

| 来源 | 验证方式 |
|---|---|
| 所有合约地址、名字、ABI 形状 | live `get_contract_info`，block ~87,146,000 |
| 所有 view 函数返回值 | live `read_contract_state` |
| 所有源码引用（Auth.sol、Fees.sol、CollateralToken.sol、UmaCtfAdapter.sol 等）| Polygon 上 verified source |
| pUSD totalSupply | live `totalSupply()` = `375853763516069` (raw, 6 decimals, block 87,232,311) |
| pUSD 价格 | **未验证**——$1.0017 来自 CoinGecko 不是 view 函数 |
| convertPositions 数学描述 | NegRiskAdapter.sol 源码 + 推导，**未做链上压力测试** |
| UMA OO V2 地址 | UmaCtfAdapter v3 `optimisticOracle()` |
| EMERGENCY_SAFETY_PERIOD | UmaCtfAdapter v3 源码常量 `2 days = 172800 秒` |

### 变更历史

- **2026-05-19 v2**：根据 reviewer 反馈修订——v1 vs v2 路由差异、pUSD role 模型、WCOL 权限不对称、NegRiskAdapter 实际有 admin、EOA 持仓不再绝对、合约 verified name 校正、totalSupply 数字校正。
- **2026-05-19 v1**：首次草稿。

---

本文的所有链上数据，都是用 [Smarts](https://smarts.md/) 实时读出来的——它把任何已验证的 EVM 合约变成可查询的 live docs。
