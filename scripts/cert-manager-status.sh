#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

echo "cert-manager status"
echo "Context:   ${KUBE_CONTEXT}"
echo "Namespace: ${CERT_MANAGER_NAMESPACE}"
echo

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${CERT_MANAGER_NAMESPACE}" \
  get pods,deployments
