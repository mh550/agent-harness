#!/usr/bin/env bash
# Stand-in for `systemctl --user` in tests, over the units stub-systemd-run.sh marks alive in $STUB_DIR/scope/; logs
# each call to $STUB_DIR/systemd.log as that stub does. Shapes copy the real ones (fixtures/systemctl-*.txt, systemd 255):
#   show -p <K,…> <u>.scope  → the asked keys in systemd's order (never the asked order); alive: the live fixture with
#                              TasksCurrent = 2 + <u>.pids still alive and MemoryPeak = the cap if <u>.oom, else
#                              $STUB_MEM_PEAK, else the fixture's; gone: fixtures/systemctl-show-gone.txt. Exit 0.
#   list-units <glob> --plain --no-legend → one fixture line per live unit matching <glob>; nothing when none.
#   stop <u>.scope           → kills <u>.pids and the running command's tree (<u>.cmd), forgets the unit (exit 0); a unit
#                              not alive: "not loaded", exit 5.
# STUB_NO_SYSTEMD=1: every call fails the way it does without a user bus (exit 1).
HERE=$(cd "$(dirname "$0")" && pwd); S=$STUB_DIR/scope; FX=$HERE/fixtures
{ echo systemctl; for a in "$@"; do printf '%s\n' "${a%%$'\n'*}"; done; echo ===; } >> "$STUB_DIR/systemd.log"
[[ ${STUB_NO_SYSTEMD:-} == 1 ]] && { cat "$FX/systemd-no-bus.txt" >&2; exit 1; }
[[ ${1:-} == --user ]] && shift
live() { local p; for p in $(cat "$S/$1.pids" 2> /dev/null); do [[ $(ps -o stat= -p "$p" 2> /dev/null) == [^Z]* ]] && echo "$p"; done; }   # zombies are gone
tree() { local c; echo "$1"; for c in $(ps -o pid= --ppid "$1" 2> /dev/null); do tree "$c"; done; }   # <pid>, then its descendants
alive() { [[ -f $S/$1.alive ]] && { [[ -f $S/$1.running ]] || [[ -n $(live "$1") ]]; }; }   # collected once empty, as a real scope
verb=$1; shift; keys=, pat=() u=""   # options may come anywhere, as the real one takes them
while (( $# )); do case $1 in -p) keys+=$2,; shift ;; -*) ;; *) pat+=("$1") ;; esac; shift; done
u=${pat[0]:-}; u=${u%.scope}
old=$(sed -n 's|^ControlGroup=.*/||p' "$FX/systemctl-show-scope.txt"); old=${old%.scope}   # the captured unit's name
case $verb in
  show)
    if alive "$u"; then
      peak=${STUB_MEM_PEAK:-}; [[ -f $S/$u.oom ]] && peak=$(cat "$S/$u.max"); tasks=$(( 2 + $(live "$u" | wc -l) ))
      sed -e "s|$old|$u|" -e "s|^TasksCurrent=.*|TasksCurrent=$tasks|" ${peak:+-e "s|^MemoryPeak=.*|MemoryPeak=$peak|"} "$FX/systemctl-show-scope.txt"
    else cat "$FX/systemctl-show-gone.txt"; fi | while IFS= read -r l; do [[ $keys == *,"${l%%=*}",* ]] && printf '%s\n' "$l"; done ;;
  list-units)
    line=$(cat "$FX/systemctl-list-units.txt")
    for f in "$S"/*.alive; do [[ -f $f ]] || continue; v=$(basename "$f" .alive); alive "$v" && [[ $v.scope == ${pat[0]:-*} ]] && echo "${line//$old/$v}"; done ;;
  stop)
    alive "$u" || { sed "s/harness-test-[0-9]*-none/$u/g" "$FX/systemctl-stop-missing.txt" >&2; exit 5; }
    c=$(cat "$S/$u.cmd" 2> /dev/null); ps=$(live "$u"; [[ -n $c ]] && tree "$c")   # all first, then TERM: a dying parent orphans
    for p in $ps; do kill "$p" 2> /dev/null; done; rm -f "$S/$u".* ;;
esac
exit 0
