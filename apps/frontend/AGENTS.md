# Frontend Agent Guide — `apps/frontend/`

Nuxt 4 + Vue Composition API, TypeScript, Pinia, Tailwind CSS 4 and Nuxt i18n.
The app implements the home page, session login/logout, public articles and
community posts, in English and Simplified Chinese.

## Stack

- Nuxt 4
- Vue 3
- Vue Router
- Pinia
- Nuxt Icon
- Tailwind CSS 4
- AlienMark workspace library
- TypeScript
- Vite through Nuxt

## Structure

| Area | Responsibility |
| --- | --- |
| `app/pages/` | Route composition and page metadata |
| `app/components/{articles,auth,community,home}/` | Feature presentation |
| `app/components/ui/` | Shared UI; read its `README.md` before extending |
| `app/composables/` | Nuxt data loading, session and feature orchestration |
| `app/api/` | Typed requests and envelope/error handling; read its `README.md` |
| `app/api/generated/v1.d.ts` | Generated OpenAPI types; never edit by hand |
| `app/plugins/{api,session}.ts` | Per-request API client and session initialization |
| `app/stores/auth.ts`, `app/middleware/` | Session state and route guards |
| `i18n/locales/{en,zh}.json` | Matching translation keys |
| `test/` | Vite+ unit tests for API, stores and utilities |
| `e2e/`, `playwright.config.ts` | Real-browser tests with a disposable Django backend |

Use `<script setup lang="ts">`. Keep pages thin and reuse existing feature
composables and UI components. User-facing strings belong in both locale files.
English routes are unprefixed; Chinese routes use `/zh`. Use locale-aware links.
Nuxt deduplicates repeated directory/file prefixes in component names: verify
names in `.nuxt/components.d.ts` rather than guessing a repeated prefix.

Browser API calls use the same-origin `/api` proxy; SSR uses
`NUXT_API_INTERNAL_BASE` and forwards only the incoming request's cookie.
Never share a session-bearing client across SSR requests. Use `useApi()` for
interactions and `useApiData()` with stable keys for SSR data. Preserve the CSRF
bootstrap and token refresh behavior when changing authentication.

## Verification

Run from the repository root:

```bash
pnpm turbo run check test typecheck --filter=frontend
pnpm --filter frontend api:check
# Page, session, SSR or backend/frontend integration changes:
pnpm turbo run test:e2e --filter=frontend
# Build/configuration changes:
pnpm turbo run build --filter=frontend
```

`check` runs static checks, not tests. `typecheck` uses build mode to traverse
Nuxt's TypeScript project references; a bare `vue-tsc --noEmit` checks the empty
root project only. Playwright tests live outside `test/` and
run separately. Follow the [setup guide](../../docs/contributors/docs/en/development/setup.md)
for dependency installation, browser installation and interactive demo startup.
The browser suite owns its servers and refuses to reuse an occupied port.
Inspect screenshots/traces on failures; generated reports remain untracked.

When the public API contract changes, follow the root guide's schema generation
steps and include both the backend schema and generated frontend types.
