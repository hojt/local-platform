#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "${script_dir}/config.sh"

refresh_type="${1:-normal}"

case "${refresh_type}" in
  normal | hard)
    ;;
  *)
    printf 'Usage: %s [normal|hard]\n' "$0" >&2
    exit 1
    ;;
esac

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${ARGOCD_NAMESPACE}" \
  annotate application \
  --all \
  "argocd.argoproj.io/refresh=${refresh_type}" \
  --overwrite
