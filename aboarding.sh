#!/bin/bash -eu
# Forcibly use a traditional bash for compatibility's sake.

source "$(dirname $0)/lib/init.rc"

function onboard() {
  # Uninstall bootstrap level tools
  /bin/bash -eu tools/bootstrap.sh install
  # Install packages
  source <(/opt/homebrew/bin/brew shellenv)  
  /opt/homebrew/bin/bash -eu tools/install-packages.sh private:install
  /opt/homebrew/bin/bash -eu tools/configurator.sh base:configure org:configure team:configure private:configure
}

function offboard() {
  # Uninstall packages
  source <(/opt/homebrew/bin/brew shellenv)  
  /opt/homebrew/bin/bash -eu tools/configurator.sh private:unconfigure team:unconfigure org:unconfigure base:unconfigure
  /opt/homebrew/bin/bash -eu tools/install-packages.sh private:uninstall
  # Uninstall bootstrap level tools
  /bin/bash -eu tools/bootstrap.sh uninstall
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
    else
      echo "Unknown subcommand: '${_i}' was given." >&2
      exit 1
    fi
  done
}

ensure_being_able_to_do_sudo
main "$@"


