// lib/memreview.mjs: the memory reviewer's input (the ops that would land, from one apply result).   node --test tests/unit/memreview.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { capReading, input, main } from "../../lib/memreview.mjs";

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
