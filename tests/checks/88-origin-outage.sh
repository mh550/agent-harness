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
check "a refused lane closes merge refused, on the card it opened" 'hlog odr | grep -qF "lane M1 closed (M1 needs Michael: merge refused)"'

# ---- past the retries: a note, a card, a notification; the tag's two notes; the push streaks (M1-02) ----
ni() { jq -s -r ".[] | select(.key == \"$2\") | ${3:-.}" "$HARNESS_STATE/proj/$1"/needs/*.json 2> /dev/null; }   # <run> <key> <jq>: an open item's field
ndone() { jq -s -r ".[] | select(.key == \"$2\") | ${3:-.}" "$HARNESS_STATE/proj/$1"/needs/done/*.json 2> /dev/null; }   # the same, resolved
# how many stub-curl posts hold every one of the given strings
posts() { awk 'BEGIN { RS = "===\n"; split(ARGV[1], k, "\t"); ARGV[1] = "" } { for (i in k) if (!index($0, k[i])) next; n++ } END { print n + 0 }' "$(IFS=$'\t'; echo "$*")" "$T/curl.log"; }
fresh() { git -C "$T/origin.git" update-ref refs/heads/main "$main0"; rm -f "$T"/gh-down-*; }   # the next run starts from main0, gh's counts at 0
srun() { local r=$1; shift; env STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$@" "$H" start "$T/proj" "$r" --spec SPEC.md --foreground > "$T/$r.out" 2>&1; }   # <run> [VAR=value…]: a stub run

# od2: origin down from M1's verify session's end until after the run's end
fresh; srun od2 STUB_ORIGIN_DOWN="M1:until $(( $(date +%s) + 3600 ))" PATH="$DOWN:$PATH"
OD2=$HARNESS_STATE/proj/od2
check "od2: a tag push past the retries is noted local only, its rejected line in run.log, never verified and tagged" \
  'hlog od2 | grep -qE "· M1 verified; tag run/od2/M1 is local only \(push failed 4 times over [0-9]+ s; see run.log\)$" \
  && ! hlog od2 | grep -q "M1 verified and tagged" && grep -qxF " ! [remote rejected] run/od2/M1 -> run/od2/M1 (failure)" "$OD2/run.log" \
  && [[ -f $OD2/tag-local-M1 ]] && ! git -C "$T/origin.git" rev-parse -q --verify refs/tags/run/od2/M1 > /dev/null'
check "od2: the record branch's and the lane branch's push streaks are noted once each at their start, every failure a run.log line" \
  '[[ $(hlog od2 | grep -c "· record branch: push of harness/od2 failed; retrying at every sync (see run.log)$") == 1 ]] \
  && [[ $(hlog od2 | grep -c "· lane M1: push of harness-lane/od2/M1 failed; retrying at every sync (see run.log)$") == 1 ]] \
  && (( $(grep -c "push of harness/od2 failed$" "$OD2/run.log") >= 2 )) && read -r _ PF < "$OD2/push-failing" && (( PF >= 2 )) && [[ -f $OD2/lane-push-failing-M1 ]]'
check "od2: the merge past the retries is one note, the lane closes on its words, the marker holds the step" \
  '[[ $(hlog od2 | grep -cE "· M1: merge failed at fetch of main after 4 tries over [0-9]+ s; merged later: harness merge od2$") == 1 ]] \
  && hlog od2 | grep -qF "lane M1 closed (M1 needs Michael: its merge (origin unreachable at fetch of main))" \
  && [[ $(cat "$OD2/merge-failed-M1") == "fetch of main" && -f $OD2/needs-M1 ]] && ! hlog od2 | grep -q "· M1 merged into main"'
check "od2: merge_failed:M1 is open with its fields and its one command, seen once over the lane's and the run end's merges" \
  '[[ $(ni od2 merge_failed:M1 "[(.card.commands == [\"harness merge od2\"] | tostring), .what, (.tries | tostring), (.tag_local | tostring), (.seen | tostring), .kind, .severity, .priority] | join(\"|\")") == "true|fetch of main|4|true|1|needs_michael|block|high" ]] \
  && ni od2 merge_failed:M1 .card.headline | grep -qx "M1: merge failed at fetch of main (origin unreachable)" \
  && ni od2 merge_failed:M1 .card.why | grep -qF "origin_try in lib/record.sh" && [[ $(ni od2 merge_failed:M1 .head) == $(git -C "$T/proj" rev-parse "run/od2/M1^{commit}") ]]'
check "od2: one high needs-you post with the card's words, and the run end's post went out too" \
  '[[ $(posts "Title: [od2] M1 needs you" "Priority: high" "M1: merge failed at fetch of main") == 1 && $(curl_count "Title: [od2] M1 needs you") == 1 ]] \
  && [[ $(curl_count "Title: [od2] ended:") == 1 ]] && [[ $(curl_count "Title: [od2] M1 merged") == 0 ]]'
rm -f "$T/origin-down"
"$H" merge od2 > "$T/od2m.out" 2>&1; OD2M=$?
check "od2: origin back, harness merge: the tag reaches origin first, M1 merged, the markers gone, the item resolved milestone merged" \
  '(( OD2M == 0 )) && hlog od2 | grep -q "· M1 merged into main" && [[ $(git -C "$T/origin.git" tag -l run/od2/M1) == run/od2/M1 ]] && on_main run/od2/M1 \
  && [[ ! -e $OD2/tag-local-M1 && ! -e $OD2/merge-failed-M1 && ! -e $OD2/needs-M1 ]] && ! nkey od2 merge_failed:M1 \
  && [[ $(ndone od2 merge_failed:M1 "[.resolved_by, .resolved_why] | join(\" \")") == "sweep milestone merged" ]] \
  && hlog od2 | grep -q "needs: resolved od2/[0-9]* (milestone merged)"'
check "od2: the record branch's streak ends in one note, committed and on origin, the worktree clean" \
  '[[ $(hlog od2 | grep -cE "· record branch: push of harness/od2 succeeded after [0-9]+ failures over [0-9]+ min$") == 1 ]] && [[ ! -e $OD2/push-failing ]] \
  && git -C "$T/origin.git" show harness/od2:.harness/runs/od2/harness-log.md | grep -E "record branch: push of harness/od2 succeeded after" > /dev/null \
  && [[ -z $(git -C "$T/wt/proj/od2" status --porcelain) ]]'

# od7: gh fails every pr merge: past its tries that is an outage, never a refusal; a later harness merge lands the open PR
fresh; srun od7 STUB_GH_DOWN=99 STUB_GH_DOWN_ONLY=merge
check "od7: pr merge past its tries: merge_failed at merging its PR, no merge_refused, the lane closes on its words" \
  'hlog od7 | grep -qE "· M1: merge failed at merging its PR after 4 tries over [0-9]+ s; merged later: harness merge od7$" \
  && [[ $(ni od7 merge_failed:M1 .what) == "merging its PR" ]] && ! nkey od7 merge_refused:M1 && [[ ! -e $HARNESS_STATE/proj/od7/refused-M1 ]] \
  && hlog od7 | grep -qF "lane M1 closed (M1 needs Michael: its merge (origin unreachable at merging its PR))" \
  && [[ $(curl_count "Title: [od7] M1 needs you") == 1 ]]'
rm -f "$T"/gh-down-*; "$H" merge od7 > "$T/od7m.out" 2>&1
check "od7: harness merge lands it through the PR it left open, the card resolved" \
  'hlog od7 | grep -q "· M1 merged into main" && on_main run/od7/M1 && ! nkey od7 merge_failed:M1 && [[ $(ndone od7 merge_failed:M1 .resolved_why) == "milestone merged" ]]'

# od8: the merge landed and gh's answer was lost on every try: on main, so merged, no card (M1-01's leftover)
fresh; srun od8 STUB_GH_LOST_MERGE=1
check "od8: a pr merge whose answer is lost is merged when its commit is on main: no card, no post" \
  'hlog od8 | grep -q "· M1 merged into main" && on_main run/od8/M1 && [[ -f $HARNESS_STATE/proj/od8/merged-M1 ]] \
  && ! nkey od8 merge_failed:M1 && ! nkey od8 merge_refused:M1 && [[ $(curl_count "Title: [od8] M1 needs you") == 0 ]]'

# odh: a pre-receive hook declines the merge branch: a refusal, one try, its card says no PR was opened
fresh
printf '%s\n' '#!/bin/sh' 'while read -r o n r; do case $r in refs/heads/harness-merge/*) exit 1 ;; esac; done' > "$T/origin.git/hooks/pre-receive"; chmod +x "$T/origin.git/hooks/pre-receive"
srun odh; rm -f "$T/origin.git/hooks/pre-receive"
check "odh: a hook-declined push is one try and merge_refused: its real git line in run.log, no PR on the card, the lane closes merge refused" \
  'L=$HARNESS_STATE/proj/odh/run.log; grep -qF "(pre-receive hook declined)" "$L" && ! grep -q "push of harness-merge/odh-M1 failed (try" "$L" \
  && ! nkey odh merge_failed:M1 && nkey odh merge_refused:M1 && [[ $(ni odh merge_refused:M1 ".card.where | map(select(.label == \"PR\")) | length") == 0 ]] \
  && ni odh merge_refused:M1 .card.why | grep -qF "push of harness-merge/odh-M1" \
  && hlog odh | grep -qF "lane M1 closed (M1 needs Michael: merge refused)" && [[ $(curl_count "Title: [odh] M1 needs you") == 1 ]]'

# odu: lane_done's last branch, which nothing should reach: no tag could be made, so nothing to merge and no reason
# known; the lane still never closes needs Michael without a card
mkdir -p "$T/tagfail"; printf '%s\n' '#!/usr/bin/env bash' '[[ $1 == tag && $2 == -a ]] && { echo "error: stub: no tag" >&2; exit 1; }' "exec $(command -v git) \"\$@\"" > "$T/tagfail/git"; chmod +x "$T/tagfail/git"
fresh; srun odu PATH="$T/tagfail:$PATH"
check "odu: a lane left with no reason opens merge_failed what=unknown and notifies before it closes; no tag, no verified-and-tagged note" \
  'hlog odu | grep -qF "lane M1 closed (M1 needs Michael: its merge)" && [[ $(ni odu merge_failed:M1 .what) == unknown ]] \
  && ni odu merge_failed:M1 .card.headline | grep -qx "M1: its merge stopped with no reason recorded" \
  && hlog odu | grep -qF "· M1 verified; tag run/odu/M1 could not be made (see run.log)" && ! hlog odu | grep -q "M1 verified and tagged" \
  && [[ $(curl_count "Title: [odu] M1 needs you") == 1 ]]'

# The invariant (a falsifier of the spec's Predictions): scanned over every run with a worktree, before gc removes any
inv_bad="" inv_n=0
inv_scan() { local d r stamp hm m close
  for d in "$HARNESS_STATE"/proj/*/; do r=$(basename "$d")
    while read -r stamp hm m; do
      close=$(date -d "$stamp $hm" +%s); inv_n=$(( inv_n + 1 ))
      find "$d"needs -name '*.json' -exec cat {} + 2> /dev/null | jq -se --arg m "$m" --argjson t "$close" 'any(.[]; .milestone == $m and (.at | sub("\\.[0-9]+Z$"; "Z") | fromdate) < $t + 60)' > /dev/null || inv_bad+=" $r/$m"
    done < <(hlog "$r" | sed -nE 's/^- ([0-9-]+ [0-9:]+) · lane ([^ ]+) closed \(\2 needs Michael: .*$/\1 \2/p')
  done; }
inv_scan

# ---- gc keeps verified, unmerged work; harness merge without the worktree (M1-03) ----
has() { git -C "$1" rev-parse -q --verify "refs/heads/$2" > /dev/null; }   # <repo> <branch>
down_run() { local r=$1; shift; fresh; srun "$r" STUB_ORIGIN_DOWN="M1:until $(( $(date +%s) + 3600 ))" PATH="$DOWN:$PATH" "$@"; rm -f "$T/origin-down"; }   # <run>: verified, the tag local, the merge failed
wt_gone() { git -C "$T/proj" worktree remove --force "$T/wt/proj/$1"; }   # the incident's gc, by hand
branch_gone() { git -C "$T/proj" branch -q -D "harness/$1" 2> /dev/null; git -C "$T/origin.git" update-ref -d "refs/heads/harness/$1"; }   # and its record branch

# od3: gc holds a verified, unmerged run in all its forms; then harness merge without the worktree, the local branch
# ahead of origin's (the outage ate its pushes), so the record's last commits are kept
down_run od3; W3=$T/wt/proj/od3 KEEP3="keeps $W3: M1 verified, not merged (harness merge od3)"
"$H" gc "$T/proj" --dry-run > "$T/gc3d.out" 2>&1; "$H" gc "$T/proj" --all-merged > "$T/gc3a.out" 2>&1; "$H" gc "$T/proj" > "$T/gc3.out" 2>&1
check "od3: gc, --dry-run and --all-merged keep a verified, unmerged run: the keeps line, its worktree, its branch on origin, its card open" \
  'grep -qxF "$KEEP3" "$T/gc3d.out" && grep -qxF "$KEEP3" "$T/gc3a.out" && grep -qxF "$KEEP3" "$T/gc3.out" && [[ -d $W3 ]] && has "$T/origin.git" harness/od3 && has "$T/proj" harness/od3 \
  && has "$T/origin.git" harness-lane/od3/M1 && has "$T/proj" harness-lane/od3/M1 \
  && nkey od3 merge_failed:M1 && ! grep -qE "resolved od3/[0-9]+ \(run removed\)" "$T/gc3.out" "$T/gc3a.out"'
wt_gone od3; "$H" gc "$T/proj" > "$T/gc3w.out" 2>&1
check "od3: a run whose worktree is gone is still held: its branches stay, its card is not swept run removed" \
  'has "$T/origin.git" harness/od3 && has "$T/proj" harness/od3 && nkey od3 merge_failed:M1 && ! grep -qE "resolved od3/[0-9]+ \(run removed\)" "$T/gc3w.out"'
"$H" merge od3 > "$T/od3m.out" 2>&1
check "od3: harness merge without the worktree: made on the local branch, ahead of origin, no spec asked; the outage's notes kept, M1 merged, the tag on origin" \
  'grep -qxF "worktree $W3 on harness/od3 (from harness/od3; harness merge)" "$T/od3m.out" && hlog od3 | grep -q "· M1: merge failed at fetch of main" \
  && hlog od3 | grep -q "· M1 merged into main" && on_main run/od3/M1 && [[ $(git -C "$T/origin.git" tag -l run/od3/M1) == run/od3/M1 && $(ndone od3 merge_failed:M1 .resolved_why) == "milestone merged" ]]'

# od3b: origin's branch as far as the local one: the worktree comes from origin
fresh; srun od3b STUB_GH_DOWN=99 STUB_GH_DOWN_ONLY=merge; rm -f "$T"/gh-down-*; wt_gone od3b; "$H" merge od3b > "$T/od3bm.out" 2>&1
check "od3b: harness merge with its worktree gone and origin up to date: on harness/<run> from origin/harness/<run>, M1 merged" \
  'grep -qxF "worktree $T/wt/proj/od3b on harness/od3b (from origin/harness/od3b; harness merge)" "$T/od3bm.out" && hlog od3b | grep -q "· M1 merged into main" && on_main run/od3b/M1'

# od3h: Michael merged the tag by hand: gc is released
down_run od3h; git -C "$T/proj" push -q origin refs/tags/run/od3h/M1
cg fetch -q origin; cg checkout -q main; cg reset -q --hard origin/main; cg fetch -q origin tag run/od3h/M1; cg merge -q --no-edit run/od3h/M1; cg push -q origin main
"$H" gc "$T/proj" > "$T/gc3h.out" 2>&1
check "od3h: a tag merged by hand no longer holds its run: gc removes the worktree and the branches, its card goes run removed" \
  '! grep -q "keeps .*od3h" "$T/gc3h.out" && [[ ! -e $T/wt/proj/od3h ]] && ! has "$T/origin.git" harness/od3h && ! has "$T/proj" harness/od3h \
  && [[ $(ndone od3h merge_failed:M1 .resolved_why) == "run removed" ]]'

# od4: MERGE_POLICY=pr, the record PR merged, the worktree, the branch and the local tag gone: main has the record, origin the tag
cp "$T/user-config.sh" "$T/user-config.bak"; printf '%s\n' MERGE_POLICY=pr RECORD_PR=end >> "$T/user-config.sh"
rec_pr() { local f; for f in "$T"/prs/pr-*; do [[ ${f##*/} =~ ^pr-[0-9]+$ && $(cat "$f") == "harness/$1" ]] && "$HERE/stub-gh.sh" pr merge "https://example.test/pr/${f##*-}" --merge --match-head-commit "$(git -C "$T/origin.git" rev-parse "harness/$1")" > /dev/null; done; }   # <run>: its record PR merged
fresh; srun od4; rec_pr od4; cp "$T/user-config.bak" "$T/user-config.sh"
wt_gone od4; branch_gone od4; git -C "$T/proj" tag -d run/od4/M1 > /dev/null
"$H" merge od4 > "$T/od4m.out" 2>&1
check "od4: harness merge from origin/main, which has the record: no restore, the missing tag fetched, M1 merged by its PR" \
  'grep -qxF "worktree $T/wt/proj/od4 on harness/od4 (from origin/main; harness merge)" "$T/od4m.out" && ! hlog od4 | grep -q "record restored" \
  && hlog od4 | grep -q "· M1 proposed for merging" && hlog od4 | grep -q "· M1 merged into main · https" && on_main run/od4/M1'

# od4m: origin's branch has no record, main has: restored from main (the record PR), main first
printf '%s\n' MERGE_POLICY=pr RECORD_PR=end >> "$T/user-config.sh"
fresh; srun od4m; rec_pr od4m; cp "$T/user-config.bak" "$T/user-config.sh"
wt_gone od4m; git -C "$T/proj" branch -q -D harness/od4m; git -C "$T/origin.git" update-ref refs/heads/harness/od4m "$main0"
"$H" merge od4m > "$T/od4mm.out" 2>&1
check "od4m: a branch without the record and a main with it: restored from main, committed and noted, M1 merged" \
  'grep -qxF "worktree $T/wt/proj/od4m on harness/od4m (from origin/harness/od4m; harness merge)" "$T/od4mm.out" \
  && [[ -n $(git -C "$T/proj" log --format=%s --grep="^HARNESS: record restored from main$" harness/od4m) ]] && hlog od4m | grep -q "· record restored from main$" \
  && hlog od4m | grep -q "· M1 merged into main" && on_main run/od4m/M1'

# od5: no record anywhere: refused, nothing left behind; then the ledger's copy back: restored from it
down_run od5; wt_gone od5; branch_gone od5; mv "$T/ledger/proj/od5" "$T/od5-ledger"
"$H" merge od5 > "$T/od5m.out" 2>&1; OD5R=$?
check "od5: no record on the branch, on main or in the ledger: its line, exit 1, no worktree and no branch left behind" \
  '(( OD5R == 1 )) && grep -qxF "harness merge od5: no record for od5 (not on harness/od5, origin/main or $T/ledger/proj/od5)" "$T/od5m.out" \
  && [[ ! -e $T/wt/proj/od5 ]] && ! git -C "$T/proj" worktree list --porcelain | grep -qF "$T/wt/proj/od5" && ! has "$T/proj" harness/od5 && ! has "$T/origin.git" harness/od5'
mv "$T/od5-ledger" "$T/ledger/proj/od5"; "$H" merge od5 > "$T/od5l.out" 2>&1
check "od5: the ledger's copy back: restored from the ledger, committed and noted, M1 merged, its tag carried to origin" \
  'grep -qxF "worktree $T/wt/proj/od5 on harness/od5 (from origin/main; harness merge)" "$T/od5l.out" \
  && [[ -n $(git -C "$T/proj" log --format=%s --grep="^HARNESS: record restored from the ledger$" harness/od5) ]] && hlog od5 | grep -q "· record restored from the ledger$" \
  && hlog od5 | grep -q "· M1 merged into main" && on_main run/od5/M1 && [[ $(git -C "$T/origin.git" tag -l run/od5/M1) == run/od5/M1 ]]'

# odt: the tag missing here: origin down is an outage, never "gone"; missing there too, it is gone and harness merge goes on
fresh; srun odt STUB_GH_DOWN=99 STUB_GH_DOWN_ONLY=merge; rm -f "$T"/gh-down-*; git -C "$T/proj" tag -d run/odt/M1 > /dev/null
echo "until $(( $(date +%s) + 3600 ))" > "$T/origin-down"; PATH=$DOWN:$PATH "$H" merge odt > "$T/odtd.out" 2>&1; rm -f "$T/origin-down"
check "odt: a missing tag while origin is down is merge_failed at fetch of tag, never is gone" \
  'hlog odt | grep -qE "· M1: merge failed at fetch of tag run/odt/M1 after 4 tries over [0-9]+ s" && ! hlog odt | grep -q "is gone" && [[ $(ni odt merge_failed:M1 .what) == "fetch of tag run/odt/M1" ]]'
git -C "$T/origin.git" tag -d run/odt/M1 > /dev/null; "$H" merge odt > "$T/odtg.out" 2>&1; ODTG=$?
"$H" gc "$T/proj" > "$T/gcodt.out" 2>&1
check "odt: a tag gone here and on origin: its line, exit 0, and gc no longer holds the run for that milestone" \
  '(( ODTG == 0 )) && [[ $(grep -c "M1: tag run/odt/M1 is gone; not merged" "$HARNESS_STATE/proj/odt/run.log") == 1 ]] && ! grep -q "keeps .*odt: M1" "$T/gcodt.out"'

inv_scan
check "the invariant: every lane closed needs Michael in this file's runs has a needs item of that milestone, opened no later than the close" \
  '[[ -z $inv_bad ]] || echo "no item:$inv_bad"; [[ -z $inv_bad ]] && (( inv_n >= 5 ))'

suite_end
