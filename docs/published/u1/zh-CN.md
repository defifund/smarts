---
date: 2026-05-26
source: https://smarts.md/ MCP (get_contract_info / get_admin_risk / get_erc20_info / read_contract_state / get_contract_source / get_governance_timeline)
contract: 0x8d0d000ee44948fc98c9b98a4fa4921476f08b0d (StablecoinV2)
verified_block: 25182415
tags: [stablecoin, usd1, smart-contract, risk, smarts]
status: draft
---

# USD1 的控制栈：mint、freeze 和签名转账

合约：`0x8d0d000ee44948fc98c9b98a4fa4921476f08b0d`（`StablecoinV2`）

代理实现：`0x694aa534bdef8ed63244eb902e7914e527891f08`

表面规模：`19 view / 23 write / 17 events`

当前快照（截至区块 `25182415`）：

- `name = World Liberty Financial USD`
- `symbol = USD1`
- `decimals = 18`
- 现有供应量 = `1,922,063,260.45 USD1`
- 现价 = 约 `$0.9985`
- 市值 = 约 `$1.92B`
- `paused = false`
- 治理时间线 = 总共 `1` 条事件，只有 `Initialized(version 2)`，区块 `24809916`

从外面看，USD1 像一枚普通美元稳定币。
但合约展开后能看到一套更大的控制栈。

它是一个可升级的稳定币实现，带有 owner 级别的 mint / burn，整套 pause / freeze 控制，冻结资金的回收路径，以及签名授权转账流程。换句话说，它不是单纯的余额表，而是一套可运营的资金系统。

真正该问的不是 USD1 能不能转账。
它当然能。
更重要的是：除了普通 `transfer` 之外，它还暴露了哪些路径、谁能触发这些路径、哪些状态变化会留下链上痕迹。

---

## 先说结论

USD1 和普通 ERC-20 的差别主要体现在三点。

1. 它有明确的管理面：`mint`、`burn`、`freeze`、`unfreeze`、`pause`、`unpause`、`drain`、`reallocate`、`recoverERC20`。
2. 它不只依赖 `approve` / `transferFrom`，还同时支持 EIP-2612 `permit` 和 EIP-3009 两套签名授权路径。
3. 当前治理历史几乎是空的。也就是说，这份合约虽然暴露了很多权限，但在我们采样到的窗口里，真正发生的治理动作只有初始化，没有持续的角色变化。

还有一个很重要的小细节：`renounceOwnership()` 是故意写成报错的。

这表示 owner 不是打算退出的角色，而是一个必须长期保留的控制面。

---

## 当前快照

当前状态很直接（截至区块 `25182415`）：

| 项目 | 当前值 |
|---|---|
| 名称 | `World Liberty Financial USD` |
| 符号 | `USD1` |
| 精度 | `18` |
| 供应量 | `1,922,063,260.45 USD1` |
| 价格 | 约 `$0.9985087024` |
| 市值 | 约 `$1,919,196,892.24` |
| Owner | `0xee9b1a09aedaced9dcda74964ea447feb93861c2` |
| 暂停状态 | `false` |
| 最近治理 | 仅 `Initialized(version 2)` |

这个 owner 地址本身也是一个合约地址，不是普通 EOA。

我不会在没有更多证据的情况下替它下结论，但至少可以确定一件事：USD1 的控制面不是直接暴露给一个普通钱包。

这和它的整体设计是匹配的。它不是一个追求“最小权限、最少功能”的简单代币。

---

## 控制栈

源码里最关键的东西很清楚。

### 1. owner 直接控制供给

`mint(uint256 amount)` 和 `burn(uint256 amount)` 都是 `onlyOwner`。

这意味着发行和销毁不是分散给很多 minter，而是直接由顶层 owner 掌握。它和很多“主 minter + 配额”式设计不一样。

### 2. 全局暂停

合约里有 `pause()` 和 `unpause()`，而转账与授权路径都受 `whenNotPaused` 约束。

这说明它不是只有地址级冻结，没有系统级开关。它可以直接把整条转账链路停下来。

### 3. 地址冻结

`freeze(address account)` 和 `unfreeze(address account)` 维护公开的 `frozen[address]` 映射。

转账和授权的内部检查会拦住被冻结参与者。也就是说，这个冻结状态不是摆设，真的会改变代币行为。

### 4. 冻结资金回收

V2 版本额外加了三个管理员路径：

- `drain(address account)`
- `reallocate(address from, address to, uint256 amount)`
- `recoverERC20(address token, address recipient, uint256 amount)`

这三条路让 USD1 更像一个“资金操作系统”，而不只是一个转账接口。

`drain` 可以把被冻结账户的全部余额转到 owner 名下。

`reallocate` 可以把被冻结源账户里的资金挪到替代账户。

`recoverERC20` 可以把误转进合约的其他代币救回去。

这已经明显超出普通 ERC-20 的范围。

### 5. 这个 owner 不打算被撤销

`renounceOwnership()` 直接 revert。

这不是意外，而是刻意设计。很多合约会允许 owner 彻底退出，这份合约不会。读风险时，这个点要放在前面看。

---

## 授权路径

USD1 在标准 `approve / transferFrom` 之外，还挂了两套签名授权路径：EIP-2612 `permit` 和 EIP-3009。也就是说它实际上有三条授权方式。

第一条是 EIP-2612。合约继承自 OpenZeppelin 的 `ERC20PermitUpgradeable`，所以会暴露 `permit(owner, spender, value, deadline, v, r, s)`。用一次签名替代一次链上的 `approve`，授权额度仍然记在 `allowance` 里，后面还要 `transferFrom` 才能动账。

第二条是 EIP-3009，它支持：

- `transferWithAuthorization`
- `receiveWithAuthorization`
- `cancelAuthorization` / `batchCancelAuthorization`
- `authorizationState(authorizer, nonce)`

EIP-3009 不是签名授权额度，而是一次性的链下签名直接转账。用户先离线签名，再由别的人把交易提交上链。对 relayer、商户收款流程、以及不想让每个用户都自己付 gas 的钱包 UX 来说，这很有用。

合约用 `bytes32 nonce` 跟踪 EIP-3009 授权是否已经用掉，所以重放控制是显式的，不是靠”大家自觉”。

差别整理一下：

1. `approve` 是链上交易直接授权额度。
2. `permit` 是 EIP-2612 签名版的 `approve`，省一次链上交易，仍然要配合 `transferFrom`。
3. `transferWithAuthorization` 是 EIP-3009 的一次性签名转账，不走 allowance。
4. `cancelAuthorization` 可以把还没用掉的 EIP-3009 授权提前作废。

所以 USD1 不是只会转账的代币，而是带有更丰富指令层的支付系统。

---

## 这个样本说明了什么

采样到的治理时间线很安静。

总共只有一条事件：`Initialized(version 2)`，区块 `24809916`。

这不代表合约没有权限，而是代表这些权限在采样窗口里没有被频繁改写。

这个区分很重要。很多人看稳定币，只会问“它能不能冻结、能不能暂停”。更好的问题是：这些控制权有没有在持续被使用？如果在使用，是怎样使用的？

在这个样本里：

1. 控制面很大。
2. 最近治理动作很少。
3. 代币已经在运行，价格接近 1 美元，供应量也已经到几十亿级别。

所以它是一个在运行中的系统，但近期并不“喧闹”。

---

## 应该盯什么

如果你要认真监控 USD1，优先看这些：

- `paused()` 的变化
- `Freeze` 和 `Unfreeze`
- `FrozenAccountDrained` 和 `FrozenFundsReallocated`
- `AuthorizationUsed` 和 `AuthorizationCanceled`
- owner 地址是否变化
- 如果发生升级，implementation 是否变化

重点是：像 USD1 这样的稳定币，不需要很大的事件流就会产生高信号。

一次 pause、freeze、drain 或 ownership 变化，本身就足够重要。

如果你只盯价格和供应量，你会漏掉系统行为。
如果你盯住管理面，你才会知道这到底是什么样的“美元系统”。

---

## 最后判断

USD1 更像一个可控的稳定币系统，而不只是余额表。

它是一个可控的稳定币系统，具备：

- owner 级别的发行和销毁能力
- 全局暂停与地址冻结
- 冻结资金回收路径
- EIP-2612 `permit` 与 EIP-3009 两套签名授权
- 故意不允许 renounce 的 owner 模型

真正的故事就在这里。

ticker 说的是“美元代币”。
合约说的是“可运营系统”。
