#!/usr/bin/env bash

set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf -- "${temporary_directory}"' EXIT
mock_bin=${temporary_directory}/bin
output_file=${temporary_directory}/env/.env.stg
install -d -m 0755 "${mock_bin}"

cat >"${mock_bin}/aws" <<'MOCK_AWS'
#!/usr/bin/env bash
set -euo pipefail

parameter_name=
while [[ $# -gt 0 ]]; do
  if [[ $1 == --name ]]; then
    parameter_name=$2
    shift 2
  else
    shift
  fi
done

case "${parameter_name}" in
  */django-secret-key) printf '%s\n' "django-\$-'\\secret" ;;
  */postgres-password) printf '%s\n' 'postgres-password' ;;
  */redis-password) printf '%s\n' 'redis p@ss/word' ;;
  */grafana-admin-password) printf '%s\n' 'grafana-password' ;;
  */email-host-user) printf '%s\n' 'smtp-user' ;;
  */email-host-password) printf '%s\n' 'smtp-password' ;;
  *) exit 1 ;;
esac
MOCK_AWS
chmod 0755 "${mock_bin}/aws"

digest=$(printf '1%.0s' {1..64})
ALIENCOMMONS_RENDER_TEST_MODE=true PATH="${mock_bin}:${PATH}" \
  "${repository_root}/infra/deploy/stg/render-environment.sh" \
  "${output_file}" \
  "example.invalid/backend@sha256:${digest}" \
  "example.invalid/frontend@sha256:${digest}" \
  "example.invalid/alienmark@sha256:${digest}" \
  aliencommons-stg-media-example

if file_mode=$(stat -c '%a' "${output_file}" 2>/dev/null); then
  :
else
  file_mode=$(stat -f '%Lp' "${output_file}")
fi
if [[ ${file_mode} != 600 ]]; then
  echo "Generated environment file must have mode 0600." >&2
  exit 1
fi

docker compose \
  --env-file "${output_file}" \
  -f "${repository_root}/infra/compose/docker-compose.base.yml" \
  -f "${repository_root}/infra/compose/docker-compose.stg.yml" \
  config --quiet

compose_json=$(docker compose \
  --env-file "${output_file}" \
  -f "${repository_root}/infra/compose/docker-compose.base.yml" \
  -f "${repository_root}/infra/compose/docker-compose.stg.yml" \
  config --format json)

jq -e '
  (.services.postgres.environment | keys | sort) == ["POSTGRES_DB", "POSTGRES_PASSWORD", "POSTGRES_USER"] and
  (.services.redis.environment | keys) == ["REDIS_PASSWORD"] and
  (.services["backend-api"].environment | has("GRAFANA_ADMIN_PASSWORD") | not) and
  (.services.grafana.environment | has("SECRET_KEY") | not) and
  (.services.frontend.environment | has("SECRET_KEY") | not)
' <<<"${compose_json}" >/dev/null

echo "Staging environment rendering test passed."
