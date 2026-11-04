#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- a merge that meets a GitHub outage (M1 of docs/specs/2026-11-04-run-resilience.md): origin_try's bounded
# retries in lib/record.sh, the outage stubs (tests/stub-git-down.sh, stub-gh's STUB_GH_DOWN), the refusal never retried ----
export COLUMNS=200 HARNESS_GLYPHS=unicode HARNESS_ORIGIN_WAITS="0 0 0"   # four tries per step, no wait between them
main0=$(git -C "$T/origin.git" rev-parse main)   # each run starts from it (one origin for the file's runs)
nkey() { cat "$HARNESS_STATE/proj/$1"/needs/*.json 2> /dev/null | jq -se --arg k "$2" 'any(.[]; .key == $k)' > /dev/null; }   # <run> <key>: an open item
DOWN=$T/down; mkdir -p "$DOWN" && ln -s "$HERE/stub-git-down.sh" "$DOWN/git"   # first on PATH for a run: the outage stub

# the outage stub alone, in a clone of the file's origin
C=$T/clone; git clone -q "$T/origin.git" "$C" 2> /dev/null
cg() { git -C "$C" -c user.name=t -c user.email=t@t "$@"; }
cg checkout -q -b down-probe; echo probe > "$C/probe"; cg add probe; cg commit -qm probe
echo 2 > "$T/origin-down"
for k in 1 2 3; do PATH=$DOWN:$PATH git -C "$C" push -q origin down-probe > "$T/push-$k.out" 2> "$T/push-$k.err"; echo $? > "$T/push-$k.rc"; done
check "stub-git-down: a count of 2 fails the first two pushes with the fixture's lines (ref and url in), the third reaches origin.git" \
  '[[ $(cat "$T"/push-{1,2,3}.rc | paste -sd" ") == "1 1 0" && ! -e $T/origin-down ]] \
  && [[ $(cat "$T/push-1.err") == " ! [remote rejected] down-probe -> down-probe (failure)"$'"'"'\n'"'"'"error: failed to push some refs to '"'"'$T/origin.git'"'"'" ]] \
  && cmp -s "$T/push-1.err" "$T/push-2.err" && [[ ! -s $T/push-3.err ]] \
  && [[ $(git -C "$T/origin.git" rev-parse down-probe) == $(cg rev-parse HEAD) ]]'
echo "until $(( $(date +%s) + 600 ))" > "$T/origin-down"
PATH=$DOWN:$PATH git -C "$C" fetch -q origin main > "$T/fetch.out" 2>&1; FR=$?
PATH=$DOWN:$PATH git -C "$C" log -1 --format=%s > /dev/null 2>&1; LR=$?
STUB_GIT_DOWN_ONLY='^push ' PATH=$DOWN:$PATH git -C "$C" fetch -q origin main > /dev/null 2>&1; OR=$?
check "stub-git-down: until <epoch> fails a fetch with exit 128 and no line; other commands and unmatched calls run the real git" \
  '(( FR == 128 && LR == 0 && OR == 0 )) && [[ ! -s $T/fetch.out && -f $T/origin-down ]]'
rm -f "$T/origin-down"; git -C "$T/origin.git" update-ref -d refs/heads/down-probe

# stub-gh: STUB_GH_DOWN=<n> fails the first <n> of each of pr view, pr create and pr merge with a real gh's line
for k in 1 2 3; do STUB_GH_DOWN=2 "$HERE/stub-gh.sh" pr create --base main --head gh-probe --title t > "$T/ghc-$k.out" 2> "$T/ghc-$k.err"; echo $? > "$T/ghc-$k.rc"; done
check "stub-gh: STUB_GH_DOWN=2 fails two pr creates with fixtures/gh-down.txt (a real gh's), the third opens the PR" \
  '[[ $(cat "$T"/ghc-{1,2,3}.rc | paste -sd" ") == "1 1 0" ]] && cmp -s "$T/ghc-1.err" "$HERE/fixtures/gh-down.txt" \
  && grep -qx "Post \"https://localhost:1/api/graphql\": dial tcp \[::1\]:1: connect: connection refused" "$HERE/fixtures/gh-down.txt" \
  && [[ $(cat "$T/ghc-3.out") == https://example.test/pr/* ]]'
rm -rf "$T/prs" "$T"/gh-down-*; : > "$T/gh.log"

# origin_try in a plain shell: the waits from HARNESS_ORIGIN_WAITS, each failed try a run.log line, a success after a
# failure one note, a refusal (GraphQL:, a pre-receive hook) one try
ot() { ( HARNESS_HOME=$HH; source "$HH/lib/record.sh"; STATE=$T/ot; rm -rf "$STATE"; mkdir -p "$STATE"
  note() { echo "$*" >> "$STATE/notes"; log "$*" > /dev/null; }
  flaky() { local n; n=$(( $(cat "$STATE/n" 2> /dev/null || echo 0) + 1 )); echo "$n" > "$STATE/n"; (( n > $1 )) && return 0; cat "$HERE/fixtures/gh-down.txt" >&2; return 1; }
  "$@" > /dev/null; echo "rc=$? tries=${ORIGIN_TRIES:-} secs=${ORIGIN_SECS:-} calls=$(cat "$STATE/n" 2> /dev/null)" ) }
OT1=$(ot origin_try M1 "fetch of main" flaky 2)
check "origin_try: a command failing twice then passing returns 0, two failed-try lines in run.log, one succeeded note" \
  '[[ $OT1 == "rc=0 "*"calls=3" ]] && [[ $(grep -cE "^[0-9-]+ [0-9:]+ M1: fetch of main failed \(try [12] of 4; next in 0 s\)$" "$T/ot/run.log") == 2 ]] \
  && [[ $(grep -c "connection refused" "$T/ot/run.log") == 2 ]] \
  && grep -qxE "M1: fetch of main succeeded on try 3 \(origin unreachable for [0-9]+ s\)" "$T/ot/notes" && [[ $(wc -l < "$T/ot/notes") == 1 ]]'
OT2=$(ot origin_try M1 "push of tag run/r/M1" flaky 9)
check "origin_try: a command failing every try returns its exit after four tries, ORIGIN_TRIES=4 and ORIGIN_SECS set, no note" \
  '[[ $OT2 =~ ^rc=1\ tries=4\ secs=[0-9]+\ calls=4$ ]] && [[ $(grep -c "M1: push of tag run/r/M1 failed (try [123] of 4; next in 0 s)" "$T/ot/run.log") == 3 ]] \
  && ! grep -q "try 4 of 4" "$T/ot/run.log" && [[ ! -e $T/ot/notes ]]'
refuse() { echo x >> "$STATE/n"; echo "GraphQL: Head branch was modified. Review and try the merge again. (mergePullRequest)" >&2; return 1; }
hook() { echo x >> "$STATE/n"; printf '%s\n' " ! [remote rejected] main -> main (pre-receive hook declined)" "error: failed to push some refs to 'o.git'" >&2; return 1; }
OT3=$(ot origin_try M1 "merging its PR" refuse) OT3H=$(ot origin_try M1 "push of harness-merge/r-M1" hook)
check "origin_try: a GraphQL: refusal or a pre-receive hook's decline is one try, its line in run.log, no failed-try line" \
  '[[ $OT3 =~ ^rc=1\ tries=1\  && $OT3H =~ ^rc=1\ tries=1\  ]] && grep -q "(pre-receive hook declined)" "$T/ot/run.log" && ! grep -q "failed (try" "$T/ot/run.log"'

# od1: origin down for three fetches of main from the end of M1's verify session: the lane's merge retries and merges
STUB_ORIGIN_DOWN=M1:3 STUB_GIT_DOWN_ONLY='^fetch -q origin main$' PATH=$DOWN:$PATH STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 \
  "$H" start "$T/proj" od1 --spec SPEC.md --foreground > "$T/od1.out" 2>&1
check "od1: origin down for three fetches at the lane's merge: three failed tries, succeeded on try 4, M1 merged, no needs post" \
  'hlog od1 | grep -qE "· M1: fetch of main succeeded on try 4 \(origin unreachable for [0-9]+ s\)$" && hlog od1 | grep -q "· M1 merged into main" \
  && [[ $(grep -c "M1: fetch of main failed (try [123] of 4; next in 0 s)" "$HARNESS_STATE/proj/od1/run.log") == 3 ]] \
  && on_main run/od1/M1 && [[ ! -e $T/origin-down ]] && ! nkey od1 merge_failed:M1 \
  && [[ $(curl_count "Title: [od1] M1 needs you") == 0 ]]'

# od6: GitHub down for two of each pr call: opening the PR and merging it succeed on their third try
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
STUB_GH_DOWN=2 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" od6 --spec SPEC.md --foreground > "$T/od6.out" 2>&1
check "od6: gh down twice at pr create and pr merge: opening its PR and merging it succeed on try 3, M1 merged" \
  'hlog od6 | grep -qE "· M1: opening its PR succeeded on try 3 \(origin unreachable for [0-9]+ s\)$" \
  && hlog od6 | grep -qE "· M1: merging its PR succeeded on try 3 " && hlog od6 | grep -q "· M1 merged into main" && on_main run/od6/M1 \
  && [[ $(grep -c "M1: opening its PR failed (try [12] of 4; next in 0 s)" "$HARNESS_STATE/proj/od6/run.log") == 2 ]] \
  && grep -qF "connect: connection refused" "$HARNESS_STATE/proj/od6/run.log"'

# a refusal is not an outage: GitHub's GraphQL line ends the step at once, the merge_refused card as before
git -C "$T/origin.git" update-ref refs/heads/main "$main0"; rm -f "$T"/gh-down-*; G0=$(grep -c . "$T/gh.log")
STUB_REFUSE_MERGE=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" odr --spec SPEC.md --foreground > "$T/odr.out" 2>&1
# each merge of M1 (the lane's, the run end's) is one pr view of its head, then one pr merge: never four
check "a refused merge is one gh pr merge per merge, its GraphQL line in run.log, merge_refused:M1 opened, no retry line" \
  'tail -n +$(( G0 + 1 )) "$T/gh.log" > "$T/odr-gh.log"; GM=$(grep -c "^gh pr merge " "$T/odr-gh.log") \
  && (( GM >= 1 )) && [[ $GM == $(grep -c "^gh pr view harness-merge/odr-M1 " "$T/odr-gh.log") ]] \
  && grep -qxF "GraphQL: Head branch was modified. Review and try the merge again. (mergePullRequest)" "$HARNESS_STATE/proj/odr/run.log" \
  && nkey odr merge_refused:M1 && ! grep -q "merging its PR failed (try" "$HARNESS_STATE/proj/odr/run.log"'

suite_end
