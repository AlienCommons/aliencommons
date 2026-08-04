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
pnpm dev
```

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
