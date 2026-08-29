#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <certificate-parameter-name> <private-key-parameter-name> [target-directory]" >&2
  exit 2
fi

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script as root so the private key can be installed with restricted permissions." >&2
  exit 1
fi

for command_name in aws openssl install; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Required command is not installed: ${command_name}" >&2
    exit 1
  fi
done

certificate_parameter=$1
private_key_parameter=$2
target_directory=${3:-/srv/aliencommons/origin-certs}
aws_region=${AWS_REGION:-ap-southeast-2}
temporary_directory=$(mktemp -d)

cleanup() {
  rm -rf -- "${temporary_directory}"
}
trap cleanup EXIT

certificate_file="${temporary_directory}/tls.crt"
private_key_file="${temporary_directory}/tls.key"

aws ssm get-parameter \
  --region "${aws_region}" \
  --name "${certificate_parameter}" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text >"${certificate_file}"

aws ssm get-parameter \
  --region "${aws_region}" \
  --name "${private_key_parameter}" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text >"${private_key_file}"

if [[ ! -s ${certificate_file} || ! -s ${private_key_file} ]]; then
  echo "The certificate or private-key parameter returned an empty value." >&2
  exit 1
fi

openssl x509 -in "${certificate_file}" -noout -checkend 86400 >/dev/null
openssl pkey -in "${private_key_file}" -check -noout >/dev/null

certificate_public_key=$(openssl x509 -in "${certificate_file}" -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256)
private_key_public_key=$(openssl pkey -in "${private_key_file}" -pubout -outform DER | openssl dgst -sha256)

if [[ ${certificate_public_key} != "${private_key_public_key}" ]]; then
  echo "The Origin CA certificate does not match the supplied private key." >&2
  exit 1
fi

install -d -m 0700 "${target_directory}"
install -m 0644 "${certificate_file}" "${target_directory}/tls.crt"
install -m 0600 "${private_key_file}" "${target_directory}/tls.key"

echo "Cloudflare Origin CA certificate material installed in ${target_directory}."
