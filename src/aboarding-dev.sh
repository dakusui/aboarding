#!/bin/bash -eu
# Forcibly use a traditional bash for compatibility's sake.
# Forcibly use a traditional bash for compatibility's sake.
set -E -o nounset -o errexit +o posix -o pipefail

function macos_default_shell() {
  dscl . -read ~/ UserShell | cut -f 2 -d ':' | sed -E 's/^[ \t]*(.+)[ \t]*$/\1/'
}

function macos_source_brew_shellenv() {
  source <(/opt/homebrew/bin/brew shellenv)  
}

function macos_homebrew_bash() {
  local _homebrew_bash="/opt/homebrew/bin/bash"
  [[ -e "${_homebrew_bash}" ]] && "${_homebrew_bash}" "${@}" || message "homebrew bash doesn't exist. nothing to do."
}

function install_bootstraps() {
  local _workdir="${1}"
  # Install bootstrap level tools
  /bin/bash -eu "${_workdir}/tools/bootstrap.sh" install
}

function download_profile() {
  local _workdir="${1}" _repo_url="${2}" _profile_name="${3}" _branch="${4}"
  begin "download profiles" "clone" "profile:${_profile_name}[branch:${_branch} from repo:${_repo_url}]"
  mkdir -p "${_workdir}/profiles"
  git clone \
      --single-branch --depth 1 \
      --branch "${_branch}" \
      "${_repo_url}"  \
      "${_workdir}/profiles/${_profile_name}" 2>&1 | \
      cat -n >&2 || \
    fail "download profile" "clone" "profile:${_profile_name}[branch:${_branch} from repo:${_repo_url}]"
  end "download profiles" "clone" "profile:${_profile_name}[branch:${_branch} from repo:${_repo_url}]"
}

function download_profiles() {
  local _workdir _repo_url
  local _i
  for _i in "${@}"; do
    local _directive="${_i%%:*}" _arg="${_i#*:}"
    local _profile_name _branch  _repo_url _workdir
    if [[ "${_directive}" == workdir ]]; then
      _workdir="${_arg}"
    elif [[ "${_directive}" == repo ]]; then
      _repo_url="${_arg}"
    elif [[ "${_directive}" == profile ]]; then
      local _profile_name _branch
      _profile_name="${_arg%%:*}"
      _branch="${_arg#*:}"
      download_profile "${_workdir?'workdir' is not set.}" \
		       "${_repo_url?'repo' is not set}" \
		       "${_profile_name}" \
                       "${_branch}"
    fi	
  done  
}

function install_packages() {
  local _workdir="${1}"
  local _profiles_dir="${2}"    
  # Install packages
  macos_source_brew_shellenv
  macos_homebrew_bash -eu "${_workdir}/tools/install-packages.sh" profiles:"${_profiles_dir}" \
			 private:install
  configure_packages "${_workdir}" "${_profiles_dir}"
}

function configure_packages() {
  local _workdir="${1}"
  local _profiles_dir="${2}"    
  macos_source_brew_shellenv
  macos_homebrew_bash -eu "${_workdir}/tools/configurator.sh" \
			 profiles:"${_profiles_dir}" \
                         configure:base \
			 configure:org \
                         configure:team \
			 configure:private
}

function onboard() {
  local _workdir="${1}" _profiles_dir="${2}"

  install_bootstraps "${_workdir}"
  download_profiles "workdir:${_workdir}" \
                    "repo:https://github.com/dakusui/aboarding.git" \
                    "profile:base:base-profile" \
                    "profile:org:example-company" \
                    "profile:team:example-team" \
                    "profile:private:$(whoami)"
  install_packages "${_workdir}" "${_profiles_dir}"
}

function uninstall_packages() {
  local _workdir="${1}"
  local _profiles_dir="${2}"    
  # Uninstall packages
  macos_source_brew_shellenv
  download_profiles "workdir:${_workdir}" \
                    "repo:https://github.com/dakusui/aboarding.git" \
                    "profile:base:base-profile" \
                    "profile:org:example-company" \
                    "profile:team:example-team" \
                    "profile:private:$(whoami)"
  macos_homebrew_bash -eu "${_workdir}/tools/configurator.sh" \
			 profiles:"${_profiles_dir}" \
			 unconfigure:private \
			 unconfigure:team \
			 unconfigure:org \
			 unconfigure:base
  macos_homebrew_bash -eu "${_workdir}/tools/install-packages.sh" profiles:"${_profiles_dir}" \
                         private:uninstall
}

function ensure_homebrew_installed_shell_is_not_default() {
  local _default_shell
  _default_shell="$(macos_default_shell)"
  if [[ "${_default_shell}" == *homebrew* ]]; then
    if [[ ! -e /bin/zsh ]]; then
      error "Even /bin/zsh doesn't exist. Do chsh -s {available shell} before trying this."
    fi
    chsh -s /bin/zsh || error "Failed to revert default shell to /bin/sh. Please change it to one that comes with macOS."
  fi
}    

function uninstall_bootstraps() {
  local _workdir="${1}"
  ensure_homebrew_installed_shell_is_not_default
  # Uninstall bootstrap level tools
  /bin/bash -eu "${_workdir}/tools/bootstrap.sh" uninstall
}

function remove_local_profiles() {
  local _workdir="${1}"
  if [[ -e "${_workdir}/profiles" ]] ; then
    rm -fr "${_workdir}/profiles"
  fi
}

function offboard() {
  local _workdir="${1}" _profiles_dir="${2}"
  ensure_homebrew_installed_shell_is_not_default
  uninstall_packages "${_workdir}" "${_profiles_dir}"
  remove_local_profiles "${_workdir}"
  uninstall_bootstraps "${_workdir}"
}

function main() {
  local _workdir="${1}"
  local _i
  local _profiles_dir
  shift
  if [[ "$#" == 0 ]]; then
    main "${_workdir}" onboard
  fi  
  _profiles_dir="${_workdir}/profiles"
  for _i in $@; do
    if [[ "${_i}" == onboard ]]; then
      onboard "${_workdir}" "${_profiles_dir}"
    elif [[ "${_i}" == offboard ]]; then
      offboard "${_workdir}" "${_profiles_dir}"
    elif [[ "${_i}" == install-bootstraps ]]; then
      install_bootstraps "${_workdir}"
    elif [[ "${_i}" == install-packages ]]; then
      install_packages "${_workdir}" "${_profiles_dir}"
    elif [[ "${_i}" == configure-packages ]]; then
      configure_packages "${_workdir}" "${_profiles_dir}"
    elif [[ "${_i}" == uninstall-bootstraps ]]; then
      uninstall_bootstraps "${_workdir}"
    elif [[ "${_i}" == uninstall-packages ]]; then
      uninstall_packages "${_workdir}" "${_profiles_dir}"
    elif [[ "${_i}" == download-profiles ]]; then
      download_profiles "workdir:${_workdir}" \
                    "repo:https://github.com/dakusui/aboarding.git" \
                    "profile:base:base-profile" \
                    "profile:org:example-company" \
                    "profile:team:example-team" \
                    "profile:private:$(whoami)"
    else
      echo "Unknown subcommand: '${_i}' was given." >&2
      exit 1
    fi
  done
}

function prepare() {
  local _workdir="${1}"
  mkdir -p "${_workdir}/lib"
  mkdir -p "${_workdir}/tools"

  cat > "${_workdir}/lib/init.rc" <<"SCRIPT_CONTENT"
__lib_init_rc__
SCRIPT_CONTENT
  cat > "${_workdir}/tools/bootstrap.sh" <<"SCRIPT_CONTENT"
__tools_bootstrap_sh__
SCRIPT_CONTENT
  cat > "${_workdir}/tools/install-packages.sh" <<"SCRIPT_CONTENT"
__tools_install_packages_sh__
SCRIPT_CONTENT
  cat > "${_workdir}/tools/configurator.sh" <<"SCRIPT_CONTENT"
__tools_configurator_sh__
SCRIPT_CONTENT
}

readonly _WORKDIR="$(mktemp -d)"

prepare "${_WORKDIR}"
source "${_WORKDIR}/lib/init.rc"
ensure_being_able_to_do_sudo
main "${_WORKDIR}" "$@"


