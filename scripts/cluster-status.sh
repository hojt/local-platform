#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

kubectl config use-context "${KUBE_CONTEXT}"
kubectl get nodes
kubectl get pods --all-namespaces
