#!/opt/homebrew/bin/bash -eu
set -E -o nounset -o errexit +o posix -o pipefail
shopt -s inherit_errexit

readonly __THIS_DIR__="$(dirname "${0}")"
source "${__THIS_DIR__}/init.rc"

function list_tool_definition_directories() {
  local _dir="${1}" _i;
  for _i in $(ls "${_dir}"); do
    _i="${_dir}/${_i}"
    if [[ ! -d "${_i}" ]]; then
      continue;
    fi
    #                      "[0-9]+_.+"
    if [[ ! "${_i##*/}" =~ [0-9]+_.+ ]]; then
      continue;
    fi
    echo "${_i}"
  done
}

function tool_name_of() {
  local _dirname="${1}"
  echo "${_dirname##*/}" | macsed -E "s/^[0-9]+_//"
}    

function resolve_operation() {
  local _op="${1}" _dirname="${2}"
  if [[ -f "${_dirname}/${_op}.sh" ]]; then
    echo "bash -eu ${_dirname}/${_op}.sh"
  else
    echo "fallback_${_op}" "$(tool_name_of "${_dirname}")"
  fi      
}

function fallback_install() {
  brew install "${1}"
}

function fallback_uninstall() {
  :
}

function fallback_caveats() {
  brew info --json=v2 "${1}"
}

function fallback_configure() {
  :
}

function fallback_unconfigure() {
  :
}
   
function install_tool() {
  local _dirname="${1}"
  $(resolve_operation install "${_dirname}")
}

function install_tools() {
  local _i
  for _i in $(list_tool_definition_directories "${__THIS_DIR__}" | sort); do
    install_tool "${_i}"
  done      
}

function uninstall_tool() {
  local _dirname="${1}"
  "$(resolve_operation uninstall "${_dirname}")"
}

function uninstall_tools() {
  local _i
  for _i in $(list_tool_definition_directories "${__THIS_DIR__}" | sort -r); do
    uninstall_tool "${_i}"
  done      
}

function main() {
  local _i
  for _i in "${@}"; do
    if [[ "${_i}" == install ]]; then
      install_tools
    elif [[ "${_i}" == uninstall ]]; then
      uninstall_tools
    else
      error "Unknown subcommand '${_i}' was given."
    fi
  done
}
main "${@}"



