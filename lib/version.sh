# shellcheck shell=bash
# Usage: source lib/version.sh; harness_version <harness dir>   (sets HARNESS_VERSION=<short sha>|unknown, HARNESS_DIRTY=0|1)
# The harness commits its own ledger/ after every run and debrief, so HEAD moves without the code changing: the
# version is the last commit outside ledger/, and only changes outside it make the harness dirty (D-H34, E1-07).
harness_version() {
  HARNESS_VERSION=$(git -C "$1" log -1 --format=%h -- . ':(exclude)ledger' 2> /dev/null)
  [[ -n $HARNESS_VERSION ]] || HARNESS_VERSION=unknown
  HARNESS_DIRTY=$([[ -n $(git -C "$1" status --porcelain -- . ':(exclude)ledger' 2> /dev/null) ]] && echo 1 || echo 0)
}
