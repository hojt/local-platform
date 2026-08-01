#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "${script_dir}/config.sh"

argocd_namespace="${ARGOCD_NAMESPACE:-argocd}"
argocd_version="${ARGOCD_VERSION:-v3.1.7}"
argocd_manifest_url="https://raw.githubusercontent.com/argoproj/argo-cd/${argocd_version}/manifests/install.yaml"

echo "Creating namespace ${argocd_namespace}"

kubectl \
  --context "${KUBE_CONTEXT}" \
  create namespace "${argocd_namespace}" \
  --dry-run=client \
  --output yaml |
kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --filename -

echo "Installing Argo CD ${argocd_version}"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${argocd_namespace}" \
  apply \
  --server-side \
  --force-conflicts \
  --filename "${argocd_manifest_url}"

echo "Waiting for Argo CD"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${argocd_namespace}" \
  rollout status deployment/argocd-server \
  --timeout 5m

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${argocd_namespace}" \
  rollout status deployment/argocd-repo-server \
  --timeout 5m

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${argocd_namespace}" \
  rollout status statefulset/argocd-application-controller \
  --timeout 5m
