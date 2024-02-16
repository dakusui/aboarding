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
[[ "${__MACABOARD_RC__:-no}" == "yes" ]] && return 0
__MACABOARD_RC__=yes

####
# Beware that this file is sourced both by bash 3.2 and 5 based scripts.
# Also source before and after installing homebrew.
# Thus, this must be written in a way, where they can work with every combination of those.

function ensure_being_able_to_do_sudo() {
  # Once sudo succeeds, it remmembers the password for 15 min.
  message "Let's ensure you can 'sudo'."
  sudo echo  "Good job!" >&2 || error "Failed to sudo!"
}

function macsed() {
  # Use macOS default sed explicitly.
  /usr/bin/sed "$@"    
}
export -f macsed

function message() {
  echo "$@" >&2
}
export -f message

function error() {
  message "$@"
  exit 1
}
export -f error
SCRIPT_CONTENT
  cat > "${_workdir}/tools/bootstrap.sh" <<"SCRIPT_CONTENT"
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
  for _i in "homebrew"; do
      uninstall_bootstrap_tool "${_i}"
  done
}

function install_homebrew() {
  yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error "Failed to install homebrew. Check your internet connection."
  return $?  
}

function uninstall_homebrew() {
  yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)" || error "Failed to uninstall homebrew. Check the log and stderr."
  return $?  
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

function uninstall_bootstrap_tool() {
  message "Uninstalling '${1}':"
  uninstall_"${1}" 2>&1 | cat -n >&2 || error "Failed to install '${1}. Check the log and stderr.'"
  message "'${1}' uninstalled."
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
SCRIPT_CONTENT
  cat > "${_workdir}/tools/install-packages.sh" <<"SCRIPT_CONTENT"
#!/opt/homebrew/bin/bash -eu
set -E -o nounset -o errexit +o posix -o pipefail
shopt -s inherit_errexit
source <(/opt/homebrew/bin/brew shellenv)

readonly __THIS_DIR__="$(dirname "${0}")"
source "$(dirname ${__THIS_DIR__})/lib/init.rc"

function list_package_definition_directories() {
  local _dir="${1}" _i;
  for _i in $(ls "${_dir}"); do
    _i="${_dir}/${_i}"
    if [[ ! -d "${_i}" ]]; then
      continue;
    fi
    #                     "[0-9]+_.+"
    if [[ ! "${_i##*/}" =~ ^[0-9]+_.+ ]]; then
      continue;
    fi
    echo "${_i}"
  done
}

function package_name_of() {
  local _dirname="${1}"
  echo "${_dirname##*/}" | macsed -E "s/^[0-9]+_//"
}    

function resolve_operation() {
  local _op="${1}" _dirname="${2}"
  if [[ -f "${_dirname}/${_op}.sh" ]]; then
    echo "bash -eu ${_dirname}/${_op}.sh" "$(package_name_of "${_dirname}")"
  else
    echo "fallback_${_op}" "$(package_name_of "${_dirname}")"
  fi      
}

function fallback_install() {
  brew install "${1}"
}

function fallback_uninstall() {
  message "nothing to do"
}

function fallback_caveats() {
  brew info --json=v2 "${1}"
}

function fallback_configure() {
  message "nothing to do"
}

function fallback_unconfigure() {
  message "nothing to do"
}

function perform_operation() {
  local _operation="${1}" _dirname="${2}"
  message "Processing: [${_operation}]: '${_dirname}'"
  $(resolve_operation "${1}" "${_dirname}") 2>&1 | cat -n >&2 || error "FAILED[${_operation}]: '${_dirname}'"
  message "Processed:  [${_operation}]: '${_dirname}'"
}

function install_packages() {
  local _packages_dir="${1}"
  local _i
  for _i in $(list_package_definition_directories "${_packages_dir}" | sort); do
    perform_operation install "${_i}"
  done      
}

function uninstall_packages() {
  local _packages_dir="${1}"
  local _i
      
  for _i in $(list_package_definition_directories "${_packages_dir}" | sort -r); do
      ( perform_operation uninstall "${_i}" ) || :
  done      
}

function main() {
  local _i
  local _profiles_dir
  _profiles_dir="$(pwd)/profiles"
  for _i in "${@}"; do
    local _profile="${_i%%:*}"
    local _op="${_i#*:}"
    if [[ "${_profile}" == profiles ]]; then
      _profiles_dir="${_op}"
      continue
    fi
    local _packages_dir="${_profiles_dir}/${_profile}/packages"
    if [[ "${_op}" == install ]]; then
      install_packages "${_packages_dir}"
    elif [[ "${_op}" == uninstall ]]; then
      uninstall_packages "${_packages_dir}"
    else
      error "Unknown subcommand '${_i}' was given."
    fi
  done
}
main "${@}"
SCRIPT_CONTENT
  cat > "${_workdir}/tools/configurator.sh" <<"SCRIPT_CONTENT"
#!/opt/homebrew/bin/bash -eu

source "$(dirname "$(dirname "${0}")")/lib/init.rc"

function modern_bash() {
  /opt/homebrew/bin/bash "${@}"  
}

function compose_destination_filename() {
  local _home="${1}" _profile="${2}" _operation_script_filename="${3}"
  local _ret="${_operation_script_filename}"
  _ret="$(echo "${_ret}" | macsed -E 's!.*__HOME__!'"${_home}"'!')"
  _ret="$(echo "${_ret}" | macsed -E 's!__PROFILE__!'"${_profile}"'!g')"
  
  echo "${_ret}"
}

function perform_profile_operation() {
  local _op="${1}" _home="${2}" _profile="${3}" _script="${4}"
  local _target_file
  _target_file="$(compose_destination_filename "${_home}" "${_profile}" "$(dirname "${_script}")")"
  message "Processing: [${_op}]: ${_script}"
  mkdir -p "$(dirname "${_target_file}")"
  modern_bash -eu "${_script}" "${_profile}" "${_target_file}" 2>&1 | cat -n
  message "Processed : [${_op}]: ${_script}"
}

function perform_profile_operations() {
  local _op="${1}" _home="${2}" _profile="${3}" _profiles_base="${4}"
  local _profile_dir="${_profiles_base}/${_profile}"
  local _i _configs
  mapfile -t _configs < <(find "${_profile_dir}" -name "${_op}.sh" -type f | sort)
  for _i in "${_configs[@]}"; do
    perform_profile_operation "${_op}" "${_home}" "${_profile}" "${_i}"
  done
}    

function main() {
  local _profiles_dir="${__PROFILES_DIR__}"
  for _i in "${@}"; do
    local _profile="${_i%%:*}"
    local _op="${_i#*:}"
    if [[ "${_profile}" == profiles ]]; then
      _profiles_dir="${_op}"
      continue
    fi
    perform_profile_operations "${_op}" "${HOME}" "${_profile}" "${_profiles_dir}"
  done
}

readonly __PROFILES_DIR__="$(pwd)/profiles"
main "${@}"
SCRIPT_CONTENT
}

readonly _WORKDIR="$(mktemp -d)"

prepare "${_WORKDIR}"
source "${_WORKDIR}/lib/init.rc"
ensure_being_able_to_do_sudo
main "${_WORKDIR}" "$@"


