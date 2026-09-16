# Local checks use the same locked workspace environment as CI.
UV_BACKEND = uv run --locked --package aliencommons-backend

.PHONY: doctor backend-test backend-lint backend-check browser-backend browser-frontend code-index code-index-status

# Use an explicitly installed GitNexus release; never download tools implicitly.
code-index:
	gitnexus analyze --index-only

code-index-status:
	gitnexus status

doctor:
	node scripts/doctor.mjs

backend-test:
	cd apps/backend && $(UV_BACKEND) python manage.py test --settings=backend.settings.test $(TEST_ARGS)

backend-lint:
	$(UV_BACKEND) ruff check apps/backend scripts/browser-backend.py

backend-check:
	$(UV_BACKEND) python apps/backend/manage.py check --settings=backend.settings.test

browser-backend:
	$(UV_BACKEND) python scripts/browser-backend.py

browser-frontend:
	NUXT_API_INTERNAL_BASE=http://127.0.0.1:43101 NUXT_PUBLIC_API_BASE=/api NUXT_PUBLIC_I18N_BASE_URL=http://127.0.0.1:43100 $(PNPM) --filter frontend dev --host 127.0.0.1 --port 43100
