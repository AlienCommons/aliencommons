#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <extracted-bundle-directory> <release-id>" >&2
  exit 2
fi

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script as root; AWS Systems Manager Run Command does this by default." >&2
  exit 1
fi

for command_name in aws cmp docker install ln mv openssl readlink; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Required command is not installed: ${command_name}" >&2
    exit 1
  fi
done

bundle_directory=$(realpath "$1")
release_id=$2
aws_region=${AWS_REGION:-ap-southeast-2}
release_root=/srv/aliencommons/stg/releases
current_link=/srv/aliencommons/stg/current
runtime_directory=/srv/aliencommons/stg/runtime
runtime_environment=${runtime_directory}/.env.stg

if [[ ! ${release_id} =~ ^[0-9a-f]{40}-[1-9][0-9]*$ ]]; then
  echo "The release ID must contain a full Git commit SHA and workflow attempt." >&2
  exit 1
fi

if [[ ! -f ${bundle_directory}/deployment.env ]]; then
  echo "The deployment bundle is missing deployment.env." >&2
  exit 1
fi

read_manifest_value() {
  local key=$1
  local value
  value=$(sed -n "s/^${key}=//p" "${bundle_directory}/deployment.env")
  if [[ -z ${value} || ${value} == *$'\n'* || ${value} == *$'\r'* ]]; then
    echo "The deployment manifest value ${key} is missing or invalid." >&2
    return 1
  fi
  printf '%s' "${value}"
}

backend_image=$(read_manifest_value BACKEND_IMAGE)
frontend_image=$(read_manifest_value FRONTEND_IMAGE)
alienmark_image=$(read_manifest_value ALIENMARK_IMAGE)
media_bucket=$(read_manifest_value AWS_STORAGE_BUCKET_NAME)
release_directory=${release_root}/${release_id}

install -d -m 0755 "${release_root}"
if [[ -e ${release_directory} ]]; then
  if [[ ! -f ${release_directory}/deployment.env ]] ||
    ! cmp -s "${bundle_directory}/deployment.env" "${release_directory}/deployment.env"; then
    echo "Release ${release_id} already exists with a different or incomplete manifest." >&2
    exit 1
  fi
else
  install -d -m 0755 "${release_directory}"
  cp -a "${bundle_directory}/." "${release_directory}/"
fi

AWS_REGION=${aws_region} "${release_directory}/infra/deploy/stg/render-environment.sh" \
  "${runtime_environment}" \
  "${backend_image}" \
  "${frontend_image}" \
  "${alienmark_image}" \
  "${media_bucket}"
install -d -m 0755 "${release_directory}/env"
ln -sfn "${runtime_environment}" "${release_directory}/env/.env.stg"

AWS_REGION=${aws_region} "${release_directory}/infra/deploy/stg/prepare-origin-certificates.sh" \
  /aliencommons/stg/traefik/origin-certificate \
  /aliencommons/stg/traefik/origin-private-key

registry=${backend_image%%/*}
aws ecr get-login-password --region "${aws_region}" |
  docker login --username AWS --password-stdin "${registry}"

proxy_compose=(
  docker compose
  -f "${release_directory}/infra/compose/docker-compose.proxy.yml"
)
staging_compose=(
  docker compose
  --env-file "${release_directory}/env/.env.stg"
  -f "${release_directory}/infra/compose/docker-compose.base.yml"
  -f "${release_directory}/infra/compose/docker-compose.stg.yml"
)

"${proxy_compose[@]}" config --quiet
"${staging_compose[@]}" config --quiet
"${proxy_compose[@]}" pull --quiet
"${staging_compose[@]}" pull --quiet

docker network inspect aliencommons-proxy >/dev/null 2>&1 ||
  docker network create aliencommons-proxy >/dev/null

previous_release=$(readlink -f "${current_link}" 2>/dev/null || true)
deployment_started=false

rollback_deployment() {
  local exit_status=$?
  trap - EXIT

  if [[ ${exit_status} -ne 0 && ${deployment_started} == true && -n ${previous_release} && -d ${previous_release} ]]; then
    echo "Deployment failed; attempting to restore the previous application containers." >&2
    local previous_proxy_compose=(
      docker compose
      -f "${previous_release}/infra/compose/docker-compose.proxy.yml"
    )
    local previous_staging_compose=(
      docker compose
      --env-file "${previous_release}/env/.env.stg"
      -f "${previous_release}/infra/compose/docker-compose.base.yml"
      -f "${previous_release}/infra/compose/docker-compose.stg.yml"
    )

    set +e
    "${previous_proxy_compose[@]}" up -d
    "${previous_staging_compose[@]}" up -d postgres redis
    "${previous_staging_compose[@]}" up -d \
      alloy \
      loki \
      grafana \
      backend-api \
      backend-task-scheduler \
      backend-task-worker \
      frontend \
      alienmark \
      static
    set -e
  fi

  exit "${exit_status}"
}
trap rollback_deployment EXIT

deployment_started=true
"${proxy_compose[@]}" up -d
"${staging_compose[@]}" up -d postgres redis

wait_for_service() {
  local service=$1
  local expected_health=$2
  local container_id
  local state

  for _ in $(seq 1 60); do
    container_id=$("${staging_compose[@]}" ps -q "${service}")
    if [[ -n ${container_id} ]]; then
      if [[ ${expected_health} == healthy ]]; then
        state=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${container_id}")
      else
        state=$(docker inspect --format '{{.State.Status}}' "${container_id}")
      fi
      if [[ ${state} == "${expected_health}" ]]; then
        return 0
      fi
      if [[ ${state} == exited || ${state} == dead ]]; then
        break
      fi
    fi
    sleep 5
  done

  "${staging_compose[@]}" ps "${service}" >&2 || true
  "${staging_compose[@]}" logs --tail 100 "${service}" >&2 || true
  echo "Service ${service} did not reach ${expected_health}." >&2
  return 1
}

wait_for_stable_services() {
  local service
  local container_id
  local state
  local restart_count
  declare -A initial_restart_counts=()

  for service in "$@"; do
    container_id=$("${staging_compose[@]}" ps -q "${service}")
    if [[ -z ${container_id} ]]; then
      echo "Service ${service} does not have a container." >&2
      return 1
    fi
    initial_restart_counts["${service}"]=$(docker inspect --format '{{.RestartCount}}' "${container_id}")
  done

  for _ in $(seq 1 6); do
    for service in "$@"; do
      container_id=$("${staging_compose[@]}" ps -q "${service}")
      state=$(docker inspect --format '{{.State.Status}}' "${container_id}")
      restart_count=$(docker inspect --format '{{.RestartCount}}' "${container_id}")
      if [[ ${state} != running || ${restart_count} != "${initial_restart_counts[${service}]}" ]]; then
        "${staging_compose[@]}" logs --tail 100 "${service}" >&2 || true
        echo "Service ${service} did not remain stable." >&2
        return 1
      fi
    done
    sleep 5
  done
}

wait_for_service postgres healthy
wait_for_service redis healthy
"${staging_compose[@]}" run --rm backend-init
"${staging_compose[@]}" up -d alloy loki grafana
"${staging_compose[@]}" up -d \
  backend-api \
  backend-task-scheduler \
  backend-task-worker \
  frontend \
  alienmark \
  static

wait_for_service backend-api healthy
wait_for_service frontend healthy
wait_for_service alienmark healthy
wait_for_stable_services \
  alloy \
  loki \
  grafana \
  backend-task-scheduler \
  backend-task-worker \
  static

proxy_container_id=$("${proxy_compose[@]}" ps -q traefik)
for _ in $(seq 1 30); do
  proxy_health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${proxy_container_id}")
  if [[ ${proxy_health} == healthy ]]; then
    break
  fi
  sleep 5
done
if [[ ${proxy_health:-unknown} != healthy ]]; then
  "${proxy_compose[@]}" logs --tail 100 traefik >&2 || true
  echo "Traefik did not become healthy." >&2
  exit 1
fi

openssl s_client \
  -connect 127.0.0.1:443 \
  -servername stg.aliencommons.com \
  -CAfile /srv/aliencommons/origin-certs/tls.crt \
  -partial_chain \
  -verify_return_error </dev/null 2>/dev/null |
  grep -q 'Verify return code: 0 (ok)'

printf 'GET /api/health HTTP/1.1\r\nHost: grafana.stg.aliencommons.com\r\nConnection: close\r\n\r\n' |
  openssl s_client \
    -quiet \
    -connect 127.0.0.1:443 \
    -servername grafana.stg.aliencommons.com \
    -CAfile /srv/aliencommons/origin-certs/tls.crt \
    -partial_chain \
    -verify_return_error 2>/dev/null |
  grep -q '"database"[[:space:]]*:[[:space:]]*"ok"'

temporary_link=${current_link}.new
ln -sfn "${release_directory}" "${temporary_link}"
mv -Tf "${temporary_link}" "${current_link}"
deployment_started=false
trap - EXIT

echo "Staging release ${release_id} is active and healthy."
