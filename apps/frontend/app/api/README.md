# API layer

The committed OpenAPI contract at `apps/backend/openapi/v1.yaml` is the source
for `generated/v1.d.ts`. Generated files are reviewable build artifacts and
must not be edited manually.

From the repository root:

```bash
pnpm --filter frontend api:generate
pnpm --filter frontend api:check
```

`api:check` performs a non-mutating drift check and is run by CI whenever the
backend OpenAPI contract or frontend API layer changes.

## Runtime boundaries

- Browser requests use `NUXT_PUBLIC_API_BASE` (default `/api`) and pass through
  the same-origin Nuxt development proxy locally or Traefik after deployment.
- SSR requests use `NUXT_API_INTERNAL_BASE` and call Django over the private
  Compose network.
- The Nuxt plugin creates one client per app/request and only forwards the
  incoming cookie during SSR.
- CSRF bootstrap runs in the browser. Unsafe requests receive the current
  `csrftoken` through client middleware.

Use `useApi()` for interaction requests. Use `useApiData()` with an explicit,
stable key for SSR initial data so Nuxt can serialize and reuse its payload.

```ts
const token = await ensureCsrfToken();
const api = useApi();
const login = unwrapApiResponse(
  await api.POST("/v1/sessions/login/", {
    params: { header: { "X-CSRFToken": token } },
    body: { email, password },
  })
);
```

The explicit login header is intentional: it satisfies both the generated
OpenAPI contract and the runtime CSRF middleware.
