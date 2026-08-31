#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

echo "Installing observability namespace"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --filename "${repo_root}/manifests/observability/namespace.yaml"
