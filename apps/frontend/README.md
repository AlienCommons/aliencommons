# AlienCommons Frontend

Nuxt 4 application with localized home, article and community pages, session
authentication, typed API requests and shared UI components.

## Setup

Make sure to install dependencies:

```bash
pnpm install --frozen-lockfile
```

## Development Server

Generate the TypeScript API contract after backend OpenAPI changes:

```bash
pnpm api:generate
```

Start the development server on `http://localhost:3000`:

```bash
NUXT_API_INTERNAL_BASE=http://localhost:8000 pnpm dev
```

Browser API requests use the same-origin `/api` path. During local development,
Nuxt proxies that path to `NUXT_API_INTERNAL_BASE`; the Docker Compose setup
configures this automatically.

The application supports English at `/` and Simplified Chinese at `/zh`.
Translations live in `i18n/locales`; keep both locale files structurally in
sync when adding interface copy.

Authentication uses Django's same-origin session cookie. The Nuxt session
plugin resolves the current user during SSR, while login and logout bootstrap
and submit the required CSRF token in the browser.

## Production

Build the application for production:

```bash
pnpm build
```

Locally preview production build:

```bash
pnpm preview
```

The API layer design and usage examples are documented in
[`app/api/README.md`](app/api/README.md).

## Verification and demo

From the repository root, run `pnpm turbo run check test typecheck --filter=frontend`.
`check` is static validation; `test` executes the unit suite. Run
`pnpm turbo run test:e2e --filter=frontend` for browser integration against a real,
disposable Django backend. The [development setup guide](../../docs/contributors/docs/en/development/setup.md)
covers prerequisites, Chromium installation and `make browser-backend` /
`make browser-frontend` for manual exploration.
