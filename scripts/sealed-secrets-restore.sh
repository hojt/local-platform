#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

backup_file="${repo_root}/.local/sealed-secrets/keys.yaml"

if [[ ! -f "${backup_file}" ]]; then
  echo "No Sealed Secrets key backup found; skipping restore"
  exit 0
fi

echo "Restoring Sealed Secrets keys"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --filename "${backup_file}"

if kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${SEALED_SECRETS_NAMESPACE}" \
  get deployment sealed-secrets-controller \
  >/dev/null 2>&1; then

  echo "Restarting Sealed Secrets controller"

  kubectl \
    --context "${KUBE_CONTEXT}" \
    --namespace "${SEALED_SECRETS_NAMESPACE}" \
    rollout restart deployment/sealed-secrets-controller

  kubectl \
    --context "${KUBE_CONTEXT}" \
    --namespace "${SEALED_SECRETS_NAMESPACE}" \
    rollout status deployment/sealed-secrets-controller \
    --timeout=5m
fi

echo "Sealed Secrets keys restored"
