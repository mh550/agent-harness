// lib/context.mjs: the context bundle's glossary section, from the gatherer's markdown and each run's docs.   node --test tests/unit/context.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { contextJson, mergeResults, openQuestions, parkedItems, runEntry, runSection, staleBundles } from "../../lib/context.mjs";

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

test("context.mjs: staleBundles keeps a dir with any file newer than 30 days", () => {
  const day = 86400000, now = Date.parse("2026-11-07T12:00:00Z");
  const dirs = [{ dir: "old", newestMs: now - 31 * day }, { dir: "recent", newestMs: now - day }, { dir: "edge", newestMs: now - 30 * day + 1000 },
    { dir: "older", newestMs: now - 400 * day }];
  assert.equal(staleBundles(dirs, now).join(" "), "old older");
  assert.equal(staleBundles(dirs, now, 1).join(" "), "old edge older");   // exactly a day old is not newer than a day
  assert.equal(staleBundles([], now).length, 0);
});

const INBOX = ["status: run", "", "<!-- steering: write under Answers", "### not an ask", "-->", "", "### B: set the gatus vars, then answer", "",
  "Pick a  topic,", "then  answer.", "", "### C: which port?", "Files: /x", "", "## Answers", "", "### 2026-11-07 12:00 (local)", "gatus vars set", ""].join("\n");

test("context.mjs: open questions are the INBOX's open asks, then the open question items", () => {
  const q = (text, reason = "question", extra = {}) => ({ reason, resolved_at: null, card: { question: { text } }, ...extra });
  const needs = [q("C: which port? Files: /x"), q("Should Y default to off?"), q("a parked one", "parked"), q("answered", "question", { resolved_at: "x" })];
  assert.equal(JSON.stringify(openQuestions(INBOX, needs)),
    JSON.stringify(["B: set the gatus vars, then answer Pick a topic, then answer.", "C: which port? Files: /x", "Should Y default to off?"]));
  assert.equal(openQuestions("", []).length, 0);
  // a heading in a fence and an answer block above Answers are no asks
  const extra = INBOX.replace("## Answers", "```\n### not an ask either\n```\n### 2026-11-07 11:00 (local)\nanswered early\n\n## Answers");
  assert.equal(openQuestions(extra, []).length, 2);
  assert.equal(openQuestions(null, [q("x".repeat(700))])[0].length, 600);
  assert.equal(openQuestions("", Array.from({ length: 20 }, (_, i) => q(`q${i}`))).length, 12);
});

test("context.mjs: context.json's keys are the spec's, in order", () => {
  const row = { state: "/s/proj/r1", run: "r1", project: "proj", ended: "waiting on Michael: B", running: "0", features: "1/3 passing",
    record: "/w/r1/.harness/runs/r1", worktree: "/w/r1", docs: "/w/r1", needs: "/tmp/n.json" };
  const needs = [{ reason: "parked", feature: "B", resolved_at: null, card: { headline: "B parked: set the gatus vars", question: { line: 7, text: "### B: set the gatus vars, then answer" } } }];
  const run = runEntry(row, { summary: null, needs, parked: { B: { why: "set the gatus vars\nand the token" } }, inbox: INBOX });
  const j = contextJson({ id: "abcdef12", generatedAt: "2026-11-07T12:00:00.000Z", since: "" }, [run],
    { glossary: [{ id: "D24", kind: "decision", text: "t", source: "/p:1" }], unresolved: ["Q99"] });
  assert.equal(Object.keys(j).join(" "), "v id generated_at scope runs glossary unresolved");
  assert.equal(Object.keys(j.scope).join(" "), "runs since");
  assert.equal(Object.keys(j.runs[0]).join(" "), "run project ended running features paths summary parked open_questions");
  assert.equal(Object.keys(j.runs[0].paths).join(" "), "record worktree state report inbox progress");
  assert.equal(Object.keys(j.runs[0].parked[0]).join(" "), "feature why question");
  assert.equal(Object.keys(j.glossary[0]).join(" "), "id kind text source");
  assert.equal(JSON.stringify([j.v, j.scope.runs, j.scope.since, j.runs[0].running, j.runs[0].paths.report, j.runs[0].paths.inbox]),
    JSON.stringify([1, ["r1"], null, false, "/w/r1/.harness/runs/r1/report.md", "/w/r1/.harness/runs/r1/INBOX.md"]));
  assert.equal(JSON.stringify(j.runs[0].parked[0]), JSON.stringify({ feature: "B", why: "set the gatus vars and the token",
    question: "B: set the gatus vars, then answer Pick a topic, then answer." }));
  // no parked.json: the headline's why; no INBOX block at its line: the card's text
  assert.equal(JSON.stringify(parkedItems(needs, null, "")), JSON.stringify([{ feature: "B", why: "set the gatus vars", question: "B: set the gatus vars, then answer" }]));
  // the line moved (the INBOX changed since the item opened): the ask that names the feature, never another's
  const moved = [{ ...needs[0], card: { ...needs[0].card, question: { line: 12, text: "### B: set the gatus vars, then answer" } } }];
  assert.equal(parkedItems(moved, null, INBOX)[0].question, "B: set the gatus vars, then answer Pick a topic, then answer.");
  assert.equal(parkedItems([{ ...moved[0], feature: "Z" }], null, INBOX)[0].question, "B: set the gatus vars, then answer");
  assert.equal(contextJson({ id: "abcdef12", generatedAt: "x", since: "2026-11-07 10:00:00" }, [], { glossary: [], unresolved: [] }).scope.since, "2026-11-07 10:00:00");
});
