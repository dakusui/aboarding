function main() {
  local _profile="${1}" _filename="${2}" # ~/.bashrc will be assigned.
  echo '
# BEGIN: macaboard: '"${_profile}"'
source ~/.macaboarding/active_profiles
# END: macaboard: '"${_profile}"'
' >> "${_filename}"
}

main "${@}"
