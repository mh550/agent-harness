#!/usr/bin/env bash
# `harness backlog`: the retro backlog (<ledger>/retro-backlog.jsonl), listed, moved and imported by hand. Writes hold the
# ledger lock the driver's ledger() holds and, with LEDGER_COMMIT=1 and the ledger in a git checkout, are one ledger
# commit of that file alone; lib/backlog.mjs does the work. decisions/2026-10-26-retro-backlog.
#   backlog.sh [list] | set <id> <status> [--spec <path>] [--pr <url>] [--note <text>] | import <file.jsonl>
set -uo pipefail
: "${HARNESS_HOME:?}"
# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"; harness_config /nonexistent   # LEDGER_COMMIT
LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger} STATE_ROOT=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}
STORE=$LEDGER/retro-backlog.jsonl B=$HARNESS_HOME/lib/backlog.mjs
SET_USAGE="usage: harness backlog set <id> <status> [--spec <path>] [--pr <url>] [--note <text>] (status: proposed|specced|queued|merged|dropped)"
die() { echo "backlog: $*" >&2; exit 1; }

# <commit message> <node backlog.mjs args…>: under the lock; the file untouched when node fails (it writes tmp, then renames)
write() {
  local msg=$1; shift
  mkdir -p "$LEDGER" "$STATE_ROOT"
  (
    flock 9
    out=$(node "$B" "$@" 2>&1) || { echo "${out%%$'\n'*}${USAGE:+ · $USAGE}" >&2; exit 1; }
    echo "$out"
    if [[ $LEDGER_COMMIT == 1 ]] && git -C "$LEDGER" rev-parse --show-toplevel > /dev/null 2>&1; then
      git -C "$LEDGER" add -- retro-backlog.jsonl && git -C "$LEDGER" commit -q -m "ledger: $msg" -- retro-backlog.jsonl \
        || echo "backlog: ledger commit skipped" >&2
    fi
    exit 0
  ) 9> "$STATE_ROOT/ledger.lock"
}

case ${1:-list} in
  list) (( $# <= 1 )) || die "usage: harness backlog [list]"
        exec node "$B" list "$STORE" ;;
  set) (( $# >= 3 && $# % 2 == 1 )) || die "$SET_USAGE"
       USAGE=$SET_USAGE write "backlog set $2 $3" set "$STORE" "${@:2}" ;;
  import) (( $# == 2 )) || die "usage: harness backlog import <file.jsonl>"
          [[ -f $2 ]] || die "no file $2"
          f=$(realpath -- "$2"); write "backlog import $(basename "$f")" import "$STORE" "$f" ;;
  *) die "usage: harness backlog [list] | set <id> <status> [--spec|--pr|--note <v>] | import <file.jsonl>" ;;
esac
