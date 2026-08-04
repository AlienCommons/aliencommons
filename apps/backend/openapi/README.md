# OpenAPI contract

`v1.yaml` is the committed, generated contract for backend API version 1. The
source of truth remains the Django views, serializers, filters, and annotations;
do not edit the YAML by hand.

Regenerate and validate it from `apps/backend/`:

```bash
uv run --project ../.. --package aliencommons-backend \
  python manage.py spectacular \
  --settings=backend.settings.test \
  --file openapi/v1.yaml \
  --validate \
  --fail-on-warn
```

CI runs the same generator and fails when the generated file differs from the
committed artifact. Client generation and breaking-change detection are
intentionally deferred for now.
