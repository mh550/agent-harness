#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- layer 1 of conflict resolution (N2-02): lib/merge-sorted.sh, the sorted-union merge driver ----
MS=$HERE/../lib/merge-sorted.sh HOME_DRIVER="$(cd "$HERE/.." && pwd)/lib/merge-sorted.sh %O %A %B"
# the fixture's pair: O is the lines outside the markers, A adds HEAD's side (the lane's), B main's
U=$T/ms; mkdir -p "$U"; FX=$HERE/fixtures/git-conflict/names.conflicted.txt
awk '/^(<<<<<<<|=======|>>>>>>>)( |$)/ { s = !/^>>>>>>>/; next } !s' "$FX" > "$U/O"
awk '/^<<<<<<<( |$)/ { s = 1; next } /^=======( |$)/ { s = 2; next } /^>>>>>>>( |$)/ { s = 0; next } s != 2' "$FX" > "$U/A"
awk '/^<<<<<<<( |$)/ { s = 1; next } /^=======( |$)/ { s = 2; next } /^>>>>>>>( |$)/ { s = 0; next } s != 1' "$FX" > "$U/B"
"$MS" "$U/O" "$U/A" "$U/B"; fx_rc=$?
check "merge-sorted: the fixture pair merges to a check, b lane check, b main check, c check with exit 0" \
  '[[ $fx_rc == 0 && $(cat "$U/O") == $'"'"'a check\nc check'"'"' && $(cat "$U/A") == $'"'"'a check\nb lane check\nb main check\nc check'"'"' ]]'
printf 'a\nb\nc\n' > "$U/O2"; printf 'a\nc\n' > "$U/A2"; printf 'a\nb\nc\nd\n' > "$U/B2"
"$MS" "$U/O2" "$U/A2" "$U/B2"; rm_rc=$?
check "merge-sorted: a base line one side removed stays removed" '[[ $rm_rc == 0 && $(cat "$U/A2") == $'"'"'a\nc\nd'"'"' ]]'
printf 'a\nc\n' > "$U/O3"; printf 'a\nb\nc\n' > "$U/A3"; cp "$U/A3" "$U/B3"
"$MS" "$U/O3" "$U/A3" "$U/B3"; both_rc=$?
check "merge-sorted: a line both sides added is one line" '[[ $both_rc == 0 && $(cat "$U/A3") == $'"'"'a\nb\nc'"'"' ]]'
printf 'a\nc\n' > "$U/O4"; printf 'a\nb\nc\n' > "$U/A4"; printf 'a\nc\nB\n' > "$U/B4"; cp "$U/A4" "$U/A4.before"
"$MS" "$U/O4" "$U/A4" "$U/B4"; uns_rc=$?
printf 'c\na\n' > "$U/A5"; printf 'a\nb\n' > "$U/B5"; cp "$U/A5" "$U/A5.before"
"$MS" "$U/O4" "$U/A5" "$U/B5"; uns_rc2=$?
check "merge-sorted: a side not in LC_ALL=C order exits 1 and leaves A untouched" \
  '[[ $uns_rc == 1 && $uns_rc2 == 1 ]] && cmp -s "$U/A4" "$U/A4.before" && cmp -s "$U/A5" "$U/A5.before"'

# a throwaway repo with the attribute and the driver in its worktree config: git merge and merge-tree both settle it
R=$T/msrepo; git init -q -b main "$R" && cd "$R" && git config user.name t && git config user.email t@test \
  && echo 'names.txt merge=sorted-union' > .gitattributes && printf 'a check\nc check\n' > names.txt && git add -A && git commit -qm base \
  && git config extensions.worktreeConfig true && git config --worktree merge.sorted-union.driver "$HOME_DRIVER" \
  && git checkout -q -b lane && printf 'a check\nb lane check\nc check\n' > names.txt && git commit -qam lane \
  && git checkout -q main && printf 'a check\nb main check\nc check\n' > names.txt && git commit -qam main
git -C "$R" merge-tree --write-tree main lane > /dev/null 2>&1; mt_rc=$?
git -C "$R" merge -q --no-edit lane > "$U/merge.out" 2>&1; mg_rc=$?; cd "$HERE" || exit 1
check "merge-sorted: with the attribute and the worktree driver, two branches adding adjacent names merge with exit 0, no marker, the union" \
  '[[ $mt_rc == 0 && $mg_rc == 0 ]] && ! grep -E "^<<<<<<<" "$R/names.txt" > /dev/null \
  && [[ $(cat "$R/names.txt") == $'"'"'a check\nb lane check\nb main check\nc check'"'"' ]]'

# two lanes, M2 after: [] (C), each adding a name between the same two lines of names.txt (on main under the attribute
# first); M2's verify waits until M1 has merged, so M2's re-base merges main's names.txt into its own
waitf() { local i; for i in $(seq $(( $2 * 5 ))); do eval "$1" && return 0; sleep 0.2; done; return 1; }   # <bash expr> <s>
tmp=$(mktemp -d); git clone -q "$T/origin.git" "$tmp" && printf 'a check\nc check\n' > "$tmp/names.txt" && echo 'names.txt merge=sorted-union' > "$tmp/.gitattributes" \
  && git -C "$tmp" add -A && git -C "$tmp" -c user.name=t -c user.email=t@test commit -qm "names.txt, sorted" && git -C "$tmp" push -q origin HEAD:main; rm -rf "$tmp"
echo 'MAX_LANES=2' >> "$T/user-config.sh"
rm -f "$T"/held-* "$T"/release-* "$T"/vwait-*; : > "$T/hold-coding"
STUB_SORTED=names.txt STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 STUB_VERIFY_WAIT=M2:work-B.txt \
  "$H" start "$T/proj" so --spec SPEC.md --foreground > "$T/so.out" 2>&1 & P=$!
waitf "[[ -f \$T/held-so-A && -f \$T/held-so-C ]]" 120
for s in "$T"/wt/proj/lanes/so/slot-*; do echo "$(git -C "$s" config --worktree merge.sorted-union.driver)"; done > "$T/so.slots"
touch "$T/release-so-C"; waitf "[[ -f \$T/vwait-so-M2 ]]" 120; touch "$T/release-so"; wait "$P"; rm -f "$T/hold-coding"
check "merge-sorted: the harness sets the driver in the slot's worktree config and never in the project's checkout" \
  '[[ $(sort -u "$T/so.slots") == "$HOME_DRIVER" && $(wc -l < "$T/so.slots") == 2 ]] \
  && [[ $(git -C "$T/wt/proj/so" config --worktree merge.sorted-union.driver) == "$HOME_DRIVER" ]] \
  && [[ -z $(git -C "$T/proj" config merge.sorted-union.driver) ]]'
check "merge-sorted: two lanes adding names to a sorted list both merge, with no conflict note and no needs record" \
  'hlog so | grep -E "· M2 re-based on main [0-9a-f]{7}: [0-9]+ files, overlapping \(names.txt\); one verify round" > /dev/null \
  && hlog so | grep -F "· M1 merged into main · " > /dev/null && hlog so | grep -F "· M2 merged into main · " > /dev/null \
  && ! hlog so | grep -E "conflicts with|needs Michael" > /dev/null && [[ -z $(ls -A "$HARNESS_STATE/proj/so/needs" 2> /dev/null) ]] \
  && [[ $(git -C "$T/origin.git" show main:names.txt) == $'"'"'a check\nb A check\nb C check\nc check'"'"' ]]'
suite_end
