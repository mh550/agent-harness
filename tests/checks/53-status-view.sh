#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- harness status (U1-04): one screen, NEEDS YOU · RUNNING · QUEUED · FINISHED and a footer, through view.mjs ----
status_stubs
V() { HARNESS_GLYPHS=unicode COLUMNS=${C:-80} "$H" status "$@" 2> "$T/view.err"; }   # the view, glyphs pinned
sec() { awk -v s="$1" 'index($0, s) == 1 { on = 1; next } /^(NEEDS YOU|RUNNING|QUEUED|FINISHED|─)/ { on = 0 } on'; }   # the rows of section $1, from stdin

check "status view: four sections in order (NEEDS YOU · harness needs, RUNNING, QUEUED · runner off, FINISHED · last 24h), a rule and the footer" '
  V > "$T/v.out" && [[ $(grep -E "^(NEEDS YOU|RUNNING|QUEUED|FINISHED)" "$T/v.out" | sed -E "s/ (─)+$//" | paste -sd"|") == "NEEDS YOU 3 · harness needs|RUNNING 1|QUEUED 2 · runner off (harness queue start)|FINISHED · last 24h · 6" ]] \
  && [[ $(tail -2 "$T/v.out" | head -1) =~ ^(─){80}$ && $(tail -1 "$T/v.out") == "1 older run: harness status --all · --since 3d · one run: harness status <run>" ]]'
check "status view: an empty state root prints the four empty sections and no footer" '
  [[ $(HARNESS_STATE=$T/empty V | paste -sd"|") == "NEEDS YOU 0 · harness needs|RUNNING 0|QUEUED 0 · runner off (harness queue start)|FINISHED · last 24h · 0" ]] && [[ ! -e $T/empty ]]'
check "status view: NEEDS YOU lists the crashed, the parked and the given-up run, oldest first, with headline, passing, dollars and age; the gc'd run none" '
  V | sec "NEEDS YOU" > "$T/n.out" && [[ $(awk "{ print \$1, \$2 }" "$T/n.out" | paste -sd"|") == "⚠ crashed|⚠ parked|⚠ givenup" ]] \
  && grep -Ex "⚠ parked +B parked: set the gatus vars +1/3 +\\\$[0-9]+ +1h" "$T/n.out" > /dev/null \
  && grep -Ex "⚠ givenup +C given up after 2 attempts +2/3 +33m" "$T/n.out" > /dev/null && ! grep -q gcd "$T/n.out"'
check "status view: RUNNING shows the live run as ● with feature, session and model alias; paused ‖; a usage-limit wait; two lanes as sub-rows" '
  V | sec RUNNING > "$T/r.out" && grep -Ex "● running +B · session 2 · opus +1/3 +\\\$[0-9]+ +2h" "$T/r.out" > /dev/null && [[ $(wc -l < "$T/r.out") == 1 ]] \
  && touch "$HARNESS_STATE/proj/running/PAUSE" && V | sec RUNNING | grep -Ex "‖ running +paused +1/3 .*" > /dev/null; r=$?; rm -f "$HARNESS_STATE/proj/running/PAUSE"
  echo $(( HARNESS_NOW + 5400 )) > "$HARNESS_STATE/LIMIT_UNTIL"; V | sec RUNNING | grep -E "^● running +waiting for the usage limit until 01:30 " > /dev/null || r=1; rm -f "$HARNESS_STATE/LIMIT_UNTIL"
  L=$HARNESS_STATE/proj/running/lanes; cp -r "$L/M1" "$L/M2"; echo "C · session 3" > "$L/M2/now"
  V | sec RUNNING > "$T/r2.out"; rm -rf "$L/M2"
  (( r == 0 )) && grep -E "^● running +2 lanes +1/3 " "$T/r2.out" > /dev/null && [[ $(grep -c "^    lane M[12] · [BC] · session [23]$" "$T/r2.out") == 2 ]]'
check "status view: QUEUED shows the waiting entries as queue rows, a held one says which run holds it, parked ones counted; past three, +<k> more" '
  C=120 V | sec QUEUED > "$T/q.out" && grep -Ex "○ 1 +start +proj \(new run\) +SPEC\.md b\.md · brief \"(brief ){5}…\" \(\+1170 chars\) +10m" "$T/q.out" > /dev/null \
  && grep -x "    held: proj busy (running)" "$T/q.out" > /dev/null && grep -Ex "○ 2 +continue +stopped \(requested\) +5m" "$T/q.out" > /dev/null \
  && [[ $(tail -1 "$T/q.out") == "1 parked: harness queue list" ]] \
  && for i in 5 6 7; do printf "%s\n" start "$T/proj3" > "$HARNESS_STATE/queue/000$i-start-proj3.args"; done \
  && V > "$T/q2.out"; r=$?; rm -f "$HARNESS_STATE"/queue/000[567]-*
  (( r == 0 )) && grep "^QUEUED 5 · " "$T/q2.out" > /dev/null && [[ $(sec QUEUED < "$T/q2.out" | grep -c "^○ ") == 3 && $(sec QUEUED < "$T/q2.out" | tail -1) == "+2 more · 1 parked: harness queue list" ]]'
check "status view: FINISHED newest first with the end class glyph and the reason, the gc'd run 23/23 from the ledger; the 3-day-old run only in the footer" '
  V | sec FINISHED > "$T/f.out" && [[ $(awk "{ print \$1, \$2 }" "$T/f.out" | paste -sd"|") == "⚠ givenup|⚠ parked|✓ gcd|✓ done2h|■ stopped|✗ crashed" ]] \
  && grep -Ex "✓ gcd +done +23/23 +\\\$[0-9]+ +1h" "$T/f.out" > /dev/null && grep -Ex "■ stopped +stopped by Michael: rebase first +1/3 .* 5h" "$T/f.out" > /dev/null \
  && V > "$T/v.out" && ! grep done3d "$T/v.out" > /dev/null'
check "status view: --since 4d adds the 3-day-old run and drops the footer; --all lists every run; --project proj2 only that project's" '
  V --since 4d > "$T/s4.out" && grep -E "^✓ done3d +done +1/1 " "$T/s4.out" > /dev/null && ! grep "older run" "$T/s4.out" > /dev/null && grep "^FINISHED · last 4d · 7" "$T/s4.out" > /dev/null \
  && V --all > "$T/all.out" && miss=$(for r in done2h done3d stopped parked givenup gcd crashed; do sec FINISHED < "$T/all.out" | grep -E "^[^ ]+ $r " > /dev/null || echo "$r"; done) && [[ -z $miss ]] \
  && sec RUNNING < "$T/all.out" | grep "^● running " > /dev/null \
  && grep "^FINISHED · all · 7" "$T/all.out" > /dev/null && ! grep "older run" "$T/all.out" > /dev/null \
  && V -p proj2 > "$T/p2.out" && [[ $(grep -E "^[^ A-Z]+ [a-z0-9-]+ " "$T/p2.out" | grep -v "^○" | awk "{ print \$2 }" | sort -u | paste -sd" ") == "givenup stopped" ]] \
  && grep -Ex "○ 2 +continue +stopped \(requested\) .*" "$T/p2.out" > /dev/null && grep "^RUNNING 0$" "$T/p2.out" > /dev/null'
check "status view: no run.log line without -v; a bad --since is an error" '
  V > "$T/v.out" && ! grep -E "^ *20[0-9]{2}-[0-9]{2}-[0-9]{2} |MemoryCurrent" "$T/v.out" > /dev/null \
  && ! V --since 3x > /dev/null && grep "^harness: bad duration" "$T/view.err" > /dev/null && ! V --bogus > /dev/null'
check "status view: no line over 60 or 80 display columns (also with -v); at 60 the long field and the cost go on an indented second line" '
  C=80 V > "$T/80.out" && [[ $(widest < "$T/80.out") -le 80 ]] && C=80 V -v --all > "$T/80v.out" && [[ $(widest < "$T/80v.out") -le 80 ]] \
  && C=60 V > "$T/60.out" && [[ $(widest < "$T/60.out") -le 60 ]] && C=60 V -v --all > "$T/60v.out" && [[ $(widest < "$T/60v.out") -le 60 ]] \
  && grep -A1 -E "^■ stopped +1/3 +5h$" "$T/60.out" | tail -1 | grep -x "  stopped by Michael: rebase first · \\\$[0-9]*" > /dev/null \
  && grep -A1 -E "^● running +1/3 +2h$" "$T/60.out" | tail -1 | grep -Ex "  B · session 2 · opus · \\\$[0-9]+" > /dev/null \
  && [[ $(tail -1 "$T/60.out") == "1 older run: harness status --all" ]] && grep "^QUEUED 2 · runner off ─" "$T/60.out" > /dev/null'
check "status view: colour only with HARNESS_TTY=1 (none under NO_COLOR); ASCII only under LC_ALL=C; paths with the home directory as a tilde" '
  V > "$T/c0.out" && ! grep $'\''\e'\'' "$T/c0.out" > /dev/null && HARNESS_TTY=1 TERM=xterm V | grep $'\''\e\\[3[1-6]m'\'' > /dev/null \
  && HARNESS_TTY=1 TERM=xterm NO_COLOR=1 V > "$T/c1.out" && ! grep $'\''\e'\'' "$T/c1.out" > /dev/null \
  && [[ $(env -u HARNESS_GLYPHS LC_ALL=C LANG= LC_CTYPE= COLUMNS=80 "$H" status | LC_ALL=C tr -d "\000-\177" | wc -c) == 0 ]] \
  && env -u HARNESS_GLYPHS LC_ALL=C COLUMNS=80 "$H" status | grep -E "^\* running +B - session 2 - opus " > /dev/null \
  && HOME=$T C=120 N=10 V > "$T/home.out" && ! grep -F "$T" "$T/home.out" > /dev/null && grep -F "in ~/wt/proj/running · port" "$T/home.out" > /dev/null'
check "status view: -v adds each running run's lane lines (P2-06's text), its own units with MemoryCurrent and the last 3 run.log lines; N alone implies -v" '
  C=120 V -v | sec RUNNING > "$T/vv.out" && [[ $(sed -n 2p "$T/vv.out") == "    lane M1 · B · session 2 · port 7960 · slot 1 · MemoryCurrent harness-running-M1-s2 300 MB" ]] \
  && [[ $(sed -n 3p "$T/vv.out") == "    harness-running-svc · MemoryCurrent 300 MB" && $(grep -c "^    2026-10-27 " "$T/vv.out") == 3 && $(wc -l < "$T/vv.out") == 6 ]] \
  && [[ $(N=1 V | sec RUNNING | grep -c "^    2026-") == 1 ]] && V -v > "$T/vf.out" && ! sec FINISHED < "$T/vf.out" | grep "^    " > /dev/null; r=$?
  cp "$HARNESS_STATE/proj/running/run.log" "$T/rl.bak"; for i in $(seq 25); do echo "2026-10-27 23:40:$(printf %02d $i) note $i" >> "$HARNESS_STATE/proj/running/run.log"; done
  N=20 V > "$T/n20.out" || r=1; cp "$T/rl.bak" "$HARNESS_STATE/proj/running/run.log"
  (( r == 0 )) && [[ $(sec RUNNING < "$T/n20.out" | grep -c "^    2026-") == 20 && $(sec RUNNING < "$T/n20.out" | tail -1) == "    2026-10-27 23:40:25 note 25" ]]'
check "status view: STATUS_SINCE defaults to 24h (lib/config.sh), commented in the user config template; the catch-up prompt asks for one project" '
  ( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config /nonexistent && [[ $STATUS_SINCE == 24h ]] ) \
  && grep "^# STATUS_SINCE=24h " "$HERE/../templates/user/config.sh" > /dev/null && grep -F "harness status --project <project>" "$HERE/../prompts/project-catchup.md" > /dev/null'
check "status view: -v with a non-numeric N keeps 3 log lines; two lanes' sub-rows are ASCII under LC_ALL=C; only a path starting with the home directory becomes a tilde; no control byte from run.log" '
  [[ $(N=abc C=120 V -v | sec RUNNING | grep -c "^    2026-") == 3 ]] \
  && L=$HARNESS_STATE/proj/running/lanes && cp -r "$L/M1" "$L/M2" && echo "C · session 3" > "$L/M2/now" && env -u HARNESS_GLYPHS LC_ALL=C COLUMNS=80 "$H" status > "$T/a2.out"; r=$?; rm -rf "$L/M2"
  RL=$HARNESS_STATE/proj/running/run.log; cp "$RL" "$T/rl2.bak"; printf "2026-10-27 23:50:00 kept /srv$T/x and $T/y\tz\033[31mred\n" >> "$RL"; HOME=$T C=120 V -v > "$T/h2.out" || r=1; cp "$T/rl2.bak" "$RL"
  (( r == 0 )) && grep -x "    lane M1 - B - session 2" "$T/a2.out" > /dev/null && [[ $(LC_ALL=C tr -d "\000-\177" < "$T/a2.out" | wc -c) == 0 ]] \
  && grep -F "kept /srv$T/x and ~/y z [31mred" "$T/h2.out" > /dev/null && ! grep $'"'"'[\t\e]'"'"' "$T/h2.out" > /dev/null'
check "status view: at 60 columns the cost stays beside a long reason; the footer keeps -p; a date window reads since <date>" '
  echo "stopped by Michael: $(printf "a long reason %.0s" $(seq 9)) · $(date -d "@$(( HARNESS_NOW - 18000 ))" "+%F %T")" > "$HARNESS_STATE/proj2/stopped/ended"
  C=60 V --all > "$T/60l.out"; r=$?; echo "stopped by Michael: rebase first · $(date -d "@$(( HARNESS_NOW - 18000 ))" "+%F %T")" > "$HARNESS_STATE/proj2/stopped/ended"
  (( r == 0 )) && grep -A1 -E "^■ stopped " "$T/60l.out" | tail -1 | grep -E "^  stopped by Michael: a long .*… · \\\$[0-9]+$" > /dev/null \
  && V -p proj --since 30m > "$T/pf.out" && C=100 V -p proj --since 30m | tail -1 | grep -x "2 older runs: harness status --all -p proj · --since 3d · one run: harness status <run>" > /dev/null \
  && V -p proj --since 30m | grep -x "2 older runs: harness status --all -p proj · --since 3d" > /dev/null \
  && V --since 2026-10-25 | grep "^FINISHED · since 2026-10-25 · " > /dev/null'
status_bulk 30
check "status view: harness status --all over 38 stub runs takes under 1 s (best of 3), and lists them all" '
  best=99999; for i in 1 2 3; do t0=$(date +%s%N); V --all > "$T/all.out" || break; t=$(( ($(date +%s%N) - t0) / 1000000 )); (( t < best )) && best=$t; done
  echo "    best of 3: $best ms"; (( best < 1000 )) && [[ $(grep -cE "^(●|‖|⚠|✓|■|✗) " "$T/all.out") == 41 ]] && grep "^31 older runs: " <(V) > /dev/null'
suite_end
