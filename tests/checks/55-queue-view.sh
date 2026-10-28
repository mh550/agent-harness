#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- harness queue list (U1-06): sectioned rows through view.mjs; harness queue show <n> [--parked]: one entry whole ----
status_stubs
Q=$HARNESS_STATE/queue
QL() { HARNESS_GLYPHS=unicode COLUMNS=${C:-100} "$H" queue list "$@" 2> "$T/ql.err"; }   # the list, glyphs pinned
QS() { HARNESS_GLYPHS=unicode COLUMNS=${C:-100} "$H" queue show "$@" 2> "$T/qs.err"; }
fld() { awk -v l="$1" 'substr($0, 1, 13) ~ "^  " l " +$" { on = 1; print; next } on && /^             / { print; next } { on = 0 }'; }   # card field $1's lines
labels() { awk '/^  [a-z]/ { l = substr($0, 3, 11); sub(/ +$/, "", l); print l }' | paste -sd"|"; }
widest() { node --input-type=module -e "import { displayWidth } from \"$HERE/../lib/view.mjs\"; import { readFileSync } from \"node:fs\";
  console.log(Math.max(0, ...readFileSync(0, \"utf8\").split(\"\n\").map(displayWidth)))"; }
B1200=$(printf 'brief %.0s' $(seq 200))
{ for i in 1 2 3 4 5 6 7; do echo "2026-10-28 0$i:48:1$i gc proj: harness gc $T/proj --all-merged --deps"; done
  echo "2026-10-28 08:00:00 runner down after starting 3 run(s): harness debrief (detached; output in queue/debrief.out)"; } > "$Q/runner.log"

check "queue list: QUEUE <n> · runner off · MAX_PARALLEL_RUNS=<k> to the width, then a row per entry: n, verb, run or project (new run) and its mark, spec basenames, age" '
  QL > "$T/l.out" && [[ $(head -1 "$T/l.out") =~ ^"QUEUE 2 · runner off · MAX_PARALLEL_RUNS=1 "(─)+$ && $(head -1 "$T/l.out" | widest) == 100 ]] \
  && grep -Ex " 1  start     proj \(new run\) +SPEC\.md b\.md +10m" "$T/l.out" > /dev/null && grep -Ex " 2  continue  stopped \(requested\) +5m" "$T/l.out" > /dev/null'
check "queue list: a 1,200-character --brief shows its first 30 characters and (+1170 chars); harness queue show 1 prints all 1,200" '
  [[ $(QL | grep -c "^    brief ") == 1 ]] && QL | grep -x "    brief \"brief brief brief brief brief …\" (+1170 chars)" > /dev/null \
  && QS 1 > "$T/s1.out" && [[ $(fld brief < "$T/s1.out" | sed -E "s/^  (brief)? +//" | paste -sd" ") == "${B1200% }" ]] && [[ $(fld brief < "$T/s1.out" | wc -l) -gt 10 ]]'
check "queue list: an entry whose project has a live run says held: <project> busy (<run>); the other entry nothing" '
  QL > "$T/l.out" && [[ $(grep -c "^    held: " "$T/l.out") == 1 ]] && [[ $(sed -n "/^ 1  start/,/^ 2 /p" "$T/l.out" | grep -c -x "    held: proj busy (running)") == 1 ]]'
check "queue list: PARKED <n> (skipped; harness queue unpark <n>) lists each parked entry with its why:" '
  QL | sed -n "/^PARKED/,/^RUNNING/p" > "$T/p.out" && [[ $(head -1 "$T/p.out") =~ ^"PARKED 1 (skipped; harness queue unpark <n>) "(─)+$ ]] \
  && grep -Ex " 1  start  proj2-next +15m" "$T/p.out" > /dev/null && grep -x "    why: waiting on the measure PRs (2026-10-28 23:00)" "$T/p.out" > /dev/null'
check "queue list: RUNNING names the live runs; RECENT is runner.log's last 5 lines, time only, home as a tilde; a rule and the show hint end it" '
  HOME=$T QL > "$T/l.out" && grep -x "RUNNING running" "$T/l.out" > /dev/null && [[ $(sed -n "/^RECENT/,\$p" "$T/l.out" | head -1) =~ ^"RECENT "(─)+$ ]] \
  && [[ $(sed -n "/^RECENT/,\$p" "$T/l.out" | sed -n 2,6p | paste -sd"|") == " 04:48  gc proj: harness gc ~/proj --all-merged --deps| 05:48  gc proj: harness gc ~/proj --all-merged --deps| 06:48  gc proj: harness gc ~/proj --all-merged --deps| 07:48  gc proj: harness gc ~/proj --all-merged --deps| 08:00  runner down after starting 3 run(s): harness debrief (detached; output in queue/debrief.out)" ]] \
  && [[ $(tail -2 "$T/l.out" | head -1) =~ ^(─){100}$ && $(tail -1 "$T/l.out") == "one entry in full: harness queue show <n>" ]]'
check "queue list: a live runner reads runner ● going; COLUMNS=60 says max <k>; at 60 and 80 no line passes the width" '
  cp "$HARNESS_STATE/proj/running/driver.pid" "$Q/runner.pid" && QL | head -1 | grep "^QUEUE 2 · runner ● going · MAX_PARALLEL_RUNS=1 " > /dev/null; r=$?; rm -f "$Q/runner.pid"
  (( r == 0 )) && C=60 QL > "$T/l60.out" && grep -E "^QUEUE 2 · runner off · max 1 (─)+$" "$T/l60.out" > /dev/null && [[ $(widest < "$T/l60.out") -le 60 ]] \
  && C=80 QL > "$T/l80.out" && [[ $(widest < "$T/l80.out") -le 80 ]] && grep "^    brief \"brief brief brief brief brief …\" (+1170 chars)$" "$T/l60.out" > /dev/null \
  && grep "^    held: proj busy (running)$" "$T/l60.out" > /dev/null && grep -x "  SPEC.md b.md" "$T/l60.out" > /dev/null'
check "queue list: an empty queue is QUEUE 0 · runner off · MAX_PARALLEL_RUNS=<k> and PARKED 0, one line each, and no hint" '
  HARNESS_STATE=$T/empty-q QL > "$T/e.out" && [[ $(paste -sd"|" "$T/e.out") == "QUEUE 0 · runner off · MAX_PARALLEL_RUNS=1|PARKED 0|RUNNING 0" ]]'
check "queue show <n>: verb, project path, run, spec, brief, until as a time, mark, added and the .args file, one labelled field per line" '
  HOME=$T QS 1 > "$T/s1.out" && [[ $(head -1 "$T/s1.out") == "○ 1 · start · proj (new run) · 10m ago" && $(sed -n 2p "$T/s1.out") =~ ^(─)+$ ]] \
  && [[ $(labels < "$T/s1.out") == "verb|project|run|spec|brief|until|held|added|file" ]] \
  && grep -x "  verb       start" "$T/s1.out" > /dev/null && grep -x "  project    ~/proj" "$T/s1.out" > /dev/null && grep -x "  run        (new run)" "$T/s1.out" > /dev/null \
  && grep -x "  spec       SPEC.md docs/b.md" "$T/s1.out" > /dev/null && grep -x "  until      2026-10-28 23:52" "$T/s1.out" > /dev/null \
  && grep -x "  held       proj busy (running)" "$T/s1.out" > /dev/null && grep -x "  file       ~/state/queue/0001-start-proj.args" "$T/s1.out" > /dev/null \
  && HOME=$T QS 2 > "$T/s2.out" && [[ $(labels < "$T/s2.out") == "verb|project|run|mark|options|added|file" ]] && grep -x "  project    ~/proj2" "$T/s2.out" > /dev/null \
  && grep -x "  run        stopped" "$T/s2.out" > /dev/null && grep -x "  mark       requested" "$T/s2.out" > /dev/null && grep -x "  options    --queued" "$T/s2.out" > /dev/null'
check "queue show <n> --parked: the parked entry with its why; a number past the end fails with the list to see" '
  QS 1 --parked > "$T/sp.out" && [[ $(head -1 "$T/sp.out") == "○ parked 1 · start · proj2-next · 15m ago" ]] && grep -x "  run        proj2-next" "$T/sp.out" > /dev/null \
  && grep -x "  why        waiting on the measure PRs (2026-10-28 23:00)" "$T/sp.out" > /dev/null && grep -x "  until      2026-10-28 01:00" "$T/sp.out" > /dev/null \
  && ! QS 3 > /dev/null && grep -x "harness: no queue entry 3 (see: harness queue list)" "$T/qs.err" > /dev/null \
  && ! QS 2 --parked > /dev/null && grep -x "harness: no parked entry 2 (see: harness queue list)" "$T/qs.err" > /dev/null && ! QS x > /dev/null'
check "queue list: its numbers are the ones queue rm takes" '
  "$H" queue rm 2 > "$T/rm.out" && grep -x "removed 0002-continue-stopped.args" "$T/rm.out" > /dev/null && QL > "$T/l.out" && grep "^QUEUE 1 · " "$T/l.out" > /dev/null \
  && grep -E "^ 1  start +proj \(new run\)" "$T/l.out" > /dev/null && ! grep "stopped" "$T/l.out" > /dev/null'
# odd entries (U1-06 review): an --until text to_epoch reads, a --brief-file, a --brief with no value, CRLF lines, an empty file
E=$T/odd/queue; mkdir -p "$E"
printf '%s\n' start /p/x --until "tomorrow 06:00" --brief-file /p/brief.md > "$E/0001-start-x.args"; printf '%s\n' start /p/y --brief > "$E/0002-start-y.args"
printf 'start\r\n/p/z\r\n' > "$E/0003-start-z.args"; : > "$E/0004-x.args"
check "queue show: an --until text shows as given, a --brief-file as its path; an empty --brief is no brief; a CR or an empty file never reaches the screen" '
  QO() { HARNESS_STATE=$T/odd HARNESS_GLYPHS=unicode COLUMNS=100 "$H" queue "$@" 2> "$T/odd.err"; }
  QO show 1 > "$T/o1.out" && grep -x "  until      tomorrow 06:00" "$T/o1.out" > /dev/null && grep -x "  brief      from /p/brief.md" "$T/o1.out" > /dev/null \
  && ! grep "^  options" "$T/o1.out" > /dev/null && QO show 2 > "$T/o2.out" && ! grep "^  brief" "$T/o2.out" > /dev/null \
  && QO list > "$T/ol.out" && ! grep "brief \"\"" "$T/ol.out" > /dev/null && ! grep -c $'"'"'\r'"'"' "$T/ol.out" > /dev/null \
  && QO show 3 > "$T/o3.out" && ! grep $'"'"'\r'"'"' "$T/o3.out" > /dev/null && ! grep null "$T/ol.out" > /dev/null && QO show 4 > "$T/o4.out" && ! grep null "$T/o4.out" > /dev/null'
check "queue show: a continue names its project path from meta.env, one %q quoted under a C locale too" '
  mkdir -p "$T/odd/p/qrun" && printf "%s\n" "PROJECT_DIR=\$'"'"'/p/caf\\303\\251 x'"'"'" "RUN_ID=qrun" "STATE=$T/odd/p/qrun" "WT=/nonexistent" > "$T/odd/p/qrun/meta.env" \
  && printf "%s\n" continue qrun --queued > "$E/0005-continue-qrun.args" && HARNESS_STATE=$T/odd HARNESS_GLYPHS=unicode "$H" queue show 5 | grep -x "  project    /p/café x" > /dev/null'
