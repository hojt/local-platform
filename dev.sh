#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_name="$(basename -- "${repo_root}")"

# Normalize tmux session name
session_name="$(printf '%s' "${repo_name}" | tr -c '[:alnum:]_-' '-')"

podman_socket="${XDG_RUNTIME_DIR:-}/podman/podman.sock"

init_colors() {
  # Check if stdout has a TTY, meaning ANSI-color use is OK
  if [[ -t 1 ]]; then
    green=$'\033[32m'
    red=$'\033[31m'
    reset=$'\033[0m'
  else
    green=""
    red=""
    reset=""
  fi
}

check_failed=false

check_passed() {
  printf '  %s✓%s %s\n' "${green}" "${reset}" "$1"
}

check_failed() {
  printf '  %s✗%s %s\n' "${red}" "${reset}" "$1" >&2
  check_failed=true
}

check_command() {
  local command_name="$1"

  if command -v "${command_name}" >/dev/null 2>&1; then
    check_passed "${command_name}"
  else
    check_failed "${command_name}"
  fi
}

check_file() {
  local file_path="$1"
  local description="$2"

  if [[ -f "${file_path}" ]]; then
    check_passed "${description}"
  else
    check_failed "${description}"
  fi
}

verify_environment() {
  echo "Verifying environment"
  init_colors

  check_command tmux
  check_command podman
  check_command devcontainer

  check_file \
    "${repo_root}/.devcontainer/devcontainer.json" \
    ".devcontainer/devcontainer.json"

  if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    check_passed "XDG_RUNTIME_DIR"
  else
    check_failed "XDG_RUNTIME_DIR"
  fi

  ensure_podman_socket

  if [[ "${check_failed}" == true ]]; then
    echo >&2
    echo "Environment verification failed." >&2
    exit 1
  fi
}

ensure_podman_socket() {
  if [[ -S "${podman_socket}" ]]; then
    check_passed "Podman socket"
    return
  fi

  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user start podman.socket >/dev/null 2>&1 || true
  fi

  if [[ -S "${podman_socket}" ]]; then
    check_passed "Podman socket"
  else
    check_failed "Podman socket"
    echo >&2
    echo "Podman socket is unavailable: ${podman_socket}" >&2
    exit 1
  fi
}

open_troubleshooting_shell() {
  local message="$1"

  echo
  printf '%s✗%s %s\n' \
    "${red}" \
    "${reset}" \
    "${message}" >&2

  echo
  echo "Opening a host shell for troubleshooting."
  echo

  exec "${SHELL:-/bin/bash}" -l
}

enter_devcontainer() {
  echo "Starting development container"

  mkdir -p "${HOME}/.config/nvim"

  if ! devcontainer up \
    --remove-existing-container \
    --workspace-folder "${repo_root}" \
    --docker-path podman
  then
    open_troubleshooting_shell \
      "Failed to start development container"
  fi

  echo
  echo "Entering ${repo_name}"
  echo

  if ! exec devcontainer exec \
    --workspace-folder "${repo_root}" \
    --docker-path podman \
    bash --login
  then
    open_troubleshooting_shell \
      "Failed to enter development container"
  fi
}

start_tmux_session() {
  # This branch executes inside the repository-specific tmux session.
  if [[ "${DEV_SH_INSIDE_SESSION:-}" == "1" ]]; then
    enter_devcontainer
  fi

  # Reuse an existing repository session.
  if tmux has-session -t "=${session_name}" 2>/dev/null; then
    if [[ -n "${TMUX:-}" ]]; then
      exec tmux switch-client -t "=${session_name}"
    else
      exec tmux attach-session -t "=${session_name}"
    fi
  fi

  # Start this script again as the first process in the new tmux session.
  local session_command

  printf -v session_command \
    'DEV_SH_INSIDE_SESSION=1 %q' \
    "${repo_root}/dev.sh"

  if [[ -n "${TMUX:-}" ]]; then
    tmux new-session \
      -d \
      -s "${session_name}" \
      -c "${repo_root}" \
      "${session_command}"

    exec tmux switch-client -t "=${session_name}"
  else
    exec tmux new-session \
      -s "${session_name}" \
      -c "${repo_root}" \
      "${session_command}"
  fi
}

verify_environment
echo

start_tmux_session
