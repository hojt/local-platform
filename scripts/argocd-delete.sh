#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  get --raw=/readyz \
  >/dev/null 2>&1; then
  echo "Kubernetes API is unavailable; skipping Argo CD deletion"
  exit 0
fi

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  get namespace "${ARGOCD_NAMESPACE}" \
  >/dev/null 2>&1; then
  echo "Argo CD: not installed"
  exit 0
fi

echo "Deleting Argo CD"

kubectl \
  --context "${KUBE_CONTEXT}" \
  delete namespace "${ARGOCD_NAMESPACE}"
