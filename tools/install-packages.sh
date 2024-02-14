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
    echo "bash -eu ${_dirname}/${_op}.sh"
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
  $(resolve_operation "${1}" "${_dirname}") | cat -n >&2 || error "FAILED[${_operation}]: '${_dirname}'"
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
  for _i in "${@}"; do
    local _profile="${_i%%:*}"
    local _op="${_i#*:}"
    local _packages_dir="$(dirname "${__THIS_DIR__}")/profiles/${_profile}/packages"
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



