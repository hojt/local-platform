#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/config.sh"

if podman container exists "${REGISTRY_NAME}"; then
  podman rm --force "${REGISTRY_NAME}"
else
  echo "Registry ${REGISTRY_NAME} does not exist"
fi
