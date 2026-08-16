#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

manifest_url="https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  get --raw=/readyz \
  >/dev/null 2>&1; then
  echo "Kubernetes API is unavailable; skipping cert-manager deletion"
  exit 0
fi

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  get namespace "${CERT_MANAGER_NAMESPACE}" \
  >/dev/null 2>&1; then
  echo "cert-manager: not installed"
  exit 0
fi

echo "Deleting cert-manager ${CERT_MANAGER_VERSION}"

kubectl \
  --context "${KUBE_CONTEXT}" \
  delete \
  --filename "${manifest_url}" \
  --ignore-not-found
