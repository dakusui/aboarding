
function load_profile() {
  local _profile="${1}"
  source "$(dirname "${0}")/${1}/rc"
}
function main() {
  load_profile org team private
}
main "${@}"
