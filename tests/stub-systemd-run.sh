#!/usr/bin/env bash
# Stand-in for `systemd-run --user --scope` in tests: appends each call to $STUB_DIR/systemd.log (the program name, each
# argument cut to its first line, then "==="). The probe (`--user --scope --quiet true`) exits 0; any other call reads
# the options up to the command, marks the unit alive in $STUB_DIR/scope/ (<unit>.alive, its MemoryMax in <unit>.max),
# runs the command with STUB_SCOPE_UNIT=<unit> (<unit>.running meanwhile) and exits with its code, the unit gone
# afterwards unless a pid in <unit>.pids lives on (as a real scope goes when empty). STUB_NO_SYSTEMD=1: every call fails the way it does without a
# user bus (fixtures/systemd-no-bus.txt, exit 1). A MemoryMax systemd can't parse fails the way the real one does
# (fixtures/systemd-run-bad-property.txt, exit 1, no unit made).
HERE=$(cd "$(dirname "$0")" && pwd)
{ echo systemd-run; for a in "$@"; do printf '%s\n' "${a%%$'\n'*}"; done; echo ===; } >> "$STUB_DIR/systemd.log"
[[ ${STUB_NO_SYSTEMD:-} == 1 ]] && { cat "$HERE/fixtures/systemd-no-bus.txt" >&2; exit 1; }
[[ $* == "--user --scope --quiet true" ]] && exit 0
S=$STUB_DIR/scope; mkdir -p "$S"; unit="" max=""
while (( $# )); do
  case $1 in
    --unit=*) unit=${1#--unit=} ;;
    -p) [[ ${2:-} == MemoryMax=* ]] && max=${2#MemoryMax=}; shift ;;
    --*) ;;
    *) break ;;
  esac; shift
done
[[ -z $max || $max =~ ^[0-9]+[KMGTkmgt]?$ ]] || { sed "s/=bogus:/=$max:/" "$HERE/fixtures/systemd-run-bad-property.txt" >&2; exit 1; }
source "$HERE/../lib/scope.sh"   # scope_bytes: the stub reads sizes as the code does
rm -f "$S/$unit".*; touch "$S/$unit.alive" "$S/$unit.running"; [[ -n $max ]] && scope_bytes "$max" > "$S/$unit.max"
STUB_SCOPE_UNIT=$unit "$@"; rc=$?   # forked, not exec'd as the real one: the stub must clean up after it
rm -f "$S/$unit.running"
for p in $(cat "$S/$unit.pids" 2> /dev/null); do kill -0 "$p" 2> /dev/null && exit $rc; done
rm -f "$S/$unit.alive"; exit $rc
