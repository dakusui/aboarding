function main() {
  local _profile="${1}" _filename="${2}" # ~/.bashrc will be assigned.
  if [[ -e "${_filename}" ]] ; then
    grep "BEGIN: aboarding" "${_filename}" > /dev/null && return
  fi
  echo '
# BEGIN: aboarding: '"${_profile}"'
source ~/.aboarding/active_bash_profiles
# END: aboarding: '"${_profile}"'
' >> "${_filename}"
}

main "${@}"
