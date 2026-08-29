#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

echo "Installing OpenTelemetry Collector"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --filename "${repo_root}/manifests/otel/namespace.yaml"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --kustomize "${repo_root}/manifests/otel"

echo
echo "Waiting for OpenTelemetry Collector"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace observability \
  rollout status deployment/otel-collector \
  --timeout=5m
