#!/usr/bin/env bash
# `harness memory [--last <n>] [<project>]`: the ledger's memory PRs (<ledger>/memory.jsonl, one row per run), newest
# first, each one's state asked of gh now and never written back; lib/summary.mjs renders them. decisions/2026-11-07-memory-policy.
#   memory.sh [--last <n>] [<project name or path>]
set -uo pipefail
: "${HARNESS_HOME:?}"
[[ -z ${HARNESS_XTRACE:-} ]] || source "$HARNESS_HOME/lib/xtrace.sh"   # the coverage trace, off unless set (lib/xtrace.sh)
LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger} S=$HARNESS_HOME/lib/summary.mjs GH=${HARNESS_GH:-gh}
USAGE="usage: harness memory [--last <n>] [<project>]"
die() { echo "memory: $*" >&2; exit 1; }
n=10 p=""
while (( $# )); do
  case $1 in
    --last) [[ ${2:-} =~ ^[1-9][0-9]*$ ]] || die "$USAGE"; n=$2; shift 2 ;;
    -*) die "$USAGE" ;;
    *) [[ -z $p ]] || die "$USAGE"; p=$(basename "$(realpath -m -- "$1")"); shift ;;   # a path's last part is the ledger's project name
  esac
done
# one copy, read by both steps: a run's ledger() may rewrite memory.jsonl between them
rows=$(mktemp) ans=$(mktemp); trap 'rm -f "$rows" "$ans"' EXIT
cp "$LEDGER/memory.jsonl" "$rows" 2> /dev/null
# the rows memoryView will show (summary.mjs memoryShown): one gh call each (a failed call leaves its state unknown)
while read -r url; do
  j=$("$GH" pr view "$url" --json state,mergedAt,commits 2> /dev/null < /dev/null) && jq -c --arg u "$url" '{url: $u, pr: .}' <<< "$j" >> "$ans" 2> /dev/null
done < <(node "$S" memory-urls "$rows" "$n" "$p")
node "$S" memory "$rows" "$ans" "$n" "$p"
