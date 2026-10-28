#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- slots and cleanup (P2-04): a slot reused across milestones, merged lane branches deleted, gc's lane passes ----
# The gc checks are here, not in 08 or 13 (the two largest files): this file builds the lane state they read.
waitf() { local i; for i in $(seq $(( $2 * 5 ))); do eval "$1" && return 0; sleep 0.2; done; return 1; }   # <bash expr> <s>
held() { rm -f "$T"/held-* "$T"/release-*; : > "$T/hold-coding"; }
ats() { hlog "$1" | grep -n -m1 -E -- "$2" | cut -d: -f1; }   # <run> <ERE>: the line of the first note matching
has() { git -C "$1" rev-parse -q --verify "refs/heads/$2" > /dev/null; }   # <repo> <branch>
printf 'node_modules/\n' > .gitignore && git add .gitignore && git commit -qm "ignore node_modules" && git push -q origin main
main0=$(git -C "$T/origin.git" rev-parse main)
lane_at() { git -C "$T/origin.git" rev-parse -q --verify "refs/heads/harness-lane/$1/M1"; }   # <run>: its M1 branch on origin

# sr: one lane. M1 (A, B) merges; M2 (C) opens in slot 0 after it and fails its one attempt (the stub's first C leaves
# the suite red), so M2 stays unverified. The first coding session writes node_modules/marker, ignored by git.
echo 'MAX_ATTEMPTS=1' >> "$T/user-config.sh"
STUB_IGNORED=node_modules/marker STUB_NO_TAMPER=1 STUB_LENIENT=1 "$H" start "$T/proj" sr --spec SPEC.md --foreground > "$T/sr.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "lanes slots: the second milestone opens in slot 0, reused by checkout -B, and finds the ignored directory the first left" \
  'grep -qx "A absent" "$T/ignored.log" && grep -qx "C present" "$T/ignored.log" \
  && hlog sr | grep -F "· lane M2 opened (slot 0, port 7950, from " | grep -F ", slot reused)" > /dev/null'
check "lanes slots: a merged lane's branch is deleted when its PR merges (noted before the next lane opens), locally and on origin" \
  'g=$(ats sr "· lane M1: branch harness-lane/sr/M1 deleted \(merged\)$") && o=$(ats sr "· lane M2 opened \(") && [[ -n $g && -n $o ]] && (( g < o )) \
  && [[ $(hlog sr | grep -c "branch harness-lane/sr/M1 deleted") == 1 ]]'
check "lanes slots: after finish no lanes/ directory is left; the merged lane branch is gone here and on origin, the unverified one stays on both" \
  '[[ -f $HARNESS_STATE/proj/sr/ended && ! -e $T/wt/proj/lanes ]] \
  && ! has "$T/proj" harness-lane/sr/M1 && ! has "$T/origin.git" harness-lane/sr/M1 && has "$T/proj" harness-lane/sr/M2 && has "$T/origin.git" harness-lane/sr/M2'

# sp: MERGE_POLICY=pr. M1's slot is freed at verify (proposed) and its branch kept; Michael merges its PR on GitHub
# (a merge of the tag into main, from a clone); then gc's harness-lane/ pass deletes the branch here and on origin
echo 'MERGE_POLICY=pr' >> "$T/user-config.sh"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" sp --spec SPEC.md --foreground > "$T/sp.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
sp_kept=$(hlog sp | grep -F "· lane M1 closed (M1 proposed)" > /dev/null && [[ ! -e $T/wt/proj/lanes ]] && has "$T/proj" harness-lane/sp/M1 && has "$T/origin.git" harness-lane/sp/M1 && echo yes)
tmp=$(mktemp -d); git clone -q "$T/origin.git" "$tmp" && git -C "$tmp" fetch -q origin "refs/tags/run/sp/M1:refs/tags/run/sp/M1" \
  && git -C "$tmp" -c user.name=gh -c user.email=gh@test merge -q --no-ff -m "Merge pull request #1" run/sp/M1 && git -C "$tmp" push -q origin HEAD:main; rm -rf "$tmp"
"$H" gc "$T/proj" > "$T/gc-sp.out" 2>&1
check "lanes slots: under pr the slot is freed at verify and the branch kept; gc deletes it once its PR merged, here and on origin" \
  '[[ $sp_kept == yes ]] && ! has "$T/proj" harness-lane/sp/M1 && ! has "$T/origin.git" harness-lane/sp/M1 \
  && grep -F "push -q origin --delete harness-lane/sp/M1" "$T/gc-sp.out" > /dev/null'

# from here each run starts from the first main (the stub's work files would otherwise already be there: A's commit empty)
git -C "$T/origin.git" update-ref refs/heads/main "$main0"

# gk: the driver SIGKILLed while its lane works (held): gc keeps the slot and the session's unit while the lane lives.
# Then the lane is killed too and the held session released (it commits and pushes A's work); a lane unit the killed
# lane left is listed: gc removes the slot and lanes/, stops the unit, and keeps the lane branch (unmerged)
held
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" gk --spec SPEC.md --foreground > "$T/gk.out" 2>&1 & P=$!
S=$HARNESS_STATE/proj/gk
waitf '[[ -f $T/held-gk-A && -s $S/lanes/M1/pid ]]' 120
gk_unit=$(cd "$T/scope" && ls harness-gk-M1-s*.running 2> /dev/null | head -1); gk_unit=${gk_unit%.running}
lp=$(cat "$S/lanes/M1/pid"); kill -KILL "$(cat "$S/driver.pid")"; wait "$P" 2> /dev/null
"$H" gc "$T/proj" > "$T/gc-gk1.out" 2>&1
check "lanes slots: gc of a run whose driver was killed but whose lane lives keeps its slot (saying why) and its lane's session unit" \
  '[[ -n $gk_unit && -f $T/scope/$gk_unit.running && -d $T/wt/proj/lanes/gk/slot-0 ]] && ! grep -F "$gk_unit" "$T/gc-gk1.out" > /dev/null \
  && grep -F "keeps $T/wt/proj/lanes/gk/slot-0: lane M1'"'"'s process $lp is alive" "$T/gc-gk1.out" > /dev/null'
kill -KILL "$lp"; touch "$T/release-gk"
waitf '[[ ! -f $T/scope/$gk_unit.running && $(lane_at gk) && $(lane_at gk) != "$main0" ]]' 60
rm -f "$T/hold-coding"
git -C "$T/wt/proj/lanes/gk/slot-0" status --porcelain --untracked-files=normal > "$T/gk-status.out" 2>&1
touch "$T/scope/harness-gk-M1-s2".{alive,running}   # a lane unit the killed lane left
"$H" gc "$T/proj" > "$T/gc-gk2.out" 2>&1
check "lanes slots: gc of a run with a dead driver and lane removes its leftover slot and lanes/, stops its lane unit and keeps its unmerged lane branch" \
  '[[ ! -s $T/gk-status.out && ! -e $T/wt/proj/lanes ]] && grep -F "+ stopped harness-gk-M1-s2.scope (gk: driver gone)" "$T/gc-gk2.out" > /dev/null \
  && [[ ! -f $T/scope/harness-gk-M1-s2.alive ]] && has "$T/proj" harness-lane/gk/M1 && has "$T/origin.git" harness-lane/gk/M1 \
  && ! git -C "$T/proj" worktree list --porcelain | grep -F "/lanes/" > /dev/null'

# gd: --deps frees an ended run's dirty slot's DEPS_DIRS and keeps the slot (its uncommitted work), as for a run worktree
held
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" gd --spec SPEC.md --foreground > "$T/gd.out" 2>&1 & P=$!
S=$HARNESS_STATE/proj/gd
waitf '[[ -f $T/held-gd-A && -s $S/lanes/M1/pid ]]' 120
lp=$(cat "$S/lanes/M1/pid"); kill -KILL "$(cat "$S/driver.pid")" "$lp"; wait "$P" 2> /dev/null; touch "$T/release-gd"
waitf '[[ $(lane_at gd) && $(lane_at gd) != "$main0" ]]' 60; sleep 1
rm -f "$T/hold-coding"; echo "ended (killed)" > "$S/ended"
GS=$T/wt/proj/lanes/gd/slot-0; mkdir -p "$GS/node_modules" && echo x > "$GS/node_modules/m" && echo wip > "$GS/wip.txt"
"$H" gc "$T/proj" --deps > "$T/gc-gd.out" 2>&1
check "lanes slots: gc --deps frees the dependency directories of an ended run's slot it keeps for its uncommitted work" \
  '[[ -d $GS && ! -e $GS/node_modules && -f $GS/wip.txt ]] && grep -F "keeps $GS: uncommitted work" "$T/gc-gd.out" > /dev/null \
  && grep -E "^\+ freed [0-9]+ MB in $GS: node_modules$" "$T/gc-gd.out" > /dev/null'
rm -f "$GS/wip.txt"; "$H" gc "$T/proj" > /dev/null 2>&1

# gl: a live run (held): gc touches neither its slot, its lane unit nor its lane branch
held
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" gl --spec SPEC.md --foreground > "$T/gl.out" 2>&1 & P=$!
S=$HARNESS_STATE/proj/gl
waitf '[[ -f $T/held-gl-A && -s $S/lanes/M1/pid ]]' 120
gl_unit=$(cd "$T/scope" && ls harness-gl-M1-s*.running 2> /dev/null | head -1); gl_unit=${gl_unit%.running}
git -C "$T/wt/proj/lanes/gl/slot-0" push -q origin harness-lane/gl/M1   # as an earlier session's sync_lane: on origin, merged (no commit yet)
gl_lane=$(lane_at gl)
"$H" gc "$T/proj" > "$T/gc-gl.out" 2>&1
check "lanes slots: gc of a run with a live driver touches no slot, no lane unit and no lane branch" \
  '[[ -n $gl_unit && -f $T/scope/$gl_unit.alive && -d $T/wt/proj/lanes/gl/slot-0 && -n $gl_lane ]] && has "$T/origin.git" harness-lane/gl/M1 \
  && has "$T/proj" harness-lane/gl/M1 && ! grep -F "/lanes/gl" "$T/gc-gl.out" > /dev/null && ! grep -F "$gl_unit" "$T/gc-gl.out" > /dev/null'
touch "$T/release-gl"; wait "$P"; rm -f "$T/hold-coding"
check "lanes slots: the held run then ends with its slot gone" '[[ -f $HARNESS_STATE/proj/gl/ended && ! -e $T/wt/proj/lanes ]]'

# lane_branch_gone on its own (no run): only what the merged tag holds goes, and only from this run's slots. M1: Michael
# pushed a fix onto it after the merge (origin kept, the box's copy goes); M2: checked out in a checkout of his (kept
# here, gone from origin); M3: in a closed lane's slot (detached, gone from both, noted once)
U=$T/ustate; mkdir -p "$U" && git -C "$T/proj" fetch -q origin
for m in M1 M2 M3; do git -C "$T/proj" branch -q -f "harness-lane/u/$m" origin/main && git -C "$T/proj" tag -f "run/u/$m" origin/main > /dev/null \
  && git -C "$T/proj" push -q origin "harness-lane/u/$m"; done
tmp=$(mktemp -d); git clone -q -b harness-lane/u/M1 "$T/origin.git" "$tmp" && echo fix > "$tmp/fix.txt" && git -C "$tmp" add fix.txt \
  && git -C "$tmp" -c user.name=m -c user.email=m@test commit -qm fix && git -C "$tmp" push -q origin HEAD:harness-lane/u/M1; rm -rf "$tmp"
git -C "$T/proj" worktree add -q "$T/mine" harness-lane/u/M2 && git -C "$T/proj" worktree add -q "$T/wt/proj/lanes/u/slot-0" harness-lane/u/M3
( cd "$T/proj" && STATE=$U RUN_ID=u MAIN_BRANCH=main WT_ROOT_DIR=$T/wt/proj && source "$HERE/../lib/record.sh" \
  && note() { echo "note: $*" >> "$T/u.log"; } && log() { echo "log: $*" >> "$T/u.log"; } && for m in M1 M2 M3; do lane_branch_gone "$m"; done )
check "lanes slots: a merged lane's branch goes only as far as its merge holds it, and only from this run's slots" \
  'has "$T/origin.git" harness-lane/u/M1 && ! has "$T/proj" harness-lane/u/M1 && grep -qx "log: lane M1: harness-lane/u/M1 kept on origin (commits its merge doesn'"'"'t hold, or the push failed)" "$T/u.log" \
  && has "$T/proj" harness-lane/u/M2 && ! has "$T/origin.git" harness-lane/u/M2 && [[ $(git -C "$T/mine" branch --show-current) == harness-lane/u/M2 ]] \
  && ! has "$T/proj" harness-lane/u/M3 && ! has "$T/origin.git" harness-lane/u/M3 && [[ -z $(git -C "$T/wt/proj/lanes/u/slot-0" branch --show-current) ]] \
  && [[ $(grep -c "^note: lane M3: branch harness-lane/u/M3 deleted (merged)$" "$T/u.log") == 1 ]] \
  && grep -qx "note: lane M1: branch harness-lane/u/M1 deleted (merged); kept on origin (see run.log)" "$T/u.log" \
  && grep -qx "note: lane M2: branch harness-lane/u/M2 deleted (merged); kept here (see run.log)" "$T/u.log"'
git -C "$T/proj" worktree remove --force "$T/mine"; git -C "$T/proj" worktree remove --force "$T/wt/proj/lanes/u/slot-0"
suite_end
