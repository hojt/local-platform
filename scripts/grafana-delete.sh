#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  get --raw=/readyz \
  >/dev/null 2>&1; then
  echo "Kubernetes API is unavailable; skipping Grafana deletion"
  exit 0
fi

echo "Deleting Grafana"

kubectl \
  --context "${KUBE_CONTEXT}" \
  delete \
  --kustomize "${repo_root}/manifests/grafana" \
  --ignore-not-found
