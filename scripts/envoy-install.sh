#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "${script_dir}/config.sh"

manifest_url="https://github.com/envoyproxy/gateway/releases/download/${ENVOY_GATEWAY_VERSION}/install.yaml"

echo "Installing Envoy Gateway ${ENVOY_GATEWAY_VERSION}"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --server-side \
  --filename "${manifest_url}"

echo
echo "Waiting for Envoy Gateway"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${ENVOY_GATEWAY_NAMESPACE}" \
  wait \
  --for=condition=Available \
  deployment/envoy-gateway \
  --timeout=5m
