#!/opt/homebrew/bin/bash -eu
set -E -o nounset -o errexit +o posix -o pipefail
shopt -s inherit_errexit

readonly __THIS_DIR__="$(dirname "${0}")"
source "${__THIS_DIR__}/init.rc"

function macsed() {
  # Use macOS default sed explicitly.
  /usr/bin/sed "${@}"    
}

function list_tool_definition_directories() {
  local _dir="${1}";
  for _i in $(ls "${_dir}"); do
    if [[ ! -d "${_i}" && ! "${_i}" =~ /[0-9]+_.+/ ]]; then
      continue;
    fi
    echo "${_i}"
  done | sort
}

function tool_name_of() {
  local _dirname="${1}"
  echo "${_dirname##*/}" | macsed -E "s/^[0-9]+_//"
}    

function resolve_installer() {
  local _dirname="${1}"    
  if [[ -f "${_dirname}/install.sh" ]]; then
    echo "bash ${_dirname}/install.sh"
  else
    echo "brew_install"
  fi      
}    

function install_tool() {
  local _dirname="${1}"
  local _installer
  _installer="$(resolve_installer "${_dirname}")"
  echo "${_installer}"
}

function brew_install() {
  brew install "${1}"
}

function main() {
  local _i
  for _i in $(list_tool_definition_directories "${__THIS_DIR__}"); do
    echo ">>${_i}"
    install_tool "${_i}"
  done      
}

main "${@}"



