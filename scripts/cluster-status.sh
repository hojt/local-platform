#!/usr/bin/env bash
set -euo pipefail

readonly context_name="kind-local"

kubectl config use-context "${context_name}"
kubectl get nodes
kubectl get pods --all-namespaces
