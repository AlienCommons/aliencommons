#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 5 ]]; then
  echo "Usage: $0 <output-file> <backend-image> <frontend-image> <alienmark-image> <media-bucket>" >&2
  exit 2
fi

test_mode=${ALIENCOMMONS_RENDER_TEST_MODE:-false}
if [[ ${EUID} -ne 0 && ${test_mode} != true ]]; then
  echo "Run this script as root so the generated environment file remains private." >&2
  exit 1
fi

for command_name in aws install jq mktemp mv; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Required command is not installed: ${command_name}" >&2
    exit 1
  fi
done

output_file=$1
backend_image=$2
frontend_image=$3
alienmark_image=$4
media_bucket=$5
aws_region=${AWS_REGION:-ap-southeast-2}

django_secret_parameter=${DJANGO_SECRET_PARAMETER:-/aliencommons/stg/app/django-secret-key}
postgres_password_parameter=${POSTGRES_PASSWORD_PARAMETER:-/aliencommons/stg/app/postgres-password}
redis_password_parameter=${REDIS_PASSWORD_PARAMETER:-/aliencommons/stg/app/redis-password}
grafana_password_parameter=${GRAFANA_PASSWORD_PARAMETER:-/aliencommons/stg/app/grafana-admin-password}
email_user_parameter=${EMAIL_USER_PARAMETER:-/aliencommons/stg/app/email-host-user}
email_password_parameter=${EMAIL_PASSWORD_PARAMETER:-/aliencommons/stg/app/email-host-password}

for image_reference in "${backend_image}" "${frontend_image}" "${alienmark_image}"; do
  if [[ ! ${image_reference} =~ ^[^[:space:]]+@sha256:[0-9a-f]{64}$ ]]; then
    echo "Every application image must use an immutable sha256 digest reference." >&2
    exit 1
  fi
done

if [[ ! ${media_bucket} =~ ^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$ ]]; then
  echo "The media bucket name is invalid." >&2
  exit 1
fi

get_secret() {
  local parameter_name=$1
  local value

  value=$(aws ssm get-parameter \
    --region "${aws_region}" \
    --name "${parameter_name}" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text)

  if [[ -z ${value} || ${value} == *$'\n'* || ${value} == *$'\r'* ]]; then
    echo "Parameter ${parameter_name} is empty or contains a line break." >&2
    return 1
  fi

  printf '%s' "${value}"
}

dotenv_quote() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\'/\\\'}
  printf "'%s'" "${value}"
}

write_value() {
  local key=$1
  local value=$2
  printf '%s=' "${key}"
  dotenv_quote "${value}"
  printf '\n'
}

django_secret=$(get_secret "${django_secret_parameter}")
postgres_password=$(get_secret "${postgres_password_parameter}")
redis_password=$(get_secret "${redis_password_parameter}")
grafana_password=$(get_secret "${grafana_password_parameter}")
email_user=$(get_secret "${email_user_parameter}")
email_password=$(get_secret "${email_password_parameter}")
redis_password_uri=$(jq -nr --arg value "${redis_password}" '$value | @uri')

output_directory=$(dirname "${output_file}")
install -d -m 0700 "${output_directory}"
temporary_file=$(mktemp "${output_file}.tmp.XXXXXX")
trap 'rm -f -- "${temporary_file}"' EXIT
chmod 0600 "${temporary_file}"

{
  write_value DJANGO_SETTINGS_MODULE backend.settings.stg
  write_value SECRET_KEY "${django_secret}"
  write_value SITE_URL https://stg.aliencommons.com
  write_value ALLOWED_HOSTS stg.aliencommons.com,api.stg.aliencommons.com
  write_value CORS_ALLOWED_ORIGINS https://stg.aliencommons.com

  write_value BACKEND_IMAGE "${backend_image}"
  write_value FRONTEND_IMAGE "${frontend_image}"
  write_value ALIENMARK_IMAGE "${alienmark_image}"

  write_value DEFAULT_FROM_EMAIL noreply@stg.aliencommons.com
  write_value SERVER_EMAIL noreply@stg.aliencommons.com
  write_value EMAIL_HOST email-smtp.ap-southeast-2.amazonaws.com
  write_value EMAIL_PORT 587
  write_value EMAIL_HOST_USER "${email_user}"
  write_value EMAIL_HOST_PASSWORD "${email_password}"
  write_value EMAIL_USE_TLS true
  write_value EMAIL_USE_SSL false

  write_value POSTGRES_DB aliencommons
  write_value POSTGRES_USER aliencommons
  write_value POSTGRES_PASSWORD "${postgres_password}"
  write_value POSTGRES_HOST postgres

  write_value REDIS_PASSWORD "${redis_password}"
  write_value REDIS_URL "redis://:${redis_password_uri}@redis:6379"
  write_value REDIS_KEY_PREFIX aliencommons:stg

  write_value GRAFANA_ADMIN_PASSWORD "${grafana_password}"

  write_value AWS_STORAGE_BUCKET_NAME "${media_bucket}"
  write_value AWS_S3_REGION_NAME "${aws_region}"
  write_value AWS_S3_CUSTOM_DOMAIN media.stg.aliencommons.com
} >"${temporary_file}"

if [[ ${EUID} -eq 0 ]]; then
  chown root:root "${temporary_file}"
fi
mv -f "${temporary_file}" "${output_file}"
trap - EXIT

echo "Staging runtime environment installed at ${output_file}."
