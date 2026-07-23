#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

if ! podman network exists "${KIND_NETWORK}"; then
  echo "Creating kind network: '${KIND_NETWORK}'"
  podman network create "${KIND_NETWORK}"
fi

if podman container exists "${REGISTRY_NAME}"; then
  echo "Registry ${REGISTRY_NAME} already exists"
else
  echo "Creating registry ${REGISTRY_NAME}"

  podman run \
    --detach \
    --restart=always \
    --name "${REGISTRY_NAME}" \
    --network "${KIND_NETWORK}" \
    --publish "127.0.0.1:${REGISTRY_HOST_PORT}:${REGISTRY_CONTAINER_PORT}" \
    "${REGISTRY_IMAGE}"
fi

echo "Registry available at ${REGISTRY_ADDRESS}"
