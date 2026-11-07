#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- harness context (A2): the debrief's gatherer, moved into lib/context.sh, for one run or every run since a time,
# plus a ## Glossary of the IDs it names (lib/glossary.mjs); read-only, written to its out directory alone ----
status_stubs
Q=$HARNESS_STATE/queue GX=$HERE/fixtures/glossary PR=$T/wt/proj/parked/.harness/runs/parked
# the glossary fixtures are proj's docs (the parked run's worktree is no checkout, so its docs root is $T/proj)
cp -r "$GX/wt/." "$T/proj/"
touch -d '2026-11-01 00:00' "$T/proj/docs/decisions.md"; touch -d '2026-11-02 00:00' "$T/proj/docs/research/2026-10-22-soulsync/README.md"
jq --slurpfile g "$GX/feature_list.json" '.features += [$g[0].features[] | select(.id == "N1-01")]' "$PR/feature_list.json" > "$T/fl.json" && mv "$T/fl.json" "$PR/feature_list.json"
printf 'status: run\n\n### B: set the gatus vars, then answer\n\n%s\n\n## Answers\n' "$(cat "$GX/text.md")" > "$PR/INBOX.md"
printf '%s\t%s\n' "$(( HARNESS_NOW - 11000 ))" "$(at 11000)" > "$Q/last-debrief"   # covers parked, givenup, running
GR=$T/wt/proj2/givenup/.harness/runs/givenup; echo '{"features":{"passing":2,"total":3},"cost":{"total":1.5}}' > "$GR/summary.json"   # a record's own summary
mkdir -p "$HARNESS_STATE/events/old" "$HARNESS_STATE/events/recent"   # the retention's (real clock: HARNESS_NOW is pinned in the past)
touch -d '31 days ago' "$HARNESS_STATE/events/old/event.json" "$HARNESS_STATE/events/old"; touch -d '1 day ago' "$HARNESS_STATE/events/recent/event.json"
touch "$T/mark"
sec() { awk -v h="### $1 (proj)" '$0 == h { on = 1; print; next } on && $0 == "~~~" { f = !f } on && !f && /^###? / { exit } on' "$2"; }   # one run's section
body() { sed '1d; /^## Glossary$/,$d' "$1"; }   # the context without its header line and its glossary

"$H" context parked --out "$T/b1" > "$T/b1.out" 2> "$T/b1.err"; b1=$?
"$H" debrief --dry-run > "$T/dry.out" 2>&1; DRY=$(head -1 "$T/dry.out")
"$H" context --since "$(at 11000)" --out "$T/b2" > "$T/b2.out" 2> "$T/b2.err"; b2=$?
"$H" context parked > "$T/b3.out" 2> "$T/b3.err"; b3=$?

check "context bundle: one run's context.md is its debrief section and a glossary" '
  (( b1 == 0 )) && [[ $(head -1 "$T/b1.out") == "$T/b1" ]] && sec parked "$T/b1/context.md" > "$T/s1" && sec parked "$DRY" > "$T/s0" \
  && [[ -s $T/s1 ]] && diff "$T/s0" "$T/s1" > /dev/null && G=$(sed -n "/^## Glossary$/,\$p" "$T/b1/context.md") \
  && grep -F -- "- **D24** (decision):" <<< "$G" > /dev/null && grep -F -- "- **N1-01** (feature):" <<< "$G" > /dev/null \
  && grep -F -- "- **M8** (milestone):" <<< "$G" > /dev/null && grep -F -- "- **D-H1** (decision):" <<< "$G" > /dev/null \
  && grep -E "^Unresolved: (.*, )?Q99(,|$)" <<< "$G" > /dev/null'
check "context bundle: --since matches the debrief's dry-run context but the glossary" '
  (( b2 == 0 )) && [[ -f $DRY && -f $T/b2/context.md ]] && grep -x "### givenup (proj2)" "$T/b2/context.md" > /dev/null \
  && diff <(body "$DRY") <(body "$T/b2/context.md")'
check "context bundle: the debrief's own context ends with the glossary" '
  [[ $(grep "^## " "$DRY" | tail -1) == "## Glossary" ]] && sed -n "/^## Glossary$/,\$p" "$DRY" | grep -F -- "- **D24** (decision):" > /dev/null'
check "context bundle: with no --out it writes events/<uuid>/ and prints that directory" '
  (( b3 == 0 )) && E=$(head -1 "$T/b3.out") && [[ $E =~ ^"$HARNESS_STATE/events/"[0-9a-f-]{36}$ && -s $E/context.md ]] \
  && [[ -z $(compgen -G "$E/.work.*") ]] && sec parked "$E/context.md" | diff "$T/s0" - > /dev/null'
check "context bundle: writes nothing outside its out directory, never summary.json" '
  E3=$(head -1 "$T/b3.out") && find "$HARNESS_STATE" "$T/wt" "$HARNESS_LEDGER" "$T/proj" -newer "$T/mark" 2> /dev/null \
    | grep -Evx "($T/b1|$T/b2|$E3|$HARNESS_STATE/debrief)(/.*)?|$HARNESS_STATE(/events)?" > "$T/new.txt"; [[ ! -s $T/new.txt ]] \
  && [[ -z $(find "$HARNESS_STATE" "$T/wt" "$HARNESS_LEDGER" "$T/b1" "$T/b2" -name summary.json -newer "$T/mark" 2> /dev/null) ]]'
check "context bundle: context.json has the spec's shape for one run" '
  jq -e ".v == 1 and (.id | type) == \"string\" and .generated_at != null and .scope.runs == [\"parked\"] and .scope.since == null and (.runs | length) == 1 and .runs[0].paths.record != null and .runs[0].parked[0].feature == \"B\" and ([.glossary[].id] | index(\"D24\")) != null and .unresolved == [\"Q99\"]" "$T/b1/context.json" > /dev/null \
  && [[ $(grep -c "jq -n" "$HH/lib/context.sh") == 0 ]] && jq -e ".runs[0] | .run == \"parked\" and .project == \"proj\" and .running == false and .paths.inbox == \"$PR/INBOX.md\" and .paths.worktree == \"$T/wt/proj/parked\" and .paths.state == \"$HARNESS_STATE/proj/parked\" and .parked[0].why == \"set the gatus vars and the token\"" "$T/b1/context.json" > /dev/null'
check "context bundle: context.json for --since names its time and every run since it" '
  c=$(sed -n "s/^- Covers: .*: [0-9]* (\(.*\))\$/\1/p" "$T/b2/context.md") && [[ -n $c ]] \
  && [[ $(jq -r ".scope.since" "$T/b2/context.json") == "$(at 11000)" && $(jq -r ".scope.runs | join(\" \")" "$T/b2/context.json") == "$c" ]] \
  && [[ $(jq -r "[.runs[].run] | join(\" \")" "$T/b2/context.json") == "$c" && $(jq ".scope.runs | length" "$T/b2/context.json") == 3 ]]'
check "context bundle: a run's summary is its summary.json, or null without one" '
  [[ $(jq -c ".runs[] | select(.run == \"givenup\") | .summary" "$T/b2/context.json") == "$(jq -c . "$GR/summary.json")" ]] \
  && jq -e "[.runs[] | select(.run != \"givenup\") | .summary] == [null, null]" "$T/b2/context.json" > /dev/null'
check "context bundle: open_questions carries the parked run's INBOX question" '
  jq -e "(.runs[0].open_questions | length) == 1 and (.runs[0].open_questions[0] | startswith(\"B: set the gatus vars, then answer Does N1-01\"))
    and .runs[0].parked[0].question == .runs[0].open_questions[0]" "$T/b1/context.json" > /dev/null'
check "context bundle: a new bundle removes events older than 30 days and says so" '
  [[ ! -e $HARNESS_STATE/events/old && -f $HARNESS_STATE/events/recent/event.json ]] && [[ $(sed -n 2p "$T/b3.out") == "events: removed 1 bundle older than 30 days" ]] \
  && [[ -s $(head -1 "$T/b3.out")/context.json && -e $HARNESS_STATE/events/recent ]] && ! grep -F "events: removed" "$T/b1.out" "$T/b2.out" > /dev/null'
check "context bundle: an unknown run exits 1, no argument prints the usage and exits 2" '
  "$H" context nosuch > /dev/null 2> "$T/d1.err"; r1=$?; "$H" context > /dev/null 2> "$T/d2.err"; r2=$?
  "$H" context --since yesterday > /dev/null 2> "$T/d3.err"; r3=$?; "$H" context parked --since "$(at 11000)" > /dev/null 2>&1; r4=$?
  "$H" context parked --from "$T/b1" > /dev/null 2>&1; r5=$?
  (( r1 == 1 && r2 == 2 && r3 == 2 && r4 == 2 && r5 == 2 )) && grep -F "no run '"'"'nosuch'"'"'" "$T/d1.err" > /dev/null \
  && grep "^usage: harness context <run-id> | --since <YYYY-MM-DD HH:MM:SS> \[--out <dir>\]" "$T/d2.err" > /dev/null && grep "^usage: harness context" "$T/d3.err" > /dev/null'

# a run whose driver is still finishing (alive, its ended written: the driver's end notify) and one with an empty ended:
# the debrief's context says what it said before the move; a bundle says how the finishing run ended
printf 'done · %s\n' "$(at 60)" > "$HARNESS_STATE/proj/running/ended"; : > "$HARNESS_STATE/proj2/givenup/ended"
"$H" debrief --dry-run > "$T/dry2.out" 2>&1; DRY2=$(head -1 "$T/dry2.out")
"$H" context running --out "$T/b4" > /dev/null 2>&1
check "context bundle: the debrief's context says a finishing run is still running, as before the move" '
  sec running "$DRY2" | grep -x -- "- ended: still running" > /dev/null \
  && awk "/^### givenup \\(proj2\\)\$/ { on = 1 } on && /^- ended:/ { print; exit }" "$DRY2" | grep -x -- "- ended: " > /dev/null'
check "context bundle: a bundle says how a finishing run ended" '
  sec running "$T/b4/context.md" | grep -x -- "- ended: done · $(at 60)" > /dev/null \
  && jq -e ".runs[0] | .ended == \"done\" and .running == false" "$T/b4/context.json" > /dev/null'

suite_end
