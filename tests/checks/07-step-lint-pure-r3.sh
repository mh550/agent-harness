#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- step lint, pure (R3, R2): features.mjs lint, one tripping and one passing step per rule ----
LINT='import { lint, lintNote } from "'$HERE'/../lib/features.mjs";
  const got = (...steps) => lint([{ id: "A", milestone: "M1", steps }]).map(f => `${f.step}:${f.rule}`).join();'
check "lint: no-anchor trips \"works correctly\", not \"the suite is green\" or \"curl :7814/x returns 200\"" 'node --input-type=module -e "$LINT"'\''
  process.exit(got("works correctly", "the suite is green", "curl :7814/x returns 200", "`harness queue list` prints (requested)", "README.md mentions it") === "1:no-anchor" ? 0 : 1);'\'
check "lint: outside-repo trips ~ and /home/ paths, not lib/driver.sh or /tmp/harness/" 'node --input-type=module -e "$LINT"'\''
  process.exit(got("read ~/projects/x/.harness/runs/…", "/home/mh550/…", "cat ../other/x", "lib/driver.sh", "/tmp/harness/…", "> /dev/null", "GET /api/health returns 200")
    === "1:outside-repo,2:outside-repo,3:outside-repo" ? 0 : 1);'\'
check "lint: self-match trips a grep of progress.md for the step's own words, not of harness-log.md or lib/" 'node --input-type=module -e "$LINT"'\''
  process.exit(got(`grep -q "M2 verified" .harness/runs/<run>/progress.md`, `grep -q "M1 verified" .harness/runs/<run>/harness-log.md`,
    "grep -c \x27^verify M1\x27 .harness/runs/<run>/progress.md", `grep -rn "note" lib/`, `grep -qF "lint: clean" .harness/runs/<run>/entries.jsonl`)
    === "1:self-match,5:self-match" ? 0 : 1);'\'
check "lint: self-match reads grep as a command: prose, option values, -x, redirects, egrep and BRE escapes" 'node --input-type=module -e "$LINT"'\''
  process.exit(got("running grep on progress.md shows M2", "rg -t md \x27^## M2\x27 progress.md", "grep --max-count 1 \x27^x\x27 progress.md",
    "grep -Fx \x27M2 verified\x27 progress.md", "grep -q \x27a\\{2\\}\x27 progress.md",
    "grep -q M2 2>/dev/null .harness/runs/r/progress.md", "egrep -q \x27M2|x\x27 progress.md", "grep -q \x27\\<M2\\>\x27 progress.md",
    " the suite is green") === "6:self-match,7:self-match,8:self-match" ? 0 : 1);'\'
check "lint: self-match ends the command at a closing backtick or a glued |, and reads --regexp=" 'node --input-type=module -e "$LINT"'\''
  process.exit(got("`rg` finds no TODO in progress.md", "grep -q M2 progress.md|wc -l", "grep --regexp=M2 progress.md", "`grep -c x lib/a.sh`; progress.md has x")
    === "2:self-match,3:self-match" ? 0 : 1);'\'
check "lint: undeclared trips a later milestone's first feature without after, not the first milestone's" 'node --input-type=module -e "$LINT"'\''
  const l = (after) => [{ id: "A", milestone: "M1" }, { id: "B", milestone: "M1" }, { id: "C", milestone: "M2", ...after }, { id: "D", milestone: "M2" }];
  const r = lint(l({})), ok = lint(l({ after: [] }));
  process.exit(r.length === 1 && r[0].id === "C" && r[0].step === "-" && r[0].rule === "undeclared" && r[0].text.startsWith("M2") && ok.length === 0 ? 0 : 1);'\'
check "lint: review-small for a review in a two-build milestone; review-missing for five builds without one; neither for five with one or docs only" 'node --input-type=module -e "$LINT"'\''
  const ms = (m, kinds) => kinds.map((kind, i) => ({ id: `${m}-${i + 1}`, milestone: m, kind, ...(m === "M1" ? {} : { after: [] }) }));
  const r = l => lint(l).map(f => `${f.id}:${f.step}:${f.rule}:${f.text}`).join("|");
  const small = r(ms("M1", ["plan", "build", "build", "review"])), one = r(ms("M1", ["build", "review"]));
  const inferred = r([{ id: "A", milestone: "M1" }, { id: "B", milestone: "M1", description: "Review + simplify of M1" }]);
  const five = r([...ms("M1", ["build", "build", "build", "build", "build", "review"]), ...ms("M2", ["plan", "build", "build", "build", "build", "build", "docs"])]);
  const docs = r(ms("M1", ["plan", "docs", "docs", "check", "review"]));
  process.exit(small === "M1-4:-:review-small:M1 has 2 build features: fold the review into M1-3\x27s steps"
    && one === "M1-2:-:review-small:M1 has 1 build feature: fold the review into M1-1\x27s steps"
    && inferred === "B:-:review-small:M1 has 1 build feature: fold the review into A\x27s steps"
    && five === "M2-7:-:review-missing:M2 has 5 build features and no review feature" && docs === "" ? 0 : 1);'\'
check "lint: the note counts by rule and names the first finding; clean says clean" 'node --input-type=module -e "$LINT"'\''
  const stub = [{ id: "A", milestone: "M1", steps: ["x", "y"] }, { id: "B", milestone: "M1", steps: ["y"] }, { id: "C", milestone: "M2", steps: ["z"] }];
  process.exit(lintNote(lint(stub)) === "lint: 5 findings (no-anchor: 4, undeclared: 1); the list is not edited — first: A step 1 no-anchor"
    && lintNote([]) === "lint: clean" ? 0 : 1);'\'
printf '%s\n' '{"features":[{"id":"A","milestone":"M1","steps":["works correctly","`lib/x.mjs` exists"]},{"id":"B","milestone":"M2","steps":["the suite is green"]}]}' > "$T/lint-list.json"
printf '%s\n' '{"features":[{"id":"A","milestone":"M1","steps":["`lib/x.mjs` exists"]},{"id":"B","milestone":"M2","after":[],"steps":["the suite is green"]}]}' > "$T/lint-clean.json"
check "lint: the CLI prints <id> step <n> <rule> <text> lines, exit 1 with findings and 0 clean" '
  out=$($F lint "$T/lint-list.json"); rc=$?; clean=$($F lint "$T/lint-clean.json"); crc=$?
  [[ $rc == 1 && $out == "$(printf "A\tstep 1\tno-anchor\tworks correctly\nB\tstep -\tundeclared\tM2%s" "'\''s first feature has no \"after\": it waits on every earlier feature")" && $crc == 0 && -z $clean ]] \
    && [[ $($F lint "$T/lint-list.json" --note; echo "rc=$?") == "lint: 2 findings (no-anchor: 1, undeclared: 1); the list is not edited — first: A step 1 no-anchor"$'\''\n'\''"rc=0" ]] \
    && h=$(sed -n "1,/^import/p" "$HERE/../lib/features.mjs") && [[ $h == *"lint <list>"* && $h == *no-anchor* && $h == *outside-repo* && $h == *self-match* && $h == *undeclared* && $h == *review-small* && $h == *review-missing* ]]'

suite_end
