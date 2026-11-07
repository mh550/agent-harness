// lib/curator.mjs: the memory curator's rules (validate, the tier, anchors, the gate, the cap, apply, the body).   node --test tests/unit/curator.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { PROTECTED, apply, body, capCheck, main, matchAnchor, tierOf, validate } from "../../lib/curator.mjs";
import { readEntries } from "../../lib/entries.mjs";
import { gotchasDiff, gotchasLines, sectionEntries } from "../../lib/memlint.mjs";
import { assemble } from "../../lib/render.mjs";

const fx = n => new URL(`../fixtures/memory/${n}`, import.meta.url);
const RUN = "r1", FACT = "The stub's lib.sh needs HARNESS_HOME before it sources lib/*.sh (r1 2026-11-07)";
const PROPOSAL = "Run the fast tier once, last, after the final edit";
const E = o => ({ feature: "A", kind: "coding", outcome: "passes", summary: "s", ...o });
const ENTRIES = [
  { feature: "init", kind: "init", outcome: "passes", summary: "init" },
  E({ discoveries: [{ text: FACT, affects: ["project"] }, { text: "A run-only fact about the lanes (r1 2026-11-07)", affects: ["run"] }], proposed_changes: [PROPOSAL] }),
];
const op = o => ({ op: "add", file: "CLAUDE.md", section: "## Gotchas", text: FACT, tier: 1, why: "w", from: "entries.jsonl:2", ...o });
const MD = ["# P", "", "## Code rules", "", "- bash only.", "", "## Live system", "", "- deploy via scripts/deploy.sh.", "",
  "## Gotchas", "", "- first gotcha line (r0 2026-11-01)", "- second `gotcha` line,", "  wrapped (r0 2026-11-01)", ""].join("\n");
const T = md => ({ "CLAUDE.md": md, ".harness/project.md": null });
const gotchas = (n, extra = []) => ["# P", "", ...extra, "## Gotchas", "", ...Array.from({ length: n }, (_, i) => `- gotcha number ${i + 1} is about its own thing (r0 2026-11-01)`), ""].join("\n");
const reasons = r => r.dropped.map(d => d.reason).join(" | ");
const lineCount = t => t.replace(/\n$/, "").split("\n").length;

test("curator.mjs: validate passes a file of three ops and returns them", () => {
  const v = validate(JSON.stringify([op(), op({ op: "replace", anchor: "first gotcha line", text: `- ${FACT}` }), op({ op: "delete", anchor: "x", text: undefined })]));
  assert.equal(v.ok, true, v.why);
  assert.equal(v.ops.length, 3);
  assert.equal(v.ops.map(o => o.op).join(), "add,replace,delete");
  assert.equal(v.ops[1].text, FACT);   // the leading `- ` dropped: the driver writes the bullet
});

test("curator.mjs: validate refuses a malformed file whole with its first reason", () => {
  const why = x => validate(typeof x === "string" ? x : JSON.stringify(x)).why;
  assert.match(why("{not json"), /^not JSON: /);
  assert.equal(validate("{not json").ok, false);
  assert.equal(why({ op: "add" }), "not a JSON list");
  assert.equal(why(Array.from({ length: 51 }, () => op())), "51 ops, at most 50");
  assert.equal(why([op({ op: "move" })]), 'op 1: op "move" is not add, replace or delete');
  assert.equal(why([op(), op({ op: "replace" })]), "op 2: replace without an anchor");
  assert.equal(why([op({ op: "delete" })]), "op 1: delete without an anchor");
  assert.equal(why([op({ from: "line 4" })]), 'op 1: from "line 4" is not entries.jsonl:<n>');
  assert.equal(why([op({ from: "entries.jsonl:0" })]), 'op 1: from "entries.jsonl:0" is not entries.jsonl:<n>');
  assert.equal(why([op({ file: "lib/x.sh" })]), 'op 1: file "lib/x.sh" is neither CLAUDE.md nor .harness/project.md');
  assert.equal(why([op({ text: "a gotcha without its suffix" })]), "op 1: a Gotchas text without its (<run> <date>) suffix");
  assert.equal(why([op({ text: "x".repeat(150) + " (r1 2026-11-07)" })]), "op 1: text of 166 characters, at most 160");
  assert.equal(why([op({ text: "two\nlines (r1 2026-11-07)" })]), "op 1: add without a one-line text");
  assert.equal(why([op({ extra: 1 })]), 'op 1: unknown key "extra"');
  assert.equal(why([op({ section: "Gotchas" })]), 'op 1: section "Gotchas" is not one ## heading');
  assert.equal(why([op({ section: "## " + "x".repeat(200) })]), "op 1: section of 203 characters, at most 200");
  assert.equal(why([op({ tier: 4 })]), "op 1: tier 4 is not 1, 2 or 3");
  assert.equal(why([op({ why: " " })]), "op 1: why is not one non-blank line of at most 300 characters");
  assert.equal(why([op({ why: "x\n## Applied" })]), "op 1: why is not one non-blank line of at most 300 characters");
  assert.equal(why([op(), op({ op: "x", file: "y" })]), 'op 2: op "x" is not add, replace or delete');   // the first reason only
  assert.equal(why([op({ section: "## Code rules", text: "no suffix outside Gotchas" })]), undefined);
});

test("curator.mjs: tierOf gives every heading of the eight projects its fixture tier", () => {
  const rows = readFileSync(fx("headings.txt"), "utf8").replace(/\n$/, "").split("\n").slice(1).map(l => l.split("\t"));
  assert.equal(rows.length, 63);
  const bad = rows.filter(([, h, t]) => tierOf(h) !== Number(t)).map(([p, h, t]) => `${p} ${h}: ${tierOf(h)}, not ${t}`);
  assert.equal(bad.join("\n"), "");
  assert.equal(new Set(rows.map(r => r[0])).size, 8);
});

test("curator.mjs: tierOf protects a heading by prefix, its dated or parenthesised suffix aside", () => {
  assert.equal(PROTECTED.length, 6);
  assert.equal(tierOf("## Hardware facts (verified 2026-10-19 on Michael's desktop)"), 3);
  assert.equal(tierOf("## Hardware and Mixxx rules (binding on every session)"), 3);
  assert.equal(tierOf("## This repo runs Michael's harness runs: what that means for a session working on it"), 3);
  assert.equal(tierOf("## Live system  "), 3);
  assert.equal(tierOf("## Off-limits"), 3);
  assert.equal(tierOf("## On-limits"), 3);
  assert.equal(tierOf("## Gotchas"), 1);
  assert.equal(tierOf("## Gotchas "), 1);
  assert.equal(tierOf("## Gotchas (old)"), 2);   // tier 1 is the one heading, exactly
  assert.equal(tierOf("## Live"), 2);            // a protected name is the prefix, never the other way
  assert.equal(tierOf("## Code rules"), 2);
  assert.equal(tierOf("## Where things go"), 2);
});

test("curator.mjs: apply derives the tier from the heading and counts a claim that disagrees", () => {
  const r = apply([op({ tier: 3 }), op({ section: "## Code rules", text: PROPOSAL, tier: 1 }), op({ text: undefined, op: "delete", anchor: "first gotcha line (r0 2026-11-01)" })], T(MD), ENTRIES, RUN);
  assert.equal(reasons(r), "");
  assert.equal(r.applied.map(o => o.tier).join(), "1,1");
  assert.equal(r.proposed.map(o => o.tier).join(), "2");
  assert.equal(r.rederived, 2);
  assert.equal(r.ops, 3);
});

test("curator.mjs: matchAnchor matches a line whose whitespace, backticks, emphasis or bullet differ", () => {
  const sec = sectionEntries(MD, "## Gotchas");
  assert.equal(sec.length, 2);
  assert.equal(matchAnchor(sec, "**second**  gotcha   line, wrapped (r0 2026-11-01)").entry?.line, 14);
  assert.equal(matchAnchor(sec, "* _first_ GOTCHA line (r0 2026-11-01)").entry?.line, 13);
  assert.equal(matchAnchor(sec, "1. second `gotcha` line, wrapped (r0 2026-11-01)").entry?.last, 15);
});

test("curator.mjs: an anchor with no match or two matches drops its op, naming the anchor", () => {
  const none = apply([op({ op: "replace", anchor: "nothing like this line" })], T(MD), ENTRIES, RUN);
  assert.equal(reasons(none), 'anchor "nothing like this line" matches no line');
  const twice = MD + "- second gotcha line, wrapped (r0 2026-11-02)\n";   // one key: the suffix aside
  const two = apply([op({ op: "replace", anchor: "second gotcha line, wrapped (r0 2026-11-01)" })], T(twice), ENTRIES, RUN);
  assert.equal(reasons(two), 'anchor "second gotcha line, wrapped (r0 2026-11-01)" matches 2 lines');
  const long = apply([op({ op: "delete", text: undefined, anchor: "y".repeat(80) })], T(MD), ENTRIES, RUN);
  assert.equal(reasons(long), `anchor "${"y".repeat(60)}…" matches no line`);
  assert.equal(none.texts["CLAUDE.md"] === MD && two.texts["CLAUDE.md"] === twice, true);
});

test("curator.mjs: a 16th Gotchas add without an anchor refuses the tier-1 commit, naming the breach", () => {
  const md = gotchas(15), r = apply([op()], T(md), ENTRIES, RUN);
  assert.equal(r.refused, "## Gotchas: 16 entries, over 15");
  assert.equal(r.applied.length, 0);
  assert.equal(reasons(r), "refused: ## Gotchas: 16 entries, over 15");
  assert.equal(r.texts["CLAUDE.md"] === md, true);
  assert.equal(capCheck("CLAUDE.md", md, md + "- one more (r1 2026-11-07)\n"), "## Gotchas: 16 entries, over 15");
  assert.equal(capCheck(".harness/project.md", md, md + "- one more (r1 2026-11-07)\n"), null);   // only CLAUDE.md is capped
});

test("curator.mjs: the same add with an anchor evicts that line and is accepted", () => {
  const md = gotchas(15), r = apply([op({ anchor: "gotcha number 3 is about its own thing (r0 2026-11-01)" })], T(md), ENTRIES, RUN);
  assert.equal(r.refused, null);
  assert.equal(r.applied.length, 1);
  const after = r.texts["CLAUDE.md"];
  assert.equal(gotchasLines(after).length, 15);
  assert.equal(gotchasLines(after)[2], `- ${FACT}`);
  assert.equal(JSON.stringify(gotchasDiff(md, after)), '{"added":0,"edited":1,"deleted":0}');
});

test("curator.mjs: a result over 120 lines refuses the tier-1 commit", () => {
  const md = gotchas(3, [...Array.from({ length: 112 }, (_, i) => `line ${i}`), ""]);
  assert.equal(lineCount(md), 120);
  const r = apply([op()], T(md), ENTRIES, RUN);
  assert.equal(r.refused, "CLAUDE.md: 121 lines, over 120");
  assert.equal(r.applied.length, 0);
  assert.equal(apply([op()], T(md), ENTRIES, RUN, { maxLines: 130 }).refused, null);   // MEMLINT_LINES's cap
});

// memlint-self's "this checkout lints clean" for what the driver writes: the two line lints hold at the write too
test("curator.mjs: a tier-1 op whose text memlint finds a derivable count or run scope in is dropped, naming the lint", () => {
  const count = "The suite runs ~1,870 tests in eleven minutes (r1 2026-11-07)", scope = "Keep lane slots at two for this run (r1 2026-11-07)";
  const es = [ENTRIES[0], E({ discoveries: [count, scope, FACT].map(text => ({ text, affects: ["project"] })) })];
  const r = apply([op({ text: count }), op({ text: scope }), op()], T(MD), es, RUN);
  assert.equal(reasons(r), 'derivable-count: "~1,870 tests" (the suite can tell: store no count) | run-scope: "this run" (run scope goes in the run\'s brief)');
  assert.equal(r.applied.length, 1);
  assert.equal(r.texts["CLAUDE.md"].includes("1,870") || r.texts["CLAUDE.md"].includes("this run"), false);
  assert.equal(apply([op({ section: "## Code rules", text: count })], T(MD), es, RUN).proposed.length, 1);   // tier 2: Michael's to judge
});

test("curator.mjs: a file already over the cap takes a replace or a delete", () => {
  const md = gotchas(16, [...Array.from({ length: 120 }, (_, i) => `line ${i}`), ""]);
  const r = apply([op({ op: "replace", anchor: "gotcha number 1 is about its own thing (r0 2026-11-01)" }),
    op({ op: "delete", text: undefined, anchor: "gotcha number 9 is about its own thing (r0 2026-11-01)" })], T(md), ENTRIES, RUN);
  assert.equal(r.refused, null);
  assert.equal(reasons(r), "");
  assert.equal(r.applied.length, 2);
  assert.equal(gotchasLines(r.texts["CLAUDE.md"]).length, 15);
  assert.equal(lineCount(r.texts["CLAUDE.md"]), lineCount(md) - 1);
});

test("curator.mjs: the write gate drops a text the entry its from names does not state, and keeps a delete with an existing anchor", () => {
  const r = apply([
    op({ text: "A fact this entry never stated (r1 2026-11-07)" }),
    op({ text: "A run-only fact about the lanes (r1 2026-11-07)" }),
    op({ from: "entries.jsonl:9" }),
    op({ from: "entries.jsonl:1" }),
    op({ op: "delete", text: undefined, anchor: "second gotcha line, wrapped (r0 2026-11-01)" }),
    op({ section: "## Code rules", text: PROPOSAL, tier: 2 }),
  ], T(MD), ENTRIES, RUN);
  assert.equal(reasons(r), "not stated by entries.jsonl:2 | not stated by entries.jsonl:2 | from entries.jsonl:9 names no entry | not stated by entries.jsonl:1");
  // a proposed_changes string is Michael's (how to work here): it gates a tier-2 op, never a tier-1 commit
  assert.equal(reasons(apply([op({ text: `${PROPOSAL} (r1 2026-11-07)` })], T(MD), ENTRIES, RUN)), "not stated by entries.jsonl:2 as a project fact");
  // a fact cut short (a long discovery fits 160) passes; the run's suffix aside
  const long = [...ENTRIES, E({ discoveries: [{ text: "The resident helper answers every .mjs question over one coproc, and a missing answer is empty, so give the bash a safe branch", affects: ["project"] }] })];
  assert.equal(apply([op({ text: "The resident helper answers every .mjs question over one coproc (r1 2026-11-07)", from: "entries.jsonl:3" })], T(MD), long, RUN).applied.length, 1);
  assert.equal(r.applied.map(o => o.op).join(), "delete");
  assert.equal(r.proposed.length, 1);
  assert.equal(gotchasLines(r.texts["CLAUDE.md"]).join("|"), "- first gotcha line (r0 2026-11-01)");
});

test("curator.mjs: a fact a later entry resolved, or already in its section, is dropped", () => {
  const es = [...ENTRIES, E({ feature: "B", resolved: [`- ${FACT.toUpperCase()} → entries.jsonl:2`] })];
  assert.equal(reasons(apply([op()], T(MD), es, RUN)), "resolved by entries.jsonl:3");
  const had = MD + `- ${FACT}\n`;
  assert.equal(reasons(apply([op()], T(had), ENTRIES, RUN)), "already in ## Gotchas");
  const short = [...ENTRIES, E({ discoveries: [{ text: "use flock -n for the lock", affects: ["project"] }] })];
  const hadShort = MD + "- use flock -n for the lock (r0 2026-10-01)\n";
  assert.equal(reasons(apply([op({ text: "use flock -n for the lock (r1 2026-11-07)", from: "entries.jsonl:3" })], T(hadShort), short, RUN)), "already in ## Gotchas");   // the (<run> <date>) suffix aside
  assert.equal(reasons(apply([op({ file: ".harness/project.md" })], T(MD), ENTRIES, RUN)), "no .harness/project.md on the base");
  assert.equal(reasons(apply([op({ section: "## Hints" })], T(MD), ENTRIES, RUN)), "no section ## Hints in CLAUDE.md");
});

test("curator.mjs: a heading inside a code fence, a repeated heading or CRLF line ends never misplace a write", () => {
  const fenced = ["# T", "", "## Live system", "rules:", "```", "## Gotchas", "```", "- never x", ""].join("\n");
  assert.equal(reasons(apply([op()], T(fenced), ENTRIES, RUN)), "no section ## Gotchas in CLAUDE.md");
  const inside = ["# T", "", "## Gotchas", "", "- a (r0 2026-11-01)", "```bash", "# comment", "```", "- b (r0 2026-11-01)", "", "## Live system", "- x", ""].join("\n");
  assert.equal(sectionEntries(inside, "## Gotchas").length, 3);   // the fenced block is one entry with its opening line
  const ls = apply([op()], T(inside), ENTRIES, RUN).texts["CLAUDE.md"].split("\n");
  assert.equal(ls.indexOf(`- ${FACT}`), 9);   // after "- b", outside the fence and before ## Live system
  const twice = MD + "\n## Gotchas\n\n- again (r0 2026-11-01)\n";
  assert.equal(reasons(apply([op()], T(twice), ENTRIES, RUN)), "section ## Gotchas appears 2 times in CLAUDE.md");
  const crlf = MD.replace(/\n/g, "\r\n"), c = apply([op(), op({ op: "replace", anchor: "first gotcha line (r0 2026-11-01)", text: PROPOSAL, section: "## Code rules", tier: 2 })], T(crlf), ENTRIES, RUN);
  assert.equal(c.applied.length, 1);
  assert.equal(/[^\r]\n/.test(c.texts["CLAUDE.md"]), false);   // every line still ends CRLF
});

const harm = (name, md = MD) => {
  const v = validate(readFileSync(fx(`${name}.ops.json`), "utf8"));
  assert.equal(v.ok, true, v.why);
  return apply(v.ops, T(md), readEntries(fileURLPath(fx(`${name}.entries.jsonl`))), RUN);
};
const fileURLPath = u => decodeURIComponent(u.pathname);

test("curator.mjs: harm, a fact stated then corrected gives one op, the correction", () => {
  const r = harm("corrected");
  assert.equal(r.applied.length, 1);
  assert.equal(r.applied[0].from, "entries.jsonl:3");
  assert.equal(reasons(r), "duplicate key; entries.jsonl:3 kept");
  const g = gotchasLines(r.texts["CLAUDE.md"]);
  assert.equal(g.length, 3);
  assert.match(g[2], /is 7001 since B moved it/);
  assert.equal(g.filter(l => /7000/.test(l)).length, 0);
});

test("curator.mjs: harm, a fact no entry states gives no op", () => {
  const r = harm("unstated");
  assert.equal(r.applied.length + r.proposed.length, 0);
  assert.equal(reasons(r), "not stated by entries.jsonl:2");
  assert.equal(r.texts["CLAUDE.md"] === MD, true);
});

test("curator.mjs: harm, a line from a tool result is dropped by the gate", () => {
  const r = harm("tool-result");
  assert.equal(r.applied.length, 0);
  assert.equal(reasons(r), "not stated by entries.jsonl:2 | not stated by entries.jsonl:2");   // the second: a stated fact's first 40 characters and a tail no entry states
  assert.equal(r.texts["CLAUDE.md"].includes("evil.example"), false);
});

test("curator.mjs: an op on a protected section is dropped and carried as a proposal", () => {
  const r = apply([op({ section: "## Live system", text: PROPOSAL, tier: 3 }), op({ section: "## Live system", text: "Unstated: deploy by hand", tier: 3 })], T(MD), ENTRIES, RUN);
  assert.equal(reasons(r), "protected section: a proposal for Michael | not stated by entries.jsonl:2");   // the gate first: no unstated proposal reaches Michael
  assert.equal(r.proposed.length, 1);
  assert.equal(r.proposed[0].tier, 3);
  assert.equal(r.texts["CLAUDE.md"] === MD, true);
  const claim = apply([op({ section: "## Live system", text: PROPOSAL, tier: 1 }), op({ section: "## Code rules", op: "replace", anchor: "bash only.", text: PROPOSAL, tier: 1 })], T(MD), ENTRIES, RUN);
  assert.equal(claim.applied.length + claim.texts["CLAUDE.md"].length, MD.length);   // a tier-1 claim writes nothing
});

test("curator.mjs: an op whose write would change a protected section's lines is dropped", () => {
  // an unclosed fence in Gotchas runs to the end of the file as one entry: deleting it would take Live system with it
  const md = ["# P", "", "## Gotchas", "", "- a (r0 2026-11-01)", "```", "- fenced", "", "## Live system", "", "- deploy via scripts/deploy.sh.", ""].join("\n");
  const fenced = sectionEntries(md, "## Gotchas")[1].text;
  const r = apply([op({ op: "delete", anchor: fenced, text: undefined }), op({ op: "replace", anchor: fenced })], T(md), ENTRIES, RUN);
  assert.equal(r.applied.length, 0);
  assert.equal(reasons(r), "would change the protected section ## Live system | would change the protected section ## Live system");
  assert.equal(r.texts["CLAUDE.md"] === md, true);
  assert.equal(apply([op()], T(MD), ENTRIES, RUN).applied.length, 1);   // a write beside a protected section is no change to it
});

test("curator.mjs: only tier 1 is written; a tier-2 op leaves the texts as they were", () => {
  const r = apply([op({ section: "## Code rules", text: PROPOSAL, tier: 2 }), op({ op: "replace", section: "## Code rules", anchor: "bash only.", text: PROPOSAL, tier: 2 })], T(MD), ENTRIES, RUN);
  assert.equal(r.applied.length, 0);
  assert.equal(r.proposed.length, 1);   // one key, one op: the later in the list
  assert.equal(r.proposed[0].op, "replace");
  assert.equal(r.texts["CLAUDE.md"] === MD, true);
  const one = apply([op()], T(MD), ENTRIES, RUN);
  assert.equal(gotchasLines(one.texts["CLAUDE.md"]).at(-1), `- ${FACT}`);
  assert.equal(one.texts["CLAUDE.md"].endsWith("\n"), true);
  assert.equal(lineCount(one.texts["CLAUDE.md"]), lineCount(MD) + 1);
});

test("curator.mjs: body lists the applied and tier-2 ops with their from, then the proposals, then the dropped with reasons", () => {
  const es = [...ENTRIES, E({ feature: "B", discoveries: [{ text: "B's fact (r1 2026-11-07)", affects: ["project"] }] })];
  const r = apply([op(), op({ section: "## Code rules", text: PROPOSAL, tier: 2 }), op({ section: "## Live system", text: "B's fact (r1 2026-11-07)", from: "entries.jsonl:3", tier: 3 }),
    op({ text: "Never stated (r1 2026-11-07)" })], T(MD), es, RUN);
  const b = body(r, RUN), at = s => b.indexOf(s);
  assert.equal(b.split("\n")[0].includes("4 ops · 1 applied · 2 dropped · 2 proposals"), true, b.split("\n")[0]);
  const order = ["## Applied (tier 1)", FACT, "## For you to paste (tier 2)", PROPOSAL, "## Proposals (protected, tier 3)", "B's fact", "## Dropped", "Never stated", "not stated by entries.jsonl:2"];
  assert.equal(order.filter(s => at(s) < 0).join(" | "), "");
  assert.equal(order.every((s, i) => i === 0 || at(order[i - 1]) < at(s)), true);
  assert.equal((b.match(/entries\.jsonl:2/g) ?? []).length >= 3, true);   // the applied, the tier-2 and the dropped op's from
  assert.equal(b.includes("(entries.jsonl:3)"), true);
  assert.equal(b.includes("protected section: a proposal"), false);   // a proposal is listed once, as a proposal
  const at2 = body({ ...r, applied: [{ ...r.applied[0], why: "ask @mh550 first" }] }, RUN);
  assert.equal(/(^|[^`])@mh550/.test(at2.replace(/@\u200b/g, "")), false);   // a mention outside a fence would notify
  assert.equal(at2.includes("@\u200bmh550"), true);
  const sec = body(apply([op({ section: "## @mh550 see" })], T(MD), ENTRIES, RUN), RUN);   // a section no file has, in Dropped
  assert.equal(/(^|[^`])@mh550/.test(sec.replace(/@\u200b/g, "")), false);
  const empty = body(apply([], T(MD), ENTRIES, RUN), RUN);
  assert.equal(/## (Applied|For you|Proposals|Dropped)/.test(empty), false);
  const refused = body(apply([op()], T(gotchas(15)), ENTRIES, RUN), RUN);
  assert.equal(refused.includes("refused: ## Gotchas: 16 entries, over 15"), true);
});

test("curator.mjs: main apply writes the worktree's CLAUDE.md and prints one JSON line", () => {
  const d = mkdtempSync(join(tmpdir(), "curator-"));
  try {
    writeFileSync(join(d, "ops.json"), JSON.stringify([op(), op({ section: "## Code rules", text: PROPOSAL, tier: 1 })]));
    writeFileSync(join(d, "entries.jsonl"), ENTRIES.map(e => JSON.stringify(e)).join("\n") + "\n");
    const w = mkdtempSync(join(d, "w-"));
    writeFileSync(join(w, "CLAUDE.md"), MD);
    assert.equal(main(["validate", join(d, "ops.json")], { env: {} }).out, "ok\n");
    const r = main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl")], { env: {} });
    assert.equal(r.rc, 0);
    assert.equal(r.out.split("\n").length, 2);   // one line and its newline
    const j = JSON.parse(r.out);
    assert.equal(`${j.ops} ${j.applied.length} ${j.proposed.length} ${j.dropped.length} ${j.rederived} ${j.refused}`, "2 1 1 0 1 null");
    assert.equal(j.files.join(), "CLAUDE.md");
    assert.equal(j.texts, undefined);
    assert.equal(gotchasLines(readFileSync(join(w, "CLAUDE.md"), "utf8")).at(-1), `- ${FACT}`);
    writeFileSync(join(d, "result.json"), r.out);
    const b = main(["body", join(d, "result.json"), RUN], { env: {} });
    assert.equal(b.rc, 0);
    assert.equal(b.out.includes(PROPOSAL), true);
    writeFileSync(join(d, "bad.json"), "{not json");
    const bad = main(["validate", join(d, "bad.json")], { env: {} });
    assert.equal(bad.rc, 1);
    assert.match(bad.out, /^not JSON: /);
    const badApply = main(["apply", join(d, "bad.json"), w, RUN, join(d, "entries.jsonl")], { env: {} });
    assert.equal(badApply.rc, 1);
    assert.match(JSON.parse(badApply.out).invalid, /^not JSON: /);
    writeFileSync(join(w, "CLAUDE.md"), gotchas(3, [...Array.from({ length: 112 }, (_, i) => `line ${i}`), ""]));
    const capped = JSON.parse(main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl")], { env: { MEMLINT_LINES: "200" } }).out);
    assert.equal(capped.refused, null);   // MEMLINT_LINES raises the cap
    const full = gotchas(15);
    writeFileSync(join(w, "CLAUDE.md"), full);
    const no = JSON.parse(main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl")], { env: {} }).out);
    assert.equal(`${no.refused} ${no.files.length}`, "## Gotchas: 16 entries, over 15 0");
    assert.equal(readFileSync(join(w, "CLAUDE.md"), "utf8") === full, true);
    // a symlinked CLAUDE.md is no file: never read through, never written through
    const outside = join(d, "outside.md");
    writeFileSync(outside, MD); rmSync(join(w, "CLAUDE.md")); symlinkSync(outside, join(w, "CLAUDE.md"));
    const link = JSON.parse(main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl")], { env: {} }).out);
    assert.equal(link.dropped[0].reason, "no CLAUDE.md on the base");
    assert.equal(readFileSync(outside, "utf8") === MD, true);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("curator.mjs: the curator prompt renders with no placeholder left", () => {
  const tpl = readFileSync(new URL("../../prompts/curator.md", import.meta.url), "utf8");
  const part = readFileSync(new URL("../../prompts/parts/where-things-go-readonly.md", import.meta.url), "utf8");
  for (const p of ["{{RUN_ID}}", "{{PROJECT}}", "{{RUN_DIR}}", "{{MEMORY_BASE}}"]) assert.equal(tpl.includes(p), true, p);
  const env = { HARNESS_RUN_ID: RUN, HARNESS_PROJECT: "p", HARNESS_RUN_DIR: ".harness/runs/r1", HARNESS_MEMORY_BASE: "/tmp/s/memory-base", HARNESS_DECISIONS: "one file per decision" };
  const out = assemble(tpl, [{ title: null, body: part }], env);
  assert.equal((out.match(/\{\{/g) ?? []).length, 0);
  for (const w of [".harness/runs/r1/memory-ops.json", "`add`", "`replace`", "`delete`", "write gate", "never a file", "/tmp/s/memory-base/CLAUDE.md", "This session is read-only"])
    assert.equal(out.includes(w), true, w);
  assert.equal(/^## Where things go/m.test(tpl), false);   // the part brings its own heading
});
