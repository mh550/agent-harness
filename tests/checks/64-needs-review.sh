#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- U2-09's review (docs/plans/2026-10-28-U2-review.md): each finding's check, red before its fix ----
NM=$HERE/../lib/needs.mjs FX=$HERE/fixtures/needs
IMP="import * as N from \"$NM\"; import { readFileSync as r } from \"node:fs\"; const ok = c => process.exit(c ? 0 : 1);"
in_node() { node --input-type=module -e "$IMP $1"; }

# 1, 2: merge_one's conflict, then the card's commands as Michael pastes them (a throwaway origin, 61-'s shape)
U=$T/u; mkdir -p "$U/st"; git init -q --bare -b main "$U/o.git"; git clone -q "$U/o.git" "$U/wt/run" 2> /dev/null
ug() { git -C "$U/wt/run" -c user.name=t -c user.email=t@t "$@"; }
echo base > "$U/wt/run/f"; ug add f; ug commit -qm base; ug push -q origin main
ug checkout -q -b harness-lane/u/M1; echo m1 > "$U/wt/run/f"; ug commit -qam m1; ug tag -a run/u/M1 -m "harness run u: M1 verified (v3)"
ug push -q origin harness-lane/u/M1 run/u/M1; ug checkout -q main; echo main2 > "$U/wt/run/f"; ug commit -qam main2; ug push -q origin main
ug checkout -q -b harness/u; mkdir -p "$U/wt/run/.harness/runs/u" "$U/st/lanes/M1"; echo "$U/wt/lanes/u/slot-0" > "$U/st/lanes/M1/slot"
printf '{"features":[{"id":"A","milestone":"M1","passes":true}]}\n' > "$U/wt/run/.harness/runs/u/feature_list.json"
mo() {   # [HARNESS_MERGE_ONLY=1]: merge_one M1 on the coordinator, gh a fake that opens PR #9 and merges it
  ( source "$HH/lib/record.sh"; HARNESS_HOME=$HH; source "$HH/lib/needs.sh"
    STATE=$U/st LS=$U/st RWT=$U/wt/run REC=$U/wt/run/.harness/runs/u RUN_DIR=.harness/runs/u RUN_ID=u PROJECT_NAME=proj MAIN_BRANCH=main RBRANCH=harness/u
    LIST=$REC/feature_list.json LBRANCH="" HARNESS_WT=$U/wt/run MERGE_POLICY=auto HARNESS_SCRATCH_ROOT=$U/fix; F() { node "$HH/lib/features.mjs" "$@"; }
    note() { echo "$*" >> "$U/notes"; }; log() { :; }; sync_record() { :; }; notify() { :; }; desk() { :; }; pr_body() { echo body; }; gh_url() { :; }; lane_branch_gone() { :; }
    ghf() { case "$1 $2" in "pr view") return 1 ;; "pr create") echo https://github.com/t/u/pull/9 ;; "pr merge") echo "$*" >> "$U/merged" ;; esac; }; GH=ghf
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
    cd "$U/wt/run" && merge_one M1; echo "rc=$?" ); }
u1=$(mo); J=$(grep -l merge_conflict:M1 "$U"/st/needs/*.json); jq -r '.card.commands[]' "$J" > "$U/cmds"
check "needs review: a card's commands fix the branch in a worktree of its own at its pushed tip, never the slot or the record worktree" \
  '[[ $u1 == rc=1 && $(wc -l < "$U/cmds") == 4 ]] && ! grep -e "cd $U/wt/lanes" -e "cd $U/wt/run " "$U/cmds" > /dev/null \
  && grep -x "git -C $U/wt/run/.harness/runs/u fetch -q origin && git -C $U/wt/run/.harness/runs/u worktree add --detach $U/fix/proj/fix-u-M1 origin/harness-lane/u/M1" "$U/cmds" > /dev/null \
  && grep -x "cd $U/fix/proj/fix-u-M1 && git merge origin/main" "$U/cmds" > /dev/null && grep -x "cd $U/fix/proj/fix-u-M1 && git push origin HEAD:harness-lane/u/M1" "$U/cmds" > /dev/null'
check "needs review: harness merge at the same main says the conflict again (never a silent return)" \
  '[[ $(HARNESS_MERGE_ONLY=1 mo) == rc=1 && $(grep -c "^M1 conflicts with main" "$U/notes") == 2 ]]'
# Michael pastes them: the merge conflicts, he resolves and commits, pushes, then `harness merge`
( export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  bash -c "$(sed -n 1p "$U/cmds")" && ! bash -c "$(sed -n 2p "$U/cmds")" > /dev/null 2>&1 \
  && echo both > "$U/fix/proj/fix-u-M1/f" && git -C "$U/fix/proj/fix-u-M1" commit -qam "merge main by hand" && bash -c "$(sed -n 3p "$U/cmds")" 2> /dev/null ) && hand=ok
u3=$(HARNESS_MERGE_ONLY=1 mo); HM=$(git -C "$U/o.git" rev-parse harness-lane/u/M1)
check "needs review: harness merge takes main merged into the lane branch by hand (the card's (a)): re-tagged there, its PR merged at it" \
  '[[ ${hand:-} == ok && $u3 == rc=0 && -f $U/st/merged-M1 && $(git -C "$U/o.git" rev-parse "run/u/M1^{commit}") == "$HM" ]] \
  && grep -x "M1: main merged into its branch by hand; re-tagged run/u/M1 at ${HM:0:7}" "$U/notes" > /dev/null \
  && grep -e "--match-head-commit $HM" "$U/merged" > /dev/null && [[ $(git -C "$U/o.git" show "main:f" 2> /dev/null; git -C "$U/o.git" show "$HM:f") == *both* ]]'
check "needs review: a card's paths are shell-quoted (a blank, a \$ or a ; pastes as one word)" \
  'jq ".record = \"/home/u/my wt/.harness/runs/r\" | .log = \"/home/u/st \$(x);y/run.log\"" "$FX/merge_conflict.json" > "$T/q.json" \
  && node "$NM" card merge_conflict "$T/q.json" | jq -r ".commands[0]" | grep -F "git -C '"'"'/home/u/my wt/.harness/runs/r'"'"' fetch" > /dev/null \
  && jq ".log = \"/home/u/st \$(x);y/run.log\"" "$FX/driver_crash.json" > "$T/d.json" \
  && node "$NM" card driver_crash "$T/d.json" | jq -r ".commands[]" | grep -xF "tail -50 '"'"'/home/u/st \$(x);y/run.log'"'"'" > /dev/null'

# 3: done on a stored parked record
needs_fixture parked open
check "needs review: harness needs done on a parked record is refused (it resolves when unparked); the record stays open, never a synthesized twin" \
  '! "$H" needs done nf-parked-open/1 > /dev/null 2> "$T/dp.err" && grep -F "resolves when the feature is unparked" "$T/dp.err" > /dev/null \
  && [[ -f $HARNESS_STATE/proj/nf-parked-open/needs/1.json && $("$H" needs nf-parked-open --json | jq -r "map(.ref) | join(\" \")") == nf-parked-open/1 ]]'
# 6: done under the record lock rewrites needs.md
needs_fixture merge_refused open; MD=$T/wt/proj/nf-merge_refused-open/.harness/runs/nf-merge_refused-open/needs.md; echo stale > "$MD"
check "needs review: harness needs done rewrites the record's needs.md (the notification's click) without the item" \
  '[[ $("$H" needs done nf-merge_refused-open/1) == "resolved nf-merge_refused-open/1" ]] && ! grep -x stale "$MD" > /dev/null \
  && grep "Nothing needs Michael in nf-merge_refused-open" "$MD" > /dev/null'
needs_fixture verify_thin open
check "needs review: done waits for the record lock a lane holds" \
  's=$SECONDS; (flock 9; sleep 3) 9> "$HARNESS_STATE/proj/nf-verify_thin-open/record.lock" &   # sleep-ok: a lane holding the lock
  wait_for 10 eval "! flock -n $HARNESS_STATE/proj/nf-verify_thin-open/record.lock true"
  r=$("$H" needs done nf-verify_thin-open/1); d=$(( SECONDS - s )); wait; [[ $r == "resolved nf-verify_thin-open/1" ]] && (( d >= 2 ))'

# 4: mergedBy and a run id that is another's prefix
check "needs review: mergedBy names a run whose id starts with the run's own (agent-harness-2026-10-25-memory in agent-harness-2026-10-25)" \
  'in_node "ok(N.mergedBy(\"Merge pull request #34 from mh550/harness-merge/agent-harness-2026-10-25-memory-M3\nMerge pull request #30 from mh550/harness-merge/agent-harness-2026-10-25-M1\", \"agent-harness-2026-10-25\") === \"agent-harness-2026-10-25-memory M3 (PR #34)\")"'
# 5, 11: lib/inbox.mjs (IM= points a red-phase run at another copy)
IM=${IM:-$HERE/../lib/inbox.mjs}
in_inbox() { node --input-type=module -e "import * as I from \"$IM\"; const ok = c => process.exit(c ? 0 : 1); $1"; }
check "needs review: a ## Answers heading with words after it (## Answers (Michael)) is the heading; ## Answersheet is not" \
  'in_inbox "const t = \"status: run\\n\\nQ1?\\n\\n## Answers (Michael)\\nyes\\n\"; ok(I.answers(t) === \"## Answers (Michael)\\nyes\\n\" && I.answersLine(\"## Answersheet\\n\") < 0)"'
check "needs review: a short reword inside the steering comment (not a question) stays there, unmoved" \
  'in_inbox "const b = \"status: run\\n<!-- Steer this run from the app. -->\\n\\n## Answers\\n\", a = b.replace(\"Steer this\", \"Steer not this\");
    const r = I.repair(b, a); ok(!r.changed && r.text === a)"'
suite_end
