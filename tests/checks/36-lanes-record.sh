#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- lanes record (lanes P1-03): the record lock; the record on harness/<run>, the code on lane branches ----
# Two background writers through record(), each a read-modify-write of one file (the shape of F pass and the counters),
# with HARNESS_RECORD_DELAY holding the lock: none of the 40 lines is lost or torn.
RL=$T/rl; mkdir -p "$RL"
rl_add() { local c; c=$(cat "$RL/f" 2> /dev/null); sleep 0.01; { [[ -n $c ]] && printf '%s\n' "$c"; printf '%s %02d %s\n' "$1" "$2" "$(printf 'x%.0s' {1..60})"; } > "$RL/f"; }
rl_writer() { ( STATE=$RL; source "$HERE/../lib/record.sh"; for i in $(seq 20); do record rl_add "$1" "$i"; done ); }
HARNESS_RECORD_DELAY=0.01 rl_writer a & HARNESS_RECORD_DELAY=0.01 rl_writer b & wait
check "record lock: two writers through record() appending 20 lines each lose none (40 lines, every one intact)" \
  '[[ $(wc -l < "$RL/f") == 40 && $(grep -cE "^[ab] [0-9]{2} x{60}$" "$RL/f") == 40 && $(sort -u "$RL/f" | wc -l) == 40 ]]'

# One stub run: A's session commits a file into its copy of the record (git add -f), Michael's phone edits INBOX.md on
# GitHub during B's session, C's session asks a question above ## Answers and parks; --base names the start of every branch
git -C "$T/proj" checkout -q -b based && echo based > based.txt && git add based.txt && git commit -qm based && git push -q origin based && git checkout -q main
STUB_COMMIT_RECORD=A STUB_RECORD_MOVE=B STUB_PARK=C STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 \
  "$H" start "$T/proj" rec --spec SPEC.md --base origin/based --foreground > "$T/rec.out" 2>&1
RO=$T/origin.git
check "lanes record: a lane commit touching .harness/runs/ is reverted with a note, and harness/<run> never gets it" \
  'hlog rec | grep -q "· A: a lane commit touched the run record; reverted$" && [[ -z $(git -C "$RO" log --format=%H harness/rec -- .harness/runs/rec/x) ]] \
  && grep -qx "A: into the record" <<< "$(git -C "$RO" log --format=%s run/rec/M1)" && ! git -C "$RO" cat-file -e run/rec/M1:.harness/runs/rec/x 2> /dev/null'
check "lanes record: a session's question above ## Answers lands in the record's INBOX.md above that line" \
  'git -C "$RO" show harness/rec:.harness/runs/rec/INBOX.md > "$T/rec-inbox.md" && awk "/^### C: set the gatus vars/ { q = NR } /^## Answers/ { a = NR } END { exit !(q && a && q < a) }" "$T/rec-inbox.md" \
  && hlog rec | grep -q "C parked (waiting on Michael): set the gatus vars" && ! hlog rec | grep -q "C unparked" && grep -q "^waiting on Michael: C" "$HARNESS_STATE/proj/rec/ended"'
check "lanes record: two sessions' passes flips both land while the record moved between them" \
  'git -C "$RO" show harness/rec:.harness/runs/rec/feature_list.json | jq -e "[.features[] | select(.id == \"A\" or .id == \"B\") | .passes] == [true, true]" > /dev/null \
  && grep -q "(phone edit)$" "$T/rec-inbox.md" && grep -qx "HARNESS: after B (passes=true)" <<< "$(git -C "$RO" log --format=%s harness/rec)"'
check "harness start --base: persisted, and the record branch and every lane start from it" \
  'grep -qx "BASE_REF=origin/based" "$HARNESS_STATE/proj/rec/run.env" && git -C "$RO" merge-base --is-ancestor based harness/rec && git -C "$RO" merge-base --is-ancestor based run/rec/M1 && git -C "$RO" merge-base --is-ancestor based harness-lane/rec/M2'
check "lanes record: the slot is gone at the end, the run keeps one worktree, the merged lane's branch is deleted" \
  '[[ $(git -C "$T/proj" worktree list | grep -c "/wt/proj/") == 1 && ! -e $T/wt/proj/lanes ]] && hlog rec | grep -q "· lane M1 opened (slot 0, port [0-9]*, from [0-9a-f]*)$" \
  && ! git -C "$RO" rev-parse -q --verify refs/heads/harness-lane/rec/M1 > /dev/null && on_main run/rec/M1'
check "harness start refuses the run id lanes (the slots' directory)" '! "$H" start "$T/proj" lanes --spec SPEC.md --foreground > "$T/lanes-id.out" 2>&1 && grep -q "taken by the lane slots" "$T/lanes-id.out"'

# A lane's PR merges only once every milestone it depends on has: M1's merge is refused, so M2 (it waits on M1) is
# verified on a base with M1's tag merged in and its PR opened, noted once; `harness merge` then lands M1, then M2
STUB_REFUSE_MERGE=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" dep --spec SPEC.md --foreground > "$T/dep.out" 2>&1
dep_open=$(grep -c "pr create .*--head harness-merge/dep-M2" "$T/gh.log"); dep_m2=$(on_main run/dep/M2 && echo on-main)
"$H" merge dep > "$T/dep-merge.out" 2>&1
check "a lane's PR waits for its dependency to merge (noted once), and harness merge lands both in order" \
  '[[ $dep_open == 1 && -z $dep_m2 && $(hlog dep | grep -c "· M2 verified; its PR waits for M1 to merge$") == 1 ]] \
  && git -C "$RO" merge-base --is-ancestor run/dep/M1 run/dep/M2 && on_main run/dep/M1 && on_main run/dep/M2 \
  && hlog dep | grep -A3 "· M1 merged into main" | grep -q "· M2 merged into main"'

# slot_open and materialize alone, in a throwaway repo: the functions lib/driver.sh calls, with its helpers stubbed
U=$T/u; mkdir -p "$U/st"; git init -q --bare -b main "$U/o.git"; git clone -q "$U/o.git" "$U/wt/run" 2> /dev/null
ug() { git -C "$U/wt/run" -c user.name=t -c user.email=t@t "$@"; }
echo base > "$U/wt/run/f"; ug add f; ug commit -qm base; ug push -q origin main
ug checkout -q -b m1; echo m1 > "$U/wt/run/f"; ug commit -qam m1; ug tag run/u/M1; ug checkout -q main; echo main2 > "$U/wt/run/f"; ug commit -qam main2; ug push -q origin main
ug checkout -q -b harness/u; mkdir -p "$U/wt/run/.harness/runs/u"
printf '{"features":[{"id":"A","milestone":"M1","passes":true},{"id":"B","milestone":"M2","after":["A"],"passes":false}]}\n' > "$U/wt/run/.harness/runs/u/feature_list.json"
printf 'status: run\n\n## Answers\n' > "$U/wt/run/.harness/runs/u/INBOX.md"
uenv() { STATE=$U/st RWT=$U/wt/run REC=$U/wt/run/.harness/runs/u RUN_DIR=.harness/runs/u RUN_ID=u MAIN_BRANCH=main RBRANCH=harness/u WT_ROOT_DIR=$U/wt PORT=7999
  LIST=$REC/feature_list.json; F() { node "$HERE/../lib/features.mjs" "$@"; }; note() { echo "$*" >> "$U/notes"; }; log() { :; }
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t; source "$HERE/../lib/record.sh"; }
u_conf=$( uenv; slot_open M2; echo "rc=$? pwd=$PWD" )
check "slot_open: a dependency's tag that conflicts with main gives the base-conflict note and needs-<m>" \
  '[[ $u_conf == "rc=1 pwd=$U/wt/run" ]] && grep -qx "M2: its base conflicts (M1 vs main); needs Michael" "$U/notes" && [[ -f $U/st/needs-M2 ]]'
# a record tracked at the slot's base (it reached main before lanes): skip-worktree, so a session's add -A stages none of it
ug checkout -q main; mkdir -p "$U/wt/run/.harness/runs/u"; echo '{"features":[]}' > "$U/wt/run/.harness/runs/u/feature_list.json"; ug add -A; ug commit -qm "old record"; ug push -q origin main
ug checkout -q harness/u 2> /dev/null; ug checkout -q -f harness/u; mkdir -p "$U/wt/run/.harness/runs/u"
printf '{"features":[{"id":"A","milestone":"M1","passes":true}]}\n' > "$U/wt/run/.harness/runs/u/feature_list.json"
printf 'status: run\n\n## Answers\n' > "$U/wt/run/.harness/runs/u/INBOX.md"
u_skip=$( uenv; slot_open M1 > /dev/null; materialize; jq -c . "$SLOT/$RUN_DIR/feature_list.json"; echo s >> "$SLOT/$RUN_DIR/INBOX.md"; git add -A; git diff --cached --quiet && echo staged-none
  unmaterialize; [[ -z $(git status --porcelain) ]] && echo clean; git show "HEAD:$RUN_DIR/feature_list.json" | jq -c . )
check "materialize: a record tracked at the slot's base is skip-worktree, so the session's commit carries none of the copy" \
  '[[ $u_skip == $'"'"'{"features":[{"id":"A","milestone":"M1","passes":true}]}\nstaged-none\nclean\n{"features":[]}'"'"' ]]'
# a lane whose base conflicts leaves the slot on its branch: reopening the lane before it checks its own branch out again
printf '{"features":[{"id":"A","milestone":"M1","passes":true},{"id":"B","milestone":"M2","after":["A"],"passes":false}]}\n' > "$U/wt/run/.harness/runs/u/feature_list.json"
u_back=$( uenv; slot_open M1 > /dev/null; slot_open M2 > /dev/null; echo "rc=$?"; slot_open M1 > /dev/null; echo "rc=$? $HARNESS_BRANCH $(git -C "$SLOT" branch --show-current)" )
check "slot_open: after a lane's base conflicts, reopening the previous lane checks its branch out again" \
  '[[ $u_back == $'"'"'rc=1\nrc=0 harness-lane/u/M1 harness-lane/u/M1'"'"' ]]'
# the slot's excludes keep the user's global ones, a ~ path expanded; a slot that can't be checked out needs Michael
mkdir -p "$U/home"; echo "secret.txt" > "$U/home/.gi"; printf '[core]\n\texcludesFile = ~/.gi\n' > "$U/gitconfig"
u_ex=$( uenv; HOME=$U/home GIT_CONFIG_GLOBAL=$U/gitconfig slot_open M1 > /dev/null; cat "$U/st/lanes/M1/exclude" | paste -sd ' ' - )
u_lock=$(git -C "$U/wt/lanes/u/slot-0" rev-parse --path-format=absolute --git-path index.lock); touch "$u_lock"; rm -f "$U/st/needs-M1"
u_fail=$( uenv; slot_open M1 > /dev/null 2>&1; echo "rc=$? pwd=$PWD" ); rm -f "$u_lock"
check "slot_open: the slot's excludes file keeps the user's global excludes (a ~ path expanded)" '[[ $u_ex == ".harness/runs/ secret.txt" ]]'
check "slot_open: a slot that can't be checked out gives a note and needs-<m> (the loop never picks it again)" \
  '[[ $u_fail == "rc=1 pwd=$U/wt/run" && -f $U/st/needs-M1 ]] && grep -q "^M1: its slot failed (checkout of harness-lane/u/M1; see run.log); needs Michael$" "$U/notes"'
suite_end
