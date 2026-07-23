#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

readonly config_file="kind/cluster.yaml"

if kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  echo "Cluster '${CLUSTER_NAME}' already exists."
  exit 0
fi

kind create cluster \
  --name "${CLUSTER_NAME}" \
  --config "${config_file}"

kubectl cluster-info --context "kind-${CLUSTER_NAME}"
