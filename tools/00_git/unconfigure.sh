function unconfigure_git() {
  rm -fr ~/.git || message "~/.git not found."
}

unconfigure_git "${@}"

