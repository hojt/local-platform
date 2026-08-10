#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --kustomize "${repo_root}/manifests/gateway/envoy"
