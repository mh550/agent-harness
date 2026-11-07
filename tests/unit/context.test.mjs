// lib/context.mjs: the context bundle's glossary section, from the gatherer's markdown and each run's docs.   node --test tests/unit/context.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mergeResults, runSection } from "../../lib/context.mjs";

const MD = [
  "# Context · 2026-11-07 17:00", "", "## Runs", "",
  "### a (proj)", "", "- ended: done", "", "#### needs", "~~~", "D24 waits", "~~~", "", "#### INBOX.md", "~~~", "### B: a question", "", "## Answers", "~~~", "",
  "### b (proj2)", "", "- ended: blocked on C", "",
  "## Retro backlog (ledger/retro-backlog.jsonl)", "", "~~~", "M9 elsewhere", "~~~", "",
].join("\n");

test("context.mjs: runSection cuts one run's section from the gatherer's markdown", () => {
  const a = runSection(MD, "a", "proj");
  assert.equal(a.split("\n")[0], "### a (proj)");
  assert.ok(a.includes("D24 waits") && a.includes("## Answers") && !a.includes("### b") && !a.includes("blocked on C"));
  const b = runSection(MD, "b", "proj2");
  assert.ok(b.startsWith("### b (proj2)") && b.includes("blocked on C") && !b.includes("M9 elsewhere") && !b.includes("Retro backlog"));
  assert.equal(runSection(MD, "c", "proj"), "");
  assert.equal(runSection(MD, "a", "proj2"), "");   // the project is part of the heading
  // a fenced part cut mid-fence (capped's head or tail) leaves an odd ~~~: the next run's heading still ends the section
  const odd = MD.replace("#### INBOX.md\n~~~\n### B: a question\n\n## Answers\n~~~", "#### INBOX.md\n~~~\n~~~\nanswered\n~~~");
  assert.equal(odd.split("\n").filter(l => l === "~~~").length % 2, 1);
  const ends = ["### a (proj)", "### b (proj2)", "## Retro backlog (ledger/retro-backlog.jsonl)"];
  const a2 = runSection(odd, "a", "proj", ends), b2 = runSection(odd, "b", "proj2", ends);
  assert.ok(a2.includes("D24 waits") && !a2.includes("### b") && b2.includes("blocked on C") && !b2.includes("M9 elsewhere"));
});

test("context.mjs: mergeResults keeps each source once and drops an id another run resolved", () => {
  const e = (id, source, kind = "decision") => ({ id, kind, text: `${id} text`, source });
  const m = mergeResults([
    { glossary: [e("D24", "/p/docs/decisions.md:9"), e("M8", "/p/README.md:1", "milestone")], unresolved: ["Q99", "N2-01"] },
    { glossary: [e("D24", "/p/docs/decisions.md:9"), e("D24", "/q/docs/decisions.md:3"), e("N2-01", "/q/fl.json:4", "feature")], unresolved: ["Q99", "Z7"] },
  ]);
  assert.equal(m.glossary.map(x => `${x.id}@${x.source}`).join(" "), "D24@/p/docs/decisions.md:9 M8@/p/README.md:1 D24@/q/docs/decisions.md:3 N2-01@/q/fl.json:4");
  assert.equal(m.unresolved.join(" "), "Q99 Z7");
  assert.equal(JSON.stringify(mergeResults([])), JSON.stringify({ glossary: [], unresolved: [] }));
});
