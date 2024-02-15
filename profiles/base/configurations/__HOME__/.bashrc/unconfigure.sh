function main() {
  local _profile="${1}" _filename="${2}"
  if [[ ! -e "${_filename}" ]]; then
    return 0
  fi
  sed -i '' '/# BEGIN: aboarding/,/#END: aboarding/d' "${_filename}"
}

main "${@}"
