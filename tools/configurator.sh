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
  local _op="${1}" _home="${2}" _profile="${3}" _profiles_base="${4}"
  local _profile_dir="${_profiles_base}/${_profile}"
  local _i _configs
  mapfile -t _configs < <(find "${_profile_dir}" -name "${op}.sh" -type f | sort)
  for _i in "${_configs[@]}"; do
    local _target_file
    _target_file="$(compose_destination_filename "${_home}" "${_profile}" "$(dirname "${_i}")")"
    mkdir -p "$(dirname "${_target_file}")"
    modern_bash -eu "${_i}" "${_profile}" "${_target_file}"
  done
}    

function configure_profile() {
  local _home="${1}" _profile="${2}" _profiles_base="${3}"
  perform_profile_operation "configure" "${_home}" "${_profile}" "${_profile_base}"}
}


function main() {
  for _i in "${@}"; do
    local _profile="${_i%%:*}"
    local _op="${_i#*:}"
    perform_profile_operation "${_op}" "${HOME}" "${_profile}" "${__PROFILES_BASE__}"
  done
}

readonly __PROFILES_BASE__="$(dirname "$(dirname "${0}")")/profiles"
main "${@}"
