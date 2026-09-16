#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

# shellcheck disable=SC1091
source "${script_dir}/config.sh"

echo "Configuring Argo CD"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --kustomize "${repo_root}/manifests/argocd"; then
  echo "Failed to configure Argo CD" >&2
  exit 1
fi

echo
echo "Restarting Argo CD server"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${ARGOCD_NAMESPACE}" \
  rollout restart deployment/argocd-server; then
  echo "Failed to restart Argo CD server" >&2
  exit 1
fi

echo
echo "Waiting for Argo CD server"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${ARGOCD_NAMESPACE}" \
  rollout status deployment/argocd-server \
  --timeout=5m; then
  echo "Argo CD server rollout failed" >&2
  exit 1
fi
