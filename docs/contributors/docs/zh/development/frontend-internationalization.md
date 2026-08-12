# 前端国际化

AlienCommons 前端正式支持英文和简体中文。项目在 Vue I18n 之上使用官方 `@nuxtjs/i18n` 模块，让路由、文案查询、语言切换、服务端渲染和本地化 SEO 共用同一套配置。

本文说明前端界面的本地化方案。用户发布的文章、社区帖子、评论和个人资料内容不会由前端自动翻译。

## 语言与路由策略

i18n 配置位于 `apps/frontend/nuxt.config.ts`。英文是默认语言，简体中文是第二语言：

```ts
i18n: {
  defaultLocale: "en",
  locales: [
    {
      code: "en",
      file: "en.json",
      language: "en-US",
      name: "English",
    },
    {
      code: "zh",
      file: "zh.json",
      language: "zh-Hans",
      name: "简体中文",
    },
  ],
  strategy: "prefix_except_default",
}
```

`prefix_except_default` 策略让英文 URL 不带语言前缀，中文 URL 则增加 `/zh`：

| 页面文件 | 英文 URL | 中文 URL |
| --- | --- | --- |
| `app/pages/index.vue` | `/` | `/zh` |
| `app/pages/login.vue` | `/login` | `/zh/login` |

不要分别创建英文和中文 Vue 页面。Nuxt I18n 会从同一个页面组件生成两条本地化路由。

## 浏览器语言检测

只有访客从根 URL 进入时才会检测浏览器语言，不会在站内导航时反复重定向：

```ts
detectBrowserLanguage: {
  cookieKey: "aliencommons_locale",
  fallbackLocale: "en",
  redirectOn: "root",
  useCookie: true,
}
```

选定的语言会保存在 `aliencommons_locale` Cookie 中。如果无法匹配浏览器语言，则使用英文。

## 翻译文件

界面文案存放在两个 JSON 文件中：

```text
apps/frontend/i18n/locales/
├── en.json  # 英文
└── zh.json  # 简体中文
```

两个文件必须使用相同的键结构。文案应该按功能分组，而不是按组件类型分组：

```json
{
  "auth": {
    "login": {
      "title": "Sign in to AlienCommons",
      "email": "Email",
      "password": "Password"
    }
  }
}
```

对应的中文文件使用相同的键：

```json
{
  "auth": {
    "login": {
      "title": "登录 AlienCommons",
      "email": "电子邮箱",
      "password": "密码"
    }
  }
}
```

翻译键应当表达语义并保持稳定。`auth.login.submit` 能说明文案的用途和所属功能；`blueButtonText` 则把翻译数据错误地绑定到了表现形式。

## 在组件中使用文案

模板可以直接使用注入的 `$t` 函数：

```vue
<h1>{{ $t("auth.login.title") }}</h1>
```

如果 `<script setup>` 中需要翻译值，包括响应式页面元数据，应使用 `useI18n()`：

```ts
const { t } = useI18n();

useSeoMeta({
  description: () => t("auth.login.description"),
  title: () => t("auth.login.metaTitle"),
});
```

这里使用回调形式很重要，因为客户端导航切换语言时，元数据也必须同步更新。

动态值应通过插值保留在完整的翻译句子中：

```json
{
  "auth": {
    "userMenu": {
      "avatarAlt": "{username} 的头像"
    }
  }
}
```

```vue
<img :alt="$t('auth.userMenu.avatarAlt', { username: user.username })" />
```

不要用多个翻译片段拼接句子。不同语言的语序和标点并不相同。

## 本地化导航

应用内链接应使用 `useLocalePath()`：

```ts
const localePath = useLocalePath();
```

```vue
<NuxtLink :to="localePath('login')">
  {{ $t("auth.login.navigation") }}
</NuxtLink>
```

英文环境下会解析为 `/login`，中文环境下会解析为 `/zh/login`。硬编码应用路径可能会把中文用户意外带回英文路由。

全局语言切换器位于 `app/components/LocaleSwitcher.vue`，使用 `SwitchLocalePathLink` 在等价页面之间切换，例如从 `/login` 切换到 `/zh/login`，而不是每次返回首页。

## SSR 与本地化 SEO

`app/composables/useSiteHead.ts` 会调用 `useLocaleHead({ seo: true })`，生成的 head 数据包括：

- `en-US` 或 `zh-Hans` 等文档语言；
- canonical 链接；
- `hreflang` 备用语言链接；
- 统一的 AlienCommons 标题模板。

每个页面通过 `useSeoMeta()` 提供本地化标题和描述。

生成绝对 canonical 和备用语言 URL 时需要公开的 i18n base URL。Compose 通过 `NUXT_PUBLIC_I18N_BASE_URL` 为不同环境提供配置：

```text
开发环境    http://localhost:8080
预发布环境  https://stg.aliencommons.com
生产环境    https://aliencommons.com
```

不要把特定环境的域名写进 `nuxt.config.ts`。

## 新增界面文案

功能需要新文案时：

1. 在该功能的命名空间下选择有语义的键。
2. 在同一次修改中把该键加入 `en.json` 和 `zh.json`。
3. 在模板中使用 `$t()`，在脚本中使用 `useI18n().t()`。
4. 应用内路由链接使用 `useLocalePath()`。
5. 新路由页面需要加入本地化 SEO 元数据。
6. 检查两个本地化 URL 以及语言切换器。

不要把界面文案直接写在 Vue 模板里，`aria-label`、空状态、校验信息、按钮标签和加载文本同样需要国际化。如果品牌名和技术标识本身与语言无关，可以有意保持不变。

## 验证

`apps/frontend/test/i18n.test.ts` 会递归比较 `en.json` 和 `zh.json` 的键。如果某种语言缺少键，测试就会失败；但这个测试无法判断翻译质量。

在仓库根目录运行前端检查：

```bash
pnpm turbo run check typecheck test build --filter=frontend
```

新增或修改路由时，还应检查：

- 英文和中文 URL；
- `<html lang>` 的值；
- 本地化 title 和 description 元数据；
- 同一页面上的语言切换；
- 较长翻译下的页面布局；
- 两种语言中的键盘操作和屏幕阅读器标签。

维护规则很简单：只有界面、导航、元数据和测试都能在两种受支持语言下正常工作，前端功能才算完成。
