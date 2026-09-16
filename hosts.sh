#!/usr/bin/env bash

set -euo pipefail

hostnames=(
  "example.local"
  "grafana.local"
  "argocd.local"
)
address="127.0.0.1"
hosts_file="/etc/hosts"

case "${1:-}" in
install)
  for hostname in "${hostnames[@]}"; do
    if grep -Fxq "${address} ${hostname}" "${hosts_file}"; then
      echo "${hostname} is already configured"
      continue
    fi

    echo "Adding ${hostname} to ${hosts_file}"
    echo "${address} ${hostname}" | sudo tee -a "${hosts_file}" >/dev/null
  done
  ;;

remove)
  for hostname in "${hostnames[@]}"; do
    echo "Removing ${hostname} from ${hosts_file}"
    sudo sed -i \
      "\|^${address} ${hostname}$|d" \
      "${hosts_file}"
  done
  ;;

*)
  echo "Usage: $0 {install|remove}" >&2
  exit 1
  ;;
esac
