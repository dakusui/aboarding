#!/bin/bash -eu

source "$(dirname $(dirname "$0"))/lib/init.rc"

readonly _LOCKFILE="$HOME/.macaboard/.bootstrap-installation-ongoing"

function check_lockfile() {
  if [[ -f "${_LOCKFILE}" ]]; then
    error "Perhaps bootstrap installation was not successful. Remove '${_lockfile}' and retry."
  else
    :
  fi
}

function lock() {
  mkdir -p "$(dirname "${_LOCKFILE}")"
  touch "${_LOCKFILE}"
}

function unlock() {
  rm "${_LOCKFILE}"
}

function install() {
  local _i
  check_lockfile
  lock
  for _i in "homebrew" "emacs" "bash" "jq"; do
      install_bootstrap_tool "${_i}"
  done
  unlock
}

function uninstall() {
  local _lockfile="${_LOCKFILE}"
  check_lockfile
  uninstall_homebrew 2>&1 | cat -n >&2 || error "Failed to install 'homebrew'. Check the log and stderr.'"
}

function install_homebrew() {
  yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error "Failed to install homebrew. Check your internet connection."
}

function uninstall_homebrew() {
  yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)" || error "Failed to uninstall homebrew. Check the log and stderr."
}

###
# Generally speaking emacs shouldn't be a part of bootstrap. But I'm so bad at playing with vi.
# Allow me to include it here.
function install_emacs() {
  run_brew install emacs   
}

function install_bash() {
  run_brew install bash
}    

function install_jq() {
  run_brew install jq
}    

function install_bootstrap_tool() {
  message "Installing '${1}':"
  install_"${1}" 2>&1 | cat -n >&2 || error "Failed to install '${1}. Check the log and stderr.'"
  message "'${1}' installed."
}

function message() {
  echo "${@}" >&2
}

function error() {
  message "${@}"
  exit 1
}

function run_brew() {
  /opt/homebrew/bin/brew "${@}"
}

function main() {
  local _i
  for _i in "${@}"; do
    if [[ "${_i}" == "install" ]]; then
      install
    elif [[ "${_i}" == "uninstall" ]]; then
      uninstall
    else
      error "Unknown subcommand '${_i}' was given."
    fi
  done
}

if [[ "$(whoami)" == "root" ]]; then
  echo "Do not run this script as root (using sudo)" >&2
fi

ensure_being_able_to_do_sudo

main "${@:-install}"
