#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- everything reads the needs record (U2-07): harness status's NEEDS YOU, --json's needs and the card's needs you
# field from <state dir>/needs/*.json (lib/needs.mjs list), the desk prompt and the answer skill on harness needs ----
# Plan: docs/plans/2026-10-28-U2-needs-record.md §4.5. The debrief's #### needs block is checked in 15- (its dry run).
export TZ=UTC HARNESS_NOW=1793145600 COLUMNS=200 HARNESS_GLYPHS=unicode
ST=$HARNESS_STATE/proj
# rec: a verify_thin record and a merge_refused one; marks: needs-, refused- and conflict- markers and a blocked end,
# no record (U1 derived three items and a run_end from these)
needs_fixture verify_thin open $(( HARNESS_NOW - 600 )) rec
node "$HERE/../lib/needs.mjs" open "$ST/rec" rec proj merge_refused M2 milestone=M2 > /dev/null
needs_fixture merge_conflict open "" marks; rm -rf "$ST/marks/needs"; touch "$ST/marks/refused-M2"; echo "blocked on B · 2026-10-27 23:00:00" > "$ST/marks/ended"
H1=$(jq -r .card.headline "$ST/rec/needs/1.json") H2=$(jq -r .card.headline "$ST/rec/needs/2.json")
sec() { awk -v s="$1" 'index($0, s) == 1 { on = 1; next } /^(NEEDS YOU|RUNNING|QUEUED|FINISHED|─)/ { on = 0 } on'; }

check "status from records: --json needs are harness needs --json's items whole; markers and an end reason alone are none" \
  '"$H" status --json > "$T/s.json" && "$H" needs --json > "$T/n.json" && [[ $(jq ".needs | length" "$T/s.json") == 2 ]] \
  && diff <(jq -S .needs "$T/s.json") <(jq -S . "$T/n.json") > /dev/null \
  && [[ $(jq -r ".needs | map(.ref) | join(\" \")" "$T/s.json") == "rec/1 rec/2" ]] \
  && [[ $(jq -r "[.finished[] | select(.run == \"rec\" or .run == \"marks\") | \"\(.run)=\(.needs)\"] | sort | join(\" \")" "$T/s.json") == "marks=0 rec=2" ]]'
check "status view: NEEDS YOU lists the records' headlines, oldest first, none for the marker-only run" \
  '"$H" status > "$T/v.out" && grep "^NEEDS YOU 2 · harness needs" "$T/v.out" > /dev/null && sec "NEEDS YOU" < "$T/v.out" > "$T/n.out" \
  && [[ $(awk "{ print \$1, \$2 }" "$T/n.out" | paste -sd"|") == "⚠ rec|⚠ rec" ]] && grep -F "$H1" "$T/n.out" > /dev/null \
  && [[ $(grep -nF "$H1" "$T/n.out" | cut -d: -f1) -lt $(grep -nF "$H2" "$T/n.out" | cut -d: -f1) ]] && ! grep marks "$T/n.out" > /dev/null'
check "status card: needs you gives the count and each open item's headline, then the harness needs hint" \
  '[[ $("$H" status rec | awk "/^  needs you/ { on = 1 } on && !/^  needs you/ && !/^      / { on = 0 } on" | paste -sd"|") == "  needs you  ⚠ 2 · $H1|             $H2|             harness needs rec" ]] \
  && ! "$H" status marks | grep "^  needs you" > /dev/null'
# many: four items (3 headlines and +1 more on the card); bare: a record without its card (written by hand); broken: a
# parked.json needs.mjs can't make an item of (an empty feature id: no subject)
needs_fixture verify_thin open $(( HARNESS_NOW - 900 )) many
for m in M2 M3 M4; do HARNESS_NOW=$(( HARNESS_NOW - 800 )) node "$HERE/../lib/needs.mjs" open "$ST/many" many proj verify_red "$m" milestone="$m" > /dev/null; done
needs_fixture verify_thin open "" bare; jq "del(.card)" "$ST/bare/needs/1.json" > "$T/b.json" && mv "$T/b.json" "$ST/bare/needs/1.json"
needs_fixture verify_thin open "" broken; echo '{"":{"why":"x"}}' > "$ST/broken/parked.json"
check "status card: past three items, +<k> more; a record without its card and an unreadable state dir never stop status or harness needs" \
  '[[ $("$H" status many | grep -A4 "^  needs you" | sed -n "1p;4,5p" | paste -sd"|") == "  needs you  ⚠ 4 · $(jq -r .card.headline "$ST/many/needs/1.json")|             +1 more|             harness needs many" ]] \
  && "$H" status > "$T/v2.out" && grep -E "^⚠ bare +\[bare\] M1 needs you" "$T/v2.out" > /dev/null && "$H" status --json > /dev/null && "$H" status broken > /dev/null \
  && "$H" needs > "$T/n2.out" 2> "$T/n2.err" && grep "\[bare\] M1 needs you" "$T/n2.out" > /dev/null && grep "broken: no subject" "$T/n2.err" > /dev/null'
check "the desk prompt reads COLUMNS=60 harness needs and needs --json, never harness parked" \
  'P=$HH/prompts/desk.md; grep -F "\`COLUMNS=60 harness needs {{RUN_ID}}\`" "$P" > /dev/null && grep -F "harness needs {{RUN_ID}} --json" "$P" > /dev/null \
  && grep -F "\`COLUMNS=60 harness needs <run>\`" "$P" > /dev/null && ! grep -F "harness parked" "$P" > /dev/null'
check "the answer skill's first step is harness needs, harness parked its alias" \
  'S=$HH/skills/harness-answer/SKILL.md; grep -E "^1\. " "$S" | grep -F "\`harness needs\`" > /dev/null \
  && sed -n "/^1\. /,/^2\. /p" "$S" | grep -F "alias" | grep -F "harness parked" > /dev/null'

suite_end
