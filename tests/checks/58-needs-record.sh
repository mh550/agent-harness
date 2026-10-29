#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the needs record (U2-03): lib/needs.mjs's record, refresh, sweep and synthesized items; harness needs --json, done ----
# Plan: docs/plans/2026-10-28-U2-needs-record.md §1, §2, §4.1. A fixture run per reason and state (tests/lib.sh
# needs_fixture), opened at BASE minus its index so the list's oldest-first order is not the order they were written in.
NM=$HERE/../lib/needs.mjs BASE=1793145600
REASONS="parked given_up verify_thin verify_red verify_recheck merge_conflict merge_refused main_conflict base_conflict feature_list_edits initializer_failed driver_crash usage_limit weekly_budget overlap"
i=0; for r in $REASONS; do i=$(( i + 1 )); needs_fixture "$r" open $(( BASE - i * 10 )); needs_fixture "$r" resolved $(( BASE - i * 10 )); done
IMP="import * as N from \"$NM\"; import { readFileSync as r } from \"node:fs\"; const ok = c => process.exit(c ? 0 : 1);"
in_node() { node --input-type=module -e "$IMP $1"; }
R1=$HARNESS_STATE/proj/nf-parked-open/needs/1.json

# the v1 event keys, in order, from the n8n spec's Event JSON block
EV=$(awk '/^Event JSON/ { f = 1 } f && /^```json$/ { g = 1; next } g && /^```$/ { exit } g' "$HERE/../docs/specs/2026-10-22-n8n-events.md" | grep -oE '"[a-z_]+":' | tr -d '":' | paste -sd' ')
check "needs record: its first 13 keys are the v1 event keys in order, kind is park, needs_michael, blocked or limit (in v1's enum)" \
  '[[ $EV == "v id at kind project run feature title body priority click actions context" ]] \
  && [[ $(jq -r "keys_unsorted[:13] | join(\" \")" "$R1") == "$EV" ]] \
  && [[ $(jq -r "keys_unsorted[13:] | join(\" \")" "$R1") == "ref key reason severity milestone seen updated_at card resolved_at resolved_by resolved_why" ]] \
  && [[ $(cat "$HARNESS_STATE"/proj/nf-*/needs/1.json | jq -r .kind | sort -u | paste -sd" ") == "blocked limit needs_michael park" ]] \
  && jq -e "(.v == 1) and (.id | test(\"^[0-9a-f-]{36}$\")) and .at == \"2026-10-27T23:59:50.000Z\" and .run == \"nf-parked-open\" and .project == \"proj\" and .feature == \"B\" and .context == null and .resolved_at == null" "$R1" > /dev/null'
check "needs record: ref is <run>/<seq>, key <reason>:<subject>; seq is one past the largest in needs/ and needs/done/; feature and milestone default from the subject or the list" \
  '[[ $(jq -r "[.ref, .key, .milestone, .seen] | join(\" \")" "$R1") == "nf-parked-open/1 parked:B M1 1" ]] \
  && d=$HARNESS_STATE/proj/nf-seq && mkdir -p "$d/needs/done" && echo "{}" > "$d/needs/done/7.json" && echo "{}" > "$d/needs/3.json" \
  && [[ $(node "$NM" open "$d" nf-seq proj verify_red M2) == nf-seq/8 && -f $d/needs/8.json && ! -e $d/needs/8.json.tmp ]] \
  && node "$NM" open "$d" nf-seq proj given_up B list="$T/wt/proj/nf-parked-open/.harness/runs/nf-parked-open/feature_list.json" run=x > /dev/null \
  && [[ $(jq -r "[.feature, .milestone] | tostring" "$d/needs/8.json") == "[null,\"M2\"]" && $(jq -r "[.feature, .milestone, .run] | tostring" "$d/needs/9.json") == "[\"B\",\"M1\",\"nf-seq\"]" ]]'
check "needs open twice with one key: one file, seen 2, exit 0 then 3; id, at and ref kept, updated_at moved" \
  'd=$HARNESS_STATE/proj/nf-twice; mkdir -p "$d"; HARNESS_NOW=$BASE node "$NM" open "$d" nf-twice proj merge_conflict M1 milestone=M1 > "$T/o1"; a=$?
   cp "$d/needs/1.json" "$T/first.json"; HARNESS_NOW=$(( BASE + 60 )) node "$NM" open "$d" nf-twice proj merge_conflict M1 milestone=M1 > "$T/o2"; b=$?
   (( a == 0 && b == 3 )) && [[ $(cat "$T/o1") == nf-twice/1 && $(cat "$T/o2") == nf-twice/1 && $(ls "$d/needs" | paste -sd" ") == "1.json" ]] \
   && jq -e --slurpfile f "$T/first.json" ".seen == 2 and .id == \$f[0].id and .at == \$f[0].at and .ref == \$f[0].ref and .updated_at == \"2026-10-28T00:01:00.000Z\"" "$d/needs/1.json" > /dev/null'
check "needs open: an unknown reason or an empty subject exits 1 with needs.mjs: on stderr and writes nothing" \
  'd=$HARNESS_STATE/proj/nf-bad; mkdir -p "$d"; node "$NM" open "$d" nf-bad proj nope M1 2> "$T/bad.err"; a=$?; node "$NM" open "$d" nf-bad proj parked "" 2>> "$T/bad.err"; b=$?
   (( a == 1 && b == 1 )) && grep "^needs.mjs: " "$T/bad.err" > /dev/null && [[ -z $(ls "$d/needs" 2> /dev/null) ]]'
check "needs REASONS: kind, severity and priority for each of the 16 reasons, as the plan's table" \
  '[[ $(in_node "console.log(Object.entries(N.REASONS).map(([r, x]) => [r, x.kind, x.severity, x.priority].join(\":\")).join(\" \"))") == "parked:park:block:high given_up:blocked:block:high verify_thin:needs_michael:block:high verify_red:needs_michael:block:high verify_recheck:needs_michael:block:high merge_conflict:needs_michael:block:high merge_refused:needs_michael:block:high main_conflict:needs_michael:block:high base_conflict:needs_michael:block:high feature_list_edits:needs_michael:block:high initializer_failed:needs_michael:block:high driver_crash:needs_michael:block:high usage_limit:limit:warn: weekly_budget:limit:warn: overlap:needs_michael:warn: question:needs_michael:warn:" ]] \
  && bad=0 && for r in $REASONS; do jq -e --arg r "$r" ".reason == \$r and .severity == (if (\$r | test(\"usage|weekly|overlap\")) then \"warn\" else \"block\" end) and (.card.headline | length > 0) and (.title | startswith(\"[nf-\"))" "$HARNESS_STATE/proj/nf-$r-open/needs/1.json" > /dev/null || bad=1; done && (( ! bad ))'

# the sweep over every fixture run: each resolved one moves to done/ with its rule's words, each open one stays
for d in "$HARNESS_STATE"/proj/nf-*-open "$HARNESS_STATE"/proj/nf-*-resolved; do echo "$d"; done > "$T/dirs"
node "$NM" sweep $(cat "$T/dirs") > "$T/sweep1.out" 2> "$T/sweep1.err"; SW1=$?; node "$NM" sweep $(cat "$T/dirs") > "$T/sweep2.out"
why() { case $1 in parked) echo "feature unparked" ;; given_up) echo "attempts reset" ;; verify_*|base_conflict) echo "needs-M1 cleared" ;;
  merge_conflict) echo "conflict cleared" ;; merge_refused) echo "refusal cleared" ;; main_conflict) echo "main merged cleanly" ;;
  overlap) echo "run removed" ;; *) echo "run continued" ;; esac; }
check "needs sweep: each reason's resolved fixture is resolved by its rule (its words), every open one stays; a second sweep moves nothing" \
  '(( SW1 == 0 )) && [[ ! -s $T/sweep1.err && ! -s $T/sweep2.out ]] \
  && [[ $(sort "$T/sweep1.out") == $(for r in $REASONS; do echo "resolved nf-$r-resolved/1 ($(why "$r"))"; done | sort) ]] \
  && bad=0 && for r in $REASONS; do o=$HARNESS_STATE/proj/nf-$r-open s=$HARNESS_STATE/proj/nf-$r-resolved
       [[ -f $o/needs/1.json && ! -e $o/needs/done/1.json && ! -e $s/needs/1.json ]] || bad=1
       jq -e --arg w "$(why "$r")" ".resolved_by == \"sweep\" and .resolved_why == \$w and (.resolved_at | test(\"Z$\"))" "$s/needs/done/1.json" > /dev/null || bad=1; done && (( ! bad ))'
check "needs sweep (pure): passes, verified-<m> and merged-<m> resolve too; a re-base failure waits on needs-<m> while verified; a milestone driver_crash waits on needs-<m>; a conflict while needs-<m> stays" \
  'in_node "const it = (reason, sub) => N.record({ run: \"r\", project: \"p\", reason, subject: sub, seq: 1 }, 0);
    const st = o => ({ removed: false, ended: false, passing: [\"B\"], parked: {}, attempts: {}, max_attempts: 2, markers: [], ...o });
    const w = (i, s) => { const { keep, resolved } = N.sweep([i], s); return resolved.length ? resolved[0].resolved_why : (keep.length ? \"kept\" : \"?\"); };
    ok(w(it(\"parked\", \"B\"), st({ parked: { B: {} } })) === \"feature passes\" && w(it(\"given_up\", \"B\"), st({ attempts: { B: 5 } })) === \"feature passes\"
      && w(it(\"given_up\", \"C\"), st({ attempts: { C: 2 } })) === \"kept\" && w(it(\"given_up\", \"C\"), st({ attempts: { C: 1 } })) === \"attempts reset\"
      && w(it(\"verify_thin\", \"M1\"), st({ markers: [\"verified-M1\"] })) === \"milestone verified\"
      && w(it(\"verify_red\", \"M1\"), st({ markers: [\"needs-M1\", \"verified-M1\"] })) === \"kept\" && w(it(\"verify_red\", \"M1\"), st({ markers: [\"needs-M1\", \"merged-M1\"] })) === \"milestone merged\"
      && w(it(\"main_conflict\", \"M1\"), st({ markers: [\"main-conflict-M1\", \"merged-M1\"] })) === \"milestone merged\" && w(it(\"main_conflict\", \"record\"), st({ markers: [\"main-conflict-record\"] })) === \"kept\"
      && w(it(\"merge_refused\", \"M1\"), st({ markers: [\"refused-M1\", \"merged-M1\"] })) === \"milestone merged\"
      && w(it(\"merge_conflict\", \"M1\"), st({ markers: [\"needs-M1\"] })) === \"kept\" && w(it(\"merge_conflict\", \"M1\"), st({ markers: [\"conflict-M1\", \"merged-M1\"] })) === \"milestone merged\"
      && w(it(\"driver_crash\", \"M2\"), st({ ended: true, markers: [\"needs-M2\"] })) === \"kept\" && w(it(\"driver_crash\", \"M2\"), st({ ended: true })) === \"needs-M2 cleared\"
      && w(it(\"driver_crash\", \"run\"), st({ ended: true })) === \"kept\" && w(it(\"overlap\", \"x\"), st({ ended: true })) === \"kept\"
      && w(it(\"verify_red\", \"M1\"), st({ removed: true, markers: [\"needs-M1\"] })) === \"run removed\")"'

# run removed: worktree and branch both gone. While the branch is there the item stays; list hides a removed run read-only
needs_fixture verify_red open $BASE nf-gone; rm -rf "$T/wt/proj/nf-gone"; git -C "$T/proj" branch -q harness/nf-gone
check "needs: a run whose worktree and record branch are both gone resolves run removed (list hides it before any sweep); the branch alone keeps it" \
  'G=$HARNESS_STATE/proj/nf-gone; [[ -z $(node "$NM" sweep "$G") && $(node "$NM" list "$G" --json | jq length) == 1 ]] \
  && git -C "$T/proj" branch -q -D harness/nf-gone && [[ $(node "$NM" list "$G" --json | jq length) == 0 && -f $G/needs/1.json ]] \
  && [[ $(node "$NM" sweep "$G") == "resolved nf-gone/1 (run removed)" && -f $G/needs/done/1.json ]]'

# synthesized items: a SIGKILLed driver (dead driver.pid, no ended) and a parked.json entry without a record
needs_fixture usage_limit open $BASE nf-syn; S=$HARNESS_STATE/proj/nf-syn; rm -f "$S/ended"; sh -c 'echo $$' > "$S/driver.pid"
touch -d @$(( BASE - 3600 )) "$S/run.log"
echo '{"B":{"why":"the token\nplease","at":"2026-10-27T22:30:00.000Z"},"A":{"why":"passes now","at":"2026-10-27T22:00:00.000Z"}}' > "$S/parked.json"
check "needs list: a dead driver.pid with no ended is a synthesized driver_crash (ref <run>/crash, at run.log's mtime), parked.json's B a parked item; nothing stored" \
  'node "$NM" list "$S" --json > "$T/syn.json" && [[ $(jq -r "map(.ref) | join(\" \")" "$T/syn.json") == "nf-syn/parked:B nf-syn/crash nf-syn/1" ]] \
  && jq -e ".[1].reason == \"driver_crash\" and .[1].key == \"driver_crash:run\" and .[1].at == \"2026-10-27T23:00:00.000Z\" and .[0].key == \"parked:B\" and .[0].kind == \"park\" and .[0].feature == \"B\" and .[0].at == \"2026-10-27T22:30:00.000Z\"" "$T/syn.json" > /dev/null \
  && [[ $(ls "$S/needs" | paste -sd" ") == "1.json" ]]'
check "needs list: no synthesized item once a record is open for it (driver_crash:run, parked:B), nor with ended or a live driver" \
  'HARNESS_NOW=$BASE node "$NM" open "$S" nf-syn proj parked B feature=B > /dev/null && HARNESS_NOW=$BASE node "$NM" open "$S" nf-syn proj driver_crash run > /dev/null \
  && [[ $(node "$NM" list "$S" --json | jq -r "map(.ref) | join(\" \")") == "nf-syn/2 nf-syn/3 nf-syn/1" ]] \
  && in_node "const s = { run: \"r\", project: \"p\", removed: false, passing: [], parked: {}, log_mtime: 0 };
    ok(N.synthesize({ ...s, driver: \"dead\", ended: true }, []).length === 0 && N.synthesize({ ...s, driver: \"live\", ended: false }, []).length === 0
      && N.synthesize({ ...s, driver: \"dead\", ended: false }, []).length === 1 && N.synthesize({ ...s, driver: null, ended: false }, []).length === 0)"'

# harness needs over the fixture runs (the synthesized ones above included)
touch "$T/needs.stamp"; export HARNESS_GLYPHS=ascii
"$H" needs --json > "$T/n.json" 2> "$T/n.err"; NJ=$?; "$H" needs > "$T/n.txt"; "$H" needs --all --json > "$T/na.json"; "$H" needs nf-merge_refused-open > "$T/n1.txt"
EXP=$( { for r in $REASONS; do echo "$r"; done | head -12 | tac | sed "s|.*|nf-&-open/1|"; printf "%s\n" nf-syn/2 nf-syn/3 nf-overlap-open/1 nf-weekly_budget-open/1 nf-usage_limit-open/1 nf-syn/1; } | paste -sd" ")
check "harness needs --json: the open records, block before warn, oldest first; --all adds the 15 resolved ones" \
  '(( NJ == 0 )) && [[ ! -s $T/n.err ]] && [[ $(jq -r "map(.ref) | join(\" \")" "$T/n.json") == "$EXP" ]] \
  && [[ $(jq "map(select(.resolved_at == null)) | length" "$T/na.json") == $(jq length "$T/n.json") && $(jq "map(select(.resolved_by == \"sweep\")) | length" "$T/na.json") == 16 ]]'
check "harness needs: a card per item (<glyph> <run> · <headline> · since … · <ref>); with a run, that run's only; nothing open: NEEDS YOU 0, nothing needs you" \
  'grep -E "^! nf-merge_refused-open - M1: the merge was refused - since [0-9]{2}:[0-9]{2} \([0-9a-z]+\) - nf-merge_refused-open/1$" "$T/n.txt" > /dev/null \
  && [[ $(grep -c "^! " "$T/n.txt") == $(jq length "$T/n.json") && $(grep -c "^! " "$T/n1.txt") == 1 ]] && grep "^! nf-merge_refused-open - " "$T/n1.txt" > /dev/null \
  && [[ $("$H" needs nf-parked-resolved) == "NEEDS YOU 0"$'"'"'\n'"'"'"nothing needs you in nf-parked-resolved" && $("$H" needs nf-parked-resolved --all | grep -c "^! ") == 1 ]] \
  && rm -rf "$T/empty" && [[ $(HARNESS_STATE=$T/empty "$H" needs) == "NEEDS YOU 0"$'"'"'\n'"'"'"nothing needs you" && ! -e $T/empty ]]'
check "harness needs is read-only" '[[ -z $(find "$HARNESS_STATE" "$T/wt" -newer "$T/needs.stamp") ]]'
check "harness needs nope: exit 1, harness: on stderr; needs done with no ref is a usage error" \
  '"$H" needs nope > "$T/nope.out" 2> "$T/nope.err"; a=$?; "$H" needs done > /dev/null 2>&1; b=$?
   (( a == 1 && b != 0 )) && grep "^harness: " "$T/nope.err" > /dev/null && [[ ! -s $T/nope.out ]]'
check "harness needs done <ref>: resolved <ref>, the file in needs/done/ by michael (--why, else done by hand); a second done, a synthesized or unknown ref exit 1" \
  'D=$HARNESS_STATE/proj/nf-merge_refused-open; [[ $("$H" needs done nf-merge_refused-open/1 --why "merged on GitHub") == "resolved nf-merge_refused-open/1" ]] \
  && [[ ! -e $D/needs/1.json ]] && jq -e ".resolved_by == \"michael\" and .resolved_why == \"merged on GitHub\" and (.resolved_at | test(\"Z$\"))" "$D/needs/done/1.json" > /dev/null \
  && [[ $("$H" needs done nf-main_conflict-open/1) == "resolved nf-main_conflict-open/1" ]] && jq -e ".resolved_why == \"done by hand\"" "$HARNESS_STATE/proj/nf-main_conflict-open/needs/done/1.json" > /dev/null \
  && ! "$H" needs done nf-merge_refused-open/1 2> /dev/null && ! "$H" needs done nf-parked-open/9 2> /dev/null \
  && rm "$S/needs/3.json" && ! "$H" needs done nf-syn/crash 2> "$T/syn.err" && grep "^harness: nf-syn/crash is derived from the run.s state; it resolves when" "$T/syn.err" > /dev/null'

suite_end
