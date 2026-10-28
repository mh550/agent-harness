#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the re-base rule (P2-03): main moved under a verified lane ----
# Two lanes, M2 after: [] (one feature, C): C goes first and M2's verify waits (STUB_VERIFY_WAIT) until M1 has merged
# work-B.txt into main, so M2 is verified on a main that has moved by the time it merges. Each run starts from the
# first main (origin's main is set back between runs: the stub's work files would otherwise already be there).
waitf() { local i; for i in $(seq $(( $2 * 5 ))); do eval "$1" && return 0; sleep 0.2; done; return 1; }   # <bash expr> <s>
held() { rm -f "$T"/held-* "$T"/release-* "$T"/vwait-*; : > "$T/hold-coding"; }
main0=$(git -C "$T/origin.git" rev-parse main)
echo 'MAX_LANES=2' >> "$T/user-config.sh"
# <run>: the two-lane run above, M1's B released once M2's verify waits; then the invariant, read before the next run
two_lanes() {
  held
  STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 STUB_VERIFY_WAIT=M2:work-B.txt "$H" start "$T/proj" "$1" --spec SPEC.md --foreground > "$T/$1.out" 2>&1 & P=$!
  waitf "[[ -f \$T/held-$1-A && -f \$T/held-$1-C ]]" 120; touch "$T/release-$1-C"
  waitf "[[ -f \$T/vwait-$1-M2 ]]" 120; touch "$T/release-$1"; wait "$P"; rm -f "$T/hold-coding"
  git -C "$T/origin.git" diff --quiet "run/$1/M2" main && echo same > "$T/$1.inv"
  rewritten > "$T/$1.forced"
  git -C "$T/origin.git" update-ref refs/heads/main "$main0"
}
# every ref update the origin logged that rewrote a ref (core.logAllRefUpdates, set below): a tag moved, or a branch
# moved to a commit not after its old one
rewritten() { (cd "$T/origin.git" && find logs/refs -type f 2> /dev/null | sort | while read -r f; do r=${f#logs/}
  while read -r old new _; do [[ $old == 0000000000000000000000000000000000000000 ]] && continue
    if [[ $r == refs/tags/* ]] || ! git merge-base --is-ancestor "$old" "$new" 2> /dev/null; then echo "$r"; fi; done < "$f"; done | sort -u | paste -sd' ') }
merged_rebased() {   # <run> <m>: merged into main, nobody asked
  hlog "$1" | grep -F "· $2 merged into main · " > /dev/null && ! hlog "$1" | grep -E "needs Michael|moved since" > /dev/null && [[ $(cat "$T/$1.inv" 2> /dev/null) == same ]]
}

# disjoint: M1 brought work-A.txt and work-B.txt, M2 has work-C.txt. The origin logs every ref update (the forced one)
git -C "$T/origin.git" config core.logAllRefUpdates always
two_lanes rb
S=$HARNESS_STATE/proj/rb
check "lanes rebase: main moved under a verified lane, files disjoint: the suite runs in full on the merged tree, the tag moves to it, it merges" \
  'hlog rb | grep -E "· M2 re-based on main [0-9a-f]{7}: [0-9]+ files, disjoint, suite green; re-tagged$" > /dev/null \
  && grep "^check: green" "$S/lanes/M2/rebase-check.out" > /dev/null && ! grep cached "$S/lanes/M2/rebase-check.out" > /dev/null \
  && merged_rebased rb M2 && grep -q "^done" "$S/ended" && [[ $(grep -c "^verify M2 " "$T/scratch/proj/rb/sessions.log") == 1 ]] \
  && git -C "$T/origin.git" tag -l --format="%(contents:subject)" run/rb/M2 | grep -E "\(v3\); re-based on main [0-9a-f]{7}, suite green$" > /dev/null'
check "lanes rebase: the tree on main after the re-based merge is the re-tagged tree (the invariant)" '[[ $(cat "$T/rb.inv" 2> /dev/null) == same ]]'
check "lanes rebase: the re-based tag is the only ref the origin saw rewritten (its forced push)" '[[ $(cat "$T/rb.forced") == refs/tags/run/rb/M2 ]]'

# overlapping: shared.txt is on main; A rewrites its first line, C its last (a clean merge, one path in both)
tmp=$(mktemp -d); git clone -q "$T/origin.git" "$tmp" && seq 10 > "$tmp/shared.txt" && git -C "$tmp" add shared.txt \
  && git -C "$tmp" -c user.name=t -c user.email=t@test commit -qm "shared.txt" && git -C "$tmp" push -q origin HEAD:main; rm -rf "$tmp"
main0=$(git -C "$T/origin.git" rev-parse main)
STUB_SHARED=shared.txt two_lanes ro
check "lanes rebase: overlapping files get one verify round on the merged tree, then the tag moves and it merges" \
  'hlog ro | grep -E "· M2 re-based on main [0-9a-f]{7}: [0-9]+ files, overlapping \(shared.txt\); one verify round \(1 of 1\)$" > /dev/null \
  && [[ $(grep -c "^verify M2 " "$T/scratch/proj/ro/sessions.log") == 2 ]] && ! hlog ro | grep "suite green; re-tagged" > /dev/null \
  && grep -l "re-base verify round 1 of 1" "$HARNESS_STATE"/proj/ro/logs/*verify-M2.prompt.md > /dev/null && merged_rebased ro M2'

# LANE_REBASE=verify: the disjoint case gets the verify round too
echo 'LANE_REBASE=verify' >> "$T/user-config.sh"
two_lanes rv
sed -i '/^LANE_REBASE=/d' "$T/user-config.sh"
check "lanes rebase: LANE_REBASE=verify gives a disjoint re-base the verify round, then it merges" \
  'hlog rv | grep -E "· M2 re-based on main [0-9a-f]{7}: [0-9]+ files, disjoint; one verify round \(LANE_REBASE=verify\)$" > /dev/null \
  && [[ $(grep -c "^verify M2 " "$T/scratch/proj/rv/sessions.log") == 2 ]] && ! hlog rv | grep "suite green; re-tagged" > /dev/null && merged_rebased rv M2'

# needs Michael: no re-base rounds left (MAX_REBASE_ROUNDS=0), and a re-base verify round that finds C failing
echo 'MAX_REBASE_ROUNDS=0' >> "$T/user-config.sh"
STUB_SHARED=shared.txt two_lanes rr
sed -i '/^MAX_REBASE_ROUNDS=/d' "$T/user-config.sh"
check "lanes rebase: with its re-base rounds used the milestone needs Michael: the slot back at the verified commit, nothing merged, nothing pushed" \
  'hlog rr | grep -E "· M2 re-based on main [0-9a-f]{7}: [0-9]+ files, overlapping \(shared.txt\); its 0 re-base round\(s\) used; not merged \(needs Michael\)$" > /dev/null \
  && hlog rr | grep -F "· lane M2 closed (M2 needs Michael: re-base rounds used)" > /dev/null && ! hlog rr | grep -F "· M2 merged into main" > /dev/null \
  && [[ $(cat "$T/rr.forced") != *run/rr/M2* ]] && [[ $(git -C "$T/origin.git" rev-parse "harness-lane/rr/M2") == $(git -C "$T/origin.git" rev-list -n1 run/rr/M2) ]]'
STUB_SHARED=shared.txt STUB_REBASE_VERIFY_FAIL=1 two_lanes rf
check "lanes rebase: a re-base verify round that fails un-verifies the milestone and removes its tag, so the old tag never merges" \
  'hlog rf | grep -F "· verify M2: the re-based tree did not hold; tag run/rf/M2 removed" > /dev/null && hlog rf | grep -F "· lane M2 closed (M2 needs Michael: C fails verification)" > /dev/null \
  && ! git -C "$T/wt/proj/rf" rev-parse -q --verify refs/tags/run/rf/M2 > /dev/null && ! git -C "$T/origin.git" rev-parse -q --verify refs/tags/run/rf/M2 > /dev/null \
  && [[ ! -f $HARNESS_STATE/proj/rf/verified-M2 ]] && ! hlog rf | grep -F "· M2 merged into main" > /dev/null'

# MERGE_POLICY=pr, one lane: M1 proposed, M2 (after M1) waiting on it; main moves; harness merge re-bases both in a slot
cp "$T/base-config.sh" "$T/user-config.sh"; echo 'MERGE_POLICY=pr' >> "$T/user-config.sh"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" rp --spec SPEC.md --foreground > "$T/rp.out" 2>&1
rp_before=$( [[ -f $HARNESS_STATE/proj/rp/proposed-M1 && -f $HARNESS_STATE/proj/rp/waits-M2 ]] && echo yes)
tmp=$(mktemp -d); git clone -q "$T/origin.git" "$tmp" && echo other > "$tmp/other.txt" && git -C "$tmp" add other.txt \
  && git -C "$tmp" -c user.name=t -c user.email=t@test commit -qm "other.txt" && git -C "$tmp" push -q origin HEAD:main; rm -rf "$tmp"
"$H" merge rp > "$T/rp-merge.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "lanes rebase: under MERGE_POLICY=pr, harness merge re-bases a proposed milestone on the moved main in a slot and merges it, then its dependent" \
  '[[ $rp_before == yes ]] && hlog rp | grep -E "· M1 re-based on main [0-9a-f]{7}: [0-9]+ files, disjoint, suite green; re-tagged$" > /dev/null \
  && hlog rp | grep -E "· M2 re-based on main [0-9a-f]{7}: [0-9]+ files, disjoint, suite green; re-tagged$" > /dev/null \
  && on_main run/rp/M1 && on_main run/rp/M2 && git -C "$T/origin.git" diff --quiet run/rp/M2 main && ! hlog rp | grep "needs Michael" > /dev/null \
  && [[ ! -d $T/wt/proj/lanes/rp ]]'
# unit: a lane killed mid-re-base (rebase-<m> already removed, moved-<m> at today's main) must not leave merge_one
# answering 1 for good: with no rebase-<m> and no needs-<m> it says "main moved" (3) again, so the re-base is redone
# at the next merge_milestones (P2 review 4; before, the milestone waited for main to move again or a harness merge)
U=$T/mvstate; mkdir -p "$U"; tmp=$(mktemp -d); git clone -q "$T/origin.git" "$tmp"
git -C "$tmp" checkout -q -b mv "$main0" && echo mine > "$tmp/mv-mine.txt" && git -C "$tmp" add mv-mine.txt && git -C "$tmp" -c user.name=m -c user.email=m@test commit -qm mine \
  && git -C "$tmp" tag -a run/mv/M1 -m "harness run mv: M1 verified (v3)" && git -C "$tmp" push -q origin run/mv/M1
git -C "$tmp" checkout -q "$main0" && echo main > "$tmp/mv-main.txt" && git -C "$tmp" add mv-main.txt && git -C "$tmp" -c user.name=m -c user.email=m@test commit -qm main \
  && git -C "$tmp" push -q origin HEAD:main; rm -rf "$tmp"
mv_rc=$( cd "$T/proj" && git fetch -q origin --tags && STATE=$U LS=$U RUN_ID=mv MAIN_BRANCH=main && source "$HERE/../lib/record.sh" \
  && note() { :; } && log() { :; } && merge_one M1; echo "first $?"; merge_one M1; echo "again $?"; rm -f "$U/rebase-M1"; true )
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
check "lanes rebase: merge_one says main moved (3) again when moved-<m> is today's main but no rebase-<m> is left (a lane killed mid-re-base)" \
  '[[ $mv_rc == "first 3"$'"'"'\n'"'"'"again 3" ]]'
suite_end
