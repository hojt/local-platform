#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

if ! podman container exists "${REGISTRY_NAME}"; then
  echo "Registry ${REGISTRY_NAME}: not created"
  exit 0
fi

if ! podman container inspect \
  --format '{{.State.Running}}' \
  "${REGISTRY_NAME}" |
  grep -qx true; then
  echo "Registry ${REGISTRY_NAME}: stopped"
  exit 0
fi

podman ps \
  --filter "name=^${REGISTRY_NAME}$"

if curl \
  --fail \
  --silent \
  --show-error \
  "http://${REGISTRY_ADDRESS}/v2/" >/dev/null; then
  echo "Registry ${REGISTRY_NAME}: running and reachable"
else
  echo "Registry ${REGISTRY_NAME}: running but not reachable"
  exit 1
fi
