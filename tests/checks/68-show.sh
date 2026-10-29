#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- harness show <run> [<feature>] [--files] [--json] (U3-04): where a run's work is, from local refs only ----
# MERGE_POLICY=pr keeps the milestones unmerged: their code stays on harness-lane/sh1/M1 and M2 (M2 stacked on M1).
# A's session changes 2 files (work-A.txt, STUB_BIG_DIFF's big-A.txt); a main commit then adds its own work-A.txt.
export HARNESS_GLYPHS=unicode HARNESS_COLOR=never COLUMNS=100
echo 'MERGE_POLICY=pr' >> "$T/user-config.sh"
# an earlier run's commit of a feature A, on main before this run: never one of this run's A commits
echo old > old-A.txt && git add old-A.txt && GIT_AUTHOR_DATE=2026-01-01T00:00:00 GIT_COMMITTER_DATE=2026-01-01T00:00:00 git commit -qm "A: from an older run" && git push -q origin main
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 STUB_BIG_DIFF=1 "$H" start "$T/proj" sh1 --spec SPEC.md --foreground > "$T/sh1.out" 2>&1
echo "main's A" > work-A.txt && git add work-A.txt && git commit -qm "main: work-A" && git push -q origin main
# key paths, as 52-status-json compares them; a session (a metrics.jsonl row as stored) and a needs card are other files' shapes
K='[paths | map(if type == "number" then "[]" else "." + . end) | join("") | ltrimstr(".")] | unique | .[] | select(test("^feature[.](sessions\\[\\]|card)[.]") | not)'
cols() { node -e 'let bad = 0; for (const l of require("fs").readFileSync(0, "utf8").split("\n")) if ([...l].length > 60 && !/^  https:\/\//.test(l)) { console.error(l); bad = 1; } process.exit(bad)'; }
row() { grep -E "^  $1  $2 " "$T/show.out"; }   # <status> <path>: its changes row
"$H" show sh1 > "$T/show.out" 2> "$T/show.err"
check "show: the run card's header and rule, then worktree, branch, record, state, lanes and the proposed milestones with their tags and PR URLs" '
  grep "^. sh1 · proj · done · 3/3 passing" "$T/show.out" > /dev/null && grep -E "^(─)+$" "$T/show.out" > /dev/null &&
  grep -E "^  worktree   $T/wt/proj/sh1 \(clean\)$" "$T/show.out" > /dev/null &&
  grep -E "^  branch     harness/sh1 @ [0-9a-f]{7} · [0-9]+ ahead, 1 behind$" "$T/show.out" > /dev/null &&
  grep -E "^  record     $T/wt/proj/sh1/.harness/runs/sh1/$" "$T/show.out" > /dev/null && grep -E "^  state      $HARNESS_STATE/proj/sh1/$" "$T/show.out" > /dev/null &&
  grep -E "^  lanes      M1 · harness-lane/sh1/M1 · slot 0 · closed$" "$T/show.out" > /dev/null && grep -E "^             M2 · harness-lane/sh1/M2 · slot 0 · closed$" "$T/show.out" > /dev/null &&
  grep -E "^  proposed   M1 · tag run/sh1/M1$" "$T/show.out" > /dev/null && grep -x "  https://example.test/pr/1" "$T/show.out" > /dev/null'
check "show: CHANGES vs origin/main lists the session's 2 files with +/−, a stacked lane counted once, and marks the one main also changed ✗ conflicts" '
  grep -E "^CHANGES vs origin/main · 4 files · \+503 −0 (─)+$" "$T/show.out" > /dev/null &&
  row A big-A.txt | grep -E "\+500$" > /dev/null && row A work-A.txt | grep -E "\+1  ✗ conflicts$" > /dev/null &&
  row A work-B.txt | grep -E "\+1$" > /dev/null && ! row A big-A.txt | grep conflicts > /dev/null &&
  grep -E "^CONFLICTS with origin/main 1 (─)+$" "$T/show.out" > /dev/null && grep -x "  work-A.txt" "$T/show.out" > /dev/null'
check "show: the compare URL of each run branch with changes, for the GitHub-shaped origin; none for a plain-path origin" '
  grep -x "  https://github.com/test/proj/compare/main...harness-lane/sh1/M1" "$T/show.out" > /dev/null &&
  grep -x "  https://github.com/test/proj/compare/main...harness-lane/sh1/M2" "$T/show.out" > /dev/null &&
  ! grep "compare/main...harness/sh1" "$T/show.out" > /dev/null &&
  git remote set-url origin "$T/origin.git" && "$H" show sh1 > "$T/plain.out" && "$H" show sh1 --json > "$T/plain.json"; ok=$?;
  git remote set-url origin git@github.com:test/proj.git
  (( ok == 0 )) && ! grep "github.com" "$T/plain.out" > /dev/null && grep "^CHANGES vs origin/main · 4 files" "$T/plain.out" > /dev/null &&
  jq -e ".compare == null and ([.lanes[].compare] | all(. == null))" "$T/plain.json" > /dev/null'
check "show: <run> <feature> lists its milestone, passes, attempts, steps, sessions, its commits and its entry files, absolute" '
  "$H" show sh1 A > "$T/a.out" 2>&1 && sha=$(git log --format=%h -1 --grep "^A: stub work" harness-lane/sh1/M1) && [[ -n $sha ]] &&
  grep -E "^  feature    A · M1 · passes · attempt 1 of 2$" "$T/a.out" > /dev/null && grep -E "^  steps      1\. " "$T/a.out" > /dev/null &&
  grep -E "^  sessions   [0-9-]+ [0-9:]+ .* · build · (opus|sonnet) · 0 min · \\\$[0-9.]+ · success$" "$T/a.out" > /dev/null &&
  grep -E "^  commits    $sha A: stub work \(1\)$" "$T/a.out" > /dev/null && ! grep -E "B: stub work" "$T/a.out" > /dev/null &&
  grep -E "^  files      $T/wt/proj/sh1/work-A.txt$" "$T/a.out" > /dev/null &&
  ! "$H" show sh1 Z > /dev/null 2> "$T/z.err" && grep -x "harness: no feature .Z. in sh1" "$T/z.err" > /dev/null'
check "show: at COLUMNS=60 no line of the run view or the feature view passes 60 columns but a URL line" '
  COLUMNS=60 "$H" show sh1 > "$T/n.out" && COLUMNS=60 "$H" show sh1 A >> "$T/n.out" && cols < "$T/n.out" &&
  grep -E "^  A  work-A.txt +(✗) +\+1$" "$T/n.out" > /dev/null'
# a needs item on A (given up), so the documents carry needs and a feature card
node "$HERE/../lib/needs.mjs" open "$HARNESS_STATE/proj/sh1" sh1 proj given_up A feature=A milestone=M1 > /dev/null
check "show: --json is one v1 document (the feature form a superset) whose sorted key paths equal tests/fixtures/show-json-keys.txt" '
  "$H" show sh1 --json > "$T/s.json" && "$H" show sh1 A --json > "$T/a.json" &&
  jq -e ".v == 1 and .run == \"sh1\" and .changes.files == 4 and .changes.added == 503 and .conflicts == [\"work-A.txt\"] and (.needs | length) == 1 and .feature == null" "$T/s.json" > /dev/null &&
  jq -e ".v == 1 and .feature.id == \"A\" and .feature.passes == true and .feature.card.headline != null and (.feature.commits | length) == 1" "$T/a.json" > /dev/null &&
  diff <(jq -r "$K" "$T/a.json") "$HERE/fixtures/show-json-keys.txt" && [[ -z $(comm -23 <(jq -r "$K" "$T/s.json") "$HERE/fixtures/show-json-keys.txt") ]]'
check "show: NEEDS YOU lists the run's open items, one line each, then the harness needs command" '
  "$H" show sh1 > "$T/show2.out" && grep -E "^NEEDS YOU 1 (─)+$" "$T/show2.out" > /dev/null &&
  grep -A2 "^NEEDS YOU 1" "$T/show2.out" | grep -x "  harness needs sh1" > /dev/null'
# 11 more files on the record branch: 15 rows, 12 shown, the rest by --files
( cd "$T/wt/proj/sh1" && for i in $(seq -w 1 11); do echo "$i" > "f$i.txt"; done && git add f*.txt && git commit -qm "more files" -m "A: note in the body" )
check "show: the 12 largest rows, then +<k> more: harness show <run> --files; --files lists every row" '
  "$H" show sh1 > "$T/m.out" && grep "^CHANGES vs origin/main · 15 files" "$T/m.out" > /dev/null &&
  [[ $(grep -cE "^  [AMD]  " "$T/m.out") == 12 ]] && grep -x "  +3 more: harness show sh1 --files" "$T/m.out" > /dev/null &&
  "$H" show sh1 --files > "$T/f.out" && [[ $(grep -cE "^  [AMD]  " "$T/f.out") == 15 ]] && ! grep "more: harness show" "$T/f.out" > /dev/null &&
  grep -x "  https://github.com/test/proj/compare/main...harness/sh1" "$T/m.out" > /dev/null'
git worktree remove --force "$T/wt/proj/sh1"   # as gc leaves a run: its branches, tags, state and ledger copy stay
check "show: once the worktree is removed: worktree removed, the record from the ledger copy, the same changes; the feature form still finds A, its one commit (not main's older A, not a body line)" '
  "$H" show sh1 > "$T/g.out" && grep -x "  worktree   removed" "$T/g.out" > /dev/null && grep -x "  record     $HARNESS_LEDGER/proj/sh1/ (ledger copy)" "$T/g.out" > /dev/null &&
  grep "^CHANGES vs origin/main · 15 files" "$T/g.out" > /dev/null && grep -x "  proposed   M1 · tag run/sh1/M1" "$T/g.out" > /dev/null &&
  "$H" show sh1 A > "$T/ga.out" && grep -E "^  commits    [0-9a-f]+ A: stub work \(1\)$" "$T/ga.out" > /dev/null && grep -E "^  feature    A · M1 · passes" "$T/ga.out" > /dev/null &&
  [[ $(grep -cE "^ +(commits +)?[0-9a-f]{7,} " "$T/ga.out") == 1 ]] && ! grep -E "older run|more files" "$T/ga.out" > /dev/null'
check "show: the pure parts: joinDiff joins by path (binary +/− null, .harness/runs/ left out), mergeTreePaths reads the real output, combine counts one blob once (stacked or fanned-out lanes), milestonesOf keeps a proposal's PR" '
  node --input-type=module -e "
    import { joinDiff, mergeTreePaths, combine, milestonesOf } from \"$HERE/../lib/show.mjs\"; import { readFileSync } from \"node:fs\";
    const a = (c, m) => { if (!c) { console.error(m); process.exit(1); } };
    const j = joinDiff(\"3\\t1\\tlib/a.sh\\n-\\t-\\tpic.png\\n2\\t0\\t.harness/runs/r/x\\n\", \"M\\tlib/a.sh\\nA\\tpic.png\\nA\\t.harness/runs/r/x\\n\");
    a(JSON.stringify(j) === JSON.stringify([{ status: \"M\", path: \"lib/a.sh\", added: 3, deleted: 1 }, { status: \"A\", path: \"pic.png\", added: null, deleted: null }]), \"joinDiff\");
    a(mergeTreePaths(readFileSync(\"$HERE/fixtures/merge-tree-name-only.txt\", \"utf8\")).join() === \"f.txt,work-A.txt\", \"mergeTreePaths\");
    const r = (x, blob) => [{ status: \"A\", path: x, added: 5, deleted: 0, blob }];
    const c = combine([{ rows: r(\"a\", \"1\"), conflicts: [] }, { rows: [...r(\"a\", \"1\"), ...r(\"b\", \"2\")], conflicts: [\"b\"] }, { rows: [...r(\"a\", \"1\"), ...r(\"b\", \"3\")], conflicts: [] }]);
    a(c.files === 2 && c.added === 15 && c.rows[0].path === \"b\" && c.rows[0].added === 10 && c.rows[0].conflict && c.rows[1].added === 5 && !(\"blob\" in c.rows[0]) && c.conflicts.join() === \"b\", \"combine \" + JSON.stringify(c));
    const m = milestonesOf(\"- 2026-10-28 17:56 · M1 proposed for merging · https://github.com/o/r/pull/7\\n- 2026-10-28 18:00 · record PR merged into main · https://x/pull/9\\n- 2026-10-28 18:01 · M1 merged into main (by its PR)\\n- 2026-10-28 18:02 · M2 merged into main · https://github.com/o/r/pull/8\\n\");
    a(JSON.stringify(m) === JSON.stringify([{ id: \"M1\", status: \"merged\", url: \"https://github.com/o/r/pull/7\" }, { id: \"M2\", status: \"merged\", url: \"https://github.com/o/r/pull/8\" }]), \"milestonesOf \" + JSON.stringify(m));
  "'
check "show: read-only: no fetch, the config read in a subshell, the project's object store untouched by merge-tree; bash -n and node --check" '
  ! grep -E "fetch" <(sed -n "/^cmd_show()/,/^}/p" "$HERE/../bin/harness") > /dev/null && grep -F "\$( (harness_config" <(sed -n "/^cmd_show()/,/^}/p" "$HERE/../bin/harness") > /dev/null &&
  n0=$(git count-objects | cut -d" " -f1) && "$H" show sh1 > /dev/null && [[ $(git count-objects | cut -d" " -f1) == "$n0" ]] &&
  bash -n "$HERE/../bin/harness" && node --check "$HERE/../lib/show.mjs"'
suite_end
