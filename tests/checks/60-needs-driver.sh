#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the session-side stop paths open needs records (U2-05): a park, a given-up feature, a finish reason, a driver
# that crashed; needs.md on the record branch is the park notification's click; sweeps resolve them ----
# Plan: docs/plans/2026-10-28-U2-needs-record.md §2.1, §2.3, §3.2, §4.2. Stub runs end to end.
nj() { jq -s "${2:-.}" "$HARNESS_STATE/proj/$1"/needs/*.json 2> /dev/null; }   # <run> [<jq over its open items>]
export COLUMNS=200 HARNESS_GLYPHS=unicode   # the views' whole lines

# a park: B asks in INBOX.md and parks; C (M2) goes on; the run ends waiting on Michael
STUB_PARK=B STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" pk --spec SPEC.md --foreground > "$T/pk.out" 2>&1
PREC=$T/wt/proj/pk/.harness/runs/pk PL=$(grep -n "^### B: set the gatus vars, then answer$" "$T/wt/proj/pk/.harness/runs/pk/INBOX.md" | cut -d: -f1)
check "a park opens one parked record; card.question.line is the first line the session added, its URL that line" \
  '[[ $(nj pk "map(select(.reason == \"parked\")) | length") == 1 && -n $PL ]] && P=$(nj pk ".[] | select(.reason == \"parked\")") \
  && [[ $(jq -r "[.key, .kind, .severity, .priority, .feature, .card.question.line] | join(\" \")" <<< "$P") == "parked:B park block high B $PL" ]] \
  && [[ $(jq -r .card.question.url <<< "$P") == "$GHP/blob/harness/pk/.harness/runs/pk/INBOX.md?plain=1#L$PL" ]] \
  && jq -r .card.question.text <<< "$P" | grep -qx "### B: set the gatus vars, then answer"'
BB=$(curl_body "Title: [pk] B needs you") BH=$(curl_with "Title: [pk] B needs you")
cmds_in() { local c; while IFS= read -r c; do [[ -z $c ]] || grep -qF -- "$c" <<< "$BB" || return 1; done < <(nj pk '.[] | select(.reason == "parked") | .card.commands[]' | jq -r .); }
check "the park notification is the record's: body PARKED: first, the question, the card's do commands, the answer line; Click needs.md" \
  '[[ $(head -1 <<< "$BB") == "PARKED: set the gatus vars" ]] && grep -qx "### B: set the gatus vars, then answer" <<< "$BB" && cmds_in \
  && [[ $(nj pk "[.[] | select(.reason == \"parked\") | .card.commands | length] | first >= 1") == true ]] && grep -q "^Answer: harness answer pk \"" <<< "$BB" \
  && grep -qx "Click: $GHP/blob/harness/pk/.harness/runs/pk/needs.md" <<< "$BH" && grep -qx "Priority: high" <<< "$BH" \
  && [[ $(nj pk ".[] | select(.reason == \"parked\") | .click") == "\"$GHP/blob/harness/pk/.harness/runs/pk/needs.md\"" ]] \
  && [[ $(nj pk ".[] | select(.reason == \"parked\") | .body" | jq -r .) == "$BB" ]]'
check "needs.md is committed on the record branch before the park goes out, and lists the park" \
  'git -C "$T/origin.git" show "$(git -C "$T/origin.git" log -1 --format=%H --grep="^HARNESS: after B (passes=false)" harness/pk):.harness/runs/pk/needs.md" | grep -q "^## .*B parked" \
  && [[ -z $(git -C "$T/wt/proj/pk" status --porcelain) ]]'

# a give-up: A never passes (one attempt); B and C wait on it; the run ends blocked on A, nothing parked
{ cat "$T/base-config.sh"; echo MAX_ATTEMPTS=1; } > "$T/user-config.sh"
STUB_GIVE_UP=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" gu --spec SPEC.md --foreground > "$T/gu.out" 2>&1
GS=$HARNESS_STATE/proj/gu; "$H" needs gu > "$T/gu-needs.out" 2>&1; "$H" parked gu > "$T/gu-parked.out" 2>&1
check "a given-up feature opens given_up naming what waits on it; harness needs and harness parked list it while parked.json is empty" \
  'G=$(nj gu ".[] | select(.key == \"given_up:A\")"); [[ -n $G && $(jq -r "[.kind, .severity, .priority, .feature] | join(\" \")" <<< "$G") == "blocked block high A" ]] \
  && jq -r .card.blocked <<< "$G" | grep -qF "A (a); 2 features wait in M1, M2" && grep -q "^blocked on A" "$GS/ended" && [[ $(jq length "$GS/parked.json" 2> /dev/null || echo 0) == 0 ]] \
  && grep -q "gu · A given up after 1 attempt " "$T/gu-needs.out" && grep -q "gu · A given up after 1 attempt " "$T/gu-parked.out" \
  && grep -qx "Title: \[gu\] ended: blocked on A" <<< "$(curl_with "Title: [gu] ended")"'
GREF=$(nj gu '.[] | select(.key == "given_up:A") | .ref' | jq -r .)
STUB_GIVE_UP=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue gu --foreground > "$T/gu2.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "harness continue resolves the given_up item (fresh attempts): moved to needs/done/ by the sweep, noted" \
  'D=$GS/needs/done/${GREF#gu/}.json; [[ -n $GREF && -f $D && ! -e $GS/needs/${GREF#gu/}.json ]] \
  && [[ $(jq -r "[.resolved_by, .resolved_why] | join(\" \")" "$D") == "sweep attempts reset" ]] && hlog gu | grep -q "needs: resolved $GREF (attempts reset)"'

# a finish reason: the initializer refused by the usage limit
STUB_INIT_LIMIT=1 "$H" start "$T/proj" il --spec SPEC.md --foreground > "$T/il.out" 2>&1; rm -f "$HARNESS_STATE/LIMIT_UNTIL"
check "finish opens usage_limit (limit, warn, no priority) for a usage-limit end; needs.md committed; the run-end title kept" \
  'U=$(nj il ".[] | select(.key == \"usage_limit:run\")"); [[ $(jq -r "[.kind, .severity, .priority, .title] | join(\"|\")" <<< "$U") == "limit|warn||[il] ended: usage limit before the feature list" ]] \
  && git -C "$T/origin.git" show harness/il:.harness/runs/il/needs.md | grep -q "ended on the usage limit" \
  && grep -qx "Title: \[il\] ended: usage limit before the feature list" <<< "$(curl_with "Title: [il] ended")"'

# a TERM mid-session: the EXIT trap ends it with its default reason and records driver_crash; harness needs done resolves it
rm -f "$T/slow-coding"
STUB_SLOW_CODING=30 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" tm --spec SPEC.md --foreground > "$T/tm.out" 2>&1 & TP=$!
for _ in $(seq 300); do [[ -e $T/slow-coding ]] && break; sleep 0.1; done
kill -TERM "$(cat "$HARNESS_STATE/proj/tm/driver.pid")"; wait "$TP"
TS=$HARNESS_STATE/proj/tm TREF=$(nj tm '.[] | select(.key == "driver_crash:run") | .ref' | jq -r .)
"$H" needs tm > "$T/tm-needs.out" 2>&1
check "the EXIT trap of a driver ended unexpectedly opens driver_crash (stored, no synthesized one); its needs.md committed" \
  '[[ -n $TREF && $TREF != tm/crash ]] && grep -q "^driver exited unexpectedly" "$TS/ended" && grep -q "tm · the driver stopped without an end" "$T/tm-needs.out" \
  && grep -qF "$TREF" "$T/tm-needs.out" && ! grep -q "tm/crash" "$T/tm-needs.out" && [[ -z $(git -C "$T/wt/proj/tm" status --porcelain -- .harness/runs/tm/needs.md) ]]'
"$H" needs done "$TREF" > "$T/tm-done.out" 2>&1; TD=$?
check "harness needs done <ref> moves the item to needs/done/, resolved by michael" \
  '(( TD == 0 )) && [[ $(cat "$T/tm-done.out") == "resolved $TREF" && -f $TS/needs/done/${TREF#tm/}.json && ! -e $TS/needs/${TREF#tm/}.json ]] \
  && [[ $(jq -r "[.resolved_by, .resolved_why] | join(\" \")" "$TS/needs/done/${TREF#tm/}.json") == "michael done by hand" ]]'

# a SIGKILL mid-session: no trap runs (no ended, driver.pid names no process); its lane is TERMed after it
rm -f "$T/slow-coding"
STUB_SLOW_CODING=30 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" sk --spec SPEC.md --foreground > "$T/sk.out" 2>&1 & TP=$!
for _ in $(seq 300); do [[ -e $T/slow-coding ]] && break; sleep 0.1; done
kill -KILL "$(cat "$HARNESS_STATE/proj/sk/driver.pid")"; wait "$TP" 2> /dev/null
for f in "$HARNESS_STATE"/proj/sk/lanes/*/pid; do p=$(cat "$f" 2> /dev/null) && kill -TERM "$p" 2> /dev/null; for _ in $(seq 100); do kill -0 "$p" 2> /dev/null || break; sleep 0.1; done; done
"$H" needs sk > "$T/sk-needs.out" 2>&1
check "a SIGKILLed driver shows a synthesized driver_crash in harness needs" \
  '[[ ! -e $HARNESS_STATE/proj/sk/ended ]] && grep -q "sk · the driver stopped without an end" "$T/sk-needs.out" && grep -q "sk/crash" "$T/sk-needs.out"'
suite_end
