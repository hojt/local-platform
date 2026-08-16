#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

manifest_url="https://github.com/envoyproxy/gateway/releases/download/${ENVOY_GATEWAY_VERSION}/install.yaml"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  get --raw=/readyz \
  >/dev/null 2>&1; then
  echo "Kubernetes API is unavailable; skipping Envoy Gateway deletion"
  exit 0
fi

echo "Deleting Envoy Gateway ${ENVOY_GATEWAY_VERSION}"

kubectl \
  --context "${KUBE_CONTEXT}" \
  delete \
  --filename "${manifest_url}" \
  --ignore-not-found
