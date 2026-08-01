#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "${script_dir}/config.sh"

argocd_namespace="${ARGOCD_NAMESPACE:-argocd}"

echo "Argo CD status"
echo "Context:   ${KUBE_CONTEXT}"
echo "Namespace: ${argocd_namespace}"
echo

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  get namespace "${argocd_namespace}" \
  >/dev/null 2>&1; then
  echo "Argo CD: not installed"
  exit 0
fi

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${argocd_namespace}" \
  get pods
