#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- questions wait in harness needs until answered (R4): lib/needs.mjs's question reason, its key, refresh, the move
# ---- forward to a later run of the project, its card, done --why and the sweep's answered-in-a-later-entry rule ----
# Plan: docs/plans/2026-10-29-R4-questions.md §2, §5. needs_fixture question (tests/lib.sh) opens A's question of line 1
# of its record's entries.jsonl; NF_Q gives another text, so fixtures of one project don't move each other's forward.
export TZ=UTC COLUMNS=200 HARNESS_GLYPHS=unicode
NM=$HERE/../lib/needs.mjs BASE=1793145600 P=$HARNESS_STATE/proj
IMP="import * as N from \"$NM\"; const ok = c => process.exit(c ? 0 : 1);"
in_node() { node --input-type=module -e "$IMP $1" "${@:2}"; }
Q='Should A keep the old cache? (default: kept) Files: /srv/q/lib/a.sh:12'

check "needs questions: questionKey folds whitespace, lower-cases, drops the harness's fill and a Files: line, cuts at 80" \
  'in_node "ok(N.questionKey(\"  Should  A\n default\tto OFF?  \") === \"should a default to off?\"
    && N.questionKey(\"Should A default to off? Files (harness, from the session): /w/run-1/lib/a.sh\") === \"should a default to off?\"
    && N.questionKey(\"Should A?\n**Files:** /x/a.sh:3, /x/b.sh\") === \"should a?\" && N.questionKey(\"Should A?\nFiles: /x/a.sh\n\n\") === \"should a?\" && N.questionKey(\"Should A? Files: /x/a.sh\") === \"should a? files: /x/a.sh\" && N.questionKey(\"Q? (default: x)\nFiles: /w/run-1/a.sh\nBranch: harness/run-1\") === \"q? (default: x) branch: harness/run-1\"
    && N.questionKey(\"X\".repeat(100)) === \"x\".repeat(80) && [...N.questionKey(\"é\".repeat(100))].length === 80 && N.questionKey(\" \n \") === \"\")"'

needs_fixture question open "$BASE" q-one
needs_fixture parked open "$(( BASE + 60 ))" q-park   # a block item, and a reason without asked_in
check "needs questions: open makes one warn item, key question:<the key>, no priority, seen 1, asked_in its run" \
  'jq -e --arg k "question:$(in_node "console.log(N.questionKey(process.argv[1]))" "$Q")" ".reason == \"question\" and .kind == \"needs_michael\" and .severity == \"warn\"
    and .priority == \"\" and .key == \$k and .seen == 1 and .asked_in == [\"q-one\"] and .feature == \"A\" and .title == \"[q-one] question from A\"
    and .card.question.text == \"$Q\" and .card.question.line == 1" "$P/q-one/needs/1.json" > /dev/null \
  && [[ $(in_node "console.log(N.REASONS.question.kind, N.REASONS.question.severity, JSON.stringify(N.REASONS.question.priority))") == "needs_michael warn \"\"" ]] \
  && jq -e "has(\"asked_in\") | not" "$P/q-park/needs/1.json" > /dev/null'
check "needs questions: the same text again in the run exits 3, one item, seen 2, a later updated_at" \
  'rec=$T/wt/proj/q-one/.harness/runs/q-one; HARNESS_NOW=$(( BASE + 60 )) node "$NM" open "$P/q-one" q-one proj question "Should  A keep the old cache?
(default: kept) Files: /srv/q/lib/a.sh:12" asker=A feature=A line=2 record="$rec" > "$T/again.out"; rc=$?
   (( rc == 3 )) && [[ $(cat "$T/again.out") == q-one/1 && $(ls "$P/q-one/needs" | paste -sd" ") == "1.json" ]] \
   && jq -e ".seen == 2 and .updated_at == \"2026-10-28T00:01:00.000Z\" and .at == \"2026-10-28T00:00:00.000Z\" and .card.question.line == 2 and .asked_in == [\"q-one\"]" "$P/q-one/needs/1.json" > /dev/null'

NF_Q="Should A drop the v1 table? (default: dropped)" needs_fixture question open "$BASE" q-a
check "needs questions: asked in a later run of the project, the item moves forward (seen +1, asked_in both, the old in its done/ as asked again in <run>)" \
  'jq ".seen = 2" "$P/q-a/needs/1.json" > "$T/s2" && mv "$T/s2" "$P/q-a/needs/1.json" \
  && mkdir -p "$P/q-b" && printf "PROJECT_DIR=%q\nWT=/x\nRUN_ID=q-b\nSTATE=%q\n" "$T/proj" "$P/q-b" > "$P/q-b/meta.env" \
  && HARNESS_NOW=$(( BASE + 120 )) node "$NM" open "$P/q-b" q-b proj question "Should A drop the v1 table? (default: dropped)" asker=A feature=A line=4 > "$T/mf.out" \
  && [[ $(cat "$T/mf.out") == q-b/1 && ! -e $P/q-a/needs/1.json && $(ls "$P/q-b/needs" | paste -sd" ") == "1.json" && -f $P/q-one/needs/1.json ]] \
  && jq -e ".seen == 3 and .asked_in == [\"q-a\", \"q-b\"] and .run == \"q-b\" and .resolved_at == null" "$P/q-b/needs/1.json" > /dev/null \
  && jq -e ".resolved_why == \"asked again in q-b\" and .resolved_by == \"sweep\" and .resolved_at == \"2026-10-28T00:02:00.000Z\" and .run == \"q-a\"" "$P/q-a/needs/done/1.json" > /dev/null \
  && in_node "const { item, resolved } = N.moveForward([{ run: \"r1\", seen: 2, asked_in: [\"r0\", \"r1\"], ref: \"r1/3\" }, { run: \"r2\", seen: 1, ref: \"r2/1\" }], { seen: 1, asked_in: [\"r3\"] }, \"r3\", 0);
    ok(item.seen === 3 && item.asked_in.join() === \"r0,r1,r2,r3\" && resolved.length === 2 && resolved.every(r => r.resolved_why === \"asked again in r3\" && r.resolved_by === \"sweep\"))"'

NF_Q="Should A log at debug? (default: info)
Files: /srv/q/lib/a.sh:12, /srv/q/lib/b.sh" needs_fixture question open "$BASE" q-list
check "needs questions: list shows the question card after a block card, its text, a where row per Files: path and the entries.jsonl line" \
  'HARNESS_NOW=$(( BASE + 600 )) node "$NM" list "$P/q-list" "$P/q-park" > "$T/list.out" \
  && p=$(grep -n "q-park · B parked" "$T/list.out" | cut -d: -f1) && q=$(grep -n "q-list · A asked: Should A log at debug? (default: info)" "$T/list.out" | cut -d: -f1) \
  && (( p > 0 && q > p )) && sed -n "$q,\$p" "$T/list.out" > "$T/qcard" \
  && grep -x "  blocked    nothing waits on it; A.s session took the default its question names" "$T/qcard" > /dev/null \
  && grep -x "  question   Should A log at debug? (default: info)" "$T/qcard" > /dev/null && grep -x "             Files: /srv/q/lib/a.sh:12, /srv/q/lib/b.sh" "$T/qcard" > /dev/null \
  && grep -x "  where      /srv/q/lib/a.sh:12" "$T/qcard" > /dev/null && grep -x "             /srv/q/lib/b.sh" "$T/qcard" > /dev/null \
  && grep -xF "             $T/wt/proj/q-list/.harness/runs/q-list/entries.jsonl:1 (entry)" "$T/qcard" > /dev/null \
  && grep -x "  do         harness needs done q-list/1 --why \"<answer>\"" "$T/qcard" > /dev/null'
check "needs questions: done --why resolves a question with that why" \
  'HARNESS_NOW=$(( BASE + 900 )) node "$NM" done "$P/q-list" q-list/1 --why "info stays" > "$T/done.out" && [[ $(cat "$T/done.out") == "resolved q-list/1" && ! -e $P/q-list/needs/1.json ]] \
  && jq -e ".resolved_by == \"michael\" and .resolved_why == \"info stays\" and .reason == \"question\"" "$P/q-list/needs/done/1.json" > /dev/null'

NF_Q="Should A pin node 20? (default: pinned)" needs_fixture question resolved "$BASE" q-swept
NF_Q="Should A gzip the logs? (default: no)" needs_fixture question resolved "$BASE" q-asked-after
check "needs questions: a later entry's resolved resolves it at the sweep (answered in <feature>'s entry), an earlier one doesn't" \
  'r=$T/wt/proj/q-asked-after/.harness/runs/q-asked-after; head -1 "$r/entries.jsonl" >> "$r/entries.jsonl" \
  && node "$NM" open "$P/q-asked-after" q-asked-after proj question "Should A gzip the logs? (default: no)" asker=A feature=A line=3 record="$r" > /dev/null; (( $? == 3 )) \
  && node "$NM" sweep "$P/q-swept" "$P/q-asked-after" > "$T/sweep.out" && [[ $(cat "$T/sweep.out") == "resolved q-swept/1 (answered in B'"'"'s entry)" ]] \
  && jq -e ".resolved_why == \"answered in B'"'"'s entry\" and .resolved_by == \"sweep\"" "$P/q-swept/needs/done/1.json" > /dev/null \
  && [[ -f $P/q-asked-after/needs/1.json && ! -e $P/q-asked-after/needs/done/1.json ]] \
  && NF_Q="Should A cap the queue? (default: 9)" needs_fixture question resolved "$BASE" q-no-line && d=$P/q-no-line/needs/1.json \
  && jq ".card.question.line = null" "$d" > "$T/nl" && mv "$T/nl" "$d" && node "$NM" sweep "$P/q-no-line" > "$T/nl.out" && [[ ! -s $T/nl.out && -f $d ]]'

# ---- R4-03: journal_ opens one question item per question of the entry it ingests (plan §3); stub runs ----
nj() { jq -s "${2:-.}" "$P/$1"/needs/*.json 2> /dev/null; }   # <run> [<jq over its open items>]
FAST=(STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1)   # one coding session per feature
main0=$(git -C "$T/origin.git" rev-parse main)
rm -rf "$P"/q-* "$T"/wt/proj/q-*   # the fixtures above are runs of proj too: an open one of the same text would move forward
env "${FAST[@]}" STUB_ASK_TWO=A "$H" start "$T/proj" qa --spec SPEC.md --foreground > "$T/qa.out" 2>&1
check "needs questions: an entry with two questions opens two question items with their Files:, noted" \
  '[[ $(nj qa "[.[] | select(.reason == \"question\")] | length") == 2 ]] \
  && [[ $(nj qa "[.[] | select(.reason == \"question\") | .card.where[0].path] | sort | join(\" \")" | jq -r .) == "/srv/q/lib/a.sh /srv/q/lib/b.sh" ]] \
  && [[ $(nj qa "[.[] | select(.reason == \"question\") | .feature + \" \" + (.card.question.line | tostring)] | unique | join(\",\")" | jq -r .) =~ ^"A "[0-9]+$ ]] \
  && hlog qa | grep -F "A: 2 question(s) for Michael recorded (harness needs)" > /dev/null'
check "needs questions: harness needs prints both question cards" \
  '"$H" needs qa > "$T/qa-needs.out" 2>&1 && [[ $(grep -c " · A asked: Should A " "$T/qa-needs.out") == 2 ]] \
  && grep -F "A asked: Should A keep the old cache?" "$T/qa-needs.out" > /dev/null && grep -F "A asked: Should A log at debug?" "$T/qa-needs.out" > /dev/null'

# A asks, B asks the same again (one item, seen 2), A's second session (M1's verify un-passes A) lists it in resolved
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_ASK=A STUB_ASK_AGAIN=B STUB_RESOLVE=A "$H" start "$T/proj" qr --spec SPEC.md --foreground > "$T/qr.out" 2>&1
check "needs questions: the same question in a later session is one item, seen 2" \
  '[[ $(jq -s "[.[] | select(.reason == \"question\")] | length" "$P/qr"/needs/*.json "$P/qr"/needs/done/*.json 2> /dev/null) == 1 ]] \
  && jq -s -e "[.[] | select(.reason == \"question\")][0] | .seen == 2 and .asked_in == [\"qr\"] and .key == \"question:should a default to off?\"" "$P/qr"/needs/done/*.json > /dev/null \
  && hlog qr | grep -F "B: 1 question(s) for Michael recorded (harness needs)" > /dev/null'
check "needs questions: a later entry's resolved closes it by the run's end" \
  '[[ -z $(nj qr "[.[] | select(.reason == \"question\")] | .[]") ]] \
  && jq -s -e "[.[] | select(.reason == \"question\")][0] | .resolved_by == \"sweep\" and .resolved_why == \"answered in A'"'"'s entry\"" "$P/qr"/needs/done/*.json > /dev/null'

# two runs of the project ask A's question: the second moves the first's open item forward
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
env "${FAST[@]}" STUB_ASK=A "$H" start "$T/proj" qm1 --spec SPEC.md --foreground > "$T/qm1.out" 2>&1
tended "$P/qm1"; git -C "$T/origin.git" update-ref refs/heads/main "$main0"
env "${FAST[@]}" STUB_ASK=A "$H" start "$T/proj" qm2 --spec SPEC.md --foreground > "$T/qm2.out" 2>&1
check "needs questions: a second run's ask moves the first run's open item forward" \
  '[[ -z $(nj qm1 "[.[] | select(.reason == \"question\")] | .[]") ]] \
  && [[ $(nj qm2 "[.[] | select(.reason == \"question\")] | length") == 1 ]] \
  && nj qm2 "[.[] | select(.reason == \"question\")][0] | .seen == 2 and .asked_in == [\"qm1\", \"qm2\"] and .run == \"qm2\"" | jq -e . > /dev/null \
  && jq -s -e "[.[] | select(.reason == \"question\")] | length == 1 and .[0].resolved_why == \"asked again in qm2\"" "$P/qm1"/needs/done/*.json > /dev/null'

suite_end
