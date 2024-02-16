#!/bin/bash -eu

function replace() {
  local _placeholder="${1}" _replacement_file="${2}"
  awk 'BEGIN{r=ARGV[1];ARGV[1]=""} {gsub(/'"${_placeholder}"'/, r)}1' "$(sed -E 's/&/\\&/g' "${_replacement_file}")"
}

function main() {
    cat "src/aboarding-dev.sh" | \
	replace "__lib_init_rc__" "./src/lib/init.rc" |
	replace "__tools_bootstrap_sh__" "./src/tools/bootstrap.sh" |
	replace "__tools_install_packages_sh__" "./src/tools/install-packages.sh" |
	replace "__tools_configurator_sh__" "./src/tools/configurator.sh"
}

main "$@"
