#!/bin/bash -eu

readonly _LOCKFILE="$HOME/.macaboard/.bootstrap-installation-ongoing"

function install() {
  local _i
  mkdir "$(dirname "${_LOCKFILE}")"
  touch "${_LOCKFILE}"
  for _i in "homebrew" "emacs" "bash" "jq"; do
      message ">${_i}"
      install_bootstrap_tool "${_i}"
  done
  rm "${_LOCKFILE}"
}

function configure() {
  :
}

function uninstall() {
  local _lockfile="${_LOCKFILE}"
  [[ -f "${_lockfile}" ]] && error "Perhaps bootstrap installation was not successful. Remove '${_lockfile}' and retry."
  uninstall_homebrew
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
  if [[ "${#}" == 0 ]]; then
    main "install" "configure"
  fi
  for _i in "${@}"; do
    if [[ "${_i}" == "install" ]]; then
      install
    elif [[ "${_i}" == "configure" ]]; then
      configure
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

message "Let's ensure you can 'sudo'."
sudo echo  "Good job!" >&2 || error "Failed to sudo!"
# Once sudo succeeds, it remmembers the password for 15 min.

main "${@}"


