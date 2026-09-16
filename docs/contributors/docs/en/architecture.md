# Project Architecture

This page describes the current implementation. Product intent is documented in
[Product](product/index.md); unconfirmed decisions remain in [Open Questions](product/open-questions.md).
Repository paths below are relative to the checkout root. Source links target `dev`;
when working on another branch, inspect the same paths in that checkout.

## Runtime boundaries

| Component | Owns | Calls / depends on |
| --- | --- | --- |
| Nuxt (`apps/frontend`) | SSR, localized routes, presentation, session UI | Django via the typed API client |
| Django (`apps/backend`) | Permissions, domain workflows, API envelopes | PostgreSQL, Redis, tasks, AlienMark HTTP |
| AlienMark service (`apps/alienmark`) | Internal HTTP Markdown rendering | `packages/alienmark` |
| AlienMark library (`packages/alienmark`) | Markdown parsing and HTML rendering | Used by service and frontend |
| DRF envelope (`packages/drf-std-response`) | Success/error response contract | Used by Django views and exception handling |
| RQ workers / scheduler | Background execution and scheduled tasks | Django services and Redis |

Browser requests use `/api/v1/...`; the Nuxt development proxy or deployed proxy
routes them to Django's `/v1/...`. SSR calls `NUXT_API_INTERNAL_BASE` directly.
The internal base is the backend origin, without `/api`. PostgreSQL/Redis are
runtime dependencies; unit tests use isolated SQLite, memory cache and immediate
tasks. The browser demo uses a fresh temporary database. See [Setup](development/setup.md).

## Login and session flow

1. `app/components/auth/LoginForm.vue` calls `useAuthSession().login()`.
2. `ensureCsrfToken()` bootstraps the browser cookie. `app/api/session.ts` submits
   credentials through the per-app/request client in `app/plugins/api.ts`.
3. Django's `SessionViewSet.login` authenticates through `EmailBackend`: a
   verified `EmailAddress`, correct password and active user are required.
4. Django creates its session and `users/services/sessions.py` records device/session metadata.
5. The frontend fetches the current user and updates the Pinia auth store.
   On SSR, only that incoming request's cookie is forwarded; do not share clients
   or auth state between requests. Logout clears both session records and UI state.

| Implementation | Regression checks |
| --- | --- |
| [Frontend API boundaries](https://github.com/AlienCommons/aliencommons/blob/dev/apps/frontend/app/api/README.md) | [API client tests](https://github.com/AlienCommons/aliencommons/blob/dev/apps/frontend/test/api-client.test.ts), [session tests](https://github.com/AlienCommons/aliencommons/blob/dev/apps/frontend/test/session-api.test.ts) |
| [Session endpoints](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/users/views/sessions.py) | [User API tests](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/users/tests/test_views.py) |
| [Session composable](https://github.com/AlienCommons/aliencommons/blob/dev/apps/frontend/app/composables/useAuthSession.ts) | [Browser smoke tests](https://github.com/AlienCommons/aliencommons/blob/dev/apps/frontend/e2e/smoke.e2e.ts) |

## Article review and publication flow

Views enforce permissions and select objects; transactional service functions
lock the article before invoking `ArticleWorkflow`. Keep workflow decisions in
services, and check both queryset filtering and object permissions.

| Record | Responsibility |
| --- | --- |
| `Article` | Stable author/workflow identity; draft, pending, published or unpublished |
| `ArticleSource` | Editable title/Markdown and source version |
| `ArticleSnapshot` | Frozen submitted content and review result |
| `ArticlePublication` | Public identity; distinct from the article UUID |
| `ArticlePublicationVersion` | Rendered content from an approved snapshot |
| `ArticleEvent` | Actor and workflow action history |

Current transitions: draft → pending on submit; pending → draft on withdrawal
or rejection; pending → published on approval; published → unpublished on
unpublish; saving an unpublished article returns it to draft. Submission checks
content, unchanged snapshot hashes and a six-hour cooldown after moderation.
Approval renders Markdown through AlienMark and creates a publication version.
Unpublishing removes the public entry and its versions. Deletion is rejected
while pending; otherwise it soft-deletes the article and removes its publication.

Published sources cannot currently be edited directly. The product goal of
revising a published work while retaining its old public version is not a complete
implemented flow. Do not infer it from the existence of version models, or implement
it implicitly during a maintenance task. See [Columns](product/articles.md).

Read [workflow services](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/articles/services/articles.py),
[models](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/articles/models/articles.py)
and [permissions](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/articles/permissions.py).
Validate with [service tests](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/articles/tests/test_services.py),
[API tests](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/articles/tests/test_views.py)
and browser article list/detail tests. The browser fixtures contain trusted,
pre-rendered HTML; they do not exercise the AlienMark HTTP rendering path.

## Notification flow

1. Comment/post/publication services create events for mentions, comment replies
   or subscribed-author publications. Events use unique deduplication keys.
2. `create_event()` queues fan-out using `transaction.on_commit`, so delivery
   begins after the surrounding database transaction commits.
3. `fan_out_notification_event_task` invokes `fan_out_event()`, which locks the
   event and creates recipient deliveries. A unique event/recipient constraint
   prevents duplicate deliveries. Retry scans handle pending/failed events.
4. Inbox endpoints expose recipient-scoped deliveries and read/unread state.

These backend capabilities exist; the frontend has no inbox page yet. Product
choices such as moderation-result and reaction notifications remain undecided.
Read [services](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/notifications/services.py),
[tasks](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/notifications/tasks.py)
and [views](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/notifications/views.py).
Validate with [service tests](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/notifications/tests/test_services.py)
and [API tests](https://github.com/AlienCommons/aliencommons/blob/dev/apps/backend/notifications/tests/test_views.py).
When testing enqueue timing, account for transaction commit callbacks explicitly.

## Contracts and change navigation

`apps/backend/openapi/v1.yaml` is generated from Django; it generates
`apps/frontend/app/api/generated/v1.d.ts`. Both are versioned and checked for drift.
Follow the [setup verification matrix](development/setup.md#verification-by-change)
when changing serializers, routes, permissions or response schemas.

Start with the closest `AGENTS.md`, then follow the relevant flow above. Prefer
current GitNexus context/impact results when available. Otherwise inspect callers,
framework registrations and tests using `rg`; include routes, signals, task
entrypoints and Nuxt auto-imports. Document uncertainty rather than assuming that
an absent text match means there are no callers.
