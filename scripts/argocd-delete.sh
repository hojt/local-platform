#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "${script_dir}/config.sh"

argocd_namespace="${ARGOCD_NAMESPACE:-argocd}"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  get namespace "${argocd_namespace}" \
  >/dev/null 2>&1; then
  echo "Argo CD: not installed"
  exit 0
fi

echo "Deleting Argo CD"

kubectl \
  --context "${KUBE_CONTEXT}" \
  delete namespace "${argocd_namespace}"
