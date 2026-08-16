#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

source "${script_dir}/config.sh"

echo "Configuring cert-manager"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --kustomize "${repo_root}/manifests/cert-manager/selfsigned"

echo
echo "Waiting for selfsigned ClusterIssuer"

kubectl \
  --context "${KUBE_CONTEXT}" \
  wait \
  --for=condition=Ready \
  clusterissuer/selfsigned \
  --timeout=2m
