#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  get --raw=/readyz \
  >/dev/null 2>&1; then
  echo "Kubernetes API is unavailable; skipping observability namespace deletion"
  exit 0
fi

echo "Deleting observability namespace"

kubectl \
  --context "${KUBE_CONTEXT}" \
  delete \
  --filename "${repo_root}/manifests/observability/namespace.yaml" \
  --ignore-not-found
