#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

echo "Sealed Secrets status"
echo "Context:   ${KUBE_CONTEXT}"
echo "Namespace: ${SEALED_SECRETS_NAMESPACE}"
echo

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${SEALED_SECRETS_NAMESPACE}" \
  get deployment sealed-secrets-controller

echo
echo "Sealing keys"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${SEALED_SECRETS_NAMESPACE}" \
  get secrets \
  --selector sealedsecrets.bitnami.com/sealed-secrets-key \
  --show-labels
