// lib/memory.mjs: Michael's answers to a run's numbered rules and proposals (the rows, the replace, the tally, the
// proposals view) and harness memory's listing with them.   node --test tests/unit/memory.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { answerRow, answersTally, items, main, proposalsView, upsert } from "../../lib/memory.mjs";
import { itemKey } from "../../lib/curator.mjs";

const RULE = { op: "add", file: "CLAUDE.md", section: "## Code rules", text: "stub proposal: run the stub suite before each commit", tier: 2, why: "w", from: "entries.jsonl:2", n: 1 };
const PROP = { op: "add", file: "CLAUDE.md", section: "## Live system", text: "deploy only through scripts/deploy.sh from git", tier: 3, why: "w", from: "entries.jsonl:3", n: 2 };
const RESULT = { ops: 3, applied: [{ op: "add", file: "CLAUDE.md", section: "## Gotchas", text: "a fact (mp 2026-11-08)", tier: 1 }], rules: [RULE], proposed: [PROP], dropped: [], run: "mp" };
const AT = "2026-11-08T12:00:00.000Z";

test("memory.mjs: answerRow is {run, project, n, tier, verdict, why, file, section, text, key, at} from the result's item", () => {
  const { row } = answerRow(RESULT, { run: "mp", project: "proj", n: 1, verdict: "declined", why: "the suite runs itself", at: AT });
  assert.equal(Object.keys(row).join(), "run,project,n,tier,verdict,why,file,section,text,key,at");
  assert.equal(JSON.stringify(row), JSON.stringify({ run: "mp", project: "proj", n: 1, tier: 2, verdict: "declined", why: "the suite runs itself", file: "CLAUDE.md",
    section: "## Code rules", text: RULE.text, key: itemKey(RULE), at: AT }));
  assert.equal(answerRow(RESULT, { run: "mp", project: "proj", n: 2, verdict: "accepted", why: "x", at: AT }).row.tier, 3);
  // an <n> the run has not (tier 1 is never numbered), and a why that is not one line of at most 300 characters
  assert.equal(answerRow(RESULT, { run: "mp", project: "proj", n: 9, verdict: "accepted", why: "x", at: AT }).why, "mp has no item 9 (its rules and proposals: mp/1 to mp/2; tier 1 is not numbered)");
  assert.equal(answerRow({ ...RESULT, rules: [], proposed: [] }, { run: "mp", project: "proj", n: 1, verdict: "accepted", why: "x", at: AT }).why, "mp has no item 1 (it has no numbered rules or proposals)");
  assert.equal(answerRow(RESULT, { run: "mp", project: "proj", n: 1, verdict: "declined", why: "a\nb", at: AT }).why, "--why must be one non-blank line of at most 300 characters");
  assert.equal(answerRow(RESULT, { run: "mp", project: "proj", n: 1, verdict: "declined", why: "x".repeat(301), at: AT }).why, "--why must be one non-blank line of at most 300 characters");
  assert.equal(items(RESULT).map(i => `${i.n}:${i.tier}`).join(), "1:2,2:3");
});

test("memory.mjs: a row replaces an earlier one for the same <run>/<n>; the answers: tally counts a replaced verdict once", () => {
  const r = (n, verdict, run = "mp") => answerRow(RESULT, { run, project: "proj", n, verdict, why: "x", at: AT }).row;
  let rows = upsert([], r(1, "declined"));
  rows = upsert(rows, r(2, "accepted"));
  rows = upsert(rows, r(1, "accepted"));
  assert.equal(rows.map(x => `${x.n}:${x.verdict}`).join(), "2:accepted,1:accepted");
  assert.equal(answersTally(rows), "answers: accepted 2 · declined 0");
  // a file appended by hand twice for one item: its last row alone counts
  assert.equal(answersTally([r(1, "declined"), r(1, "accepted"), r(2, "declined")]), "answers: accepted 1 · declined 1");
  assert.equal(answersTally([r(1, "declined"), r(1, "declined", "other")], ["mp"]), "answers: accepted 0 · declined 1");   // over the shown runs
  assert.equal(answersTally([]), "answers: accepted 0 · declined 0");
});

test("memory.mjs: proposalsView lists each numbered item with its tier, section and text, and its verdict", () => {
  const rows = [answerRow(RESULT, { run: "mp", project: "proj", n: 1, verdict: "declined", why: "the suite runs itself", at: AT }).row];
  assert.equal(proposalsView(RESULT, "mp", rows).join("\n"), [`mp/1 · rules · CLAUDE.md · ## Code rules · ${RULE.text} · declined: the suite runs itself`,
    `mp/2 · proposal · CLAUDE.md · ## Live system · ${PROP.text}`].join("\n"));
  assert.equal(proposalsView({ ...RESULT, rules: [], proposed: [] }, "mp", []).join("\n"), "mp: no numbered rules or proposals");
  assert.equal(proposalsView({ ...RESULT, rules: [{ ...RULE, op: "delete", anchor: "bash only", text: undefined }], proposed: [] }, "mp", []).join("\n"), "mp/1 · rules · CLAUDE.md · ## Code rules · delete: bash only");
});

test("memory.mjs main: answer appends the row (an earlier one for that <run>/<n> replaced) and prints its line; a bad <n> or a torn line in the file is one line, exit 1", () => {
  const d = mkdtempSync(join(tmpdir(), "memory-"));
  try {
    const res = join(d, "memory-result.json"), file = join(d, "memory-answers.jsonl");
    writeFileSync(res, JSON.stringify(RESULT));
    const one = main(["answer", file, res, "proj", "mp", "1", "declined", "the suite runs itself"], { env: {} });
    assert.equal(`${one.rc} ${one.out}`, `0 memory: mp/1 declined · ## Code rules · ${RULE.text}\n`);
    main(["answer", file, res, "proj", "mp", "1", "accepted", "fine"], { env: {} });
    const rows = readFileSync(file, "utf8").trim().split("\n").map(l => JSON.parse(l));
    assert.equal(rows.map(x => `${x.n}:${x.verdict}:${x.why}`).join(), "1:accepted:fine");
    const bad = main(["answer", file, res, "proj", "mp", "9", "accepted", "x"], { env: {} });
    assert.equal(`${bad.rc} ${bad.out}`, "1 mp has no item 9 (its rules and proposals: mp/1 to mp/2; tier 1 is not numbered)\n");
    assert.equal(main(["proposals", res, "mp", join(d, "missing.jsonl")], { env: {} }).out.split("\n").length, 3);
    // a line that is no JSON row (a hand edit gone wrong) is never erased by the rewrite: one line, exit 1, the file as it was
    writeFileSync(file, `{"run":"mp",\n${readFileSync(file, "utf8")}`);
    const before = readFileSync(file, "utf8"), torn = main(["answer", file, res, "proj", "mp", "2", "declined", "y"], { env: {} });
    assert.equal(`${torn.rc} ${torn.out}`, `1 ${file} line 1 is not a JSON row: fix or remove it by hand first\n`);
    assert.equal(readFileSync(file, "utf8") === before, true);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("memory.mjs: a continue's renumbered item is another item: its answer never replaces the first one's, nor shows its verdict", () => {
  const first = answerRow(RESULT, { run: "mp", project: "proj", n: 1, verdict: "declined", why: "no", at: AT }).row;
  const next = { ...RESULT, rules: [{ ...RULE, text: "another rule entirely, in other words than the first", n: 1 }], proposed: [] };   // the continue's mp/1
  assert.equal(proposalsView(next, "mp", [first]).join("\n"), "mp/1 · rules · CLAUDE.md · ## Code rules · another rule entirely, in other words than the first");
  const rows = upsert([first], answerRow(next, { run: "mp", project: "proj", n: 1, verdict: "accepted", why: "ok", at: AT }).row);
  assert.equal(rows.map(r => `${r.n}:${r.verdict}`).join(), "1:declined,1:accepted");
  assert.equal(answersTally(rows), "answers: accepted 1 · declined 1");
});
