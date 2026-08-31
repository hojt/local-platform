#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

echo "Deleting Prometheus"

kubectl \
  --context "${KUBE_CONTEXT}" \
  delete \
  --kustomize "${repo_root}/manifests/prometheus" \
  --ignore-not-found
