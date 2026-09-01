#!/usr/bin/env bash

set -euo pipefail

readonly sysctl_key="fs.inotify.max_user_instances"
readonly recommended_value="1024"
readonly config_file="/etc/sysctl.d/99-local-platform-inotify.conf"

status() {
  echo "Current inotify configuration"
  sysctl "${sysctl_key}"
}

install() {
  echo "Configuring ${sysctl_key}=${recommended_value}"

  printf '%s = %s\n' \
    "${sysctl_key}" \
    "${recommended_value}" |
    sudo tee "${config_file}" >/dev/null

  sudo sysctl --system

  echo
  status
}

remove() {
  echo "Removing local-platform inotify configuration"

  sudo rm -f "${config_file}"
  sudo sysctl --system

  echo
  status
}

usage() {
  cat <<EOF
Usage: $0 {status|install|remove}

Commands:
  status   Show the current inotify instance limit
  install  Configure the recommended inotify instance limit
  remove   Remove the local-platform sysctl configuration
EOF
}

case "${1:-}" in
status)
  status
  ;;
install)
  install
  ;;
remove)
  remove
  ;;
*)
  usage >&2
  exit 1
  ;;
esac
