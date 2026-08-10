#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "${script_dir}/config.sh"

service_name="$(
  kubectl \
    --context "${KUBE_CONTEXT}" \
    --namespace "${ENVOY_GATEWAY_NAMESPACE}" \
    get services \
    --selector "gateway.envoyproxy.io/owning-gateway-name=${ENVOY_GATEWAY_NAME}" \
    --output jsonpath='{.items[0].metadata.name}'
)"

if [[ -z "${service_name}" ]]; then
  echo "No Envoy service found for ${ENVOY_GATEWAY_NAME}" >&2
  exit 1
fi

echo "Forwarding ${ENVOY_GATEWAY_NAME} to http://localhost:${ENVOY_GATEWAY_LOCAL_PORT}"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${ENVOY_GATEWAY_NAMESPACE}" \
  port-forward \
  "service/${service_name}" \
  "${ENVOY_GATEWAY_LOCAL_PORT}:80"
