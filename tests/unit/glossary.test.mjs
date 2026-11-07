// lib/glossary.mjs: feature, milestone and decision IDs found in a text and resolved against a feature list and a project's docs.   node --test tests/unit/glossary.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { cpSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { cli } from "./cli-same.mjs";
import { findIds, fsReader, glossaryMarkdown, knownIds, resolveIds, strip } from "../../lib/glossary.mjs";

// the fixtures: copied from dj-crate-streaming and this repo (tests/fixtures/glossary/README.md)
const FX = fileURLToPath(new URL("../fixtures/glossary/", import.meta.url)), WT = join(FX, "wt");
const fx = n => readFileSync(join(FX, n), "utf8");
const list = (n = "feature_list.json") => ({ path: join(FX, n), text: fx(n) });
const TEXT = fx("text.md");
const DAY = 86400000, T0 = Date.UTC(2026, 10, 1);
// every fixture doc its own mtime: research newer than decisions, README newer than architecture
const MTIMES = {
  "docs/decisions.md": T0, "docs/research/2026-10-22-soulsync/README.md": T0 + DAY, "docs/architecture.md": T0 + 2 * DAY,
  "README.md": T0 + 3 * DAY, "journal/decisions.md": T0, "journal/decisions/2026-10-21-one-file-per-decision.md": T0,
  "docs/plans/near-miss.md": T0,
};
const reader = (mtimes = MTIMES) => fsReader(WT, { mtimes });
const ids = r => r.map(x => `${x.id}:${x.kind}`).join(" ");
const of = (g, id) => g.glossary.filter(x => x.id === id);
const resolveText = (text, fl = list(), rd = reader()) => {
  const parsed = JSON.parse(fl.text);
  return resolveIds(findIds(text, knownIds(parsed)), { featureList: fl }, rd);
};
// an in-memory reader: { path: text }, every file one mtime unless given
const memReader = (root, files, titleOnly = p => p.startsWith("journal/decisions/")) => ({
  root,
  files: () => Object.keys(files).map(path => ({ path, mtimeMs: T0, titleOnly: titleOnly(path) })),
  read: p => files[p] ?? null,
});

test("glossary.mjs: findIds takes D24 and D-H1 as decisions, N1-01 as a feature, M8 and Q99 as milestones", () => {
  assert.equal(ids(findIds(TEXT)), "N1-01:feature D24:decision D-H1:decision M8:milestone Q99:milestone");
});

test("glossary.mjs: findIds never takes N1 from N1-01 nor H1 from D-H1", () => {
  const r = findIds("N1-01, D-H1 and D-H12; H3-02 then H3 alone; D1-01 is a feature of D1");
  assert.equal(ids(r), "N1-01:feature D-H1:decision D-H12:decision H3-02:feature H3:milestone D1-01:feature D1:decision");
});

test("glossary.mjs: findIds takes an id of the feature list the regexes miss", () => {
  const text = "N1F-01 and S2-05a ship before S2-R1 and N1F";
  const known = [{ id: "N1F-01", kind: "feature" }, { id: "S2-05a", kind: "feature" }, { id: "S2-R1", kind: "feature" }, { id: "N1F", kind: "milestone" }];
  assert.equal(ids(findIds(text, known)), "N1F-01:feature S2-05a:feature S2-R1:feature N1F:milestone");
  const bare = findIds(text);
  assert.equal(bare.some(x => ["N1F-01", "S2-05a", "S2-R1", "N1F"].includes(x.id)), false);
  assert.deepEqual(knownIds(JSON.parse(fx("feature_list.json"))).filter(x => x.id.startsWith("N1F")).map(x => `${x.id}:${x.kind}`), ["N1F-01:feature", "N1F:milestone"]);
});

test("glossary.mjs: resolveIds gives D24 its table row, stripped and cut at 300, with path and line", () => {
  const d = of(resolveText("D24"), "D24"), row = d.find(x => x.source.endsWith("docs/decisions.md:18"));
  assert.ok(row, d.map(x => x.source).join());
  assert.equal(row.kind, "decision");
  assert.equal(row.source, join(WT, "docs/decisions.md") + ":18");
  assert.equal(row.text.slice(0, 60), "One download quality. A file is acceptable when it is lossle");
  assert.equal([...row.text].length, 300);
  assert.equal(/[*`]/.test(row.text), false);
  const d36 = of(resolveText("D36"), "D36");
  assert.equal(d36.length, 1);
  assert.equal(d36[0].text.slice(0, 50), "default · The cleanup's trash step runs only with ");
});

test("glossary.mjs: resolveIds gives N1-01 its description and milestone", () => {
  const g = resolveText("N1-01"), f = of(g, "N1-01");
  assert.equal(f.length, 1);
  assert.equal(f[0].kind, "feature");
  assert.equal(f[0].text.slice(0, 50), "A reviewed plan file exists for the Navidrome dupl");
  assert.equal(f[0].text.slice(-15), " (milestone N1)");
  const line = fx("feature_list.json").split("\n").findIndex(l => l.includes('"id": "N1-01"')) + 1;
  assert.equal(f[0].source, `${join(FX, "feature_list.json")}:${line}`);
  assert.deepEqual(g.unresolved, []);
});

test("glossary.mjs: resolveIds gives M8 the headings that open with it, newest file first", () => {
  const m = of(resolveText("M8"), "M8");
  assert.deepEqual(m.map(x => x.source), [join(WT, "README.md") + ":1", join(WT, "docs/architecture.md") + ":1"]);
  assert.equal(m[0].kind, "milestone");
  assert.equal(m[0].text, "M8: lifecycle (ownership, replacement, play-now). M8 follows docs/specs/2026-10-16-ownership-and-identity.md. What it changed, in plain words:");
  assert.equal(m[1].text.slice(0, 40), "M8 (built). Built and committed on this ");
});

test("glossary.mjs: resolveIds gives D-H1 its heading and the text under it", () => {
  const d = of(resolveText("D-H1"), "D-H1");
  assert.equal(d.length, 1);
  assert.equal(d[0].source, join(WT, "journal/decisions.md") + ":4");
  assert.equal(d[0].text.slice(0, 120), "D-H1 · Fresh session per feature, not one long session (iteration 3). - Options: one /loop session with compaction and h");
});

test("glossary.mjs: an id written in two files gives every match, newest file first", () => {
  const src = r => of(resolveText("D24", list(), r), "D24").map(x => x.source.slice(WT.length + 1));
  assert.deepEqual(src(), ["docs/research/2026-10-22-soulsync/README.md:7", "docs/decisions.md:18"]);
  const swapped = { ...MTIMES, "docs/decisions.md": T0 + 9 * DAY };
  assert.deepEqual(src(reader(swapped)), ["docs/decisions.md:18", "docs/research/2026-10-22-soulsync/README.md:7"]);
  assert.equal(of(resolveText("D24"), "D24")[0].text.slice(0, 50), "(ours:docs/specs/2026-10-17-amperfy-pivot.md:19) ·");
});

test("glossary.mjs: a D1 that is a decision row and a milestone keeps both", () => {
  const g = resolveText("D1 and D1-01", list("feature_list-d.json")), d = of(g, "D1");
  assert.deepEqual(d.map(x => x.kind), ["decision", "milestone"]);
  assert.equal(d[0].source, join(WT, "docs/decisions.md") + ":13");
  assert.equal(d[1].text, "milestone in feature_list.json: D1-01 (1 features, 0 passing)");
  assert.equal(of(g, "D1-01").length, 1);
});

test("glossary.mjs: a milestone of the feature list comes before its headings", () => {
  const files = { "docs/plan.md": "# N1 · the cleanup\n\nIts body.\n" };
  const n = of(resolveText("N1", list(), memReader("/p", files)), "N1");
  assert.equal(n.length, 2);
  assert.equal(n[0].text, "milestone in feature_list.json: N1-01, N1-02, N1-03, N1-04, N1-05 (5 features, 5 passing)");
  assert.equal(n[1].source, "/p/docs/plan.md:1");
  assert.equal(n[1].text, "N1 · the cleanup. Its body.");
});

test("glossary.mjs: Q99 is unresolved and no near match is taken", () => {
  const g = resolveText(TEXT);
  assert.deepEqual(g.unresolved, ["Q99"]);
  assert.equal(g.glossary.some(x => x.id === "Q99" || x.source.includes("near-miss")), false);
  assert.equal(ids(g.glossary).split(" ").filter((x, i, a) => a.indexOf(x) === i).join(" "), "N1-01:feature D24:decision D-H1:decision M8:milestone");
  const q = resolveText("Q9 and Q990");
  assert.deepEqual([q.glossary.length, q.unresolved], [2, []]);
});

test("glossary.mjs: journal/decisions files count by their title line only", () => {
  const files = { "journal/decisions/2026-11-01-x.md": "# D-H9 · the title\n\n### D-H8 · in the body\n| D7 | a row |\n", "docs/a.md": "```\n# D5 in a fence\n```\n" };
  const g = resolveIds(findIds("D-H9 D-H8 D7 D5"), { featureList: null }, memReader("/p", files));
  assert.equal(ids(g.glossary), "D-H9:decision");
  assert.equal(g.glossary[0].text, "D-H9 · the title");
  assert.deepEqual(g.unresolved, ["D-H8", "D7", "D5"]);
  const real = fsReader(WT).files().find(f => f.path === "journal/decisions/2026-10-21-one-file-per-decision.md");
  assert.equal(real?.titleOnly, true);
});

test("glossary.mjs: glossaryMarkdown renders one line per entry under ## Glossary, then Unresolved", () => {
  const md = glossaryMarkdown({ glossary: [{ id: "D24", kind: "decision", text: "One quality.", source: "/p/docs/d.md:3" }, { id: "M8", kind: "milestone", text: "M8: lifecycle.", source: "/p/README.md:1" }], unresolved: ["Q99", "Q98"] });
  assert.equal(md, "## Glossary\n\n- **D24** (decision): One quality. (/p/docs/d.md:3)\n- **M8** (milestone): M8: lifecycle. (/p/README.md:1)\n\nUnresolved: Q99, Q98\n");
  assert.equal(glossaryMarkdown({ glossary: [], unresolved: [] }), "## Glossary\n\n(no IDs found)\n");
  assert.equal(strip("**One** [link](http://x) `code` *it* snake_case_name  > no"), "One link code it snake_case_name > no");
  assert.equal(strip("- **Options:** a"), "Options: a");
});

test("glossary.mjs: glossaryMarkdown keeps whole lines within its byte cap and says how many are left", () => {
  const e = i => ({ id: `F1-0${i}`, kind: "feature", text: "é".repeat(20), source: `/p:${i}` });
  const g = { glossary: [1, 2, 3, 4].map(e), unresolved: ["Q99"] };
  const full = glossaryMarkdown(g), line = "- **F1-01** (feature): " + "é".repeat(20) + " (/p:1)\n";
  const cap = Buffer.byteLength("## Glossary\n\n" + line + line) + Buffer.byteLength("… (3 more; context.json lists every one)\n");
  const md = glossaryMarkdown(g, cap);
  assert.ok(Buffer.byteLength(md) <= cap, `${Buffer.byteLength(md)} > ${cap}`);
  assert.equal(md.split("\n").filter(l => l.startsWith("- **")).length, 2);
  assert.equal(md.split("\n").at(-2), "… (3 more; context.json lists every one)");
  assert.equal(glossaryMarkdown(g, Buffer.byteLength(full)), full);
  assert.equal(glossaryMarkdown(g, 5), "");
});

test("glossary.mjs: the CLI prints the glossary and unresolved for a worktree, a list and stdin", () => {
  const tmp = mkdtempSync(join(tmpdir(), "glossary-"));
  try {
    cpSync(FX, tmp, { recursive: true });
    const r = cli("glossary.mjs", [join(tmp, "wt"), join(tmp, "feature_list.json")], { input: TEXT });
    assert.equal(r.rc, 0);
    const o = JSON.parse(r.out);
    assert.deepEqual(Object.keys(o), ["glossary", "unresolved"]);
    assert.deepEqual(o.unresolved, ["Q99"]);
    assert.deepEqual([...new Set(o.glossary.map(x => x.id))], ["N1-01", "D24", "D-H1", "M8"]);
    assert.equal(o.glossary.every(x => x.source.startsWith(tmp + "/")), true);
    assert.equal(cli("glossary.mjs", [], { input: "" }).rc, 2);
    const none = cli("glossary.mjs", [join(tmp, "wt"), join(tmp, "nosuch.json")], { input: "N1-01 Q99" });
    assert.deepEqual([none.rc, JSON.parse(none.out).unresolved], [0, ["N1-01", "Q99"]]);
  } finally { rmSync(tmp, { recursive: true, force: true }); }
});

test("glossary.mjs: an odd feature list or doc never throws and resolves nothing it cannot", () => {
  for (const text of ['{"features":{"A1-01":{}}}', '{"features":"abc"}', "5", "null", "{not json", '{"features":[{"id":""},{"id":5},null,{"id":"A1-01","description":null}]}']) {
    const parsed = (() => { try { return JSON.parse(text); } catch { return null; } })();
    const g = resolveIds(findIds("A1-01 x , y", knownIds(parsed)), { featureList: { path: "/l.json", text } }, memReader("/p", {}));
    assert.equal(g.glossary.every(e => e.id === "A1-01"), true, text);
    assert.equal(g.glossary.length + g.unresolved.length, 1, text);
  }
  const files = { "docs/a.md": "````md\n```\n## M8 · inside a fence\n````\n## M8.1 sub\n## D1 – D23\n| D1 - D23 | old |\n## M8 · the real one\ntext\n```sh\n# comment\n```\nafter\n" };
  const g = resolveIds(findIds("M8 D1"), { featureList: null }, memReader("/p", files));
  assert.equal(ids(g.glossary), "M8:milestone");
  assert.equal(g.glossary[0].text, "M8 · the real one. text after");
  assert.deepEqual(g.unresolved, ["D1"]);
});

test("glossary.mjs: findIds takes the feature list's ids before the regex passes", () => {
  const known = [{ id: "S2-D1", kind: "feature" }, { id: "X-H1", kind: "milestone" }];
  assert.equal(ids(findIds("see S2-D1 and X-H1, then D1", known)), "S2-D1:feature X-H1:milestone D1:decision");
});

test("glossary.mjs: a dotted id (M8.1, D24.3) is not its prefix, in a text or a table row", () => {
  assert.equal(ids(findIds("M8.1 and D24.3 and N1-01.2, then M8.")), "M8:milestone");
  assert.equal(ids(findIds("M8.1", [{ id: "M8", kind: "milestone" }])), "");
  const g = resolveIds([{ id: "D24", kind: "decision" }], {}, memReader("/r", { "docs/d.md": "| D24.1 | a near row |\n" }));
  assert.equal(g.glossary.length, 0);
  assert.deepEqual(g.unresolved, ["D24"]);
});
