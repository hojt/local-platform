#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

backup_dir="${repo_root}/.local/sealed-secrets"
backup_file="${backup_dir}/keys.yaml"
tmp_file="${backup_file}.tmp"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  get --raw=/readyz \
  >/dev/null 2>&1; then
  echo "Kubernetes API is unavailable; skipping Sealed Secrets key backup"
  exit 0
fi

key_count="$(
  kubectl \
    --context "${KUBE_CONTEXT}" \
    --namespace "${SEALED_SECRETS_NAMESPACE}" \
    get secrets \
    --selector sealedsecrets.bitnami.com/sealed-secrets-key \
    --output name |
    wc -l
)"

if [[ "${key_count}" -eq 0 ]]; then
  echo "No Sealed Secrets keys found; skipping backup"
  exit 0
fi

mkdir -p "${backup_dir}"

echo "Backing up ${key_count} Sealed Secrets key(s)"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${SEALED_SECRETS_NAMESPACE}" \
  get secrets \
  --selector sealedsecrets.bitnami.com/sealed-secrets-key \
  --output yaml \
  >"${tmp_file}"

chmod 600 "${tmp_file}"

mv "${tmp_file}" "${backup_file}"

echo "Sealed Secrets key backup written to ${backup_file}"
