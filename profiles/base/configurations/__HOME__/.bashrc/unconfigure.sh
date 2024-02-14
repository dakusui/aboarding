function main() {
  local _profile="${1}" _filename="${2}"
  sed -i '' '/# BEGIN: aboarding/,/#END: macaboarding/d' "${_filename}"
}

main "${@}"
