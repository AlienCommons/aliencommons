# Agent Guide — AlienCommons

> **Read this first.** Then read the closest nested `AGENTS.md` for the area you are editing.
> Keep changes small, intentional, and consistent with the surrounding code.

## What this is

AlienCommons is a community platform for Technical Minecraft players. It is a polyglot monorepo: a Django 6 backend, a Nuxt 4 frontend, an internal Fastify Markdown-rendering service, a TypeScript Markdown parser library, a DRF envelope library, three Zensical documentation sites, and the Docker/observability wiring to run all of it.

## Repository map

```
aliencommons/
├── apps/
│   ├── backend/         Django 6 + DRF API. See apps/backend/AGENTS.md.
│   ├── frontend/        Nuxt 4 + Vue 3 + Pinia + Tailwind 4. See apps/frontend/AGENTS.md.
│   └── alienmark/       Internal Fastify service that renders Markdown via packages/alienmark.
├── packages/
│   ├── alienmark/        TypeScript Markdown parser + HTML renderer (published to GitHub Packages).
│   └── drf-std-response/ DRF response-envelope + exception-handler library used by the backend.
├── docs/                Three Zensical sites (users, contributors, alienmark). See docs/AGENTS.md.
├── infra/compose/       Docker Compose files for dev / stg / pro / proxy.
├── infra/opentofu/      OpenTofu modules and environment roots for AWS/Cloudflare.
├── o11y/                Grafana, Loki, Grafana Alloy configs.
├── make/                docker.mk + node.mk, included by the root Makefile.
├── env/                 Environment files for local Compose (.env.dev, .env.test).
└── .github/workflows/   CI/CD. ci.yml is the source of truth for verification gates.
```

## Nested guides (progressive disclosure)

Read the closest applicable guide **before** editing. The closest guide wins; this file only adds cross-cutting rules.

| Area | Guide | Read when |
|------|-------|-----------|
| Django backend | [`apps/backend/AGENTS.md`](apps/backend/AGENTS.md) | Touching anything under `apps/backend/` or `packages/drf-std-response/` |
| Nuxt frontend | [`apps/frontend/AGENTS.md`](apps/frontend/AGENTS.md) | Touching anything under `apps/frontend/` |
| AlienMark service | [`apps/alienmark/AGENTS.md`](apps/alienmark/AGENTS.md) | Touching the Fastify rendering service |
| AlienMark parser | [`packages/alienmark/AGENTS.md`](packages/alienmark/AGENTS.md) | Touching the parser library or its public API |
| DRF envelope lib | [`packages/drf-std-response/AGENTS.md`](packages/drf-std-response/AGENTS.md) | Touching the envelope / exception handler |
| Documentation | [`docs/AGENTS.md`](docs/AGENTS.md) | Touching anything under `docs/` |

If an area has no dedicated guide, follow the conventions already present in nearby code.

## Toolchains at a glance

| Concern | Tool | Pinning |
|---|---|---|
| Node workspace | pnpm 11 workspaces + Turbo | `package.json`, `pnpm-workspace.yaml`, `turbo.json` |
| Node quality/build | [Vite+](https://viteplus.dev) (`vp`) | root `vite.config.ts` (lint, format, type-aware checks) |
| Python (backend + docs) | uv workspaces | root `pyproject.toml`, `uv.lock` |
| Python lint | ruff | `apps/backend/ruff.toml` |
| Containers | Docker Compose | `infra/compose/*.yml`, driven via `make/` |
| Infrastructure | OpenTofu | `infra/opentofu/`, with remote S3 state per environment |
| CI | GitHub Actions | `.github/workflows/ci.yml` |

## Environments

Three environments. Do not encode environment-specific values in source.

- **`dev`** — local, via Docker Compose (`make dev-up`).
- **`stg`** — staging in the dedicated AWS member account under `Workloads/Stg`; mirrors production.
- **`pro`** — production in the dedicated AWS member account under `Workloads/Pro`. DNS for `aliencommons.com` is in Cloudflare.

The AWS Organizations management account is governance-only: do not deploy application workloads, buckets, registries, or CI roles there. Keep account IDs, root email addresses, role ARNs, and concrete bucket names out of the repository; provide them through environment-scoped deployment configuration.

## Common commands

Run from the repository root unless noted.

```bash
# Diagnose local prerequisites; see docs/contributors/docs/en/development/setup.md
make doctor
make backend-test           # Isolated local backend suite; no Docker required

# Full local stack (Postgres, Redis, backend, workers, frontend, AlienMark, observability)
make dev-up

# Node workspace (matches CI `node` job)
pnpm install
pnpm run check              # Format, lint and TypeScript static checks
pnpm run test               # Node behavior tests
pnpm turbo run typecheck --filter=frontend  # Vue SFC type checks
pnpm run knip               # advisory; pnpm run knip:strict to fail on findings

# Backend (matches CI `backend-*` jobs)
make dev-backend-test       # uses settings=test inside the backend-api container
make dev-backend-check      # python manage.py check inside the backend-api container
# Or locally inside apps/backend/:
#   uv run python manage.py test --settings=backend.settings.test
#   uv run ruff check <app...> manage.py

# Docs subproject (matches CI `docs-*` jobs); run inside docs/<name>/
uv run zensical build --strict
uv run zensical build --strict --config-file zensical.zh.toml

# Single Node package via Turbo filter
pnpm turbo run check --filter=frontend
pnpm turbo run check --filter=alienmark
pnpm turbo run check --filter=alienmark-service

# Staging infrastructure (from infra/opentofu/environments/stg)
tofu fmt -check -recursive ../..
tofu init -backend=false
tofu validate
```

All other Make targets live in [`make/docker.mk`](make/docker.mk) and [`make/node.mk`](make/node.mk).

## Verification

Run the **smallest** check that covers your change. If a check cannot be run, say so in your final response.

| Change | Command |
|---|---|
| Node static checks | `pnpm turbo run check --filter=<package>` (or `pnpm run check` for the workspace) |
| Node behavior | `pnpm turbo run test --filter=<package>`; `check` does not run tests |
| Frontend types / browser behavior | `pnpm turbo run typecheck --filter=frontend`; `pnpm turbo run test:e2e --filter=frontend` for page, session, SSR or API integration changes |
| Backend behavior | `uv run python manage.py test --settings=backend.settings.test` from `apps/backend/`, or `make dev-backend-test` |
| Backend lint | `uv run ruff check <apps> manage.py` from `apps/backend/` |
| API contract | Regenerate `apps/backend/openapi/v1.yaml`, then run `pnpm --filter frontend api:generate` and commit both generated artifacts |
| Docs site | Run both strict Zensical builds from `docs/<name>/` (default English config, then `zensical.zh.toml`) |
| Unused-code audit (advisory) | `pnpm run knip` |
| OpenTofu configuration | `tofu fmt -check -recursive ../..`, `tofu init -backend=false`, then `tofu validate` from the environment root |

### API contract synchronization

When backend permissions, serializers, views, response schemas, or routes change the public API contract:

```bash
cd apps/backend
DJANGO_SETTINGS_MODULE=backend.settings.test uv run --project ../.. --package aliencommons-backend python manage.py spectacular --file openapi/v1.yaml --validate --fail-on-warn
cd ../..
pnpm --filter frontend api:generate
pnpm --filter frontend api:check
```

Commit both `apps/backend/openapi/v1.yaml` and `apps/frontend/app/api/generated/v1.d.ts` when they change. CI regenerates these files and fails if either committed artifact is stale.

CI mirrors these in `.github/workflows/ci.yml`. If your change alters app names, settings modules, build commands, or verification steps, update the workflow too.

## Working rules

- **Read nearby code first.** Match the conventions already in the file or package you are touching.
- **Follow the closest nested guide.** It overrides anything generic here.
- **Don't widen scope.** No unrelated rewrites, no broad reformatting, no reverting user changes unless asked.
- **Keep secrets out of source.** No credentials, access keys, or bucket names in committed files. Prefer environment variables and IAM roles.
- **Treat migrations as part of model changes.** Add focused migrations when models change; don't edit applied migrations unless deliberately rewriting history.
- **Add or update tests when behavior changes** — even if nobody asked.
- **Keep generated artifacts out of diffs** (`.nuxt/`, `.output/`, `dist/`, `site/`, `staticfiles/`, `media/`, lockfile regeneration) unless the task is explicitly about them.

## Git

- Focused commits with clear messages.
- Feature work branches from `dev`. `main` is the release branch; releases are git tags.
- Don't encode release versions in `AGENTS.md`.
- Don't add a `Verification` section to PR descriptions unless explicitly asked.

## Code navigation and impact analysis

Use the official `turborepo` skill when available for Node workspace tasks,
dependency filters and cache configuration. Keep Python and documentation checks
on their documented uv/Make paths; Turbo does not model those dependencies.

Use `make code-index-status` to check GitNexus freshness and `make code-index`
to refresh the index without replacing this guide or installing generated skills.
Pass `repo: "aliencommons"` explicitly in MCP calls when multiple repos are indexed.
Treat partial/unknown results and cross-language resolution gaps as incomplete
evidence, and supplement them with the manual checks below.

Before modifying an existing function, class or method, identify its callers,
affected workflows and relevant tests. Report the blast radius and risk before
editing. Group related symbols in one report when they share a workflow.

Prefer GitNexus when its tools are available and its index matches the checkout:

- `query({search_query: "concept"})` for workflow discovery.
- `context({name: "symbolName"})` for callers and callees.
- `impact({target: "symbolName", direction: "upstream"})` before edits.
- `detect_changes()` before committing; for branch reviews use the actual PR
  base (normally `dev` for feature work, `main` for a release).
- Report HIGH or CRITICAL findings before proceeding; inspect affected callers
  and run targeted regression tests.

If GitNexus is missing, unavailable or stale, use `rg` to find definitions,
imports, callers and framework registrations (routes, signals, tasks and Nuxt
auto-imports), read those paths, and run the corresponding tests. State that
this is a manual analysis and describe unresolved coverage. Tool availability
must not silently bypass impact analysis or block routine work with a complete
manual alternative. Use language-aware rename tools when available; otherwise
review every definition/reference and validate the rename with types and tests.

Before committing without GitNexus, inspect `git diff --check`, the complete diff
and changed-file list; verify only intended code, contracts and workflows changed.

See [development setup](docs/contributors/docs/en/development/setup.md#optional-code-navigation)
for optional GitNexus setup. Shared instructions belong in version control;
indexes, credentials and personal agent settings do not.
