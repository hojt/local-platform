#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

repo_root="$(cd -- "${script_dir}/.." && pwd)"

cluster_exists() {
  kind get clusters 2>/dev/null |
    grep -Fxq "${CLUSTER_NAME}"
}

ensure_cluster_nodes_running() {
  local container_name="${CLUSTER_NAME}-control-plane"

  if ! podman container exists "${container_name}"; then
    echo "Kind node container ${container_name} does not exist" >&2
    return 1
  fi

  if [[ "$(podman inspect --format '{{.State.Running}}' "${container_name}")" == "true" ]]; then
    echo "Kind node ${container_name} is already running"
    return
  fi

  echo "Starting Kind node ${container_name}"
  podman start "${container_name}" >/dev/null
}

wait_for_kubernetes() {
  echo "Waiting for Kubernetes API"

  for _ in {1..60}; do
    if kubectl \
      --context "${KUBE_CONTEXT}" \
      get --raw=/readyz \
      >/dev/null 2>&1; then
      echo "Kubernetes API is ready"
      break
    fi

    sleep 1
  done

  if ! kubectl \
    --context "${KUBE_CONTEXT}" \
    get --raw=/readyz \
    >/dev/null 2>&1; then
    echo "Timed out waiting for Kubernetes API" >&2
    exit 1
  fi

  echo "Waiting for Kubernetes nodes"

  kubectl \
    --context "${KUBE_CONTEXT}" \
    wait \
    --for=condition=Ready \
    node \
    --all \
    --timeout=2m

  echo "Kubernetes nodes are ready"
}

if cluster_exists; then
  echo "Cluster '${CLUSTER_NAME}' already exists"
  ensure_cluster_nodes_running
else
  kind create cluster \
    --name "${CLUSTER_NAME}" \
    --config "${repo_root}/manifests/kind/cluster.yaml"
fi

wait_for_kubernetes
