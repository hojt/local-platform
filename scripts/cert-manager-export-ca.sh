#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

output_dir="${repo_root}/.local"
output_file="${output_dir}/local-root-ca.crt"

mkdir -p "${output_dir}"

echo "Exporting local root CA"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${CERT_MANAGER_NAMESPACE}" \
  get secret local-root-ca \
  --output jsonpath='{.data.tls\.crt}' |
  base64 --decode \
    >"${output_file}"

echo "Local root CA exported to ${output_file}"
