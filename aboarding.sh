#!/bin/bash -eu
# Forcibly use a traditional bash for compatibility's sake.

source "$(dirname $0)/lib/init.rc"

function macos_default_shell() {
  dscl . -read ~/ UserShell | cut -f 2 -d ':' | sed -E 's/^[ \t]*(.+)[ \t]*$/\1/'
}

function install_bootstraps() {
  # Install bootstrap level tools
  /bin/bash -eu tools/bootstrap.sh install
}

function install_packages() {
  # Install packages
  source <(/opt/homebrew/bin/brew shellenv)  
  /opt/homebrew/bin/bash -eu tools/install-packages.sh private:install
  /opt/homebrew/bin/bash -eu tools/configurator.sh base:configure org:configure team:configure private:configure
}

function onboard() {
  install_bootstraps
  install_packages
}

function uninstall_packages() {
  # Uninstall packages
  source <(/opt/homebrew/bin/brew shellenv)  
  /opt/homebrew/bin/bash -eu tools/configurator.sh private:unconfigure team:unconfigure org:unconfigure base:unconfigure
  /opt/homebrew/bin/bash -eu tools/install-packages.sh private:uninstall
}

function ensure_homebrew_installed_shell_is_not_default() {
  local _default_shell
  _default_shell="$(macos_default_shell)"
  if [[ "${_default_shell}" == *homebrew* ]]; then
    if [[ ! -e /bin/zsh ]]; then
      error "Even /bin/zsh doesn't exist. Do chsh -s {available shell} before trying this."
    fi
    chsh -s /bin/zsh || error "Failed to revert default shell to /bin/sh. Please change it to one that comes with macOS."
  fi
}    

function uninstall_bootstraps() {
  ensure_homebrew_installed_shell_is_not_default
  # Uninstall bootstrap level tools
  /bin/bash -eu tools/bootstrap.sh uninstall
}    

function offboard() {
  ensure_homebrew_installed_shell_is_not_default
  uninstall_packages
  uninstall_bootstraps  
}

function main() {
  local _i
  if [[ "$#" == 0 ]]; then
    main onboard
  fi  
  for _i in $@; do
    if [[ "${_i}" == onboard ]]; then
      onboard
    elif [[ "${_i}" == offboard ]]; then
      offboard
    elif [[ "${_i}" == install-packages ]]; then
      install_packages
    elif [[ "${_i}" == install-bootstraps ]]; then
      install_bootstraps
    elif [[ "${_i}" == uninstall-bootstraps ]]; then
      uninstall_bootstraps
    elif [[ "${_i}" == uninstall-packages ]]; then
      uninstall_packages
    else
      echo "Unknown subcommand: '${_i}' was given." >&2
      exit 1
    fi
  done
}

ensure_being_able_to_do_sudo
main "$@"


