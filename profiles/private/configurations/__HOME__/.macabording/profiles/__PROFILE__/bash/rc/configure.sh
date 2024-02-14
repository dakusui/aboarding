function main() {
  local _filename="${1}"
  cat > "${_filename}" <<-'EOF'
# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac
[[ "${__BASH_PRIVATE_RC__:-no}" == "yes" ]] && return 0
__BASH_PRIVATE_RC__=yes

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=50000
HISTIGNORE=ls:history
HISTCONTROL=ignoreboth 

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
  xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
# force_color_prompt=yes

# https://www.kirsle.net/wizards/ps1.html
PS1="\[$(tput bold)\]\[$(tput setaf 4)\][\[$(tput setaf 4)\]\[$(tput setaf 5)\]\$? \D{%Y/%m/%dT%H:%M:%S%Z} \u@\[$(tput setaf 5)\]\h \[$(tput setaf 2)\]\w\[$(tput setaf 4)\]]\n\\$ \[$(tput sgr0)\]"

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

export EDITOR='emacs -nw'
export PATH=~/bin:$PATH

function today() {
  local _num="${1:-0}"
  date --date="${_num} day" "+%Y/%m/%d"
}

function workdir() {
  local _num="${1:-0}"
  echo "${HOME}/Documents/Daily/$(today ${1})/Desktop"
}

function statworkdir() {
  local _num="${1:-0}"
  shift
  ls "${@}" $(workdir "${_num}") 
}

function lsworkdir() {
  local _base="${HOME}/Documents/Daily"
  cd "${_base}" && find . -wholename '*/20[0-9][0-9]/[0-9][0-2]/[0-3][0-9]' -type d | sed -r 's/^\.\///'
}

function downloaddir() {
  local _num="${1:-0}"
  echo "${HOME}/Documents/Daily/$(today ${1})/Downloads"
}

function statdownloaddir() {
  local _num="${1:-0}"
  shift
  ls "${@}" $(downloaddir "${_num}") 
}

function _stash() {
  local _mode="${1:-desktop}"
  local _dest_root
  local _target_dir
  if [[ "${_mode}" == "desktop" ]]; then
    _dest_root="$(workdir)"
    _target_dir="Desktop"
  elif [[ "${_mode}" == "downloads" ]]; then
    _dest_root="$(downloaddir)"
    _target_dir="Downloads"
  else
    echo "Unknown mode ${_mode}"
    return 1
  fi
  mkdir -p ${_dest_root}
  mv ~/"${_target_dir}"/* ${_dest_root} >& /dev/null || echo "No file was found in '~/${_target_dir}/'"
}

function stash() {
  _stash "desktop"
  _stash "downloads"
}
EOF
}

main "${@}"
