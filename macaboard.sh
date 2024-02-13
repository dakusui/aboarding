#!/bin/bash -eu
# Forcibly use a traditional bash for compatibility's sake.

function onboard() {
  /bin/bash -eu bootstrap/bootstrap.sh
  /opt/homebrew/bin/bash -eu tools/install-tools.sh
}

function offboard() {

  /bin/bash -eu bootstrap/bootstrap.sh uninstall
}

