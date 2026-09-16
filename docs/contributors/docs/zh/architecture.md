# 项目架构

本文描述当前实现。产品目标见[产品定位](product/index.md)，未确认决策见[开放问题](product/open-questions.md)。
下文路径均相对于仓库根目录。源码链接指向 `dev`；处理其他分支时应查看该工作区的同名文件。

## 运行边界

| 组件 | 职责 | 调用或依赖 |
| --- | --- | --- |
| Nuxt（`apps/frontend`） | SSR、本地化路由、页面展示、会话 UI | 通过类型化 API 客户端调用 Django |
| Django（`apps/backend`） | 权限、业务流程、API 响应封装 | PostgreSQL、Redis、后台任务、AlienMark HTTP |
| AlienMark 服务（`apps/alienmark`） | 内部 HTTP Markdown 渲染 | `packages/alienmark` |
| AlienMark 库（`packages/alienmark`） | Markdown 解析与 HTML 渲染 | 被服务和前端复用 |
| DRF 响应库（`packages/drf-std-response`） | 成功及错误响应契约 | 被 Django 视图和异常处理器使用 |
| RQ Worker / 调度器 | 后台执行和定时任务 | Django 服务及 Redis |

浏览器请求 `/api/v1/...`，由 Nuxt 开发代理或部署代理转发到 Django 的 `/v1/...`。
SSR 直接使用 `NUXT_API_INTERNAL_BASE`；这个内部地址是后端源站地址，不带 `/api`。
PostgreSQL 和 Redis 用于正常运行环境；单元测试使用独立 SQLite、内存缓存和即时任务。
浏览器演示环境每次创建临时数据库，参见[开发环境](development/setup.md)。

## 登录与会话流程

1. `app/components/auth/LoginForm.vue` 调用 `useAuthSession().login()`。
2. `ensureCsrfToken()` 初始化浏览器 Cookie；`app/api/session.ts` 通过
   `app/plugins/api.ts` 创建的每应用／请求独立客户端提交凭证。
3. Django 的 `SessionViewSet.login` 使用 `EmailBackend` 认证：要求存在已验证的
   `EmailAddress`、密码正确且用户处于活动状态。
4. Django 创建会话，`users/services/sessions.py` 记录设备及会话元数据。
5. 前端获取当前用户并更新 Pinia 状态。SSR 只转发当前请求的 Cookie，客户端和认证状态
   不可跨请求共享。退出登录清理会话记录及 UI 状态。

| 实现入口 | 回归验证 |
| --- | --- |
| [前端 API 边界](https://github.com/AlienCommons/aliencommons/blob/dev/apps/frontend/app/api/README.md) | [客户端测试](https://github.com/AlienCommons/aliencommons/blob/dev/apps/frontend/test/api-client.test.ts)、[会话测试](https://github.com/AlienCommons/aliencommons/blob/dev/apps/frontend/test/session-api.test.ts) |
| [会话端点](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/users/views/sessions.py) | [用户 API 测试](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/users/tests/test_views.py) |
| [会话 composable](https://github.com/AlienCommons/aliencommons/blob/dev/apps/frontend/app/composables/useAuthSession.ts) | [浏览器冒烟测试](https://github.com/AlienCommons/aliencommons/blob/dev/apps/frontend/e2e/smoke.e2e.ts) |

## 文章审核与发布流程

视图负责权限和对象选择；事务服务函数锁定文章，再调用 `ArticleWorkflow`。
业务决策放在服务层，同时检查查询集过滤和对象权限。

| 数据记录 | 职责 |
| --- | --- |
| `Article` | 稳定的作者／流程标识；草稿、待审核、已发布或已撤稿 |
| `ArticleSource` | 可编辑的标题、Markdown 和源版本 |
| `ArticleSnapshot` | 提交时冻结的内容及审核结果 |
| `ArticlePublication` | 公开入口，其 UUID 不同于文章 UUID |
| `ArticlePublicationVersion` | 已通过审核快照的渲染内容 |
| `ArticleEvent` | 操作者与流程动作历史 |

当前转换为：草稿提交后进入待审核；撤回或拒绝后回到草稿；通过后进入已发布；
撤稿后进入已撤稿；保存已撤稿文章后回到草稿。提交会检查正文、相同快照哈希以及
审核后的六小时冷却。审核通过时通过 AlienMark 渲染 Markdown 并创建公开版本。
撤稿会删除公开入口及其版本。待审核文章不可删除，其他状态软删除并移除公开入口。

当前不能直接编辑已发布文章的源内容。“保留旧公开版本，同时修改并审核新版本”是产品目标，
尚未形成完整的已实现流程。不要根据版本模型的存在推断该能力，也不要在维护任务中隐式补做。
参见[专栏作品](product/articles.md)。

阅读[流程服务](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/articles/services/articles.py)、
[模型](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/articles/models/articles.py)和
[权限](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/articles/permissions.py)。
使用[服务测试](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/articles/tests/test_services.py)、
[API 测试](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/articles/tests/test_views.py)
及浏览器列表／详情测试验证。浏览器样例采用可信的预渲染 HTML，不验证 AlienMark HTTP 渲染链路。

## 通知流程

1. 评论、帖子和发布服务为提及、评论回复、已关注作者发布内容创建事件，使用唯一去重键。
2. `create_event()` 通过 `transaction.on_commit` 排队，因此投递在外围数据库事务提交后开始。
3. `fan_out_notification_event_task` 调用 `fan_out_event()`，锁定事件并为收件人创建投递记录。
   事件／收件人唯一约束防止重复投递，重试扫描处理待投递和失败事件。
4. 收件箱端点按收件人隔离数据，提供已读／未读状态。

这些后端能力已经存在；前端尚无收件箱页面。审核结果通知、点赞通知等产品选择仍待确定。
阅读[服务](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/notifications/services.py)、
[任务](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/notifications/tasks.py)和
[视图](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/notifications/views.py)。
使用[服务测试](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/notifications/tests/test_services.py)和
[API 测试](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/notifications/tests/test_views.py)验证。
测试入队时机时，应显式处理事务提交回调。

## 契约与修改导航

Django 生成 `apps/backend/openapi/v1.yaml`，再生成
`apps/frontend/app/api/generated/v1.d.ts`。两者均受版本控制并检查漂移。
修改序列化器、路由、权限或响应结构时，按[开发环境](development/setup.md)中的验证矩阵执行。

先读最近的 `AGENTS.md`，再按上面的业务路径定位。GitNexus 可用且索引有效时优先使用；
否则使用 `rg` 检查调用方、框架注册和测试，包括路由、信号、任务入口和 Nuxt 自动导入。
应说明不确定性，不能因为没有搜到文本引用就断言没有调用方。
