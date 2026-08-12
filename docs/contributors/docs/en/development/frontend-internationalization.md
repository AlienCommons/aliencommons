# Frontend Internationalization

The AlienCommons frontend officially supports English and Simplified Chinese. It uses the official `@nuxtjs/i18n` module on top of Vue I18n, so routing, message lookup, language switching, server-side rendering, and localized SEO all share one configuration.

This page describes the frontend interface localization system. User-generated articles, community posts, comments, and profile content are not translated automatically.

## Language and Route Strategy

The i18n configuration lives in `apps/frontend/nuxt.config.ts`. English is the default locale and Simplified Chinese is the secondary locale:

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

The `prefix_except_default` strategy keeps English URLs unprefixed and adds `/zh` to Chinese URLs:

| Page file | English URL | Chinese URL |
| --- | --- | --- |
| `app/pages/index.vue` | `/` | `/zh` |
| `app/pages/login.vue` | `/login` | `/zh/login` |

Do not create separate English and Chinese Vue page files. Nuxt I18n generates both localized routes from the same page component.

## Browser Language Detection

Language detection runs only when a visitor enters at the root URL. It does not repeatedly redirect visitors while they navigate:

```ts
detectBrowserLanguage: {
  cookieKey: "aliencommons_locale",
  fallbackLocale: "en",
  redirectOn: "root",
  useCookie: true,
}
```

The selected locale is remembered in the `aliencommons_locale` cookie. English is used when the browser language cannot be matched.

## Translation Files

Interface messages are stored in two JSON files:

```text
apps/frontend/i18n/locales/
├── en.json  # English
└── zh.json  # Simplified Chinese
```

Both files must have the same key structure. Group messages by feature instead of by component type:

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

The matching Chinese file uses the same keys:

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

Keep keys semantic and stable. A key such as `auth.login.submit` communicates where and why a message is used; a key such as `blueButtonText` couples translation data to presentation.

## Using Messages in Components

Templates can use the injected `$t` function:

```vue
<h1>{{ $t("auth.login.title") }}</h1>
```

Use `useI18n()` when a translated value is needed in `<script setup>`, including reactive page metadata:

```ts
const { t } = useI18n();

useSeoMeta({
  description: () => t("auth.login.description"),
  title: () => t("auth.login.metaTitle"),
});
```

The callback form is important because the metadata must update when the active locale changes during client-side navigation.

Interpolation keeps dynamic values inside the translated sentence:

```json
{
  "auth": {
    "userMenu": {
      "avatarAlt": "{username}'s avatar"
    }
  }
}
```

```vue
<img :alt="$t('auth.userMenu.avatarAlt', { username: user.username })" />
```

Do not assemble translated sentences from several fragments. Word order and punctuation differ between languages.

## Localized Navigation

Use `useLocalePath()` for application links:

```ts
const localePath = useLocalePath();
```

```vue
<NuxtLink :to="localePath('login')">
  {{ $t("auth.login.navigation") }}
</NuxtLink>
```

This resolves to `/login` in English and `/zh/login` in Chinese. Hard-coded application paths can accidentally send a Chinese visitor back to the English route.

The global language selector is implemented in `app/components/LocaleSwitcher.vue` with `SwitchLocalePathLink`. It switches the locale while retaining the equivalent page, such as `/login` to `/zh/login`, rather than returning to the homepage.

## SSR and Localized SEO

`app/composables/useSiteHead.ts` calls `useLocaleHead({ seo: true })`. The generated head data includes:

- the document language, such as `en-US` or `zh-Hans`;
- canonical links;
- `hreflang` alternate links;
- the shared AlienCommons title template.

Each page supplies its translated title and description through `useSeoMeta()`.

Absolute canonical and alternate URLs require the public i18n base URL. Compose configures it per environment through `NUXT_PUBLIC_I18N_BASE_URL`:

```text
development  http://localhost:8080
staging      https://stg.aliencommons.com
production   https://aliencommons.com
```

Keep environment-specific domains out of `nuxt.config.ts`.

## Adding Interface Copy

When a feature needs new text:

1. Choose a semantic key under the feature namespace.
2. Add the key to both `en.json` and `zh.json` in the same change.
3. Use `$t()` in templates or `useI18n().t()` in script.
4. Use `useLocalePath()` for links to application routes.
5. Add translated SEO metadata for new route pages.
6. Check both localized URLs and the language switcher.

Avoid placing interface copy directly in Vue templates, including `aria-label`, empty states, validation messages, button labels, and loading text. Brand names and technical identifiers may remain unchanged when they are intentionally language-neutral.

## Verification

`apps/frontend/test/i18n.test.ts` recursively compares the keys in `en.json` and `zh.json`. The test fails if one locale is missing a key, although it cannot judge translation quality.

Run the frontend checks from the repository root:

```bash
pnpm turbo run check typecheck test build --filter=frontend
```

For a new or changed route, also verify:

- the English and Chinese URLs;
- the `<html lang>` value;
- translated title and description metadata;
- language switching on the same page;
- layout at the longer of the two translations;
- keyboard and screen-reader labels in both languages.

The maintenance rule is simple: a frontend feature is not complete until its interface, navigation, metadata, and tests work in both supported languages.
