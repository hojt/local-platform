#!/usr/bin/env bash
set -euo pipefail

readonly cluster_name="local"
readonly config_file="kind/cluster.yaml"

if kind get clusters | grep -qx "${cluster_name}"; then
  echo "Cluster '${cluster_name}' already exists."
  exit 0
fi

kind create cluster \
  --name "${cluster_name}" \
  --config "${config_file}"

kubectl cluster-info --context "kind-${cluster_name}"
