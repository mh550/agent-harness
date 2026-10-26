#!/usr/bin/env bash
# Cuts the single-file suite into tests/checks/NN-<slug>.sh by its `# ---- <title> ----` markers (run once; kept as the record).
#   tests/split.sh [<monolith>]   → default: tests/run.sh at $SPLIT_FROM, the last commit before the split, into $SPLIT_OUT
#                                   (tests/checks), which must be empty: files added since the split are never overwritten
# Every section's lines go into its file byte for byte, between the lib.sh preamble and suite_end; no check line is edited.
# A section that fails alone but passes in the monolith reads an earlier section's state: it is grouped with that section
# (one file, sections in their monolith order), never patched. Each pair names two titles by a prefix that matches one.
# Or the later section's file replays the earlier one first (REPLAYS_, P0-02): its lines byte for byte between REPLAY=1
# and REPLAY=, so its checks run silent and uncounted (lib.sh's check): they count in their own file, and state a replay
# got wrong fails the file's own checks. A replay costs the section's time again but cuts a chain: run 1 is 13 s, and
# grouping everything that reads it made one file of 400 s.
set -uo pipefail
GROUPS_=(   # "<later title prefix> -> <earlier title prefix>"   why
  "eval money -> harness eval run"           # reads $ED, the results dir of the eval the earlier section ran
  "capped sessions -> run 1:"                # reads demo's session scopes in systemd.log and $T/demo-hlog.md
  "the services scope -> capped sessions"    # reads demo's svc scope and bare's init.out and metrics
  "services_down -> run 1:"                  # reads demo's teardown marker and svc stop
  "services_down -> capped sessions"         # reads leftover's report
  "services_down -> scope.sh"                # reads $T/meminfo-2g.txt
  "capped suites -> run 1:"                  # reads demo's check scope
  "gc: -> run 1:"                            # collects run 1's demo worktree, tags and state
  "run 7: -> run 6:"                         # writes LIMIT_UNTIL into the state root an earlier run made
  "parked entries -> queue:"                 # reads $Q
  "run 15e -> run 1:"                        # reads $T/demo-hlog.md
  "debrief: the runner -> queue:"            # reads the queue's debrief log and last-debrief ($DB, $Q, $NOTE)
  "debrief: since -> debrief: the runner"    # counts the debriefs before it
  "debrief: since -> run 4:"                 # gated's
  "debrief: since -> run 5:"                 # limited's
  "debrief: since -> run 9:"                 # walled's
  "debrief: a big -> debrief: since"         # reads the last debrief and stoppy's report
  "run 17 -> queue:"                         # reads $Q
  "the desk -> run 16"                       # desks for parky (run 16), strict (run 3) and later (run 10)
  "the desk -> run 3:"                       # strict's
  "the desk -> run 10:"                      # later's
  "the desk -> run 2:"                       # stoppy's (found by P0-02's parallel run)
  "scratch -> run 1:"                        # reads demo's kept scratch and $T/demo-hlog.md
  "tmux (L3-04) -> queue:"                   # calls has_s
)
REPLAYS_=(  # "<later title prefix> <= <earlier title prefix>"   why
  "run 2: <= run 1:"                         # reads demo's port
  "run 2b <= run 1:"                         # stoppy is started by run 2, whose start reads demo's port (2026-10-26, the retro run's R7 section)
  "run 2b <= run 2:"                         # reads stoppy's harness-log.md and ended
  "run 16 <= run 1:"                         # writes a parked.json into demo's state dir
  "run 16 <= gc:"                            # demo's worktree gc'd: its parked.json names nothing (found by P0-02's parallel run)
  "debrief: since <= run 1:"                 # appends to demo's run.log (ran demo); a check reads run 1's HV
  "debrief: since <= run 2:"                 # appends to stoppy's run.log and ended
)
HERE=$(cd "$(dirname "$0")" && pwd); out=${SPLIT_OUT:-$HERE/checks}
SPLIT_FROM=${SPLIT_FROM:-3aa98b5}
src=$(mktemp); trap 'rm -f "$src"' EXIT
if [[ -n ${1:-} ]]; then cp "$1" "$src"; else git -C "$HERE/.." show "$SPLIT_FROM:tests/run.sh" > "$src" || exit 1; fi

mapfile -t marks < <(grep -n '^# ---- .* ----$' "$src" | cut -d: -f1)
epi=$(grep -n '^(( fails )) && { echo "--- run1 output"' "$src" | cut -d: -f1)   # the single file's own ending
(( ${#marks[@]} )) && [[ -n $epi ]] || { echo "split: no markers or no ending in the monolith" >&2; exit 1; }
n=${#marks[@]} titles=() root=() replay=()
for ((i = 0; i < n; i++)); do titles[i]=$(sed -n "${marks[i]}s/^# ---- \(.*\) ----$/\1/p" "$src"); root[i]=$i; done

# the one section whose title starts with $1
find_title() { local i hit=""; for ((i = 0; i < n; i++)); do [[ ${titles[i]} == "$1"* ]] && hit+="$i "; done
  [[ $hit =~ ^[0-9]+\ $ ]] || { echo "split: \"$1\" matches ${hit:-no section}" >&2; exit 1; }; echo "${hit% }"; }
top() { local i=$1; while (( root[i] != i )); do i=${root[i]}; done; echo "$i"; }
for p in "${GROUPS_[@]}"; do
  a=$(find_title "${p%% -> *}") && b=$(find_title "${p#* -> }") || exit 1
  a=$(top "$a") b=$(top "$b")
  (( a < b )) && root[b]=$a || root[a]=$b
done

for p in "${REPLAYS_[@]}"; do   # by the later section's group: its file replays the earlier section, never its own
  a=$(find_title "${p%% <= *}") && b=$(find_title "${p#* <= }") || exit 1
  a=$(top "$a"); (( $(top "$b") != a && b < a )) || { echo "split: \"$p\" replays its own group or a later section" >&2; exit 1; }
  [[ " ${replay[a]:-} " == *" $b "* ]] || replay[a]+=" $b"
done
lines() { local e=$(( $1 + 1 < n ? marks[$1 + 1] - 1 : epi - 1 )); sed -n "${marks[$1]},${e}p" "$src"; }   # section $1's lines

slug() { tr 'A-Z' 'a-z' <<< "$1" | tr -d "'" | tr -cs 'a-z0-9' ' ' | awk '{ s = ""; k = 0; for (i = 1; i <= NF && k < 4; i++) if ($i !~ /^(the|a|an)$/) { s = s (k++ ? "-" : "") $i } print s }'; }
[[ -z $(ls -A "$out" 2> /dev/null) ]] || { echo "split: $out is not empty" >&2; exit 1; }
mkdir -p "$out"
nn=0
for ((i = 0; i < n; i++)); do
  (( $(top "$i") == i )) || continue
  name=$(slug "${titles[i]}")   # a group's name adds its other sections' first words, so `tests/run.sh gc` still finds gc
  for ((j = i + 1; j < n; j++)); do (( $(top "$j") == i )) || continue; w=$(slug "${titles[j]}"); w=${w%%-*}
    [[ -$name- == *-$w-* ]] || name+=-$w; done
  nn=$((nn + 1)); f=$(printf '%s/%02d-%s.sh' "$out" "$nn" "$name")
  { echo '#!/usr/bin/env bash'; echo 'source "$(dirname "$0")/../lib.sh" && suite_setup'
    if [[ -n ${replay[i]:-} ]]; then
      echo "REPLAY=1   # replayed for their state, checked in their own files (tests/split.sh REPLAYS_)"
      for j in $(tr ' ' '\n' <<< "${replay[i]}" | sort -n); do lines "$j"; done
      echo "REPLAY="
    fi
    for ((j = i; j < n; j++)); do (( $(top "$j") == i )) && lines "$j"; done
    echo 'suite_end'; } > "$f"
  chmod +x "$f"
done
echo "split: $n sections → $nn files in $out"
