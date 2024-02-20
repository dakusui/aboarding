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
  begin "Install" "${_op}" "${_profile}[${_script}]"
  mkdir -p "$(dirname "${_target_file}")"
  modern_bash -eu "${_script}" "${_profile}" "${_target_file}" 2>&1 | \
      cat -n || \
      fail "Install" "${_op}" "${_profile}[${_script}]"
  end "Install" "${_op}" "${_profile}[${_script}]"
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
  local _profiles_dir
  for _i in "${@}"; do
    local  _op="${_i%%:*}" _target="${_i#*:}"
    if [[ "${_op}" == profiles ]]; then
      _profiles_dir="${_target}"
      continue
    elif [[ "${_op}" == configure || "${_op}" == unconfigure  ]]; then
      perform_profile_operations "${_op}" "${HOME}" "${_target}" "${_profiles_dir?profiles: was not set.}"
    else
      error "Unknown operation: [${_op}] was given."
    fi
  done
}

readonly __PROFILES_DIR__="$(pwd)/profiles"
main "${@}"
