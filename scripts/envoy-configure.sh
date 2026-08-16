#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

echo "Configuring Envoy Gateway"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --kustomize "${repo_root}/manifests/gateway/envoy"

echo
echo "Waiting for Envoy Gateway data plane"

deployment_name=""

for _ in {1..60}; do
  deployment_name="$(
    kubectl \
      --context "${KUBE_CONTEXT}" \
      --namespace "${ENVOY_GATEWAY_NAMESPACE}" \
      get deployments \
      --selector "gateway.envoyproxy.io/owning-gateway-name=${ENVOY_GATEWAY_NAME}" \
      --output name |
      head -n 1
  )"

  if [[ -n "${deployment_name}" ]]; then
    break
  fi

  sleep 1
done

if [[ -z "${deployment_name}" ]]; then
  echo "Timed out waiting for Envoy data plane deployment for ${ENVOY_GATEWAY_NAME}" >&2
  exit 1
fi

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${ENVOY_GATEWAY_NAMESPACE}" \
  rollout status \
  "${deployment_name}" \
  --timeout=5m
