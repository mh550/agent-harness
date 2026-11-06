#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
source "$HERE/origin-lib.sh"
# ---- gc keeps verified, unmerged work; harness merge without the worktree (M1-03) ----
has() { git -C "$1" rev-parse -q --verify "refs/heads/$2" > /dev/null; }   # <repo> <branch>
down_run() { local r=$1; shift; fresh; srun "$r" STUB_ORIGIN_DOWN="M1:until $(( $(date +%s) + 3600 ))" PATH="$DOWN:$PATH" "$@"; rm -f "$T/origin-down"; }   # <run>: verified, the tag local, the merge failed
wt_gone() { git -C "$T/proj" worktree remove --force "$T/wt/proj/$1"; }   # the incident's gc, by hand
branch_gone() { git -C "$T/proj" branch -q -D "harness/$1" 2> /dev/null; git -C "$T/origin.git" update-ref -d "refs/heads/harness/$1"; }   # and its record branch
C=$T/clone; git clone -q "$T/origin.git" "$C" 2> /dev/null   # Michael's own checkout, for a merge by hand
cg() { git -C "$C" -c user.name=t -c user.email=t@t "$@"; }

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

# od3b: origin's branch as far as the local one: the worktree comes from origin. Removed with rm, so git still lists it
fresh; srun od3b STUB_GH_DOWN=99 STUB_GH_DOWN_ONLY=merge; rm -f "$T"/gh-down-*; rm -rf "$T/wt/proj/od3b"; "$H" merge od3b > "$T/od3bm.out" 2>&1
check "od3b: harness merge with its worktree deleted and origin up to date: on harness/<run> from origin/harness/<run>, M1 merged" \
  'grep -qxF "worktree $T/wt/proj/od3b on harness/od3b (from origin/harness/od3b; harness merge)" "$T/od3bm.out" && hlog od3b | grep -q "· M1 merged into main" && on_main run/od3b/M1'

# od3h: Michael merges the tags by hand, one at a time: M1 on main hands the hold to M2 (built on M1's tag during the
# outage), and M2 on main releases the run
inv_scan   # before a gc removes a run's worktree, its log with it
hand() { git -C "$T/proj" push -q origin "refs/tags/run/$1"; cg fetch -q origin tag "run/$1"; cg merge -q --no-edit "run/$1"; cg push -q origin main; }   # <run>/<m>
down_run od3h; cg fetch -q origin; cg checkout -q main; cg reset -q --hard origin/main
hand od3h/M1; "$H" gc "$T/proj" > "$T/gc3h1.out" 2>&1
check "od3h: a tag merged by hand holds nothing: the run's next verified, unmerged milestone holds it" \
  '! grep -q "keeps .*od3h: M1" "$T/gc3h1.out" && grep -qxF "keeps $T/wt/proj/od3h: M2 verified, not merged (harness merge od3h)" "$T/gc3h1.out" && [[ -d $T/wt/proj/od3h ]]'
hand od3h/M2; "$H" gc "$T/proj" > "$T/gc3h.out" 2>&1
check "od3h: every tag merged by hand: gc removes the worktree and the branches, its card goes run removed" \
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
# a branch on origin with no record: the local branch the refused merge made goes too
git -C "$T/origin.git" update-ref refs/heads/harness/od5 "$main0"; "$H" merge od5 > "$T/od5b.out" 2>&1; OD5B=$?
check "od5: origin's branch without a record: refused too, and the local branch it just made is gone" \
  '(( OD5B == 1 )) && grep -qF "harness merge od5: no record for od5" "$T/od5b.out" && [[ ! -e $T/wt/proj/od5 ]] && ! has "$T/proj" harness/od5'
git -C "$T/origin.git" update-ref -d refs/heads/harness/od5
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
inv_scan   # before this gc removes the merged runs' worktrees
"$H" gc "$T/proj" > "$T/gcodt.out" 2>&1
check "odt: a tag gone here and on origin: its line, exit 0, and gc no longer holds the run for that milestone" \
  '(( ODTG == 0 )) && [[ $(grep -c "M1: tag run/odt/M1 is gone; not merged" "$HARNESS_STATE/proj/odt/run.log") == 1 ]] && ! grep -q "keeps .*odt: M1" "$T/gcodt.out"'

# odo: MERGE_POLICY=off: harness merge merges nothing there, so a verified milestone holds nothing
echo MERGE_POLICY=off >> "$T/user-config.sh"; fresh; srun odo; "$H" gc "$T/proj" > "$T/gcodo.out" 2>&1; cp "$T/user-config.bak" "$T/user-config.sh"
check "odo: under MERGE_POLICY=off gc does not hold a verified run for a merge that can't come" \
  '[[ -f $HARNESS_STATE/proj/odo/verified-M1 ]] && ! grep -q "keeps .*odo:" "$T/gcodo.out" && [[ ! -e $T/wt/proj/odo ]]'

inv_scan
check "the invariant, across gc: every lane closed needs Michael in this file's runs has a needs item of that milestone, opened no later than the close" \
  '[[ -z $inv_bad ]] || echo "no item:$inv_bad"; [[ -z $inv_bad ]] && (( inv_n >= 3 ))'

suite_end
