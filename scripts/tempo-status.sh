#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

echo "Tempo status"
echo "Context:   ${KUBE_CONTEXT}"
echo "Namespace: observability"
echo

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace observability \
  get pods,deployments,services \
  --selector app.kubernetes.io/name=tempo
