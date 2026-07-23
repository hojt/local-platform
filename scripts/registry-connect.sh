#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

registry_dir="/etc/containerd/certs.d/${REGISTRY_ADDRESS}"

if ! podman inspect \
  --format '{{json .NetworkSettings.Networks}}' \
  "${REGISTRY_NAME}" |
  grep -q "${KIND_NETWORK}"; then
  echo "Registry ${REGISTRY_NAME} is not connected to the kind network '${KIND_NETWORK}'" >&2
  echo "Recreate the registry with: task registry:delete registry:create" >&2
  exit 1
fi
echo "Registry is connected to the kind network"

echo "Configuring containerd registry mirror"

nodes="$(kind get nodes --name "${CLUSTER_NAME}")"

if [[ -z "${nodes}" ]]; then
  echo "No nodes found for cluster ${CLUSTER_NAME}" >&2
  exit 1
fi

while IFS= read -r node; do
  podman exec "${node}" \
    mkdir -p "${registry_dir}"

  podman exec \
    --interactive \
    "${node}" \
    sh -c "cat > '${registry_dir}/hosts.toml'" <<EOF
server = "http://${REGISTRY_NAME}:${REGISTRY_CONTAINER_PORT}"

[host."http://${REGISTRY_NAME}:${REGISTRY_CONTAINER_PORT}"]
  capabilities = ["pull", "resolve"]
EOF
done <<<"${nodes}"

echo "Publishing registry information in Kubernetes"

kubectl \
  --context "${KUBE_CONTEXT}" \
  apply --filename - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "${REGISTRY_ADDRESS}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

echo "Registry connected to cluster ${CLUSTER_NAME}"
