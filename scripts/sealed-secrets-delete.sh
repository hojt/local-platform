#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

manifest_url="https://github.com/bitnami-labs/sealed-secrets/releases/download/${SEALED_SECRETS_VERSION}/controller.yaml"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  get --raw=/readyz \
  >/dev/null 2>&1; then
  echo "Kubernetes API is unavailable; skipping Sealed Secrets deletion"
  exit 0
fi

echo "Deleting Sealed Secrets ${SEALED_SECRETS_VERSION}"

kubectl \
  --context "${KUBE_CONTEXT}" \
  delete \
  --filename "${manifest_url}" \
  --ignore-not-found
