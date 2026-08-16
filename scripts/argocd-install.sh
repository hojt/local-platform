#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

argocd_manifest_url="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

echo "Creating namespace ${ARGOCD_NAMESPACE}"

kubectl \
  --context "${KUBE_CONTEXT}" \
  create namespace "${ARGOCD_NAMESPACE}" \
  --dry-run=client \
  --output yaml |
  kubectl \
    --context "${KUBE_CONTEXT}" \
    apply \
    --filename -

echo "Installing Argo CD ${ARGOCD_VERSION}"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${ARGOCD_NAMESPACE}" \
  apply \
  --server-side \
  --force-conflicts \
  --filename "${argocd_manifest_url}"

echo "Waiting for Argo CD"

for _ in {1..60}; do
  if kubectl \
    --context "${KUBE_CONTEXT}" \
    --namespace "${ARGOCD_NAMESPACE}" \
    get pods \
    --no-headers \
    2>/dev/null |
    grep -q .; then
    break
  fi

  sleep 1
done

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${ARGOCD_NAMESPACE}" \
  get pods \
  --no-headers \
  2>/dev/null |
  grep -q .; then
  echo "Timed out waiting for Argo CD pods to be created" >&2
  exit 1
fi

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${ARGOCD_NAMESPACE}" \
  wait \
  --for=condition=Ready \
  pod \
  --all \
  --timeout=5m
