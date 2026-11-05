// lib/features.mjs: the scheduler's deps and the step lint (its rules and its note).   node --test tests/unit/features.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, writeFileSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { sameAsCli } from "./cli-same.mjs";
import { deps, lint, lintNote, RULES, fixFeature, kindOf, repairList, schedule } from "../../lib/features.mjs";

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

// ---- fix rounds (decisions/2026-11-04-fix-rounds): the fix feature a red verify appends ----
const FXL = () => [{ id: "A", milestone: "M1", kind: "build", description: "a", steps: ["`x` exits 0"], passes: true },
  { id: "B", milestone: "M1", kind: "build", description: "b", steps: ["`y` exits 0"], passes: true },
  { id: "C", milestone: "M2", kind: "build", description: "c", steps: ["`z` exits 0"], after: ["M1"], passes: false }];
const FXO = { milestone: "M1", round: 1, issue: "all", names: ["t1"], files: ["t1"], out: ".harness/runs/r/fix/M1-1.out", check: "$HARNESS_CHECK", model: "opus" };

test("fix rounds: fixFeature builds <m>-fix<r> after the milestone's last feature, kind fix, issue, round, the names, files and out, three steps, not passing", () => {
  const f = fixFeature(FXL(), FXO);
  assert.deepEqual(f, { id: "M1-fix1", milestone: "M1", kind: "fix", issue: "all", round: 1, after: ["B"], model: "opus",
    fix_names: ["t1"], fix_files: ["t1"], fix_out: ".harness/runs/r/fix/M1-1.out",
    description: "fix round 1 of M1: the full suite is red on the verified tree (1 failing: t1)",
    steps: ["`$HARNESS_CHECK t1` exits 0 (the HARNESS_FAILED files of .harness/runs/r/fix/M1-1.out)", "`$HARNESS_CHECK --fast` exits 0",
      "`$HARNESS_CHECK` exits 0 (the full suite; the harness runs it at the verify)"], passes: false });
  assert.equal(Object.keys(f).join(), "id,milestone,kind,issue,round,after,model,fix_names,fix_files,fix_out,description,steps,passes");
  // round 2 waits on round 1's feature (the milestone's last by then); no model given: no key (F next falls back)
  const l2 = [...FXL(), { ...f, passes: true }], g = fixFeature(l2, { ...FXO, round: 2, names: ["t3"], files: ["t3", "t4"], out: "o", model: undefined });
  assert.deepEqual([g.id, g.after, g.round, "model" in g, g.steps[0]], ["M1-fix2", ["M1-fix1"], 2, false, "`$HARNESS_CHECK t3 t4` exits 0 (the HARNESS_FAILED files of o)"]);
});

test("fix rounds: the description names up to five failing checks, then +n; a red with no files is the whole suite", () => {
  const d = n => fixFeature(FXL(), { ...FXO, names: Array.from({ length: n }, (_, i) => `n${i + 1}`) }).description;
  assert.equal(d(5), "fix round 1 of M1: the full suite is red on the verified tree (5 failing: n1, n2, n3, n4, n5)");
  assert.equal(d(7), "fix round 1 of M1: the full suite is red on the verified tree (7 failing: n1, n2, n3, n4, n5 +2)");
  const w = fixFeature(FXL(), { ...FXO, files: [] });
  assert.deepEqual(w.fix_files, []);
  assert.equal(w.steps[0], "`$HARNESS_CHECK` exits 0 (the whole suite: .harness/runs/r/fix/M1-1.out has no HARNESS_FAILED line)");
  assert.equal(w.steps.length, 3);
});

test("fix rounds: the step lint prints nothing for a fix feature, kindOf returns fix, and it is no build or review to the review rules", () => {
  const l = [...FXL(), fixFeature(FXL(), FXO)];
  assert.deepEqual(lint(l), []);
  assert.equal(kindOf(l.at(-1)), "fix");
  assert.deepEqual(lint([...l, fixFeature(l, { ...FXO, round: 2, files: [] })]), []);   // the whole-suite steps too
});

test("fix rounds: schedule offers the fix feature in its lane once the milestone's last feature passes, and nothing waits on it", () => {
  const l = [...FXL(), fixFeature(FXL(), FXO)];
  assert.equal(schedule(l, {}, 2, new Set(), "M1").next.id, "M1-fix1");
  assert.equal(schedule(l, {}, 2, new Set(), "M2").next.id, "C");   // C's "after M1" is the M1 features before C: the fix is after it
  assert.deepEqual(deps(l, l[2]), ["A", "B"]);
});

test("fix rounds: repairList with the appended feature in before keeps it, and reverts a session that removes or edits it", () => {
  const before = { run: "r", features: [...FXL(), fixFeature(FXL(), FXO)] }, copy = () => JSON.parse(JSON.stringify(before));
  const passed = copy(); passed.features[3].passes = true;
  const ok = repairList(before, passed, f => f.id === "M1-fix1");
  assert.deepEqual([ok.reverted, ok.list.features[3].passes, ok.list.features.length], [[], true, 4]);
  const gone = copy(); gone.features.pop();
  assert.deepEqual(repairList(before, gone, f => f.id === "M1-fix1").reverted, ["M1-fix1: removed"]);
  const easier = copy(); easier.features[3].fix_files = [];
  const r = repairList(before, easier, f => f.id === "M1-fix1");
  assert.deepEqual([r.reverted, r.list.features[3].fix_files], [["M1-fix1: edited"], ["t1"]]);
});

test("fix rounds: the CLI fix-add appends the feature to the list file and prints its id and the failing words; a second add of the id is refused", () => {
  const d = mkdtempSync(join(tmpdir(), "fx-")), p = join(d, "feature_list.json"), F = fileURLToPath(new URL("../../lib/features.mjs", import.meta.url));
  const run = (...a) => execFileSync(process.execPath, [F, "fix-add", p, ...a], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  try {
    writeFileSync(p, JSON.stringify({ run: "r", features: FXL() }));
    assert.equal(run("M1", "1", "all", "t1", "needs card (x): y", "--", "t1", "59-needs-cards", "--", ".harness/runs/r/fix/M1-1.out", "$HARNESS_CHECK", "opus"), "M1-fix1\t2 failing: t1, needs card (x): y\n");
    const l = JSON.parse(readFileSync(p, "utf8"));
    assert.equal(l.run, "r");
    assert.deepEqual(l.features.map(f => f.id), ["A", "B", "C", "M1-fix1"]);
    assert.deepEqual(l.features[3], fixFeature(FXL(), { ...FXO, names: ["t1", "needs card (x): y"], files: ["t1", "59-needs-cards"] }));
    assert.throws(() => run("M1", "1", "all", "t1", "--", "t1", "--", "o", "$HARNESS_CHECK"), /M1-fix1 is in the list already/);
    // no files (the whole suite) and no model
    assert.equal(run("M1", "2", "all", "whole suite", "--", "--", "o2", "$HARNESS_CHECK"), "M1-fix2\t1 failing: whole suite\n");
    const g = JSON.parse(readFileSync(p, "utf8")).features[4];
    assert.deepEqual([g.fix_files, g.after, "model" in g], [[], ["M1-fix1"], false]);
    assert.throws(() => run("M9", "1", "all", "t1", "--", "t1", "--", "o", "$HARNESS_CHECK"), /no feature of milestone M9/);
    assert.throws(() => run("M1", "3", "all", "t1", "--", "t1"), /usage: features\.mjs fix-add/);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

// ---- main(argv, io): the CLI's bytes and exit code (decisions/2026-11-03-resident-helper) ----
const inList = async fn => { const d = mkdtempSync(join(tmpdir(), "fm-")); try { return await fn(d); } finally { rmSync(d, { recursive: true, force: true }); } };
const twoFeatures = d => {
  const list = join(d, "feature_list.json");
  writeFileSync(list, JSON.stringify({ features: [
    { id: "A1", milestone: "A", description: "one", steps: ["s"], passes: true, kind: "build", depends_on: null },
    { id: "A2", milestone: "A", description: "two", steps: ["s"], passes: false, kind: "build", depends_on: null },
    { id: "B1", milestone: "B", description: "three", steps: ["s"], passes: false, kind: "build", depends_on: null, after: ["A"] }] }));
  writeFileSync(join(d, "att.json"), JSON.stringify({ A2: 1 }));
  writeFileSync(join(d, "parked.json"), "{}");
  writeFileSync(join(d, "meta.env"), "RUN_ID=r1\n");
  return { list, att: join(d, "att.json"), parked: join(d, "parked.json") };
};

test("features.mjs: main gives the CLI's bytes for summary, next, poll, lanes, model and the read-only questions", () => inList(async d => {
  const { list, att, parked } = twoFeatures(d);
  assert.equal((await sameAsCli("features.mjs", ["summary", list])).out, "1/3 passing\n");
  assert.equal((await sameAsCli("features.mjs", ["next", list, att, "3", parked])).rc, 0);
  assert.ok((await sameAsCli("features.mjs", ["poll", list, att, "3", parked])).out.length > 0, "poll answers");
  assert.ok((await sameAsCli("features.mjs", ["lanes", list, att, "3", parked, d])).out.startsWith("A\t"));
  assert.equal((await sameAsCli("features.mjs", ["model", "sonnet"])).rc, 0);
  for (const a of [["blocked", list, att, "3", parked], ["deps", list, "B"], ["undeclared", list], ["lint", list], ["lint", list, "--note"], ["kind", list, "A1"], ["kind", list, "nope"],
    ["milestones", list], ["evidence", list, "A", join(d, "none")], ["snapshot", list], ["milestone", list, "A2"], ["ids", list, "A"], ["models"], ["parked", parked, list], ["unparks", parked, "h"]])
    await sameAsCli("features.mjs", a);
}));

test("features.mjs: main's exit codes are the CLI's: passes of a feature not passing is 1, of one passing 0, milestone-done, an unknown subcommand 2", () => inList(async d => {
  const { list } = twoFeatures(d);
  assert.equal((await sameAsCli("features.mjs", ["passes", list, "A2"])).rc, 1);
  assert.equal((await sameAsCli("features.mjs", ["passes", list, "A1"])).rc, 0);
  assert.equal((await sameAsCli("features.mjs", ["milestone-done", list, "A"])).rc, 1);
  assert.equal((await sameAsCli("features.mjs", ["nope"])).rc, 2);
}));

test("features.mjs: main throws where the CLI exits 70 (a list that is not JSON)", () => inList(async d => {
  const bad = join(d, "bad.json");
  writeFileSync(bad, "{");
  const { main } = await import("../../lib/features.mjs");
  assert.throws(() => main(["summary", bad], { cwd: d }));
  assert.equal(execFileRc(["summary", bad]), 70);
}));

test("features.mjs: main's writes are the CLI's: bump and pass", () => inList(async d => {
  const { main } = await import("../../lib/features.mjs");
  const lib = fileURLToPath(new URL("../../lib/features.mjs", import.meta.url));
  for (const side of ["m", "c"]) {
    const s = join(d, side); writeFileSync(`${s}.json`, JSON.stringify({ features: [{ id: "A", milestone: "M", steps: [], passes: false }] }));
    writeFileSync(`${s}.att`, "{}");
    if (side === "m") { assert.deepEqual(main(["bump", `${s}.att`, "A"], { cwd: d }), { rc: 0, out: "" }); assert.deepEqual(main(["pass", `${s}.json`, "A"], { cwd: d }), { rc: 0, out: "" }); }
    else { execFileSync(process.execPath, [lib, "bump", `${s}.att`, "A"]); execFileSync(process.execPath, [lib, "pass", `${s}.json`, "A"]); }
  }
  assert.equal(readFileSync(join(d, "m.json"), "utf8"), readFileSync(join(d, "c.json"), "utf8"));
  assert.equal(readFileSync(join(d, "m.att"), "utf8"), readFileSync(join(d, "c.att"), "utf8"));
}));

function execFileRc(argv) {
  try { execFileSync(process.execPath, [fileURLToPath(new URL("../../lib/features.mjs", import.meta.url)), ...argv], { stdio: ["ignore", "pipe", "ignore"] }); return 0; }
  catch (e) { return e.status; }
}
