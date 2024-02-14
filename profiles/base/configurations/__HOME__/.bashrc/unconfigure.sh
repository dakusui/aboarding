function main() {
  local _profile="${1}" _filename="${2}"
  sed -i '' '/# BEGIN: macaboard: '"${_profile}"'/,/#END: macaboard: '"${_profile}"'/d' "${_filename}"
}

main "${@}"
