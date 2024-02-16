#!/bin/bash -eu
# Forcibly use a traditional bash for compatibility's sake.

function macos_default_shell() {
  dscl . -read ~/ UserShell | cut -f 2 -d ':' | sed -E 's/^[ \t]*(.+)[ \t]*$/\1/'
}

function install_bootstraps() {
  local _workdir="${1}"
  # Install bootstrap level tools
  /bin/bash -eu "${_workdir}/tools/bootstrap.sh" install
}

function install_packages() {
  local _workdir="${1}"
  local _profiles_dir="${2}"    
  # Install packages
  source <(/opt/homebrew/bin/brew shellenv)  
  /opt/homebrew/bin/bash -eu "${_workdir}/tools/install-packages.sh" profiles:"${_profiles_dir}" \
			 private:install
  configure_packages "${_workdir}" "${_profiles_dir}"
}

function configure_packages() {
  local _workdir="${1}"
  local _profiles_dir="${2}"    
  source <(/opt/homebrew/bin/brew shellenv)  
  /opt/homebrew/bin/bash -eu "${_workdir}/tools/configurator.sh" profiles:"${_profiles_dir}" \
                                                                 base:configure org:configure \
                                                                 team:configure private:configure
}


function onboard() {
  local _workdir="${1}" _profiles_dir="${2}"

  install_bootstraps "${_workdir}"
  install_packages "${_workdir}" "${_profiles_dir}"
}

function uninstall_packages() {
  local _workdir="${1}"
  local _profiles_dir="${2}"    
  # Uninstall packages
  source <(/opt/homebrew/bin/brew shellenv)  
  /opt/homebrew/bin/bash -eu "${_workdir}/tools/configurator.sh" profiles:"${_profiles_dir}" \
			 private:unconfigure \
			 team:unconfigure \
			 org:unconfigure \
			 base:unconfigure
  /opt/homebrew/bin/bash -eu "${_workdir}/tools/install-packages.sh" profiles:"${_profiles_dir}" \
                         private:uninstall
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
  local _workdir="${1}"
  ensure_homebrew_installed_shell_is_not_default
  # Uninstall bootstrap level tools
  /bin/bash -eu "${_workdir}/tools/bootstrap.sh" uninstall
}    

function offboard() {
  local _workdir="${1}" _profiles_dir="${2}"
  ensure_homebrew_installed_shell_is_not_default
  uninstall_packages "${_workdir}" "${_profiles_dir}"
  uninstall_bootstraps "${_workdir}"
}

function main() {
  local _workdir="${1}"
  local _i
  local _profiles_dir
  shift
  if [[ "$#" == 0 ]]; then
    main "${_workdir}" onboard
  fi  
  _profiles_dir="$(pwd)/profiles"
  for _i in $@; do
    if [[ "${_i}" == onboard ]]; then
      onboard "${_workdir}" "${_profiles_dir}"
    elif [[ "${_i}" == offboard ]]; then
      offboard "${_workdir}" "${_profiles_dir}"
    elif [[ "${_i}" == install-bootstraps ]]; then
      install_bootstraps "${_workdir}"
    elif [[ "${_i}" == install-packages ]]; then
      install_packages "${_workdir}" "${_profiles_dir}"
    elif [[ "${_i}" == configure-packages ]]; then
      configure_packages "${_workdir}" "${_profiles_dir}"
    elif [[ "${_i}" == uninstall-bootstraps ]]; then
      uninstall_bootstraps "${_workdir}"
    elif [[ "${_i}" == uninstall-packages ]]; then
      uninstall_packages "${_workdir}" "${_profiles_dir}"
    else
      echo "Unknown subcommand: '${_i}' was given." >&2
      exit 1
    fi
  done
}

function prepare() {
  local _workdir="${1}"
  mkdir -p "${_workdir}/lib"
  mkdir -p "${_workdir}/tools"

  cat > "${_workdir}/lib/init.rc" <<"SCRIPT_CONTENT"
__lib_init_rc__
SCRIPT_CONTENT
  cat > "${_workdir}/tools/bootstrap.sh" <<"SCRIPT_CONTENT"
__tools_bootstrap_sh__
SCRIPT_CONTENT
  cat > "${_workdir}/tools/install-packages.sh" <<"SCRIPT_CONTENT"
__tools_install_packages_sh__
SCRIPT_CONTENT
  cat > "${_workdir}/tools/configurator.sh" <<"SCRIPT_CONTENT"
__tools_configurator_sh__
SCRIPT_CONTENT
}

readonly _WORKDIR="$(mktemp -d)"

prepare "${_WORKDIR}"
source "${_WORKDIR}/lib/init.rc"
ensure_being_able_to_do_sudo
main "${_WORKDIR}" "$@"


