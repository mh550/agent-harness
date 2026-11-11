// lib/memreview.mjs: the memory reviewer's input (the ops that would land), its file validated, its verdicts and the ## Review section.   node --test tests/unit/memreview.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { capReading, card, heldFailed, input, line, main, render, renderNone, title, validate, verdicts } from "../../lib/memreview.mjs";

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

// ---- the memory event's object and title (docs/specs/2026-11-10-review-surface.md §V1-01); the three files are a stub
// run's record (memory-review.sh's run helper, STUB_CURATOR_OPS=evict-two STUB_MEMORY_REVIEW=evict-fails, MEMORY_POLICY=pr) ----
const FX = n => new URL(`../fixtures/memory/event-${n}.json`, import.meta.url);
const fx = n => JSON.parse(readFileSync(FX(n), "utf8"));

test("memreview.mjs: card is the memory event's object: each failed op's id, its input section, q and reason without (q<n>), both PRs, open, merged when merged_by is driver", () => {
  const c = card(fx("verdicts"), fx("memory"), fx("input"), "pr");
  assert.equal(Object.keys(c).join(" "), "pr rules_pr policy reviewed held failed failures state review");
  assert.equal(JSON.stringify([c.pr, c.rules_pr, c.policy, c.reviewed, c.held, c.failed, c.state, c.review]),
    '["https://example.test/pr/3","https://example.test/pr/4","pr",3,2,1,"open","ok"]');
  assert.equal(c.failures.length, 1);
  const [f] = c.failures;
  assert.equal(Object.keys(f).join(" "), "id section q reason");
  assert.equal(JSON.stringify([f.id, f.section, f.q]), '["facts/2","## Gotchas",2]');
  assert.match(f.reason, /^7 files: tests\/checks\/needs-cards\.sh, .*…$/);
  assert.ok(!f.reason.endsWith("(q2)"), f.reason);
  assert.equal(card(fx("verdicts"), { ...fx("memory"), merged_by: "driver" }, fx("input"), "auto").state, "merged");
  // a thin or unreviewed op has no q; an id the input lacks has no section; no PR is null
  const v = { reviewed: 2, held: 0, failed: 2, ops: [{ id: "rules/1", holds: false, reason: "not reviewed", q: null }, { id: "facts/9", holds: false, reason: "review too thin (2 of 4 rows)", q: null }] };
  const t = card(v, { reviewed: 2, held: 0, failed: 2, review: "ok", pr: null, rules_pr: "u" }, fx("input"), "pr");
  assert.equal(JSON.stringify(t.failures), '[{"id":"rules/1","section":"## Code rules","q":null,"reason":"not reviewed"},{"id":"facts/9","section":null,"q":null,"reason":"review too thin (2 of 4 rows)"}]');
  assert.equal(JSON.stringify([t.pr, t.rules_pr]), '[null,"u"]');
});

test("memreview.mjs: card on a review none has no failures and review the why", () => {
  const m = { ...fx("memory"), held: 0, failed: 0, review: "the reviewer failed (exit 124)" };
  const c = card(null, m, fx("input"), "pr");
  assert.equal(JSON.stringify([c.failures, c.review, c.state]), '[[],"the reviewer failed (exit 124)","open"]');
  assert.equal(card(fx("verdicts"), m, fx("input"), "pr").failures.length, 0, "a verdicts file left over is no verdict");
  assert.equal(card(null, { ...fx("memory"), review: "ok" }, [], "pr").review, "no verdicts", "as line says it");
});

test("memreview.mjs: title is [<run>] memory: <held> held · <failed> failed, or review none when review is not ok", () => {
  assert.equal(title(fx("memory"), "r1"), "[r1] memory: 2 held · 1 failed");
  assert.equal(title({ ...fx("memory"), review: "the reviewer hit a limit" }, "r1"), "[r1] memory: review none");
  assert.equal(title(card(fx("verdicts"), fx("memory"), fx("input"), "pr"), "r1"), "[r1] memory: 2 held · 1 failed", "the card's object too");
  assert.equal(title(card(null, fx("memory"), [], "pr"), "r1"), "[r1] memory: review none");
});

test("memreview.mjs: card and title as commands print the object as one JSON line and the title", () => {
  const d = mkdtempSync(join(tmpdir(), "memcard-"));
  try {
    const out = main(["card", FX("verdicts").pathname, FX("memory").pathname, FX("input").pathname, "pr"], { env: {} });
    assert.equal(`${out.rc} ${out.out}`, `0 ${JSON.stringify(card(fx("verdicts"), fx("memory"), fx("input"), "pr"))}\n`);
    const none = main(["card", join(d, "none.json"), FX("memory").pathname, FX("input").pathname, "auto"], { env: {} });
    assert.equal(none.rc, 0); assert.equal(JSON.parse(none.out).policy, "auto");
    assert.equal(JSON.parse(none.out).failures.length, 0, "no verdicts file: no failures");
    writeFileSync(join(d, "c.json"), out.out);
    assert.equal(main(["title", join(d, "c.json"), "r1"], { env: {} }).out, "[r1] memory: 2 held · 1 failed\n");
    assert.equal(main(["card", FX("verdicts").pathname], { env: {} }).rc, 2);
  } finally { rmSync(d, { recursive: true, force: true }); }
});
