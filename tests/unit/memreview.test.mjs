// lib/memreview.mjs: the memory reviewer's input (the ops that would land), its file validated, its verdicts and the ## Review section.   node --test tests/unit/memreview.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { capReading, heldFailed, input, line, main, render, renderNone, validate, verdicts } from "../../lib/memreview.mjs";

const F = (text, o) => ({ op: "add", file: "CLAUDE.md", section: "## Gotchas", text, tier: 1, why: "w", from: "entries.jsonl:2", ...o });
const RESULT = {
  ops: 4, run: "r1", dropped: [], proposed: [{ ...F("p"), section: "## Live system", tier: 3, n: 3 }],
  applied: [F("first fact (r1 2026-11-09)"), F("second fact (r1 2026-11-09)", { op: "add", anchor: "- old line (r0 2026-11-01)", from: "entries.jsonl:3" })],
  rules: [{ ...F("a rule"), section: "## Code rules", tier: 2, n: 2 }],
};
const PATHS = { base: "/s/memory-base", afterFacts: "/s/memory-after-facts", afterRules: "/s/memory-after-rules" };

test("memreview.mjs: input facts/<i> in apply's order then rules/<n> with the result's numbers, each with its paths and the cap reading", () => {
  const caps = { "/s/memory-base/CLAUDE.md": { gotchas: 14, lines: 97 } }, xs = input(RESULT, PATHS, caps);
  assert.equal(xs.map(x => x.id).join(" "), "facts/1 facts/2 rules/2");
  const [a, b, r] = xs;
  assert.equal(a.text, "first fact (r1 2026-11-09)");
  assert.equal(b.anchor, "- old line (r0 2026-11-01)");
  assert.equal(b.from, "entries.jsonl:3");
  for (const k of ["op", "file", "section", "anchor", "text", "why", "from", "base", "after", "cap"]) assert.ok(k in r, `rules/2 has ${k}`);
  assert.equal(a.base, "/s/memory-base/CLAUDE.md");
  assert.equal(a.after, "/s/memory-after-facts/CLAUDE.md");
  assert.equal(r.after, "/s/memory-after-rules/CLAUDE.md");
  assert.equal(r.base, "/s/memory-base/CLAUDE.md", "the rules base defaults to the facts base");
  assert.equal(JSON.stringify(a.cap), '{"gotchas":14,"lines":97}');
  assert.equal(input(RESULT, { ...PATHS, rulesBase: "/s/memory-rules-base" }, caps)[2].base, "/s/memory-rules-base/CLAUDE.md");
});

test("memreview.mjs: input an apply result with empty applied and rules is an empty list (nothing to review)", () => {
  assert.equal(input({ ...RESULT, applied: [], rules: [] }, PATHS).length, 0);
  assert.equal(input({}, PATHS).length, 0);
});

test("memreview.mjs: capReading Gotchas entries and lines as the gate counts them; no file is null", () => {
  const md = ["# P", "", "## Gotchas", "", "<!-- At most 15 lines -->", "- one (r 2026-11-01)", "- two (r 2026-11-01)", "", "## Other", "", "- x", ""].join("\n");
  assert.equal(JSON.stringify(capReading(md)), '{"gotchas":2,"lines":11}');
  assert.equal(capReading(null), null);
});

test("memreview.mjs: input as a command prints the list as one JSON document and exits 0", () => {
  const d = mkdtempSync(join(tmpdir(), "memreview-"));
  try {
    for (const x of ["base", "af", "ar"]) mkdirSync(join(d, x));
    writeFileSync(join(d, "base", "CLAUDE.md"), "# P\n\n## Gotchas\n\n- one (r 2026-11-01)\n");
    writeFileSync(join(d, "r.json"), JSON.stringify(RESULT));
    const { rc, out } = main(["input", join(d, "r.json"), join(d, "base"), join(d, "af"), join(d, "ar")], { env: {} });
    assert.equal(rc, 0);
    const xs = JSON.parse(out);
    assert.equal(xs.map(x => x.id).join(" "), "facts/1 facts/2 rules/2");
    assert.equal(xs[0].base, join(d, "base", "CLAUDE.md"));
    assert.equal(JSON.stringify(xs[0].cap), '{"gotchas":1,"lines":5}');
    assert.equal(main(["input", join(d, "r.json")], { env: {} }).rc, 2, "a missing directory is the usage");
  } finally { rmSync(d, { recursive: true, force: true }); }
});

const ITEMS = [{ id: "facts/1" }, { id: "facts/2" }, { id: "rules/3" }];
const row = (id, q, o) => ({ id, q, ran: `q${q} of ${id}`, saw: "it holds", holds: true, ...o });
const four = id => [1, 2, 3, 4].map(q => row(id, q));
const REVIEW = { rows: [...four("facts/1"), ...four("facts/2"), ...four("rules/3")], summary: "s" };

test("memreview.mjs: validate passes four rows per item and refuses, naming the row, an unknown id, a q of 5, a doubled (id, q), a non-boolean holds and too many rows", () => {
  assert.equal(validate(REVIEW, ITEMS), null);
  const bad = (rows, k) => validate({ rows }, ITEMS) ?? "", rs = REVIEW.rows;
  assert.equal(bad([...rs.slice(0, 11), row("facts/9", 4)]), 'row 12: id "facts/9" is not in the input');
  assert.equal(bad([row("facts/1", 5)]), "row 1: q 5 is not 1 to 4");
  assert.equal(bad([row("facts/1", 1), row("facts/1", 1)]), "row 2: (facts/1, q1) twice");
  assert.equal(bad([row("facts/1", 1, { holds: "yes" })]), "row 1: holds is not a boolean");
  assert.equal(bad([...rs, row("facts/1", 1)]), "13 rows, at most 12 (4 per item)");
  assert.match(validate("{not json", ITEMS), /^not JSON/);
  assert.equal(validate({ rows: {} }, ITEMS), "rows is not a list");
});

test("memreview.mjs: verdicts holds an op with four holding rows and fails one on its first failing row's saw (q named), one with three rows as thin and one with none as not reviewed", () => {
  const rows = [...four("facts/1"), ...four("facts/2").map(r => (r.q >= 2 ? { ...r, holds: false, saw: `7 files (q${r.q} saw)` } : r)), ...four("rules/3").slice(0, 3)];
  const v = verdicts({ rows }, [...ITEMS, { id: "rules/4" }]);
  assert.equal(JSON.stringify([v.reviewed, v.held, v.failed]), "[4,1,3]");
  assert.equal(JSON.stringify(v.ops.map(o => [o.id, o.holds, o.reason])),
    JSON.stringify([["facts/1", true, null], ["facts/2", false, "7 files (q2 saw) (q2)"], ["rules/3", false, "review too thin (3 of 4 rows)"], ["rules/4", false, "not reviewed"]]));
  assert.equal(JSON.stringify(v.ops.map(o => o.q)), "[null,2,null,null]", "the failing row's question, for the ledger's failed_ids");
});

test("memreview.mjs: render the ## Review section, one line per op and the verify's five-column table; none: <why> without a review", () => {
  const rows = REVIEW.rows.map(r => (r.id === "facts/2" && r.q === 2 ? { ...r, holds: false, saw: "7 files: a | b" } : r));
  const t = render(verdicts({ rows }, ITEMS), { rows }), ls = t.split("\n");
  assert.equal(ls[0], "## Review");
  assert.ok(ls.includes("- facts/1 holds") && ls.includes("- facts/2 **fails**: 7 files: a | b (q2)") && ls.includes("- rules/3 holds"), t);
  const h = ls.indexOf("| Op | Q | What you ran or read | What you saw | Holds |");
  assert.ok(h > ls.indexOf("- rules/3 holds") && ls[h + 1] === "|---|---|---|---|---|", t);
  assert.equal(ls.filter(l => l.startsWith("| facts/") || l.startsWith("| rules/")).length, 12);
  assert.ok(ls.includes("| facts/2 | 2 | q2 of facts/2 | 7 files: a \\| b | no |"), t);
  assert.equal(renderNone("the reviewer hit a limit"), "## Review\n\nnone: the reviewer hit a limit\n");
});

test("memreview.mjs: validate, verdicts and render as commands", () => {
  const d = mkdtempSync(join(tmpdir(), "memreview-"));
  try {
    const f = (n, x) => { writeFileSync(join(d, n), typeof x === "string" ? x : JSON.stringify(x)); return join(d, n); };
    const i = f("i.json", ITEMS), r = f("r.json", REVIEW), b = f("b.json", "{not json");
    const ok = main(["validate", r, i], { env: {} }), no = main(["validate", b, i], { env: {} });
    assert.equal(`${ok.rc} ${ok.out.trim()}`, "0 ok");
    assert.equal(no.rc, 1); assert.match(no.out, /^not JSON/);
    const v = main(["verdicts", r, i], { env: {} });
    assert.equal(v.rc, 0); assert.equal(v.out.trim().split("\n").length, 1);
    assert.equal(JSON.parse(v.out).held, 3);
    const out = main(["render", f("v.json", v.out), r], { env: {} });
    assert.equal(out.rc, 0); assert.ok(out.out.startsWith("## Review\n"));
    assert.equal(main(["render", "--none", "nothing to review"], { env: {} }).out, "## Review\n\nnone: nothing to review\n");
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("memreview.mjs: line is the one memory: line of the note and the card, facts held and failed with each fail's id, reason and question, rules held, both PRs; none: its why; nothing unreviewed", () => {
  const rows = [...four("facts/1"), ...four("facts/2").map(r => (r.q === 2 ? { ...r, holds: false, saw: "7 files match `(─)`" } : r)), ...four("rules/3")];
  const v = verdicts({ rows }, ITEMS), m = { reviewed: 3, held: 2, failed: 1, review: "ok", pr: "https://example.test/pr/1", rules_pr: "https://example.test/pr/2" };
  assert.equal(line(v, m), "memory: facts 1 held · 1 failed (facts/2: 7 files match `(─)`, q2) · rules 1 held · PR https://example.test/pr/1 · rules PR https://example.test/pr/2");
  const all = verdicts({ rows: [...four("facts/1"), ...four("facts/2"), ...four("rules/3")] }, ITEMS);
  assert.equal(line(all, { ...m, rules_pr: null }), "memory: facts 2 held · 0 failed · rules 1 held · PR https://example.test/pr/1 · rules PR none");
  // a rule that fails names its fail; a thin op has no question
  const thin = verdicts({ rows: [...four("facts/1"), ...four("facts/2").slice(0, 2), ...four("rules/3").map(r => (r.q === 4 ? { ...r, holds: false, saw: "declined by Michael (old/1)" } : r))] }, ITEMS);
  assert.equal(line(thin, m), "memory: facts 1 held · 1 failed (facts/2: review too thin (2 of 4 rows)) · rules 0 held · 1 failed (rules/3: declined by Michael (old/1), q4) · PR https://example.test/pr/1 · rules PR https://example.test/pr/2");
  assert.equal(line(null, { ...m, review: "the reviewer hit a limit" }), "memory: review none (the reviewer hit a limit) · PR https://example.test/pr/1 · rules PR https://example.test/pr/2");
  assert.equal(line(null, { reviewed: 0, review: "nothing to review", pr: null }), "", "nothing to review (memory_json's shape)");
  assert.equal(line(null, { reviewed: 0, review: "the review input failed (see run.log)", pr: "u" }), "memory: review none (the review input failed (see run.log)) · PR u · rules PR none", "every op landed unreviewed (R2's review, M5)");
  assert.equal(line(null, { applied: 2, pr: "u" }), "", "a memory.json before the review");
  assert.equal(heldFailed(3, 0), "3 held · 0 failed");
  const d = mkdtempSync(join(tmpdir(), "memline-"));
  try {
    writeFileSync(join(d, "v.json"), JSON.stringify(v)); writeFileSync(join(d, "m.json"), JSON.stringify(m));
    const out = main(["line", join(d, "v.json"), join(d, "m.json")], { env: {} });
    assert.equal(`${out.rc} ${out.out}`, `0 ${line(v, m)}\n`);
    writeFileSync(join(d, "n.json"), JSON.stringify({ ...m, review: "the reviewer failed (exit 124)" }));
    assert.equal(main(["line", join(d, "none.json"), join(d, "n.json")], { env: {} }).out, `${line(null, { ...m, review: "the reviewer failed (exit 124)" })}\n`, "no verdicts file");
    writeFileSync(join(d, "o.json"), JSON.stringify({ applied: 1 }));
    assert.deepEqual(main(["line", join(d, "none.json"), join(d, "o.json")], { env: {} }), { rc: 0, out: "" });
  } finally { rmSync(d, { recursive: true, force: true }); }
});
