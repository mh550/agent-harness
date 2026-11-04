// lib/features.mjs: the scheduler's deps and the step lint (its rules and its note).   node --test tests/unit/features.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { deps, lint, lintNote, RULES } from "../../lib/features.mjs";

const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const got = (...steps) => lint([{ id: "A", milestone: "M1", steps }]).map(f => `${f.step}:${f.rule}`).join();

test("after may name a milestone", () => {
  const l = [{ id: "A", milestone: "M1" }, { id: "B", milestone: "M1" },
    { id: "C", milestone: "M2", after: ["M1"] }, { id: "D", milestone: "M3", after: ["C", "M9"] }];
  assert.equal(deps(l, l[2]).join(), "A,B");
  assert.equal(deps(l, l[3]).join(), "C,M9");
});

test("lint: no-anchor trips \"works correctly\", not \"the suite is green\" or \"curl :7814/x returns 200\"", () => {
  assert.equal(got("works correctly", "the suite is green", "curl :7814/x returns 200", "`harness queue list` prints (requested)", "README.md mentions it"), "1:no-anchor");
});

test("lint: outside-repo trips ~ and /home/ paths, not lib/driver.sh or /tmp/harness/", () => {
  assert.equal(got("read ~/projects/x/.harness/runs/…", "/home/mh550/…", "cat ../other/x", "lib/driver.sh", "/tmp/harness/…", "> /dev/null", "GET /api/health returns 200"),
    "1:outside-repo,2:outside-repo,3:outside-repo");
});

test("lint: self-match trips a grep of progress.md for the step's own words, not of harness-log.md or lib/", () => {
  assert.equal(got(`grep -q "M2 verified" .harness/runs/<run>/progress.md`, `grep -q "M1 verified" .harness/runs/<run>/harness-log.md`,
    "grep -c \x27^verify M1\x27 .harness/runs/<run>/progress.md", `grep -rn "note" lib/`, `grep -qF "lint: clean" .harness/runs/<run>/entries.jsonl`),
    "1:self-match,5:self-match");
});

test("lint: self-match reads grep as a command: prose, option values, -x, redirects, egrep and BRE escapes", () => {
  assert.equal(got("running grep on progress.md shows M2", "rg -t md \x27^## M2\x27 progress.md", "grep --max-count 1 \x27^x\x27 progress.md",
    "grep -Fx \x27M2 verified\x27 progress.md", "grep -q \x27a\\{2\\}\x27 progress.md",
    "grep -q M2 2>/dev/null .harness/runs/r/progress.md", "egrep -q \x27M2|x\x27 progress.md", "grep -q \x27\\<M2\\>\x27 progress.md",
    " the suite is green"), "6:self-match,7:self-match,8:self-match");
});

test("lint: self-match ends the command at a closing backtick or a glued |, and reads --regexp=", () => {
  assert.equal(got("`rg` finds no TODO in progress.md", "grep -q M2 progress.md|wc -l", "grep --regexp=M2 progress.md", "`grep -c x lib/a.sh`; progress.md has x"),
    "2:self-match,3:self-match");
});

test("lint: undeclared trips a later milestone's first feature without after, not the first milestone's", () => {
  const l = (after) => [{ id: "A", milestone: "M1" }, { id: "B", milestone: "M1" }, { id: "C", milestone: "M2", ...after }, { id: "D", milestone: "M2" }];
  const r = lint(l({})), ok = lint(l({ after: [] }));
  assert.equal(r.length, 1);
  assert.equal(r[0].id, "C");
  assert.equal(r[0].step, "-");
  assert.equal(r[0].rule, "undeclared");
  assert.match(r[0].text, /^M2/);
  assert.equal(ok.length, 0);
});

test("lint: review-small for a review in a two-build milestone; review-missing for five builds without one; neither for five with one or docs only", () => {
  const ms = (m, kinds) => kinds.map((kind, i) => ({ id: `${m}-${i + 1}`, milestone: m, kind, ...(m === "M1" ? {} : { after: [] }) }));
  const r = l => lint(l).map(f => `${f.id}:${f.step}:${f.rule}:${f.text}`).join("|");
  const small = r(ms("M1", ["plan", "build", "build", "review"])), one = r(ms("M1", ["build", "review"]));
  const inferred = r([{ id: "A", milestone: "M1" }, { id: "B", milestone: "M1", description: "Review + simplify of M1" }]);
  const five = r([...ms("M1", ["build", "build", "build", "build", "build", "review"]), ...ms("M2", ["plan", "build", "build", "build", "build", "build", "docs"])]);
  const docs = r(ms("M1", ["plan", "docs", "docs", "check", "review"]));
  assert.equal(small, "M1-4:-:review-small:M1 has 2 build features: fold the review into M1-3\x27s steps");
  assert.equal(one, "M1-2:-:review-small:M1 has 1 build feature: fold the review into M1-1\x27s steps");
  assert.equal(inferred, "B:-:review-small:M1 has 1 build feature: fold the review into A\x27s steps");
  assert.equal(five, "M2-7:-:review-missing:M2 has 5 build features and no review feature");
  assert.equal(docs, "");
});

test("lint: the note counts by rule and names the first finding; clean says clean", () => {
  const stub = [{ id: "A", milestone: "M1", steps: ["x", "y"] }, { id: "B", milestone: "M1", steps: ["y"] }, { id: "C", milestone: "M2", steps: ["z"] }];
  assert.equal(lintNote(lint(stub)), "lint: 5 findings (no-anchor: 4, undeclared: 1); the list is not edited — first: A step 1 no-anchor");
  assert.equal(lintNote([]), "lint: clean");
});

test("lint: unit-collision names each milestone whose LANEU name another shares (M1-x, M1.x, M1_x), none for M1 and M2", () => {
  const ms = ids => ids.flatMap(m => [{ id: `${m}/a`, milestone: m, after: [] }, { id: `${m}/b`, milestone: m }]);
  const uc = l => lint(l).filter(f => f.rule === "unit-collision");
  const r = uc(ms(["M1-x", "M0", "M1.x", "M1_x"])), all = ["M1-x", "M1.x", "M1_x"];
  assert.equal(r.map(f => `${f.id}:${f.step}`).join(), "M1-x/a:-,M1.x/a:-,M1_x/a:-");
  r.forEach((f, i) => {
    assert.match(f.text, new RegExp("^" + esc(all[i] + " shares lane unit name M1_x with ")));
    for (const o of all.filter(m => m !== all[i])) assert.match(f.text, new RegExp(esc(o)));
    assert.match(f.text, /lib\/lane\.sh/);
  });
  assert.equal(uc(ms(["M1", "M2"])).length, 0);
});

test("lint: unreproducible flags a time bound or one run's count, once per step, with its message", () => {
  const msg = "a number another box or run won\x27t reproduce: cite the command that prints it, or a bound with room";
  const yes = ["it runs in < 150 s", "under 2 minutes", "in at most 30 s", "395 tests", "this run\x27s check.out", "<150 s",
    "this run\x27s scratch check.out (395 tests)", "963/963 checks passed", "the suite finishes in under 4 min"];
  const r = lint([{ id: "A", milestone: "M1", steps: yes }]).filter(f => f.rule === "unreproducible");
  assert.equal(r.map(f => f.step).join(), yes.map((_, i) => i + 1).join());
  for (const f of r) assert.match(f.text, new RegExp("^" + esc(msg)));
});

test("lint: unreproducible leaves names, flags, budgets, sizes and file counts alone", () => {
  const no = ["the suite is green", "TEST_FILE_TIMEOUT=10m", "--repeat 10", "at most 400 characters", "a budget of 30 minutes",
    "`tests/run.sh` prints `N/M checks passed`", "3 checks in tests/checks/07-step-lint-pure-r3.sh", "ENTRY_RESUME_TIMEOUT (10m)",
    "the 25-minute CHECK_TIMEOUT", "a 10m timeout", "within 2 lines of the note", "R3-04 adds 2 checks", "`wait_for 30 test -f <file>`"];
  assert.equal(lint([{ id: "A", milestone: "M1", steps: no }]).filter(f => f.rule === "unreproducible").map(f => f.step).join(), "");
});

test("lint: RULES and the header comment name unit-collision and unreproducible; the note counts them", () => {
  const n = lintNote(lint([{ id: "A", milestone: "M-1", steps: ["395 tests"] }, { id: "B", milestone: "M_1", after: [], steps: ["`x`"] }]));
  assert.equal(RULES.includes("unit-collision"), true);
  assert.equal(RULES.includes("unreproducible"), true);
  assert.match(n, /unreproducible: 1/);
  assert.match(n, /unit-collision: 2/);
  // the header: line 1 to the first import, and the step lint's comment to RULES (the sed ranges the bash check read)
  const L = readFileSync(fileURLToPath(new URL("../../lib/features.mjs", import.meta.url)), "utf8").split("\n");
  const imp = L.findIndex((l, i) => i > 0 && /^import/.test(l)), p = L.findIndex(l => /^ \* Pure: the step lint/.test(l));
  const h = [...L.slice(0, imp + 1), ...L.slice(p, L.findIndex((l, i) => i > p && /^export const RULES/.test(l)) + 1)].join("\n");
  assert.ok(imp > 0 && p > imp, "the header ranges are found");
  assert.match(h, /unit-collision[\s\S]*unit-collision/);
  assert.match(h, /unreproducible[\s\S]*unreproducible/);
});
