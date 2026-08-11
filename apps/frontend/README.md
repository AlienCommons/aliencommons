# AlienCommons Frontend

Minimal Nuxt 4 application scaffold.

## Setup

Make sure to install dependencies:

```bash
pnpm install
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
