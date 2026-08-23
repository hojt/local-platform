#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

manifest_url="https://github.com/bitnami/sealed-secrets/releases/download/${SEALED_SECRETS_VERSION}/controller.yaml"

echo "Installing Sealed Secrets ${SEALED_SECRETS_VERSION}"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --server-side \
  --filename "${manifest_url}"

echo
echo "Waiting for Sealed Secrets controller"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${SEALED_SECRETS_NAMESPACE}" \
  rollout status deployment/sealed-secrets-controller \
  --timeout=5m
