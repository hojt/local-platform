#!/usr/bin/env bash

set -euo pipefail

hostname="example.local"
address="127.0.0.1"
hosts_file="/etc/hosts"

case "${1:-}" in
install)
  if grep -Fxq "${address} ${hostname}" "${hosts_file}"; then
    echo "${hostname} is already configured"
    exit 0
  fi

  echo "Adding ${hostname} to ${hosts_file}"
  echo "${address} ${hostname}" | sudo tee -a "${hosts_file}" >/dev/null
  ;;

remove)
  echo "Removing ${hostname} from ${hosts_file}"
  sudo sed -i \
    "\|^${address} ${hostname}$|d" \
    "${hosts_file}"
  ;;

*)
  echo "Usage: $0 {install|remove}" >&2
  exit 1
  ;;
esac
