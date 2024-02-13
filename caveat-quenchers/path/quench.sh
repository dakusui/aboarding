function main() {
  local _arg="${1}"
  local _pathrc="${HOME}/.sh/pathrc"
  mkdir -p "$(dirname "${_pathrc}")"
  touch "${_pathrc}"
  echo 'export PATH='"${_arg}"':$PATH' > "$_pathrc{}"
}

main "${@}"
