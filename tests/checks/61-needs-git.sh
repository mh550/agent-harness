#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the git-side stop paths open needs records (U2-06): sync_main's conflict (notified once per main commit),
# merge_one's conflict and refusal, verify's three needs lines, a lane's base conflict; needs_you sends the record ----
# Plan: docs/plans/2026-10-28-U2-needs-record.md §2.1, §3.2, §4.2. Stub runs end to end, slot_open alone.
nj() { jq -s "${2:-.}" "$HARNESS_STATE/proj/$1"/needs/*.json 2> /dev/null; }   # <run> [<jq over its open items>]
# <run> <key>: the item's card field, or the item's own with a leading dot (.title)
ni() { nj "$1" ".[] | select(.key == \"$2\") | ${3:-.}" | jq -r .; }
# how many stub-curl posts hold every one of the given strings
posts() { awk 'BEGIN { RS = "===\n"; split(ARGV[1], k, "\t"); ARGV[1] = "" } { for (i in k) if (!index($0, k[i])) next; n++ } END { print n + 0 }' "$(IFS=$'\t'; echo "$*")" "$T/curl.log"; }
export COLUMNS=200 HARNESS_GLYPHS=unicode
main0=$(git -C "$T/origin.git" rev-parse main)   # each run starts from it: a run's merges would otherwise already be on main

check "conflict_files: the conflicted paths of git merge-tree --write-tree --name-only (a real conflict's output)" \
  '[[ $(source "$HH/lib/record.sh"; conflict_files < "$HERE/fixtures/merge-tree-name-only.txt") == $'"'"'f.txt\nwork-A.txt'"'"' ]]'

# main conflict: A's first session lands another run's PR on main adding work-A.txt; M1's two verifies (the strict
# verifier un-passes A each round) both find main conflicting with the lane branch
STUB_MAIN_TOUCH=A:work-A.txt STUB_STRICT_VERIFIER=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 "$H" start "$T/proj" mc --spec SPEC.md --foreground > "$T/mc.out" 2>&1
MS=$HARNESS_STATE/proj/mc MN=$(git -C "$T/origin.git" rev-parse main)
check "sync_main's conflict opens main_conflict for the lane: the conflicted file in where, the merged PR's run in why, the main commit" \
  '[[ $(ni mc main_conflict:M1 "[.kind, .severity, .priority, .milestone, .title] | join(\"|\")") == "needs_michael|block|high|M1|[mc] M1 needs you" ]] \
  && [[ $(ni mc main_conflict:M1 ".card.where[] | select(.label == \"conflict\") | .path") == */work-A.txt ]] \
  && ni mc main_conflict:M1 .card.why | grep -qF "main gained other M3 (PR #7), and both sides change work-A.txt" \
  && [[ $(ni mc main_conflict:M1 .card.commit.main) == "${MN:0:7}" && $(cat "$MS/main-conflict-M1") == "$MN" ]] \
  && hlog mc | grep -q "main conflicts with harness-lane/mc/M1; carrying on without it"'
check "a main conflict notifies once per main commit across 2 verifies: high, title <m> needs you, body the card, click needs.md" \
  '[[ $(grep -c "^verify M1 " "$T/scratch/proj/mc/sessions.log") == 2 && $(ni mc main_conflict:M1 .seen) == 2 ]] \
  && [[ $(posts "Title: [mc] M1 needs you" "main conflicts with the run branch (1 file)") == 1 ]] \
  && [[ $(posts "Title: [mc] M1 needs you" "main conflicts with the run branch" "Priority: high" "Click: $GHP/blob/harness/mc/.harness/runs/mc/needs.md") == 1 ]]'
check "verify's re-check failure opens verify_recheck with the failed ids; its notification is the record's" \
  '[[ $(ni mc verify_recheck:M1 "[.card.headline, .title, .card.blocked] | join(\"|\")") == "M1: A failed the re-check|[mc] M1 needs you|M1 (1/2 passing; A failed the re-check); 1 feature waits" ]] \
  && [[ $(posts "Title: [mc] M1 needs you" "M1: A failed the re-check" "Priority: high" "Click: $GHP/blob/harness/mc/.harness/runs/mc/needs.md") == 1 ]]'
# Michael merges main into the lane branch by hand (the card's recommended option), then continues
MD=$T/mc-hand; git clone -q "$T/origin.git" "$MD" 2> /dev/null; mg() { git -C "$MD" -c user.name=m -c user.email=m@test "$@"; }
mg checkout -q harness-lane/mc/M1; mg merge -q origin/main > /dev/null 2>&1; mg checkout -q --ours work-A.txt; mg add work-A.txt; mg commit -qm "merge main by hand"; mg push -q origin harness-lane/mc/M1
MREF=$(ni mc main_conflict:M1 .ref)
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue mc --foreground > "$T/mc2.out" 2>&1
check "a later clean sync_main resolves main_conflict: its item in needs/done/, main merged cleanly, noted" \
  'D=$MS/needs/done/${MREF#mc/}.json; [[ -n $MREF && -f $D && ! -e $MS/needs/${MREF#mc/}.json && ! -e $MS/main-conflict-M1 ]] \
  && [[ $(jq -r "[.resolved_by, .resolved_why] | join(\" \")" "$D") == "sweep main merged cleanly" ]] && hlog mc | grep -q "needs: resolved $MREF (main merged cleanly)"'

git -C "$T/origin.git" update-ref refs/heads/main "$main0"
# merge conflict and refusal: M1's verify session lands the PR on main after the verify merged main in, so M1's merge
# conflicts; M2 (independent) verifies on that main and GitHub refuses its merge
STUB_MAIN_TOUCH=verify-M1:work-A.txt STUB_REFUSE_MERGE=1 STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 \
  "$H" start "$T/proj" mr --spec SPEC.md --foreground > "$T/mr.out" 2>&1
RN=$(git -C "$T/origin.git" rev-parse main) PRU=$(ni mr merge_refused:M2 '.card.where[] | select(.label == "PR") | .url')
check "merge_one's conflict opens merge_conflict: the merge-tree files in where, main and the tag commit, notified with the card" \
  '[[ $(ni mr merge_conflict:M1 "[.priority, .title] | join(\"|\")") == "high|[mr] M1 needs you" ]] \
  && [[ $(ni mr merge_conflict:M1 ".card.where[] | select(.label == \"conflict\") | .path") == */work-A.txt ]] \
  && [[ $(ni mr merge_conflict:M1 .card.commit.main) == "${RN:0:7}" && $(ni mr merge_conflict:M1 .card.commit.branch) == "$(git -C "$T/origin.git" rev-parse --short=7 "run/mr/M1^{commit}")" ]] \
  && [[ $(posts "Title: [mr] M1 needs you" "M1 conflicts with main (1 file)" "Priority: high" "Click: $GHP/blob/harness/mr/.harness/runs/mr/needs.md") == 1 ]]'
check "merge_one's refusal opens merge_refused: the PR URL in where and as its click, notified once with it" \
  '[[ $PRU == https://example.test/pr/* && $(ni mr merge_refused:M2 .click) == "$PRU" ]] \
  && [[ $(posts "Title: [mr] M2 needs you" "M2: the merge was refused" "Priority: high" "Click: $PRU") == 1 ]] && hlog mr | grep -q "M2: the merge was refused"'

# thin evidence in every round: verify_thin
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
STUB_THIN_VERIFY=all STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" th --spec SPEC.md --foreground > "$T/th.out" 2>&1
check "a thin verify opens verify_thin under [<run>] M1 needs you; the notification's body is the card, click needs.md" \
  '[[ $(ni th verify_thin:M1 "[.kind, .priority, .title, .card.headline] | join(\"|\")") == "needs_michael|high|[th] M1 needs you|M1 not verified: evidence too thin" ]] \
  && [[ $(posts "Title: [th] M1 needs you" "M1 not verified: evidence too thin" "Priority: high" "Click: $GHP/blob/harness/th/.harness/runs/th/needs.md") == 1 ]]'

# slot_open alone (44-'s throwaway repo): a dependency's tag that conflicts with main opens base_conflict
U=$T/u; mkdir -p "$U/st"; git init -q --bare -b main "$U/o.git"; git clone -q "$U/o.git" "$U/wt/run" 2> /dev/null
ug() { git -C "$U/wt/run" -c user.name=t -c user.email=t@t "$@"; }
echo base > "$U/wt/run/f"; ug add f; ug commit -qm base; ug push -q origin main
ug checkout -q -b m1; echo m1 > "$U/wt/run/f"; ug commit -qam m1; ug tag run/u/M1; ug checkout -q main; echo main2 > "$U/wt/run/f"; ug commit -qam main2; ug push -q origin main
ug checkout -q -b harness/u; mkdir -p "$U/wt/run/.harness/runs/u"
printf '{"features":[{"id":"A","milestone":"M1","passes":true},{"id":"B","milestone":"M2","after":["A"],"passes":false}]}\n' > "$U/wt/run/.harness/runs/u/feature_list.json"
printf 'status: run\n\n## Answers\n' > "$U/wt/run/.harness/runs/u/INBOX.md"
u_base=$( source "$HH/lib/record.sh"; HARNESS_HOME=$HH; source "$HH/lib/needs.sh"
  STATE=$U/st LS=$U/st LDIR="" RWT=$U/wt/run REC=$U/wt/run/.harness/runs/u RUN_DIR=.harness/runs/u RUN_ID=u PROJECT_NAME=proj MAIN_BRANCH=main RBRANCH=harness/u WT_ROOT_DIR=$U/wt PORT=7999
  LIST=$REC/feature_list.json; F() { node "$HH/lib/features.mjs" "$@"; }; note() { echo "$*" >> "$U/notes"; }; log() { :; }
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  slot_open M2; echo "rc=$?" )
check "slot_open: a dependency's tag that conflicts with main opens base_conflict naming that tag" \
  '[[ $u_base == rc=1 && -f $U/st/needs-M2 ]] && [[ $(jq -r "[.key, .card.headline] | join(\"|\")" "$U/st/needs/1.json") == "base_conflict:M2|M2 can'"'"'t open: its base conflicts (run/u/M1)" ]] \
  && jq -r ".card.commands[]" "$U/st/needs/1.json" | grep -qx "cd $T/scratch/proj/fix-u-M2 && git merge run/u/M1"'
# merge_one on the coordinator (no lane: LBRANCH empty, cwd the record worktree): the record names the lane's branch
u_merge=$( source "$HH/lib/record.sh"; HARNESS_HOME=$HH; source "$HH/lib/needs.sh"
  STATE=$U/st LS=$U/st RWT=$U/wt/run REC=$U/wt/run/.harness/runs/u RUN_DIR=.harness/runs/u RUN_ID=u PROJECT_NAME=proj MAIN_BRANCH=main RBRANCH=harness/u
  LIST=$REC/feature_list.json LBRANCH="" HARNESS_WT=$U/wt/run; F() { node "$HH/lib/features.mjs" "$@"; }; note() { :; }; log() { :; }
  sync_record() { :; }; notify() { echo "notified $*" >> "$U/notified"; }; desk() { :; }
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  cd "$U/wt/run" && merge_one M1; echo "rc=$?" )
check "merge_one on the coordinator: merge_conflict names the lane branch, never the record branch, and is notified" \
  '[[ $u_merge == rc=1 ]] && J=$(grep -l merge_conflict:M1 "$U"/st/needs/*.json) && [[ $(jq -r .card.branch "$J") == harness-lane/u/M1 ]] \
  && jq -r ".card.options[0].text" "$J" | grep -q "^merge main into harness-lane/u/M1 by hand" && grep -q "^notified M1 needs Michael: conflicts with main" "$U/notified"'
suite_end
