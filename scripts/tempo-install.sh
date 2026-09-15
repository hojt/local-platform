#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

echo "Installing Tempo"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --kustomize "${repo_root}/manifests/tempo"

echo
echo "Waiting for Tempo"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace observability \
  rollout status deployment/tempo \
  --timeout=5m
