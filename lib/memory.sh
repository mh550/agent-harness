#!/usr/bin/env bash
# `harness memory [--last <n>] [<project>]`: the ledger's memory PRs (<ledger>/memory.jsonl, one row per PR: a run's
# facts PR and its rules PR, each with its tier), newest first, each one's state asked of gh now and never written back;
# lib/summary.mjs renders them with the review's held and failed and Michael's overrides, one tally line per tier, one of
# Michael's verdicts and one of the review, and for a project the `auto:` line last (decisions/2026-11-09-memory-graduation). `proposals <run>` lists a
# run's numbered rules and proposals (<ledger>/<project>/<run>/memory-result.json); `accept|decline <run>/<n> --why`
# is Michael's verdict on one, a row of <ledger>/memory-answers.jsonl written under the ledger lock and, with
# LEDGER_COMMIT=1, one ledger commit of that file (as `harness backlog set`); lib/memory.mjs does the work.
# decisions/2026-11-07-memory-policy, decisions/2026-11-08-memory-rules-pr, decisions/2026-11-08-memory-session-and-answers.
#   memory.sh [--last <n>] [<project name or path>] | proposals <run> | accept|decline <run>/<n> --why "<text>"
set -uo pipefail
: "${HARNESS_HOME:?}"
[[ -z ${HARNESS_XTRACE:-} ]] || source "$HARNESS_HOME/lib/xtrace.sh"   # the coverage trace, off unless set (lib/xtrace.sh)
LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger} S=$HARNESS_HOME/lib/summary.mjs M=$HARNESS_HOME/lib/memory.mjs GH=${HARNESS_GH:-gh}
ANS=$LEDGER/memory-answers.jsonl
USAGE="usage: harness memory [--last <n>] [<project>] | proposals <run> | accept|decline <run>/<n> --why \"<text>\""
die() { echo "memory: $*" >&2; exit 1; }

# <run> → RES, its memory-result.json in the ledger's copy of the run record, and PROJ, the project it is under
result_of() {
  local fs=()
  [[ $1 =~ ^[A-Za-z0-9._-]+$ ]] || die "no run $1 in the ledger (no <project>/$1/memory-result.json)"
  shopt -s nullglob; fs=("$LEDGER"/*/"$1"/memory-result.json); shopt -u nullglob
  (( ${#fs[@]} )) || die "no run $1 in the ledger (no <project>/$1/memory-result.json)"
  (( ${#fs[@]} == 1 )) || die "run $1 is under more than one project in the ledger: ${fs[*]}"
  RES=${fs[0]} PROJ=$(basename "$(dirname "$(dirname "$RES")")")
}

case ${1:-} in
  proposals)
    (( $# == 2 )) || die "usage: harness memory proposals <run>"
    result_of "$2"; exec node "$M" proposals "$RES" "$2" "$ANS" ;;
  accept|decline)
    v=$1 why="" hasw="" verdict=${1/%accept/accepted}; verdict=${verdict/%decline/declined}; shift
    [[ ${1:-} =~ ^([A-Za-z0-9._-]+)/([1-9][0-9]*)$ ]] || die "usage: harness memory $v <run>/<n> --why \"<text>\""
    run=${BASH_REMATCH[1]} n=${BASH_REMATCH[2]}; shift
    while (( $# )); do
      case $1 in --why) (( $# >= 2 )) || break; why=$2 hasw=1; shift 2 ;; *) die "usage: harness memory $v <run>/<n> --why \"<text>\"" ;; esac
    done
    [[ -n $hasw ]] || die "$v $run/$n needs --why \"<text>\" (one line, at most 300 characters: what the next curator reads)"
    result_of "$run"
    # shellcheck source=lib/config.sh
    source "$HARNESS_HOME/lib/config.sh"; harness_config /nonexistent   # LEDGER_COMMIT
    STATE_ROOT=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}
    mkdir -p "$LEDGER" "$STATE_ROOT"
    (
      flock 9   # the lock the driver's ledger() and harness backlog hold
      out=$(node "$M" answer "$ANS" "$RES" "$PROJ" "$run" "$n" "$verdict" "$why" 2>&1) || { echo "memory: ${out%%$'\n'*}" >&2; exit 1; }
      echo "$out"
      if [[ $LEDGER_COMMIT == 1 ]] && git -C "$LEDGER" rev-parse --show-toplevel > /dev/null 2>&1; then
        git -C "$LEDGER" add -- memory-answers.jsonl && git -C "$LEDGER" commit -q -m "ledger: memory $v $run/$n" -- memory-answers.jsonl \
          || echo "memory: ledger commit skipped" >&2
      fi
      exit 0
    ) 9> "$STATE_ROOT/ledger.lock"
    exit ;;
esac

n=10 p="" pdir="" pol=pr
while (( $# )); do
  case $1 in
    --last) [[ ${2:-} =~ ^[1-9][0-9]*$ ]] || die "$USAGE"; n=$2; shift 2 ;;
    -*) die "$USAGE" ;;
    *) [[ -z $p ]] || die "$USAGE"; p=$(basename "$(realpath -m -- "$1")") pdir=$1; shift ;;   # a path's last part is the ledger's project name
  esac
done
# a project's MEMORY_POLICY, for the auto: line's revisit (decisions/2026-11-09-memory-graduation): a path (one with a
# /) reads the user's config and the project's .harness/config.sh, a bare name the user's alone (*default*); in a
# subshell, so a config's names never reach this script's
if [[ -n $p ]]; then
  pol=$(set +u; source "$HARNESS_HOME/lib/config.sh"
    if [[ $pdir == */* && -d $pdir ]]; then harness_config "$pdir"; else harness_config /nonexistent; fi > /dev/null 2>&1; echo "${MEMORY_POLICY:-pr}")
  [[ $pol =~ ^[a-z]+$ ]] || pol=pr
fi
# one copy, read by both steps: a run's ledger() may rewrite memory.jsonl between them
rows=$(mktemp) ans=$(mktemp); trap 'rm -f "$rows" "$ans"' EXIT
cp "$LEDGER/memory.jsonl" "$rows" 2> /dev/null
# the rows memoryView will show (summary.mjs memoryShown): one gh call each (a failed call leaves its state unknown)
while read -r url; do
  j=$("$GH" pr view "$url" --json state,mergedAt,commits 2> /dev/null < /dev/null) && jq -c --arg u "$url" '{url: $u, pr: .}' <<< "$j" >> "$ans" 2> /dev/null
done < <(node "$S" memory-urls "$rows" "$n" "$p")
node "$S" memory "$rows" "$ans" "$n" "$p" "$ANS" "$pol"   # a missing memory-answers.jsonl is no verdicts
