# 开发环境

除非特别说明，下列命令从仓库根目录执行。使用 Node 24、`package.json` 固定的 pnpm、
Python 3.14 和 uv（CI 中的 uv 版本固定在 `.github/workflows/ci.yml`）。
仅完整运行栈需要 Docker；单元测试和浏览器演示不需要。

## 安装与诊断

```bash
corepack enable
pnpm install --frozen-lockfile
uv sync --locked --all-packages --dev
make doctor
```

锁定安装不应重新生成锁文件；Nuxt 的 postinstall 会准备生成类型。
`make doctor` 检查 Node/pnpm、uv、后端依赖导入和 Nuxt 准备状态，不安装依赖或读取密钥值。
失败时返回非零退出码并给出修复命令。可选检查：

```bash
node scripts/doctor.mjs --browser
node scripts/doctor.mjs --docker
```

缺少可选的 GitNexus CLI 只给出提示；仅指定 `--browser` 时，缺少 Chromium 才算失败。
浏览器检查还会拒绝被占用的 IPv4/IPv6 测试端口，`test:e2e` 会自动执行这项预检。
仅指定 `--docker` 时检查 Compose 和 Docker daemon。

## 快速本地检查

```bash
make backend-check
make backend-lint
make backend-test
make backend-test TEST_ARGS="users.tests.test_views --verbosity 2"
pnpm turbo run check test typecheck --filter=frontend
pnpm turbo run check test --filter=alienmark
```

后端测试目标显式选择 `backend.settings.test`，并在 `apps/backend` 中运行以发现完整测试集。
它使用 SQLite、内存缓存、本地邮件和即时任务，无需 PostgreSQL、Redis、S3 或远程凭证。
`check` 是静态检查，不执行 Node 行为测试。前端 `typecheck` 使用
`vue-tsc --build --noEmit` 遍历 Nuxt 项目引用；不带 build 模式只检查空的根项目。
也可以在 `apps/backend` 中直接运行：

```bash
uv run --locked --package aliencommons-backend python manage.py test --settings=backend.settings.test
```

`manage.py` 默认使用开发配置，需要隔离测试时不要省略 settings。
新单元测试复用 `core.tests.factories` 和共享测试基类，不依赖演示数据。

## 浏览器集成与交互演示

```bash
pnpm --filter frontend exec playwright install chromium
node scripts/doctor.mjs --browser
pnpm turbo run test:e2e --filter=frontend
```

Linux CI 使用 `pnpm --filter frontend exec playwright install --with-deps chromium`
安装浏览器系统依赖。Playwright 在 `127.0.0.1:43101` 启动 Django，
在 `127.0.0.1:43100` 启动 Nuxt。测试拒绝复用现有服务，请先停止手动演示进程。
每次运行创建临时 SQLite 数据库和媒体目录，执行迁移及固定样例初始化，正常退出后删除。
它不会修改 Compose 或单元测试数据库，各测试之间使用独立浏览器上下文。

手动探索时，在两个终端分别运行：

```bash
# 终端 1：带样例数据的临时 Django API
make browser-backend
```

```bash
# 终端 2：通过同源 /api 代理访问后端的 Nuxt
make browser-frontend
```

打开[本地演示](http://127.0.0.1:43100)。使用 `reader@demo.invalid`、
`author@demo.invalid` 或 `moderator@demo.invalid` 登录，密码均为 `local-demo-only`。
这些是公开的一次性演示凭证。审核员仅有产品审核标记，没有 staff/superuser 权限。
样例包括草稿、待审核、已发布、已撤稿文章，以及一条社区帖。
重启后端即可重置数据，两个终端均使用 Ctrl+C 停止。

`seed_demo` 使用稳定标识，在同一数据库重复运行时保留已编辑的样例。
除非显式启用 `ALLOW_DEMO_DATA`，它会拒绝执行；仓库只有 browser 配置启用该选项。
启动器覆盖继承的 settings 并独占临时目录，部署环境不可启用此选项。
样例使用可信的预渲染 HTML；文章流程和 AlienMark HTTP 行为由其他测试覆盖。

浏览器测试覆盖 hydration 前禁用登录、错误／正确登录、刷新与 SSR 会话、退出、
服务端文章渲染及详情、
语言切换、社区详情和缺失文章的 404 恢复。失败截图和 trace 保存在
`apps/frontend/test-results/`；使用 `pnpm --filter frontend exec playwright show-report`
查看 HTML 报告。CI 上传失败证据；报告和浏览器下载不纳入源码。

## 完整运行栈

```bash
node scripts/doctor.mjs --docker
make dev-up
make dev-backend-migrate
```

使用已提交的本地 `env/.env.dev` 和 Compose 定义，运行前端、API、AlienMark、
PostgreSQL、Redis、Worker、调度器和可观测性服务。日志和生命周期命令见 `make/docker.mk`。
`make dev-down` 停止服务并保留数据卷。此环境验证真实服务集成；轻量浏览器测试
不验证 PostgreSQL 锁、RQ 投递、S3 或部署代理行为。

## 按修改范围验证

| 修改 | 必需检查 |
| --- | --- |
| Node 代码 | 包级 `check`；行为改变时执行 `test` |
| Vue 组件／composable | 前端 `check test typecheck`；页面、会话、SSR 集成改变时执行浏览器测试 |
| 后端行为 | `make backend-lint`、`make backend-check`、相关 `make backend-test TEST_ARGS="..."` |
| 模型 | 后端测试与聚焦的迁移；检查 `makemigrations --check --dry-run --settings=backend.settings.test` |
| 公开 API | 按下方步骤生成契约；后端测试、前端 API 测试和 `api:check` |
| 浏览器启动器或样例 | `make backend-test TEST_ARGS=core.tests.test_seed_demo`、后端 lint 和浏览器测试 |
| 构建／运行配置 | 对应包构建与集成检查 |
| 贡献者文档 | 先英文、后中文的两次严格构建 |
| Doctor | 默认及适用的可选模式，根脚本 lint／格式检查 |

```bash
# API 契约：在 apps/backend 中
DJANGO_SETTINGS_MODULE=backend.settings.test uv run --locked --project ../.. --package aliencommons-backend python manage.py spectacular --file openapi/v1.yaml --validate --fail-on-warn
# 然后回到仓库根目录
pnpm --filter frontend api:generate
pnpm --filter frontend api:check
```

包含两个发生变化的契约文件，不手工修改生成类型。

```bash
# 在 docs/contributors 中
uv run --locked --package aliencommons-contributor-docs zensical build --strict
uv run --locked --package aliencommons-contributor-docs zensical build --strict --config-file zensical.zh.toml
```

CI 分别执行后端测试、Node 测试、Vue 类型检查、契约漂移检查和浏览器集成检查。
后端或 Node 变化触发浏览器检查，文档按站点检查。新增共享工具时同步路径过滤规则。
无法运行的检查应明确说明，不可报告为通过。

## 可选代码导航

### Turborepo Agent Skill

将 [Turborepo 官方 Skill](https://turborepo.dev/docs/guides/ai) 安装到代理的个人
Skill 目录。上游路径是 `vercel/turborepo/skills/turborepo`；对于 Skills CLI 支持的客户端：

```bash
npx skills add vercel/turborepo --skill turborepo --agent codex --global
```

确认客户端的可用 Skill 列表中出现 `turborepo`。Codex 新安装的 Skill 在下一轮对话可用。
该 Skill 提供 Node 工作区指导；后端和文档检查仍使用 uv/Make。

### GitNexus MCP

GitNexus 是可选工具，参见其[安装说明](https://github.com/abhigyanpatwari/GitNexus#readme)。
使用 `npm install --global gitnexus@VERSION` 安装经过审阅的发行版，将 `VERSION`
替换为选定的精确版本，并记录在个人环境配置中；普通任务不隐式安装最新版。
从仓库根目录执行 `gitnexus --version`、`gitnexus status`，需要更新索引时执行
`make code-index`，它通过 `gitnexus analyze --index-only` 保留自定义代理指令。
使用 `make code-index-status` 检查索引状态；切换分支、拉取变更或修改源码后刷新索引。
状态命令用于诊断，不是 CI 门禁。本机集成已使用 GitNexus `1.6.11` 验证。

将代理的 MCP 客户端配置为启动命令 `gitnexus`、参数 `mcp`，或使用 `gitnexus setup`
配置支持的编辑器。确认客户端暴露 query/context/impact 工具，且索引对应当前分支和提交。
本地存在索引并不能证明代理具备 MCP 访问能力。索引和个人客户端配置继续被忽略，
共享规则纳入版本控制。仓库流程不依赖自动生成的 `.claude/skills` 文件。

Codex 使用 `codex mcp add gitnexus -- gitnexus mcp` 注册已安装的命令。
如果桌面客户端的 PATH 与终端不同，使用 Node 和 GitNexus CLI 入口的绝对路径。
新服务未出现时重新加载客户端或会话。使用 `repo: "aliencommons"` 实际验证
`list_repos`、`query`、`context`、`impact` 和 `detect_changes`，仅存在配置不足以证明连接可用。
不要将 partial/unknown 结果、动态分派边界或未解析的 Python/TypeScript 关系
解释成没有受影响调用方。

CLI、MCP 连接或当前索引不可用时，按根 `AGENTS.md` 使用 `rg` 检查定义、调用方、
路由／信号／任务和测试，报告影响范围及不确定性，并运行针对性测试。
提交前审阅完整 diff 并执行 `git diff --check`。不要依据过时的图判断修改安全。
