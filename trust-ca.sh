#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source_file="${repo_root}/.local/local-root-ca.crt"
target_file="/etc/pki/ca-trust/source/anchors/local-root-ca.crt"

case "${1:-}" in
install)
  if [[ ! -f "${source_file}" ]]; then
    echo "Local root CA not found: ${source_file}" >&2
    echo "Run: task cert-manager:export-ca" >&2
    exit 1
  fi

  echo "Installing local root CA"
  sudo cp "${source_file}" "${target_file}"
  sudo update-ca-trust

  echo "Local root CA installed"
  ;;

remove)
  echo "Removing local root CA"
  sudo rm -f "${target_file}"
  sudo update-ca-trust

  echo "Local root CA removed"
  ;;

*)
  echo "Usage: $0 {install|remove}" >&2
  exit 1
  ;;
esac
