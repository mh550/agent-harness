#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- lanes continue (P1-05): harness continue reopens a lane from its origin branch; a legacy run is refused; a pr-held dependency ----
# MAX_SESSIONS=3 ends the first segment mid-M2: A and B pass, M1 merges, C's first session leaves the suite red. Michael
# then pushes a fix to the lane branch by hand, while the box's branch has a commit whose push failed: the two diverged.
# The continue reopens the lane from both and finishes M2 on it
mkdir -p "$HARNESS_STATE/proj/lc" && echo MAX_SESSIONS=3 > "$HARNESS_STATE/proj/lc/run.env"
STUB_NO_TAMPER=1 STUB_LENIENT=1 "$H" start "$T/proj" lc --spec SPEC.md --foreground > "$T/lc-a.out" 2>&1
lc_c1=$(git -C "$T/origin.git" log --format=%H --grep '^C: stub work (1)$' harness-lane/lc/M2 2> /dev/null | head -1)
lc_end=$(head -1 "$HARNESS_STATE/proj/lc/ended")
rm -rf "$T/lc-hand"; git clone -q -b harness-lane/lc/M2 "$T/origin.git" "$T/lc-hand" && echo fix > "$T/lc-hand/hand-M2.txt" \
  && git -C "$T/lc-hand" add -A && git -C "$T/lc-hand" -c user.name=m -c user.email=m@test commit -qm "M2: a fix by hand" && git -C "$T/lc-hand" push -q origin harness-lane/lc/M2
lc_hand=$(git -C "$T/lc-hand" rev-parse HEAD) lc_local=""
git -C "$T/proj" worktree add -q "$T/lc-local" harness-lane/lc/M2 && echo local > "$T/lc-local/local-M2.txt" && git -C "$T/lc-local" add -A \
  && git -C "$T/lc-local" commit -qm "C: a commit whose push failed" && lc_local=$(git -C "$T/lc-local" rev-parse HEAD) && git -C "$T/proj" worktree remove "$T/lc-local"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue lc --foreground > "$T/lc-b.out" 2>&1
lc_from=$(hlog lc | sed -n 's/.*· lane M2 opened (slot 0, port [0-9]*, from \([0-9a-f]*\)[,)].*/\1/p' | tail -1)
check "lanes continue: a run stopped mid-M2 reopens harness-lane/<run>/M2 from the origin's and the box's branch and finishes M2 on it" \
  '[[ $lc_end == "session cap (3)"* && -n $lc_c1 && -n $lc_local && -n $lc_from ]] && grep -q "^done" "$HARNESS_STATE/proj/lc/ended" && on_main run/lc/M2 \
  && hlog lc | grep -F "· M2: harness-lane/lc/M2 here and on origin had diverged; merged origin'"'"'s into it" > /dev/null \
  && git -C "$T/origin.git" merge-base --is-ancestor "$lc_hand" "$lc_from" && git -C "$T/origin.git" merge-base --is-ancestor "$lc_local" "$lc_from" \
  && ! grep -q "push of harness-lane/lc/M2 failed" "$HARNESS_STATE/proj/lc/run.log"'
check "lanes continue: M2's merged PR still has the lane's earlier commits (the first segment's, the one by hand, the unpushed one)" \
  '( for c in "$lc_c1" "$lc_hand" "$lc_local"; do git -C "$T/origin.git" merge-base --is-ancestor "$c" run/lc/M2 || exit 1; done ) && on_main run/lc/M2'

# A legacy run: its branch carries code main doesn't have (a run from before lanes). harness continue refuses it with
# the three ways forward, says so in run.log and a high-priority notification, starts no driver and leaves its state
mkdir -p "$HARNESS_STATE/proj/lg" && echo MAX_SESSIONS=1 > "$HARNESS_STATE/proj/lg/run.env"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" lg --spec SPEC.md --foreground > "$T/lg-a.out" 2>&1
echo code > "$T/wt/proj/lg/legacy-code.txt" && git -C "$T/wt/proj/lg" add -A && git -C "$T/wt/proj/lg" commit -qm "A: code on the run branch (v2)" && git -C "$T/wt/proj/lg" push -q origin harness/lg
lg_end=$(cat "$HARNESS_STATE/proj/lg/ended"); lg_att=$(cat "$HARNESS_STATE/proj/lg/attempts.json")
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue lg --foreground > "$T/lg-b.out" 2>&1; lg_rc=$?
check "lanes continue: a legacy run (code on its branch beyond main) is refused with the three ways forward, exit 1" \
  'O=$(cat "$T/lg-b.out"); [[ $lg_rc == 1 && $O == *"harness/lg has code main does not have"*"legacy-code.txt"* && $O == *"harness merge lg"* \
    && $O == *"harness start $T/proj --brief"*"harness/lg is the source"* && $O == *"by hand on harness/lg"* ]] \
  && [[ $(grep -c " run lg on " "$HARNESS_STATE/proj/lg/run.log") == 1 && $(cat "$HARNESS_STATE/proj/lg/ended") == "$lg_end" && $(cat "$HARNESS_STATE/proj/lg/attempts.json") == "$lg_att" ]] \
  && grep -q "continue refused: harness/lg has code main does not have" "$HARNESS_STATE/proj/lg/run.log" \
  && B=$(curl_with "Title: [lg] continue refused: a pre-lanes run") && grep -qx "Priority: high" <<< "$B"'
"$H" merge lg > "$T/lg-m.out" 2>&1; lg_mrc=$?
check "lanes continue: harness merge of a legacy run is not refused" '[[ $lg_mrc == 0 ]] && ! grep -q "continue refused" "$T/lg-m.out"'

# A run started with --base: its branch carries the base's code, which main lacks; it is measured against its base, so
# it is no legacy run
rm -rf "$T/lb-base"; git clone -q "$T/origin.git" "$T/lb-base" && git -C "$T/lb-base" checkout -qb based && echo based > "$T/lb-base/based.txt" \
  && git -C "$T/lb-base" add -A && git -C "$T/lb-base" -c user.name=m -c user.email=m@test commit -qm "the base's own code" && git -C "$T/lb-base" push -q origin based
mkdir -p "$HARNESS_STATE/proj/lb" && echo MAX_SESSIONS=1 > "$HARNESS_STATE/proj/lb/run.env"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" lb --base origin/based --spec SPEC.md --foreground > "$T/lb-a.out" 2>&1
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue lb --foreground > "$T/lb-b.out" 2>&1; lb_rc=$?
check "lanes continue: a run started with --base is measured against its base, not main: not refused" \
  '[[ $lb_rc == 0 ]] && ! grep -q "continue refused" "$T/lb-b.out" && [[ $(grep -c " run lb on " "$HARNESS_STATE/proj/lb/run.log") == 2 ]]'
# review of P1, finding 1: that continue merged main into harness/lb; main moves again; a further continue measures the
# branch against its base and main merged, so main's own files are no code of the run's
git -C "$T/lb-base" fetch -q origin && git -C "$T/lb-base" checkout -q -B mv origin/main && echo moved > "$T/lb-base/main-moved.txt" \
  && git -C "$T/lb-base" add -A && git -C "$T/lb-base" -c user.name=m -c user.email=m@test commit -qm "main moves" && git -C "$T/lb-base" push -q origin mv:main
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue lb --foreground > "$T/lb-c.out" 2>&1   # merges main-moved.txt in
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue lb --foreground > "$T/lb-d.out" 2>&1
check "lanes continue: a --base run whose branch merged main is not refused once main moves on (no main file counts as its code)" \
  'git -C "$T/origin.git" cat-file -e harness/lb:main-moved.txt && ! grep -q "continue refused" "$T/lb-c.out" "$T/lb-d.out"'

# A segment killed mid-session leaves uncommitted work in its slot, and the push of its WIP commit fails (the origin
# refuses it once): the reopened lane keeps that commit, so it reaches the merged PR
mkdir -p "$HARNESS_STATE/proj/kw" && echo MAX_SESSIONS=1 > "$HARNESS_STATE/proj/kw/run.env"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" kw --spec SPEC.md --foreground > "$T/kw-a.out" 2>&1
rm -f "$HARNESS_STATE/proj/kw/run.env"   # the continue runs to the end
git -C "$T/proj" worktree add -q "$HARNESS_WORKTREES/proj/lanes/kw/slot-0" harness-lane/kw/M1 && echo wip > "$HARNESS_WORKTREES/proj/lanes/kw/slot-0/wip-kw.txt"
printf '#!/bin/sh\nwhile read o n r; do [ "$r" = refs/heads/harness-lane/kw/M1 ] && [ -f %q ] && { rm -f %q; echo refused >&2; exit 1; }; done; exit 0\n' \
  "$T/kw-refuse" "$T/kw-refuse" > "$T/origin.git/hooks/pre-receive" && chmod +x "$T/origin.git/hooks/pre-receive" && touch "$T/kw-refuse"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue kw --foreground > "$T/kw-b.out" 2>&1
rm -f "$T/origin.git/hooks/pre-receive"
check "lanes continue: a reused slot's work, committed while its push failed, stays on the lane and reaches main" \
  '[[ ! -e $T/kw-refuse ]] && grep -q "^done" "$HARNESS_STATE/proj/kw/ended" && on_main run/kw/M1 && git -C "$T/origin.git" cat-file -e run/kw/M1:wip-kw.txt'

# A record-only run whose record reached main through pre-lanes milestone PRs (n8n-home-2026-10-22): MAX_SESSIONS=2
# leaves M1 complete and unverified; its branch has nothing but the record beyond main, so it continues as a lanes run
mkdir -p "$HARNESS_STATE/proj/ro" && echo MAX_SESSIONS=2 > "$HARNESS_STATE/proj/ro/run.env"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" ro --spec SPEC.md --foreground > "$T/ro-a.out" 2>&1
rm -rf "$T/ro-main"; git clone -q "$T/origin.git" "$T/ro-main" && git -C "$T/ro-main" -c user.name=gh -c user.email=gh@test merge -q --no-ff -m "Merge pull request #90 (a pre-lanes PR carried the record)" origin/harness/ro \
  && git -C "$T/ro-main" push -q origin HEAD:main
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue ro --foreground > "$T/ro-b.out" 2>&1; ro_rc=$?
check "lanes continue: a record-only run (its record on main too) continues as a lanes run and ends done" \
  '[[ $ro_rc == 0 ]] && ! grep -q "continue refused" "$T/ro-b.out" && grep -q "^done" "$HARNESS_STATE/proj/ro/ended" && on_main run/ro/M1 && on_main run/ro/M2 \
  && [[ $(grep -c " run ro on " "$HARNESS_STATE/proj/ro/run.log") == 2 ]]'

# MERGE_POLICY=pr, M2 waiting on M1 (no after): M1 is proposed; M2 opens from main with M1's tag merged in, and its PR
# waits for M1's; harness merge then lands both, M1 first
{ cat "$T/base-config.sh"; echo 'MERGE_POLICY=pr'; } > "$T/user-config.sh"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" ph --spec SPEC.md --foreground > "$T/ph-a.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
S=$HARNESS_STATE/proj/ph
pr_of() { local f; for f in "$T"/prs/pr-*; do [[ $f != *.merged && $(cat "$f") == "harness-merge/${2:-ph}-$1" ]] && { echo "$f"; return 0; }; done; return 1; }
ph_from=$(hlog ph | sed -n 's/.*· lane M2 opened (slot 0, port [0-9]*, from \([0-9a-f]*\)[,)].*/\1/p' | tail -1)
ph_m1=$(pr_of M1) ph_m2=$(pr_of M2)
check "lanes pr-held: M1 verified is proposed (its PR open, not merged), and M2 opens from main with run/<run>/M1 merged in" \
  '[[ -n $ph_m1 && ! -f $ph_m1.merged && -f $S/proposed-M1 && ! -f $S/merged-M1 && -n $ph_from ]] && ! on_main run/ph/M1 \
  && git -C "$T/origin.git" merge-base --is-ancestor run/ph/M1 "$ph_from" && grep -q "^done" "$S/ended"'
check "lanes pr-held: M2 verified opens its PR, not merged, with the waits note once" \
  '[[ -n $ph_m2 && ! -f $ph_m2.merged && ! -f $S/merged-M2 ]] && [[ $(hlog ph | grep -c "· M2 verified; its PR waits for M1 to merge$") == 1 ]] && ! on_main run/ph/M2'
"$H" merge ph > "$T/ph-m.out" 2>&1
at() { hlog ph | grep -n -m1 -F -- "$1" | cut -d: -f1; }
check "lanes pr-held: harness merge afterwards merges M1, then M2" \
  'm1=$(at "· M1 merged into main · ") m2=$(at "· M2 merged into main · "); [[ -n $m1 && -n $m2 ]] && (( m1 < m2 )) && on_main run/ph/M1 && on_main run/ph/M2 \
  && [[ -f $ph_m1.merged && -f $ph_m2.merged ]]'

# The same under pr, but Michael merges M1's PR on GitHub: the next segment sees M1 merged, so M2 is proposed and he
# is told it is ready
{ cat "$T/base-config.sh"; echo 'MERGE_POLICY=pr'; } > "$T/user-config.sh"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" pm --spec SPEC.md --foreground > "$T/pm-a.out" 2>&1
pm_m1=$(pr_of M1 pm); ( cd "$T/proj" && "$HERE/stub-gh.sh" pr merge "https://example.test/pr/${pm_m1##*-}" --merge --match-head-commit "$(git rev-parse run/pm/M1^{commit})" )
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue pm --foreground > "$T/pm-b.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "lanes pr-held: M1 merged on GitHub is seen as merged, and the waiting M2 is proposed, with its notification" \
  'a=$(hlog pm | grep -n -m1 -F "· M1 merged into main (by its PR)" | cut -d: -f1) b=$(hlog pm | grep -n -m1 -F "· M2 proposed for merging · " | cut -d: -f1) \
  && [[ -n $a && -n $b ]] && (( a < b )) && [[ -f $HARNESS_STATE/proj/pm/merged-M1 && -f $HARNESS_STATE/proj/pm/proposed-M2 ]] && [[ -n $(curl_with "Title: [pm] M2 ready to merge") ]]'

suite_end
