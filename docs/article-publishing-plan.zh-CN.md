# 多语言文章发布系统计划

## 目标

- 在 Smarts 内部实现一个极简的多语言文章系统。
- 把文章作为 Smarts 的营销抓手，覆盖稳定币、链上风险、Polymarket、MCP、agent 工作流和产品叙事。
- 公开 URL 保持极短、稳定。
- 文章发布通过 MCP tools 完成，不做普通 API 优先。
- 暂时不抽 gem。先在 Smarts 里实现，等第二个真实项目复用后，再提炼稳定抽象。

## V1 不做

- 不做完整 CMS 后台。
- 不接入 X 发布系统。
- 不把分类放进 URL。
- 不做复杂 taxonomy、嵌套分类、标签、作者、系列或编辑流。
- 不做普通文章发布 API，除非后续出现非 agent 集成需求。

## URL 设计

公开文章 URL：

- 英文 / 默认：`/:slug`
- 简体中文：`/cn/:slug`
- 繁体中文：`/tw/:slug`

示例：

- `/7g`
- `/cn/7g`
- `/tw/7g`

Slug 规则：

- 固定两位。
- 只允许小写字母和数字：`[a-z0-9]{2}`。
- 不允许大写字母。
- 用户会主动规避未来应用路径冲突。

保留 slug：

```ruby
RESERVED_SLUGS = %w[
  up
  ai
  go
  to
  my
  me
  in
  on
]
```

说明：

- `/up` 已经是 Rails health check。
- `/ai` 预留给未来 AI / 产品入口。
- `/my` 预留给用户自己的 workspace、资产、watchlist、API keys、billing 等。
- `/me` 预留给个人 profile 或 identity。
- `/go` 和 `/to` 预留给短跳转、campaign 或 deeplink。
- `/in` 和 `/on` 预留给 sign in、onboarding、connect flow。
- `cn`、`tw` 不需要作为文章 slug 排除，因为本地化文章是两段路径，例如 `/cn/7g`。

路由优先级：

- 明确的系统路由放在 article route 前面。
- 两位 article route 放在现有 contract slug route 前面。
- 现有 contract slug 更长且受 `ContractSlugs::ROUTE_PATTERN` 约束，正常不会和两位文章 slug 冲突。

## 语言设计

V1 支持语言：

```ruby
SUPPORTED_LOCALES = %w[
  en
  zh-CN
  zh-TW
]
```

语言范围：

- `en`：英文。
- `zh-CN`：简体中文。
- `zh-TW`：繁体中文，覆盖台湾和香港受众。

公开路由：

- `en`：`/:slug`
- `zh-CN`：`/cn/:slug`
- `zh-TW`：`/tw/:slug`

路由到内部 locale 的映射：

```ruby
LOCALE_ROUTE_MAP = {
  "cn" => "zh-CN",
  "tw" => "zh-TW"
}
```

原则：

- 公开 URL 用短别名，符合 Smarts 的极简风格。
- 内部仍使用标准 locale key，便于 SEO、hreflang、翻译管理和未来兼容。

Fallback 顺序：

- 请求的 locale。
- 英文。
- 任意可用 locale。

可选重定向：

- `/zh/:slug` 未来可以重定向到 `/cn/:slug`。
- `/zh-CN/:slug` 未来可以重定向到 `/cn/:slug`。
- `/zh-TW/:slug` 未来可以重定向到 `/tw/:slug`。

## User 和 Account 模型

使用 Rails 8 自带 authentication，不用 Devise。

V1 包含：

- 通过 Rails 8 sessions 登录。
- 通过 `UsersController` 注册。
- 通过 Rails 8 signed password reset token 重置密码。
- API token 在注册或 rotate 后只显示一次。

`User` 字段：

```ruby
name:string
email_address:string
password_digest:string
api_token_prefix:string
api_token_digest:string
timestamps
```

规则：

- `email_address` 和 `password_digest` 使用 Rails 8 authentication 默认约定。
- MCP 发布工具仍接收明文参数 `publish_token`，但数据库只保存 `api_token_prefix` 和 `api_token_digest`。
- 明文 API token 只在生成时显示一次，不入库。
- API token 使用可识别前缀，例如 `sma_...`。
- 鉴权时先按 `api_token_prefix` 缩小候选，再用 BCrypt 校验 digest。

`Account` 字段：

```ruby
user_id:references
provider:string
handle:string
locale:string
access_token:string
access_token_secret:string
timestamps
```

规则：

- V1 `provider` 只支持 `x`。
- `locale` 必须是 `en`、`zh-CN`、`zh-TW` 之一。
- 一个 user 在同一 provider + locale 下只绑定一个 account。
- `access_token` 和 `access_token_secret` 使用 Active Record Encryption 加密保存。
- 使用时仍然方便：`account.access_token` 会返回解密后的值，可直接传给 `x_queue`。

未来接 `x_queue`：

```ruby
account = article.user.accounts.find_by!(provider: "x", locale: locale)

XQueue::Scheduler.thread(
  texts: tweets,
  account: account,
  source: article
)
```

## 数据模型

新增 `Article`。

字段：

```ruby
user_id:references
slug:string
category:string
subcategory:string
title:jsonb
summary:jsonb
content:jsonb
published_at:datetime
timestamps
```

索引：

- `slug` 唯一索引。
- `category` 索引。
- `[category, subcategory]` 组合索引。
- `published_at` 索引。

校验：

- `user` 必填。
- `slug` 必须匹配 `[a-z0-9]{2}`。
- `slug` 不能在 `RESERVED_SLUGS` 内。
- `category` 必填，且必须在允许列表内。
- `subcategory` 可选；如果存在，必须属于对应 `category`。
- `title` 至少有英文或中文。
- `content` 至少有英文或中文。

发布 scope：

```ruby
Article.published.where("published_at <= ?", Time.current)
```

## 两层分类设计

使用轻量的两层分类，让文章系统有内容框架，但不变成 CMS。

规则：

- `category` 是一级内容支柱。
- `subcategory` 是可选的二级细分。
- `category` 和 `subcategory` 都不进入公开 URL。
- 分类 key 是内部标识。
- 展示 label 在渲染时翻译。
- 分类和子分类未来可用于文章列表、相关文章、landing page 和 SEO cluster。

初始一级分类：

```ruby
CATEGORIES = %w[
  product
  stablecoins
  risk
  markets
  guides
  company
]
```

初始二级分类：

```ruby
SUBCATEGORIES = {
  "product" => %w[mcp tools workflows releases],
  "stablecoins" => %w[issuers reserves payments regulation infrastructure],
  "risk" => %w[admin-controls upgrades governance incidents compliance],
  "markets" => %w[polymarket prediction-markets liquidity resolution odds],
  "guides" => %w[setup integrations examples playbooks],
  "company" => %w[positioning updates roadmap]
}
```

校验：

```ruby
subcategory.blank? || SUBCATEGORIES.fetch(category, []).include?(subcategory)
```

这样既保留灵活性，又不会让 V1 依赖完整 taxonomy 系统。

翻译示例：

```yaml
en:
  article_categories:
    stablecoins: "Stablecoins"
  article_subcategories:
    stablecoins:
      infrastructure: "Infrastructure"
zh-CN:
  article_categories:
    stablecoins: "稳定币"
  article_subcategories:
    stablecoins:
      infrastructure: "基础设施"
zh-TW:
  article_categories:
    stablecoins: "穩定幣"
  article_subcategories:
    stablecoins:
      infrastructure: "基礎設施"
```

## Draft 文件结构

Draft 放在仓库里：

```text
docs/drafts/7g/
  meta.json
  en.md
  zh-CN.md
  zh-TW.md
```

未来发布后的源文件可以移动或复制到：

```text
docs/published/7g/
  meta.json
  en.md
  zh-CN.md
  zh-TW.md
```

`meta.json` 示例：

```json
{
  "category": "stablecoins",
  "subcategory": "infrastructure",
  "title": {
    "en": "Coinbase and Custom Stablecoins",
    "zh-CN": "Coinbase 与定制稳定币",
    "zh-TW": "Coinbase 與客製化穩定幣"
  },
  "summary": {
    "en": "A concise summary.",
    "zh-CN": "一段简短摘要。",
    "zh-TW": "一段簡短摘要。"
  }
}
```

Markdown 规则：

- 每个语言一个 Markdown 文件。
- 如果第一行是一级标题，发布器可以去掉，因为标题来自 `meta.json`。
- 正文 Markdown 存入 `content`。

## Service Objects

新增 service：

```text
app/services/articles/draft_reader.rb
app/services/articles/publisher.rb
```

`Articles::DraftReader`

- 读取 `docs/drafts/:slug`。
- 解析 `meta.json`。
- 加载各语言 Markdown。
- 去掉可选的第一行 `# Heading`。
- 校验缺失文件、不支持的 locale、非法分类、非法 slug 和空内容。
- 返回结构化 validation errors。

`Articles::Publisher`

- 使用 `DraftReader`。
- 创建或更新 `Article`。
- 设置 `published_at`。
- 返回各语言公开 URL。
- 支持 dry-run validation。
- V1 可以先不移动 draft 文件；等流程稳定后再加 `docs/published` 移动逻辑。

## MCP 发布工具

文章发布使用 MCP，不优先做普通 API。

原因：

- Smarts 是 MCP-native 产品，发布系统应该 dogfood 自己的核心能力。
- Codex、Claude 等 agent client 可以直接发布，不需要额外 HTTP 集成。
- Tool schema 比临时 API 更清晰。
- 真正业务逻辑在 service objects 里，未来如果需要 API 或 UI，也能复用。

新增 tools：

```text
list_article_drafts
validate_article_draft
publish_article
```

安全设计：

- 这些 tools 会挂在公开 MCP server 上，所以 V1 必须要求绑定 user 的发布 token。
- 每个发布 tool 都接收 `publish_token`。
- `publish_token` 通过 `User.api_token_prefix` + `User.api_token_digest` 鉴权。
- token 缺失或错误时返回 error，不执行 draft 读取或数据库写入。
- 发布后的文章记录 `article.user_id`。

Tool 行为：

- `list_article_drafts`：列出 draft slugs、语言和分类。
- `validate_article_draft`：校验单篇 draft，返回 blocking errors / warnings。
- `publish_article`：校验后创建或更新文章，并返回 URL。

返回 URL 示例：

```text
https://smarts.md/7g
https://smarts.md/cn/7g
https://smarts.md/tw/7g
```

## 页面渲染

新增 `ArticlesController#show`。

行为：

- 只查找已发布文章。
- 从路由参数解析 locale。
- fallback 到英文，再 fallback 到任意可用 locale。
- 渲染标题、分类 label、摘要、发布日期和 Markdown 正文。
- 添加 canonical URL。
- 添加基础 SEO metadata。

V1 页面风格：

- 复用 Smarts 现有视觉语言。
- 文章页优先保证可读、快速、干净。
- 文章数量不足时，先不做 index page。

## 测试

需要覆盖：

- `Article` slug 校验。
- reserved slug。
- category / subcategory 校验。
- locale fallback。
- published scope。
- 路由：
  - `/:slug`
  - `/cn/:slug`
  - `/tw/:slug`
  - `/up` 仍然是 health check。
- Draft reader validation。
- Publisher create/update。
- MCP tool payload。
- 现有 contract slug route 不受影响。

运行：

```bash
bin/rails test
```

## Gem 提炼策略

不要先抽 gem。

推荐路径：

1. 先在 Smarts 内实现。
2. 用 MCP 发布真实 Smarts 文章。
3. 等另一个项目需要同样工作流时，只提炼稳定部分：
   - `Article` engine / migrations
   - draft reader
   - publisher
   - MCP tools 或 adapters
   - route helpers
4. 项目自己的 marketing copy、分类、样式、SEO 留在 app 内，不进 gem。

可能的最终形态：

- 后续可以提炼成 Rails engine / gem。
- 第一版留在 app 内，避免过早固定错误抽象。

## 后续可选项

- 文章 index page。
- 分类 landing pages。
- 相关文章。
- hreflang tags。
- 作者 metadata。
- 通过 `x_queue` 发布到 X。
- 定时发布。
- Draft 发布后移动到 `docs/published`。
- Admin UI。
- 按文章 / 分类做 analytics。
