#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- harness status <run> (U1-05): a card, the state line, a rule and labelled fields, through view.mjs ----
status_stubs
CD() { HARNESS_GLYPHS=unicode COLUMNS=${C:-80} "$H" status "$@" 2> "$T/card.err"; }   # a card, glyphs pinned
fld() { awk -v l="$1" 'substr($0, 1, 13) ~ "^  " l " +$" || $0 == "  " l { on = 1; print; next } on && /^    / { print; next } { on = 0 }'; }   # field $1's lines, from stdin
labels() { awk '/^  [a-z]/ { l = substr($0, 3, 11); sub(/ +$/, "", l); print l }' | paste -sd"|"; }   # the field labels, in order
widest() { node --input-type=module -e "import { displayWidth } from \"$HERE/../lib/view.mjs\"; import { readFileSync } from \"node:fs\";
  console.log(Math.max(0, ...readFileSync(0, \"utf8\").split(\"\n\").filter(l => !/^  [a-z]+:\/\//.test(l)).map(displayWidth)))"; }

check "status card: line 1 is glyph, run, project, class or state, x/y passing and the age, then a rule" '
  CD done2h > "$T/d.out" && [[ $(head -1 "$T/d.out") == "✓ done2h · proj · done · 3/3 passing · 2h ago" && $(sed -n 2p "$T/d.out") =~ ^(─){80}$ ]] \
  && [[ $(CD stopped | head -1) == "■ stopped · proj2 · stopped · 1/3 passing · 5h ago" && $(CD givenup | head -1) == "⚠ givenup · proj2 · waiting · 2/3 passing · 30m ago" ]] \
  && [[ $(CD running | head -1) == "● running · proj · running · 1/3 passing · started 2h ago" && $(CD crashed | head -1) == "✗ crashed · proj · crashed · 0/1 passing · 10h ago" ]]'
check "status card: an ended run has ended, milestones, spend, branch, worktree, next; no now, lanes or units" '
  CD done2h > "$T/d.out" && [[ $(labels < "$T/d.out") == "ended|milestones|spend|branch|worktree|next" ]] \
  && grep -x "  ended      2026-10-27 22:00 (2h ago) · done" "$T/d.out" > /dev/null && grep -x "  milestones M1 ✓ merged 3/3" "$T/d.out" > /dev/null \
  && grep -Ex "  spend      \\\$[0-9]+\.[0-9]{2} · 3 sessions · 2\.0 h wall · tests 419 → 430" "$T/d.out" > /dev/null \
  && [[ $(fld next < "$T/d.out" | paste -sd"|") == "  next       harness report done2h|             harness continue done2h" ]]'
check "status card: a running run has now (feature, session, attempt of max, model, minutes in), lanes verbatim, its own units, next attach" '
  C=120 CD running > "$T/r.out" && [[ $(labels < "$T/r.out") == "now|milestones|lanes|spend|branch|worktree|units|next" ]] \
  && grep -x "  now        B · session 2 · attempt 2 of 2 · opus · 30 min in" "$T/r.out" > /dev/null \
  && [[ $(fld lanes < "$T/r.out" | paste -sd"|") == "  lanes      1 open|    lane M1 · B · session 2 · port 7960 · slot 1 · MemoryCurrent harness-running-M1-s2 300 MB" ]] \
  && grep -x "  units      harness-running-svc · 300 MB" "$T/r.out" > /dev/null && grep -x "  milestones M1 1/2 · M2 0/1" "$T/r.out" > /dev/null \
  && grep -Ex "  spend      \\\$[0-9]+\.[0-9]{2} · 2 sessions · 2\.0 h wall · port 7954" "$T/r.out" > /dev/null \
  && grep -x "  next       harness attach running" "$T/r.out" > /dev/null && ! grep "^  ended " "$T/r.out" > /dev/null \
  && touch "$HARNESS_STATE/proj/running/PAUSE" && [[ $(CD running | head -1) == "‖ running · proj · paused · 1/3 passing · started 2h ago" ]]; r=$?; rm -f "$HARNESS_STATE/proj/running/PAUSE"; (( r == 0 ))'
check "status card: N=3 and -v end with exactly the last 3 run.log lines; N=1 one; none without either" '
  C=200 N=3 CD done2h > "$T/n3.out" && diff <(tail -3 "$T/n3.out") <(tail -3 "$HARNESS_STATE/proj/done2h/run.log" | sed "s/^/    /") \
  && [[ $(grep -c "^    2026-" "$T/n3.out") == 3 && $(fld log < "$T/n3.out" | sed -n 1p) == "  log        last 3 lines of run.log" ]] \
  && [[ $(CD running -v | grep -c "^    2026-") == 3 && $(N=1 CD running | grep -c "^    2026-") == 1 ]] && ! CD done2h | grep "^    2026-" > /dev/null'
check "status card: the gcd run says removed by gc and 23/23 from the ledger; its milestones from the summary; next report only" '
  CD gcd > "$T/g.out" && [[ $(head -1 "$T/g.out") == "✓ gcd · proj · done · 23/23 passing · 1h ago" ]] && grep -x "  worktree   removed by gc" "$T/g.out" > /dev/null \
  && grep -x "  milestones M1 ✓ merged 12/12 · M2 ✓ merged 11/11" "$T/g.out" > /dev/null && grep -x "  branch     harness/gcd (worktree removed)" "$T/g.out" > /dev/null \
  && [[ $(fld next < "$T/g.out") == "  next       harness report gcd" ]]'
check "status card: needs you counts the run's items with the first headline and the harness needs hint" '
  [[ $(CD parked | fld "needs you" | paste -sd"|") == "  needs you  ⚠ 1 · B parked: set the gatus vars|             harness needs parked" ]] \
  && grep -x "  ended      2026-10-27 23:00 (1h ago) · waiting on Michael: B" <(CD parked) > /dev/null && ! CD done2h | grep "^  needs you" > /dev/null'
check "status card: branch names its commit and ahead, behind origin/main from local refs, with no fetch and no write" '
  W=$T/wt/proj/done2h && git -C "$W" init -q -b harness/done2h && git -C "$W" commit -q --allow-empty -m base && B=$(git -C "$W" rev-parse HEAD) \
  && git -C "$W" commit -q --allow-empty -m m1 && git -C "$W" update-ref refs/remotes/origin/main HEAD && git -C "$W" reset -q --hard "$B" \
  && git -C "$W" commit -q --allow-empty -m a1 && git -C "$W" commit -q --allow-empty -m a2 && touch "$T/card.stamp" && sleep 1 \
  && CD done2h > "$T/b.out" && grep -x "  branch     harness/done2h @ $(git -C "$W" rev-parse --short HEAD) · 2 ahead, 1 behind" "$T/b.out" > /dev/null \
  && [[ -z $(find "$HARNESS_STATE" "$T/wt" "$HARNESS_LEDGER" -newer "$T/card.stamp") ]]; r=$?; rm -rf "$W/.git"; (( r == 0 ))'
check "status card: COLUMNS=60 lines never exceed 60 columns but a URL; a long reason wraps under its label" '
  E=$HARNESS_STATE/proj2/stopped/ended; cp "$E" "$T/e.bak"; echo "stopped by Michael: $(printf "a long reason %.0s" $(seq 9)) see https://github.com/mh550/agent-harness/pull/123456789/files#diff-0123456789abcdef · $(date -d "@$(( HARNESS_NOW - 18000 ))" "+%F %T")" > "$E"
  C=60 N=3 CD stopped > "$T/60.out"; r=$?; cp "$T/e.bak" "$E"
  (( r == 0 )) && [[ $(widest < "$T/60.out") -le 60 ]] && grep -x "  https://github.com/mh550/agent-harness/pull/123456789/files#diff-0123456789abcdef" "$T/60.out" > /dev/null \
  && [[ $(fld ended < "$T/60.out" | wc -l) -ge 3 ]] && for r in running gcd parked crashed; do o=$(C=60 N=3 CD "$r") || echo 999; widest <<< "$o"; done | awk "\$1 > 60 { bad = 1 } END { exit bad }"'
check "status card: harness status nope exits 1 with harness: on stderr; -a, --since, -p with a run are an error" '
  "$H" status nope > "$T/nope.out" 2> "$T/nope.err"; [[ $? == 1 && ! -s $T/nope.out ]] && grep "^harness: no run '\''nope'\''" "$T/nope.err" > /dev/null \
  && ! "$H" status done2h --all > /dev/null 2>&1 && ! "$H" status done2h -p proj > /dev/null 2>&1'
check "status card: ASCII only under LC_ALL=C (lane and log lines are verbatim); no ESC off a TTY, colour with HARNESS_TTY=1; the worktree with the home directory as a tilde" '
  [[ $(for r in done2h parked gcd running crashed; do env -u HARNESS_GLYPHS LC_ALL=C LANG= LC_CTYPE= "$H" status "$r" || echo "✗ failed"; done | grep -v "^    " | LC_ALL=C tr -d "\000-\177" | wc -c) == 0 ]] \
  && env -u HARNESS_GLYPHS LC_ALL=C "$H" status done2h | head -1 | grep -x "+ done2h - proj - done - 3/3 passing - 2h ago" > /dev/null \
  && ! CD running -v | grep $'\''\e'\'' > /dev/null && HARNESS_TTY=1 TERM=xterm CD running | grep $'\''\e\\['\'' > /dev/null \
  && HOME=$T CD running | grep -x "  worktree   ~/wt/proj/running" > /dev/null'
check "status card: the debrief keeps N=3 harness status <run>; the supervisor asks for -v and keeps N=20" '
  grep -F "N=3 \"\$H\" status \"\$RUN_ID\"" "$HERE/../lib/debrief.sh" > /dev/null \
  && grep -F "harness status {{RUN_ID}} -v" "$HERE/../prompts/supervisor.md" > /dev/null && grep -F "N=20 harness status {{RUN_ID}}" "$HERE/../prompts/supervisor.md" > /dev/null'
check "status card: a driver killed before run.log has no NaN, a missing worktree is not removed by gc; a run started just now; N=0 adds no log field" '
  D=$HARNESS_STATE/proj/early; mkdir -p "$D" && printf "PROJECT_DIR=%q\nWT=%q\nRUN_ID=early\nSTATE=%q\n" "$T/proj" "$T/wt/proj/early" "$D" > "$D/meta.env" && sh -c "echo \$\$" > "$D/driver.pid"
  CD early > "$T/early.out"; r=$?; rm -rf "$D"; RL=$HARNESS_STATE/proj/running/run.log
  (( r == 0 )) && ! grep NaN "$T/early.out" > /dev/null && grep -x "  ended      driver gone without an end reason" "$T/early.out" > /dev/null \
  && ! grep "removed" "$T/early.out" > /dev/null && grep -x "  worktree   $T/wt/proj/early (missing)" "$T/early.out" > /dev/null \
  && cp "$RL" "$T/rl.bak" && echo "$(date -d "@$(( HARNESS_NOW - 30 ))" "+%F %T") run running on harness/running" >> "$RL" \
  && CD running > "$T/now.out"; r=$?; [[ -f $T/rl.bak ]] && cp "$T/rl.bak" "$RL"
  (( r == 0 )) && [[ $(head -1 "$T/now.out") == *" · started now" ]] && ! N=0 CD done2h | grep "^  log " > /dev/null'
check "status card: harness needs <run>, the card's hint, answers until U2's own command (the parked features)" '
  "$H" needs parked > "$T/needs.out" 2>&1 && grep "set the gatus vars" "$T/needs.out" > /dev/null'
