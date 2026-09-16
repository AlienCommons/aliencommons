# Development Setup

Run commands from the repository root unless a working directory is specified.
Use Node 24, the pnpm version pinned in `package.json`, Python 3.14 and uv
(CI pins its uv version in `.github/workflows/ci.yml`). Docker is only required
for the full runtime stack, not unit tests or the browser demo.

## Install and diagnose

```bash
corepack enable
pnpm install --frozen-lockfile
uv sync --locked --all-packages --dev
make doctor
```

The frozen/locked installs must not regenerate lockfiles. Nuxt's postinstall
prepares its generated types. `make doctor` checks Node/pnpm, uv, backend imports
and Nuxt preparation without installing dependencies or reading secret values.
Failures return a non-zero exit code and a repair command. Optional checks:

```bash
node scripts/doctor.mjs --browser
node scripts/doctor.mjs --docker
```

A missing optional GitNexus CLI is informational. A missing Chromium installation
fails only when `--browser` is requested. Browser checks also reject occupied
IPv4/IPv6 test ports. The `test:e2e` command runs this preflight automatically. Docker checks inspect Compose and daemon
availability only with `--docker`.

## Fast local checks

```bash
make backend-check
make backend-lint
make backend-test
make backend-test TEST_ARGS="users.tests.test_views --verbosity 2"
pnpm turbo run check test typecheck --filter=frontend
pnpm turbo run check test --filter=alienmark
```

The backend test target selects `backend.settings.test` explicitly and runs from
`apps/backend` so Django discovers the full suite. It uses SQLite, memory cache,
local email and immediate tasks. No PostgreSQL, Redis, S3 or remote credentials
are needed. `check` is static validation; it does not execute Node behavior tests.
Frontend `typecheck` uses `vue-tsc --build --noEmit` to traverse Nuxt project
references; bare `vue-tsc --noEmit` checks only the empty root project.
For a direct backend invocation, run inside `apps/backend`:

```bash
uv run --locked --package aliencommons-backend python manage.py test --settings=backend.settings.test
```

`manage.py` otherwise defaults to development settings. Do not use its bare test
command when you intend an isolated run. Reuse `core.tests.factories` and the
shared test cases; do not depend on demo data for unit tests.

## Browser integration and interactive demo

```bash
pnpm --filter frontend exec playwright install chromium
node scripts/doctor.mjs --browser
pnpm turbo run test:e2e --filter=frontend
```

On Linux CI install browser system dependencies with
`pnpm --filter frontend exec playwright install --with-deps chromium`.
Playwright starts Django on `127.0.0.1:43101` and Nuxt on `127.0.0.1:43100`.
The suite refuses to reuse existing servers. Stop interactive demo servers first.
Each run creates a temporary SQLite database/media directory, migrates it and
seeds fixed fixtures; normal shutdown removes that directory. It does not touch
the Compose or unit-test databases. Browser contexts are isolated between tests.

For manual exploration, run these in two terminals:

```bash
# Terminal 1: disposable Django API, with fixtures
make browser-backend
```

```bash
# Terminal 2: Nuxt with the same-origin /api proxy
make browser-frontend
```

Open [the local demo](http://127.0.0.1:43100). Sign in using
`reader@demo.invalid`, `author@demo.invalid` or `moderator@demo.invalid` with
password `local-demo-only`. These are public, disposable demo credentials.
The moderator has the product moderation flag, not staff/superuser privileges.
The dataset contains draft, pending, published and unpublished articles plus one
community post. Restart the backend to reset it. Stop both terminals with Ctrl+C.

`seed_demo` uses stable identifiers and preserves existing fixture edits when
repeated in the same database. It refuses to run unless `ALLOW_DEMO_DATA` is
explicitly enabled; only browser settings enable it in the repository. The
launcher overrides inherited settings and owns the temporary directory. Never
turn this setting on in a deployment. Fixtures use pre-rendered trusted HTML;
publication workflow and AlienMark HTTP behavior remain covered separately.

The browser suite checks that login is disabled before hydration, invalid/valid
login, session reload/SSR and logout,
server-rendered articles and details, language switching, community detail and
missing-publication 404 recovery. Failures retain screenshots and traces under
`apps/frontend/test-results/`; open the HTML report with
`pnpm --filter frontend exec playwright show-report`. CI uploads failure evidence.
Reports and browser downloads are not source artifacts.

## Full runtime stack

```bash
node scripts/doctor.mjs --docker
make dev-up
make dev-backend-migrate
```

This uses the committed local `env/.env.dev` and Compose definitions to run the
frontend, API, AlienMark, PostgreSQL, Redis, workers, scheduler and observability.
See `make/docker.mk` for logs and lifecycle commands. Run `make dev-down` to stop
it while retaining volumes. This environment exercises real service integration;
the lightweight browser suite does not validate PostgreSQL locking, RQ delivery,
S3 or deployment proxy behavior.

## Verification by change

| Change | Required checks |
| --- | --- |
| Node code | Package-scoped `check`; `test` when behavior changes |
| Vue components/composables | Frontend `check test typecheck`; browser suite for page/session/SSR integration |
| Backend behavior | `make backend-lint`, `make backend-check`, relevant `make backend-test TEST_ARGS="..."` |
| Models | Backend tests and a focused migration; check `makemigrations --check --dry-run --settings=backend.settings.test` |
| Public API | Regenerate schema/types below; backend tests, frontend API tests, `api:check` |
| Browser launcher or fixtures | `make backend-test TEST_ARGS=core.tests.test_seed_demo`, backend lint and browser suite |
| Build/runtime configuration | Relevant package build and integration checks |
| Contributor docs | Both strict builds below, English before Chinese |
| Doctor | Run default and applicable optional modes; root script lint/format check |

```bash
# API contract: from apps/backend
DJANGO_SETTINGS_MODULE=backend.settings.test uv run --locked --project ../.. --package aliencommons-backend python manage.py spectacular --file openapi/v1.yaml --validate --fail-on-warn
# Then from the repository root
pnpm --filter frontend api:generate
pnpm --filter frontend api:check
```

Include both changed contract artifacts; never edit generated types manually.

```bash
# From docs/contributors
uv run --locked --package aliencommons-contributor-docs zensical build --strict
uv run --locked --package aliencommons-contributor-docs zensical build --strict --config-file zensical.zh.toml
```

CI runs backend tests, Node tests, Vue type checks, contract drift checks and
browser integration as separate gates. Browser checks run for backend or Node
changes; docs checks run for their site. Keep path filters synchronized with new
shared tooling. Report checks that could not run instead of reporting them passed.

## Optional code navigation

### Turborepo agent skill

Install the [official Turborepo skill](https://turborepo.dev/docs/guides/ai)
into your agent's personal skill directory. The upstream path is
`vercel/turborepo/skills/turborepo`; for clients supported by the Skills CLI:

```bash
npx skills add vercel/turborepo --skill turborepo --agent codex --global
```

Confirm that `turborepo` appears in the client's available skills. In Codex, a
newly installed skill becomes available on the next turn. This is Node workspace
guidance; continue using uv/Make for backend and documentation checks.

### GitNexus MCP

GitNexus is optional tooling; see its [installation guide](https://github.com/abhigyanpatwari/GitNexus#readme).
Install a reviewed release with `npm install --global gitnexus@VERSION`, replacing
`VERSION` with the exact release you chose. Keep that version in your environment
setup record; do not implicitly install the latest release during ordinary tasks.
From the repository root, run `gitnexus --version`, `gitnexus status`, and
`make code-index` when a fresh index is needed. This runs
`gitnexus analyze --index-only` and preserves custom agent instructions.
`make code-index-status` reports index freshness. Refresh after switching branches,
pulling changes or changing source; status is a diagnostic, not a CI gate.
The local integration was verified with GitNexus `1.6.11`.

Configure your agent's MCP client to launch command `gitnexus` with argument `mcp`
(or use `gitnexus setup` to configure supported editors). Confirm that the client
exposes query/context/impact tools and that the indexed checkout matches the current
branch/commit. A local index alone does not prove the agent has MCP access.
Indexes and personal client settings stay ignored; shared guidance stays in Git.
No repository workflow depends on generated `.claude/skills` files.

For Codex, register the installed executable with `codex mcp add gitnexus -- gitnexus mcp`.
If the desktop client's PATH differs from your shell, use absolute paths to Node
and GitNexus's CLI entry point. Reload the client/session if the new server does
not appear. Verify `list_repos`, `query`, `context`, `impact` and `detect_changes`
against `repo: "aliencommons"`; configuration presence alone is insufficient.
Do not interpret partial/unknown results, dynamic dispatch boundaries or unresolved
Python/TypeScript relationships as proof that there are no affected callers.

If the CLI, MCP connection or current index is unavailable, follow root `AGENTS.md`:
inspect definitions, callers, routes/signals/tasks and tests using `rg`, report
blast radius and uncertainty, and validate with targeted tests. Before committing,
review the full diff and run `git diff --check`. Do not infer safety from a stale graph.
