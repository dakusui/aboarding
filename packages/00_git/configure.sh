function my_name() {
  for i in $(whoami | macsed -E 's/\./ /'); do echo -n "${i^} "; done | macsed -E 's/ +$//'
}

function configure_git() {
  git config --global user.email "$(whoami)@gmail.com"
  git config --global user.name "$(my_name)"
}

configure_git "${@}"
