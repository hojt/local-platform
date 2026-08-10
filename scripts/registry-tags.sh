#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "${script_dir}/config.sh"

image="${1:?Usage: registry-tags.sh IMAGE}"

curl \
  --fail \
  --silent \
  "http://localhost:${REGISTRY_HOST_PORT}/v2/${image}/tags/list"
