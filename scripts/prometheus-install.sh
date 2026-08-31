#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

echo "Installing Prometheus"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --kustomize "${repo_root}/manifests/prometheus"

echo
echo "Waiting for Prometheus"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace observability \
  rollout status deployment/prometheus \
  --timeout=5m
