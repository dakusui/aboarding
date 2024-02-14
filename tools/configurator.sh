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

function configure_profile() {
  local _home="${1}" _profile="${2}" _profiles_base="${3}"
  local _profile_dir="${_profiles_base}/${_profile}"
  local _i _configs
  mapfile -t _configs < <(find "${_profile_dir}" -name 'configure.sh' -type f | sort)
  for _i in "${_configs[@]}"; do
    modern_bash -eu "${_i}" "${_profile}" "$(compose_destination_filename "${_home}" "${_profile}" "$(dirname "${_i}")")"
  done
}


function main() {
  for _i in "${@}"; do
    configure_profile "${HOME}" "${_i}" "${__PROFILES_BASE__}"
  done
}

readonly __PROFILES_BASE__="$(dirname "$(dirname "${0}")")/profiles"
main "${@}"
