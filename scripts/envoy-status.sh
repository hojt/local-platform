#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "${script_dir}/config.sh"

echo "Envoy Gateway status"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${ENVOY_GATEWAY_NAMESPACE}" \
  get pods,deployments,services
