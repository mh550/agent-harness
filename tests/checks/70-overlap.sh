#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- overlaps (U3-05, the pure half): lib/overlap.mjs named finds the tracked paths a spec or brief names, overlap ----
# ---- their intersection. tests/fixtures/overlap-spec.md is a byte copy of docs/specs/2026-10-26-suite-split.md ----
O=$HERE/../lib/overlap.mjs
git -C "$HERE/.." ls-files > "$T/tracked.txt"
node "$O" named "$T/tracked.txt" < "$HERE/fixtures/overlap-spec.md" > "$T/named.txt"
check "overlap: named on the suite-split spec with this repo's git ls-files finds tests/run.sh, lib/treekey.mjs and lib/check.sh" '
  grep -qx tests/run.sh "$T/named.txt" && grep -qx lib/treekey.mjs "$T/named.txt" && grep -qx lib/check.sh "$T/named.txt"'
check "overlap: every name is a tracked file or a tracked dir/ of two or more segments; no tests/, lib/ or .harness/runs/" '
  ok=1; while IFS= read -r l; do
    if [[ $l == */ ]]; then [[ $l == */*/ ]] && grep -q "^$l" "$T/tracked.txt" || ok=0; else grep -qxF -- "$l" "$T/tracked.txt" || ok=0; fi
    [[ $l == .harness/runs/* ]] && ok=0; done < "$T/named.txt"
  (( ok )) && [[ -s $T/named.txt ]] && ! grep -qxE "tests/|lib/" "$T/named.txt" && grep -qx tests/checks/ "$T/named.txt" && [[ $(LC_ALL=C sort -u "$T/named.txt") == "$(cat "$T/named.txt")" ]]'
printf '%s\n' CLAUDE.md README.md lib/a.sh lib/b/c.mjs lib/b/d.mjs tests/checks/01-x.sh tests/run.sh .harness/runs/r/x.md > "$T/t.txt"
nm() { printf '%s' "$1" | node "$O" named "$T/t.txt" | paste -sd" "; }
check "overlap: named takes backticked and bare path words, strips .,:;) and :<line>, and a word without / only in backticks" '
  [[ $(nm "see lib/a.sh:12, (tests/run.sh). And \`CLAUDE.md\` but not README.md") == "CLAUDE.md lib/a.sh tests/run.sh" ]] &&
  [[ $(nm "\`./lib/a.sh\` and lib/nope.sh") == "lib/a.sh" ]]'
check "overlap: a dir/ or glob names its directory of two or more segments; .harness/runs/ never" '
  [[ $(nm "lib/b/ and lib/ and tests/checks/NN-<slug>.sh and tests/*.sh") == "lib/b/ tests/checks/" ]] &&
  [[ $(nm "lib/x/ .harness/runs/r/x.md .harness/runs/") == "" ]]'
check "overlap: Markdown emphasis and HTML tags stuck to a path neither hide it nor turn it into its directory" '
  [[ $(nm "**lib/a.sh** and *tests/run.sh*") == "lib/a.sh tests/run.sh" ]] && [[ $(nm "lib/b/c.mjs<br> <code>tests/checks/01-x.sh</code>") == "lib/b/c.mjs tests/checks/01-x.sh" ]] &&
  [[ $(nm "**tests/checks/*.sh**") == "tests/checks/" && $(nm "tests/checks/0*") == "tests/checks/" ]]'
printf '%s\n' lib/a.sh tests/checks/ docs/x.md > "$T/a.txt"; printf '%s\n' tests/checks/02-y.sh lib/a.sh README.md > "$T/b.txt"
printf '%s\n' docs/y.md > "$T/c.txt"; printf '%s\n' tests/checks/ > "$T/d.txt"
check "overlap: overlap is the sorted intersection: file and file, a dir/ and a file under it (the file), dir/ and dir/; none" '
  [[ $(node "$O" overlap "$T/a.txt" "$T/b.txt" | paste -sd" ") == "lib/a.sh tests/checks/02-y.sh" ]] &&
  [[ $(node "$O" overlap "$T/b.txt" "$T/a.txt" | paste -sd" ") == "lib/a.sh tests/checks/02-y.sh" ]] &&
  [[ $(node "$O" overlap "$T/a.txt" "$T/d.txt") == tests/checks/ ]] && [[ -z $(node "$O" overlap "$T/a.txt" "$T/c.txt") ]]'
check "overlap: named and overlap are exported and pure (no I/O at import); node --check lib/overlap.mjs" '
  node --check "$O" && node --input-type=module -e "
    import { named, overlap } from \"$O\";
    const n = named(\"\`lib/a.sh\` lib/b/\", [\"lib/a.sh\", \"lib/b/c.mjs\"]);
    if (n.join() !== \"lib/a.sh,lib/b/\") process.exit(1);
    if (overlap(n, [\"lib/b/c.mjs\"]).join() !== \"lib/b/c.mjs\") process.exit(2);"'
# ---- the wiring (U3-06): before a start and at queue add, what the new run's spec and brief name meets each other ----
# ---- run of the project (alive, or ended with unmerged changes); a warning and a record on both runs, never a hold ----
# MERGE_POLICY=pr keeps a stub run's code on its lane branches (work-A.txt, work-B.txt, work-C.txt, none on main)
export HARNESS_GLYPHS=unicode HARNESS_COLOR=never COLUMNS=200
echo 'MERGE_POLICY=pr' >> "$T/user-config.sh"; Q=$HARNESS_STATE/queue
printf '%s\n' CLAUDE.md docs/plans/2026-10-01-x.md > "$T/t2.txt"
check "overlap: named leaves docs/plans/ out as a directory (every run writes its plan there); a plan file named exactly still counts" '
  [[ -z $(printf "%s" "docs/plans/<date>-<m>.md and docs/plans/" | node "$O" named "$T/t2.txt") ]] &&
  [[ $(printf "%s" "docs/plans/2026-10-01-x.md" | node "$O" named "$T/t2.txt") == docs/plans/2026-10-01-x.md ]]'
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" ov1 --spec SPEC.md --foreground > "$T/ov1.out" 2>&1
# an ended run with nothing unmerged (no branch) whose brief names work-A.txt: never compared
O1=$HARNESS_STATE/proj/old1; mkdir -p "$O1" && printf 'PROJECT_DIR=%q\nWT=/x\nRUN_ID=old1\nSTATE=%q\n' "$T/proj" "$O1" > "$O1/meta.env" && echo 'redo `work-A.txt`' > "$O1/brief.md"
"$H" queue add proj --brief 'redo `work-A.txt` and `CLAUDE.md`' > "$T/qa.out" 2> "$T/qa.err"
check "overlap: queue add of a start whose brief names a file an ended run's unmerged branch changed warns and queues it; old1 (nothing unmerged) is not compared" '
  grep -x "queued: 0001-start-proj.args" "$T/qa.out" > /dev/null && grep -x "warning: overlaps ov1 on work-A.txt" "$T/qa.err" > /dev/null &&
  ! grep old1 "$T/qa.err" > /dev/null && (( $(wc -l < "$T/qa.err") == 1 ))'
check "overlap: queue list shows ⚠ overlaps <R> on <files> under the entry; status --json's queued entry overlap lists {run, files}" '
  "$H" queue list > "$T/ql.out" && grep -E "^ +⚠ overlaps ov1 on work-A.txt$" "$T/ql.out" > /dev/null &&
  "$H" status > "$T/sv.out" && grep -E "^ +⚠ overlaps ov1 on work-A.txt$" "$T/sv.out" > /dev/null &&
  "$H" status --json > "$T/st.json" && jq -e ".queued[0].overlap == [{\"run\": \"ov1\", \"files\": [\"work-A.txt\"]}]" "$T/st.json" > /dev/null'
sleep 600 & LIVE=$!; echo "$LIVE" >> "$T/left.pids"   # sleep-ok: a live driver
L=$HARNESS_STATE/proj/live1; mkdir -p "$L" && echo "$LIVE" > "$L/driver.pid" && printf 'PROJECT_DIR=%q\nWT=/x\nRUN_ID=live1\nSTATE=%q\n' "$T/proj" "$L" > "$L/meta.env" && echo 'see `CLAUDE.md`' > "$L/brief.md"
check "overlap: a live run is compared by what its spec and brief name (no branch yet); more than 6 files end in and <k> more" '
  "$H" queue add proj --brief "see \`CLAUDE.md\`" 2> "$T/qb.err" > /dev/null && grep -x "warning: overlaps live1 on CLAUDE.md" "$T/qb.err" > /dev/null &&
  [[ $(printf "f%s\n" 1 2 3 4 5 6 7 8 | node "$O" names) == "f1, f2, f3, f4, f5, f6 and 2 more" && $(printf "a\nb\n" | node "$O" names) == "a, b" ]]'
kill "$LIVE" 2> /dev/null; rm -rf "$L"; "$H" queue clear > /dev/null 2>&1; rm -f "$Q"/*.args
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start proj ov2 --spec SPEC.md --brief 'redo `work-A.txt`' --now --foreground > "$T/ov2.out" 2> "$T/ov2.err"
"$H" needs --json > "$T/needs.json" 2> /dev/null
check "overlap: start --now prints the warning, starts, and opens a warn overlap record on both runs naming the files and which merges second" '
  grep -x "warning: overlaps ov1 on work-A.txt" "$T/ov2.err" > /dev/null && grep " run ov2 on harness/ov2 " "$HARNESS_STATE/proj/ov2/run.log" > /dev/null &&
  jq -e "[.[] | select(.reason == \"overlap\")] | length == 2" "$T/needs.json" > /dev/null &&
  jq -e "any(.[]; .reason == \"overlap\" and .run == \"ov2\" and .key == \"overlap:ov1\" and .severity == \"warn\" and .priority == \"\")" "$T/needs.json" > /dev/null &&
  jq -e "any(.[]; .reason == \"overlap\" and .run == \"ov1\" and .key == \"overlap:ov2\" and (.card.why | contains(\"ov2 merges second\")) and (.card.where[0].path | endswith(\"/work-A.txt\")))" "$T/needs.json" > /dev/null &&
  grep " needs: overlap with ov1 opened " "$HARNESS_STATE/proj/ov2/run.log" > /dev/null && grep " needs: overlap with ov2 opened " "$HARNESS_STATE/proj/ov1/run.log" > /dev/null &&
  ! hlog ov1 | grep "overlap with ov2" > /dev/null'
check "overlap: queue add --continue <run> warns from the run's spec and brief (brief.md) against the others" '
  "$H" queue add --continue ov2 > "$T/qc.out" 2> "$T/qc.err" && grep -x "warning: overlaps ov1 on work-A.txt" "$T/qc.err" > /dev/null; ok=$?; rm -f "$Q"/*.args; (( ok == 0 ))'
R2=$(jq -r ".[] | select(.reason == \"overlap\" and .run == \"ov2\") | .ref" "$T/needs.json")
check "overlap: harness needs done <ref> resolves one by hand; sweep resolves the other once ov2's lane branches are gone (other run merged)" '
  "$H" needs done "$R2" > /dev/null && for r in $(git for-each-ref --format="%(refname)" refs/heads/harness-lane/ov2/ refs/remotes/origin/harness-lane/ov2/); do git update-ref -d "$r"; done &&
  node "$HERE/../lib/needs.mjs" sweep "$HARNESS_STATE/proj/ov1" > "$T/sw.out" && grep -E "^resolved ov1/[0-9]+ \(other run merged\)$" "$T/sw.out" > /dev/null &&
  "$H" needs --json > "$T/n2.json" 2> /dev/null && jq -e "[.[] | select(.reason == \"overlap\")] | length == 0" "$T/n2.json" > /dev/null'
check "overlap: the sweep rule: other run gone, other run merged, this run merged, else kept (no git facts: kept)" '
  node --input-type=module -e "
    import { sweep } from \"$HERE/../lib/needs.mjs\";
    const i = { key: \"overlap:R\", reason: \"overlap\", ref: \"x/1\" }, w = st => sweep([i], { markers: [], passing: [], ...st }).resolved[0]?.resolved_why ?? \"kept\";
    const got = [w({ overlaps: { R: \"gone\" } }), w({ overlaps: { R: \"merged\" } }), w({ overlaps: { R: \"open\" }, self: \"merged\" }), w({ overlaps: { R: \"open\" }, self: \"open\" }), w({ ended: true })];
    if (got.join() !== \"other run gone,other run merged,this run merged,kept,kept\") { console.log(got.join()); process.exit(1); }"'
suite_end
