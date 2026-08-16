#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

manifest_url="https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml"

echo "Installing cert-manager ${CERT_MANAGER_VERSION}"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply \
  --filename "${manifest_url}"

if ! kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${CERT_MANAGER_NAMESPACE}" \
  get deployment cert-manager \
  --output jsonpath='{.spec.template.spec.containers[0].args}' |
  grep -q -- '--enable-gateway-api'; then
  echo
  echo "Enabling Gateway API support"

  kubectl \
    --context "${KUBE_CONTEXT}" \
    --namespace "${CERT_MANAGER_NAMESPACE}" \
    patch deployment cert-manager \
    --type=json \
    --patch='[
      {
        "op": "add",
        "path": "/spec/template/spec/containers/0/args/-",
        "value": "--enable-gateway-api"
      }
    ]'
else
  echo
  echo "Gateway API support is already enabled"
fi

echo
echo "Waiting for cert-manager"

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${CERT_MANAGER_NAMESPACE}" \
  rollout status deployment/cert-manager \
  --timeout=5m

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${CERT_MANAGER_NAMESPACE}" \
  rollout status deployment/cert-manager-cainjector \
  --timeout=5m

kubectl \
  --context "${KUBE_CONTEXT}" \
  --namespace "${CERT_MANAGER_NAMESPACE}" \
  rollout status deployment/cert-manager-webhook \
  --timeout=5m

echo
echo "Waiting for cert-manager API"

for _ in {1..60}; do
  if kubectl \
    --context "${KUBE_CONTEXT}" \
    apply \
    --dry-run=server \
    --filename - \
    >/dev/null 2>&1 <<'EOF'; then
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: readiness-check
spec:
  selfSigned: {}
EOF
    echo "cert-manager API is ready"
    exit 0
  fi

  sleep 1
done

echo "Timed out waiting for cert-manager API" >&2
exit 1
