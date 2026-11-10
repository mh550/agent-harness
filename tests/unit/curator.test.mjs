// lib/curator.mjs: the memory curator's rules (validate, the tier, anchors, the gate, the cap, apply, the body).   node --test tests/unit/curator.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { PROTECTED, answersText, apply, body, capCheck, graft, itemKey, main, matchAnchor, tierOf, validate } from "../../lib/curator.mjs";
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
  assert.equal(why([op({ file: "lib/x.sh" })]), 'op 1: file "lib/x.sh" is none of CLAUDE.md, .harness/project.md, .claude/CLAUDE.md');
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
  assert.equal(r.rules.map(o => o.tier).join(), "2");
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

const G = n => `gotcha number ${n} is about its own thing (r0 2026-11-01)`;
const ES2 = [...ENTRIES, E({ feature: "B", discoveries: [{ text: "B's fact (r1 2026-11-07)", affects: ["project"] }] })];

test("curator.mjs: a 16th Gotchas add without an anchor is dropped naming the cap; the replace beside it lands", () => {
  const md = gotchas(15), r = apply([op(), op({ op: "replace", anchor: G(2), text: "B's fact (r1 2026-11-07)", from: "entries.jsonl:3" })], T(md), ES2, RUN);
  assert.equal(reasons(r), "over the cap: ## Gotchas: 16 entries, over 15");
  assert.equal(r.dropped[0].op.op, "add");
  assert.equal(r.applied.map(o => o.op).join(), "replace");
  assert.equal(gotchasLines(r.texts["CLAUDE.md"]).length, 15);
  assert.equal(gotchasLines(r.texts["CLAUDE.md"])[1], "- B's fact (r1 2026-11-07)");
  assert.equal("refused" in r, false);
  assert.equal(capCheck("CLAUDE.md", md, md + "- one more (r1 2026-11-07)\n"), "## Gotchas: 16 entries, over 15");
  assert.equal(capCheck(".harness/project.md", md, md + "- one more (r1 2026-11-07)\n"), null);   // only CLAUDE.md is capped
});

test("curator.mjs: the op that crosses 120 lines is dropped naming the cap; the ops before and after it land", () => {
  const md = gotchas(3, [...Array.from({ length: 111 }, (_, i) => `line ${i}`), ""]);
  assert.equal(lineCount(md), 119);
  const r = apply([op({ text: "B's fact (r1 2026-11-07)", from: "entries.jsonl:3" }), op(),
    op({ op: "replace", anchor: G(1), text: "B's fact, corrected later (r1 2026-11-07)", from: "entries.jsonl:4" })], T(md),
    [...ES2, E({ feature: "C", discoveries: [{ text: "B's fact, corrected later (r1 2026-11-07)", affects: ["project"] }] })], RUN);
  assert.equal(reasons(r), "over the cap: CLAUDE.md: 121 lines, over 120");
  assert.equal(r.dropped[0].op.text, FACT);   // the second add: the first fit, the replace (written first) kept the count
  assert.equal(r.applied.map(o => o.op).join(), "replace,add");
  assert.equal(lineCount(r.texts["CLAUDE.md"]), 120);
  assert.equal(apply([op()], T(gotchas(3, [...Array.from({ length: 112 }, (_, i) => `line ${i}`), ""])), ENTRIES, RUN, { maxLines: 130 }).applied.length, 1);   // MEMLINT_LINES's cap
});

test("curator.mjs: a delete and an anchorless add in one list on a file at 15 Gotchas both land, the delete first", () => {
  const md = gotchas(15), r = apply([op(), op({ op: "delete", text: undefined, anchor: G(4) })], T(md), ENTRIES, RUN);
  assert.equal(reasons(r), "");
  assert.equal(r.applied.map(o => o.op).join(), "delete,add");
  const g = gotchasLines(r.texts["CLAUDE.md"]);
  assert.equal(`${g.length} ${g.at(-1) === `- ${FACT}`} ${g.includes(`- ${G(4)}`)}`, "15 true false");
});

test("curator.mjs: an anchored add appends while the file is under both caps, and evicts its anchor at 15 Gotchas", () => {
  const md = gotchas(3), r = apply([op({ anchor: G(2) })], T(md), ENTRIES, RUN);
  assert.equal(r.applied.length, 1);
  assert.equal(r.applied[0].evicted, undefined);
  assert.equal(gotchasLines(r.texts["CLAUDE.md"]).at(-1), `- ${FACT}`);
  assert.equal(gotchasLines(r.texts["CLAUDE.md"]).includes(`- ${G(2)}`), true);   // its anchor line kept
  assert.equal(JSON.stringify(gotchasDiff(md, r.texts["CLAUDE.md"])), '{"added":1,"edited":0,"deleted":0}');
  const b = body(r, RUN);
  assert.equal(b.includes("in place of"), false);
  const full = gotchas(15), e = apply([op({ anchor: G(3) })], T(full), ENTRIES, RUN), after = e.texts["CLAUDE.md"];
  assert.equal(e.applied.length, 1);
  assert.equal(e.applied[0].evicted, `- ${G(3)}`);
  assert.equal(gotchasLines(after).length, 15);
  assert.equal(gotchasLines(after)[2], `- ${FACT}`);
  assert.equal(JSON.stringify(gotchasDiff(full, after)), '{"added":0,"edited":1,"deleted":0}');
  assert.equal(body(e, RUN).includes(`- \`add\` CLAUDE.md · ## Gotchas: ${FACT} (in place of: - ${G(3)}) — w (entries.jsonl:2)`), true);
  const lines = gotchas(3, [...Array.from({ length: 112 }, (_, i) => `line ${i}`), ""]), l = apply([op({ anchor: G(1) })], T(lines), ENTRIES, RUN);
  assert.equal(`${lineCount(lines)} ${l.applied[0].evicted === `- ${G(1)}`} ${lineCount(l.texts["CLAUDE.md"])}`, "120 true 120");   // the line cap alone evicts
});

test("curator.mjs: an anchored add whose anchor a delete in the same list removed lands as a plain add when it fits", () => {
  const md = gotchas(15), r = apply([op({ anchor: G(3) }), op({ op: "delete", text: undefined, anchor: G(3) })], T(md), ENTRIES, RUN);
  assert.equal(reasons(r), "");
  assert.equal(r.applied.map(o => `${o.op}${o.evicted ? " evicted" : ""}`).join(), "delete,add");
  const g = gotchasLines(r.texts["CLAUDE.md"]);
  assert.equal(`${g.length} ${g.at(-1) === `- ${FACT}`} ${g.includes(`- ${G(3)}`)}`, "15 true false");
  const none = apply([op({ anchor: "no such gotcha (r0 2026-11-01)" })], T(md), ENTRIES, RUN);   // at the cap it still needs its anchor
  assert.equal(reasons(none), 'anchor "no such gotcha (r0 2026-11-01)" matches no line');
  const typo = apply([op({ anchor: "no such gotcha (r0 2026-11-01)" })], T(gotchas(3)), ENTRIES, RUN);   // under the cap: no delete took it
  assert.equal(`${typo.applied.length} ${reasons(typo)}`, '0 anchor "no such gotcha (r0 2026-11-01)" matches no line');
});

// memlint-self's "this checkout lints clean" for what the driver writes: the two line lints hold at the write too
test("curator.mjs: a tier-1 op whose text memlint finds a derivable count or run scope in is dropped, naming the lint", () => {
  const count = "The suite runs ~1,870 tests in eleven minutes (r1 2026-11-07)", scope = "Keep lane slots at two for this run (r1 2026-11-07)";
  const es = [ENTRIES[0], E({ discoveries: [count, scope, FACT].map(text => ({ text, affects: ["project"] })) })];
  const r = apply([op({ text: count }), op({ text: scope }), op()], T(MD), es, RUN);
  assert.equal(reasons(r), 'derivable-count: "~1,870 tests" (the suite can tell: store no count) | run-scope: "this run" (run scope goes in the run\'s brief)');
  assert.equal(r.applied.length, 1);
  assert.equal(r.texts["CLAUDE.md"].includes("1,870") || r.texts["CLAUDE.md"].includes("this run"), false);
  assert.equal(apply([op({ section: "## Code rules", text: count })], T(MD), es, RUN).rules.length, 1);   // tier 2: a rule for Michael to merge
});

test("curator.mjs: a file already over the cap takes a replace or a delete and drops an anchorless add naming the cap", () => {
  const md = gotchas(16, [...Array.from({ length: 120 }, (_, i) => `line ${i}`), ""]);
  const r = apply([op({ text: "B's fact (r1 2026-11-07)", from: "entries.jsonl:3" }), op({ op: "replace", anchor: "gotcha number 1 is about its own thing (r0 2026-11-01)" }),
    op({ op: "delete", text: undefined, anchor: "gotcha number 9 is about its own thing (r0 2026-11-01)" })], T(md), ES2, RUN);
  assert.equal(reasons(r), `over the cap: CLAUDE.md: ${lineCount(md)} lines, over 120`);   // after the delete: one line out, one in
  assert.equal(r.applied.map(o => o.op).join(), "delete,replace");
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
  // after its first 40 characters a line may leave words out, never add, change or reorder one (agent-harness-2026-11-08's
  // dropped op: the entry's 199-character fact at 160, three phrases left out, passes)
  const stated = "A note given before the curator session (memory_base) is reverted by its restrict with harness-log.md; give it after ro_rescue, as curator() does with RULES_NOTE (r1 2026-11-08)";
  const words = [...ENTRIES, E({ discoveries: [{ text: stated, affects: ["project"] }, { text: "The lock is never taken twice by one lane (r1 2026-11-08)", affects: ["project"] }] })];
  const w = text => apply([op({ text, from: "entries.jsonl:3" })], T(MD), words, RUN);
  assert.equal(w("A note given before the curator session is reverted by its restrict: give it after ro_rescue, as curator() does RULES_NOTE (r1 2026-11-08)").applied.length, 1);
  assert.equal(reasons(w("A note given before the curator session is reverted by its restrict: give it quietly after ro_rescue (r1 2026-11-08)")), 'not stated by entries.jsonl:3 ("quietly" is not the entry\'s next word)');
  assert.equal(reasons(w("A note given before the curator session is reverted by its restrict: give it before ro_rescue (r1 2026-11-08)")), 'not stated by entries.jsonl:3 ("before" is not the entry\'s next word)');
  assert.equal(reasons(w("A note given before the curator session is reverted by its restrict: give it after ro_rescue, as curator() does RULES_NOTE with (r1 2026-11-08)")), 'not stated by entries.jsonl:3 ("with" is not the entry\'s next word)');
  assert.equal(reasons(w("The lock is never taken twice by one lane; the lock is taken twice (r1 2026-11-08)")), 'not stated by entries.jsonl:3 ("the" is not the entry\'s next word)');
  assert.equal(reasons(w("The lock is taken twice by one lane (r1 2026-11-08)")), "not stated by entries.jsonl:3");   // the first 40 characters are no entry's
  const neg = [...ENTRIES, E({ discoveries: [{ text: "Never pipe a multi-write producer into grep -q in a check: the early exit does not reach the producer, so it is not stopped (r1 2026-11-08)", affects: ["project"] }] })];
  assert.equal(reasons(apply([op({ text: "Never pipe a multi-write producer into grep -q in a check: the early exit does reach the producer (r1 2026-11-08)", from: "entries.jsonl:3" })], T(MD), neg, RUN)), 'not stated by entries.jsonl:3 ("not" left out)');
  // a cut whose lost tail holds a negation is a left-out negation too; a tail cut around it passes
  assert.equal(reasons(apply([op({ text: "Never pipe a multi-write producer into grep -q in a check: the early exit does not reach the producer (r1 2026-11-08)", from: "entries.jsonl:3" })], T(MD), neg, RUN)), 'not stated by entries.jsonl:3 ("not" left out)');
  assert.equal(apply([op({ text: "Never pipe a multi-write producer into grep -q in a check: the early exit does not reach the producer, it is not stopped (r1 2026-11-08)", from: "entries.jsonl:3" })], T(MD), neg, RUN).applied.length, 1);
  assert.equal(r.applied.map(o => o.op).join(), "delete");
  assert.equal(r.rules.length, 1);
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
  assert.equal(reasons(r), 'not stated by entries.jsonl:2 | not stated by entries.jsonl:2 ("then" is not the entry\'s next word)');   // the second: a stated fact's first 40 characters and a tail no entry states
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

test("curator.mjs: apply writes a tier-2 op into ruleTexts and a tier-1 op into texts, each from the base; proposed is tier 3 only", () => {
  const r = apply([op(), op({ section: "## Code rules", text: PROPOSAL, tier: 2 }), op({ op: "replace", section: "## Code rules", anchor: "bash only.", text: PROPOSAL, tier: 2 }),
    op({ section: "## Live system", text: "B's fact (r1 2026-11-07)", from: "entries.jsonl:3", tier: 3 })], T(MD), [...ENTRIES, E({ feature: "B", discoveries: [{ text: "B's fact (r1 2026-11-07)", affects: ["project"] }] })], RUN);
  assert.equal(r.applied.length, 1);
  assert.equal(r.rules.length, 1);   // one key, one op: the later in the list
  assert.equal(r.rules[0].op, "replace");
  assert.equal(r.proposed.map(o => o.tier).join(","), "3");
  assert.equal(r.texts["CLAUDE.md"].includes(PROPOSAL), false, "a tier-2 op is not in texts");
  assert.equal(gotchasLines(r.texts["CLAUDE.md"]).at(-1), `- ${FACT}`);
  assert.equal(r.ruleTexts["CLAUDE.md"].includes(FACT), false, "a tier-1 op is not in ruleTexts");
  assert.equal(r.ruleTexts["CLAUDE.md"], MD.replace("- bash only.", `- ${PROPOSAL}`));
  assert.equal(lineCount(r.texts["CLAUDE.md"]), lineCount(MD) + 1);
  assert.equal(r.ops, r.applied.length + r.rules.length + r.dropped.length);
  // the rules numbered first, then the proposals, one sequence: <run>/<n>
  assert.equal(JSON.stringify([...r.rules, ...r.proposed].map(o => o.n)), "[1,2]");
  // a rules base of its own (a continue's harness-rules tip): the tier-2 op is matched and written there
  const rb = MD.replace("- bash only.", "- bash only.\n- an earlier rule.");
  const own = apply([op({ op: "replace", section: "## Code rules", anchor: "an earlier rule.", text: PROPOSAL, tier: 2 })], T(MD), ENTRIES, RUN, { ruleBase: T(rb) });
  assert.equal(own.rules.length, 1, reasons(own));
  assert.equal(own.ruleTexts["CLAUDE.md"], rb.replace("- an earlier rule.", `- ${PROPOSAL}`));
  assert.equal(own.texts["CLAUDE.md"] === MD, true);
});

test("curator.mjs: the union shadow drops a tier-2 add that takes the merged file past 120 lines while each tier alone fits", () => {
  const pad = Array.from({ length: 112 }, (_, i) => `pad line ${i + 1}`);   // 119 lines with the heading block below
  const md = ["# P", "", "## Code rules", "", "- bash only.", "", ...pad, "## Gotchas", ""].join("\n").replace(/\n$/, "") + "\n";
  assert.equal(lineCount(md), 119);
  const r = apply([op(), op({ section: "## Code rules", text: PROPOSAL, tier: 2 })], T(md), ENTRIES, RUN);
  assert.equal(r.applied.length, 1);
  assert.equal(r.rules.length, 0);
  assert.equal(reasons(r), "over the cap: CLAUDE.md: 121 lines, over 120");
  assert.equal(r.ruleTexts["CLAUDE.md"] === md, true);
  assert.equal(apply([op({ section: "## Code rules", text: PROPOSAL, tier: 2 })], T(md), ENTRIES, RUN).rules.length, 1, "alone it fits");
});

test("curator.mjs: on a continue the union shadow is the rules tip with the facts tip's Gotchas, so neither tier's op takes the merge past 120 lines", () => {
  const pad = Array.from({ length: 111 }, (_, i) => `pad line ${i + 1}`);
  const main = ["# P", "", "## Code rules", "", "- bash only.", "", ...pad, "## Gotchas", ""].join("\n").replace(/\n$/, "") + "\n";
  assert.equal(lineCount(main), 118);
  const factsTip = main + "- an earlier gotcha (r0 2026-11-01)\n", rulesTip = main.replace("- bash only.", "- bash only.\n- an earlier rule.");
  assert.equal(graft(rulesTip, factsTip), rulesTip + "- an earlier gotcha (r0 2026-11-01)\n");   // the merge of both PRs: 120 lines
  const two = apply([op({ section: "## Code rules", text: PROPOSAL, tier: 2 })], T(factsTip), ENTRIES, RUN, { ruleBase: T(rulesTip) });
  assert.equal(`${two.rules.length} ${reasons(two)}`, "0 over the cap: CLAUDE.md: 121 lines, over 120");
  const one = apply([op()], T(factsTip), ENTRIES, RUN, { ruleBase: T(rulesTip) });
  assert.equal(`${one.applied.length} ${reasons(one)}`, "0 over the cap: CLAUDE.md: 121 lines, over 120");
  assert.equal(apply([op()], T(factsTip), ENTRIES, RUN).applied.length, 1, "without a rules tip of its own it fits");
  assert.equal(graft(null, factsTip), factsTip);
});

test("curator.mjs: a continue after main gained lines outside Gotchas counts them in the union shadow, from the CLI's rules merge-base and main", () => {
  // the rules tip was cut from main0; main has since gained 5 Code rules lines (another PR merged): the merge takes them all
  const main0 = ["# P", "", "## Code rules", "", "- bash only.", "", "## Gotchas", "", "- an earlier gotcha (r0 2026-11-01)", ""].join("\n");
  const main1 = main0.replace("- bash only.", ["- bash only.", ...Array.from({ length: 5 }, (_, i) => `- a later rule ${i + 1}.`)].join("\n"));
  const rulesTip = main0.replace("- bash only.", "- bash only.\n- an earlier rule.");
  assert.equal(`${lineCount(main0)} ${lineCount(main1)} ${lineCount(rulesTip)}`, "9 14 10");
  const rule = op({ section: "## Code rules", text: PROPOSAL, tier: 2 });
  // the stale tip alone: 11 lines on the shadow, under 13; the merge would be 15 (main1 + 2 rules)
  assert.equal(apply([rule], T(main1), ENTRIES, RUN, { ruleBase: T(rulesTip), maxLines: 13 }).rules.length, 1);
  const r = apply([rule], T(main1), ENTRIES, RUN, { ruleBase: T(rulesTip), maxLines: 13, drift: { "CLAUDE.md": 5 } });
  assert.equal(`${r.rules.length} ${reasons(r)}`, "0 over the cap: CLAUDE.md: 16 lines, over 13");
  // a tier-1 add is capped on the same shadow
  const f = apply([op()], T(main1), ENTRIES, RUN, { ruleBase: T(rulesTip), maxLines: 15, drift: { "CLAUDE.md": 5 } });
  assert.equal(`${f.applied.length} ${reasons(f)}`, "0 over the cap: CLAUDE.md: 16 lines, over 15");
  // an anchored tier-1 add that fits the facts text but not the union evicts its anchor rather than dropping
  const ev = apply([op({ anchor: "an earlier gotcha (r0 2026-11-01)" })], T(main1), ENTRIES, RUN, { ruleBase: T(rulesTip), maxLines: 15, drift: { "CLAUDE.md": 5 } });
  assert.equal(`${ev.applied.length} ${ev.applied[0]?.evicted} ${reasons(ev)}`, "1 - an earlier gotcha (r0 2026-11-01) ");
  const d = mkdtempSync(join(tmpdir(), "curator-drift-"));
  try {
    const put = (dir, md) => { mkdirSync(join(d, dir)); writeFileSync(join(d, dir, "CLAUDE.md"), md); return join(d, dir); };
    const w = put("w", main1), rb = put("rb", rulesTip), mb = put("mb", main0), mn = put("main", main1);
    writeFileSync(join(d, "ops.json"), JSON.stringify([rule]));
    writeFileSync(join(d, "entries.jsonl"), ENTRIES.map(e => JSON.stringify(e)).join("\n") + "\n");
    const cli = (...x) => JSON.parse(main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl"), rb, ...x], { env: { MEMLINT_LINES: "13" } }).out);
    assert.equal(cli().rules.length, 1, "no merge-base given: no drift");
    assert.equal(cli(mb, mn).dropped.map(x => x.reason).join(), "over the cap: CLAUDE.md: 16 lines, over 13");
    // main moved only inside Gotchas (the facts PR merged): no drift
    put("g", main0.replace("- an earlier gotcha (r0 2026-11-01)", "- an earlier gotcha (r0 2026-11-01)\n- a merged gotcha (r0 2026-11-02)"));
    assert.equal(cli(mb, join(d, "g")).rules.length, 1);
    assert.equal(main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl"), rb, mb], { env: {} }).rc, 2, "a merge-base needs its main");
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("curator.mjs: a rules write that would change a protected section's raw lines is dropped", () => {
  // an unclosed fence in Code rules runs to the end of the file as one entry: replacing it would take Live system with it
  const md = ["# P", "", "## Code rules", "", "- a rule", "```", "- fenced", "", "## Live system", "", "- deploy via scripts/deploy.sh.", ""].join("\n");
  const fenced = sectionEntries(md, "## Code rules")[1].text;
  const r = apply([op({ op: "replace", section: "## Code rules", anchor: fenced, text: PROPOSAL, tier: 2 })], T(md), ENTRIES, RUN);
  assert.equal(r.rules.length, 0);
  assert.equal(reasons(r), "would change the protected section ## Live system");
  assert.equal(r.ruleTexts["CLAUDE.md"] === md, true);
});

test("curator.mjs: body renders the facts, rules and union bodies, rules then proposals numbered <run>/<n>, each naming the other PR", () => {
  const es = [...ENTRIES, E({ feature: "B", discoveries: [{ text: "B's fact (r1 2026-11-07)", affects: ["project"] }] })];
  const r = apply([op(), op({ section: "## Code rules", text: PROPOSAL, tier: 2 }), op({ section: "## Live system", text: "B's fact (r1 2026-11-07)", from: "entries.jsonl:3", tier: 3 }),
    op({ text: "Never stated (r1 2026-11-07)" })], T(MD), es, RUN);
  const facts = body(r, RUN, "facts", "https://example.test/pr/9"), rules = body(r, RUN, "rules", "https://example.test/pr/8"), all = body(r, RUN, "union");
  for (const b of [facts, rules, all]) assert.equal(b.split("\n")[0].includes("4 ops · 1 facts · 1 rules · 2 dropped · 1 proposals"), true, b.split("\n")[0]);
  const inOrder = (b, xs) => xs.filter(s => !b.includes(s)).join(" | ") || (xs.every((s, i) => i === 0 || b.indexOf(xs[i - 1]) < b.indexOf(s)) ? "" : "out of order");
  assert.equal(inOrder(facts, ["## Applied (tier 1)", FACT, "## Proposals (protected, tier 3)", "### 2 · `add` CLAUDE.md · ## Live system (entries.jsonl:3)", "## Dropped", "not stated by entries.jsonl:2", "Rules of this run: https://example.test/pr/9"]), "");
  assert.equal(facts.includes("## Rules (tier 2)") || facts.includes(`- ${PROPOSAL}`), false, "the facts body carries no rule");
  assert.equal(facts.trimEnd().endsWith("Rules of this run: https://example.test/pr/9"), true);
  assert.equal(inOrder(rules, ["## Rules (tier 2)", "### 1 · `add` CLAUDE.md · ## Code rules (entries.jsonl:2)", PROPOSAL, "## Proposals (protected, tier 3)", "### 2 · ", "## Dropped", "Never stated", "Facts of this run: https://example.test/pr/8"]), "");
  assert.equal(rules.includes("## Applied (tier 1)"), false, "the rules body carries no fact");
  assert.equal(inOrder(all, ["## Applied (tier 1)", "## Rules (tier 2)", "### 1 · ", "## Proposals (protected, tier 3)", "### 2 · ", "## Dropped"]), "");
  assert.equal(body(r, RUN, "facts").trimEnd().endsWith("Rules of this run: none"), true);
  assert.equal(body(r, RUN, "rules").trimEnd().endsWith("Facts of this run: none"), true);
  assert.equal(body(r, RUN), all, "the union by default");
  assert.equal(/For you to paste|protected section: a proposal/.test(all), false);   // a proposal is listed once, as a proposal
  const at2 = body({ ...r, applied: [{ ...r.applied[0], why: "ask @mh550 first" }] }, RUN, "facts");
  assert.equal(/(^|[^`])@mh550/.test(at2.replace(/@​/g, "")), false);   // a mention outside a fence would notify
  assert.equal(at2.includes("@​mh550"), true);
  const sec = body(apply([op({ section: "## @mh550 see" })], T(MD), ENTRIES, RUN), RUN);   // a section no file has, in Dropped
  assert.equal(/(^|[^`])@mh550/.test(sec.replace(/@​/g, "")), false);
  const empty = body(apply([], T(MD), ENTRIES, RUN), RUN);
  assert.equal(/## (Applied|Rules|Proposals|Dropped)/.test(empty), false);
  const capped = body(apply([op()], T(gotchas(15)), ENTRIES, RUN), RUN, "facts");
  assert.equal(capped.includes("over the cap: ## Gotchas: 16 entries, over 15"), true);
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
    assert.equal(`${j.ops} ${j.applied.length} ${j.rules.length} ${j.proposed.length} ${j.dropped.length} ${j.rederived} ${"refused" in j}`, "2 1 1 0 0 1 false");
    assert.equal(j.files.join(), "CLAUDE.md");
    assert.equal(j.texts, undefined);
    // the rules: in the JSON line for memory_pr's rules pass, never written into the worktree
    assert.equal(`${j.ruleFiles.join()} ${Object.keys(j.ruleTexts).join()} ${j.ruleTexts["CLAUDE.md"].includes(PROPOSAL)} ${j.ruleTexts["CLAUDE.md"].includes(FACT)}`, "CLAUDE.md CLAUDE.md true false");
    assert.equal(readFileSync(join(w, "CLAUDE.md"), "utf8").includes(PROPOSAL), false);
    assert.equal(gotchasLines(readFileSync(join(w, "CLAUDE.md"), "utf8")).at(-1), `- ${FACT}`);
    writeFileSync(join(d, "result.json"), r.out);
    const b = main(["body", join(d, "result.json"), RUN], { env: {} });
    assert.equal(b.rc, 0);
    assert.equal(b.out.includes(PROPOSAL), true);
    assert.equal(main(["body", join(d, "result.json"), RUN, "facts", "https://example.test/pr/2"], { env: {} }).out.includes(PROPOSAL), false);
    assert.equal(main(["body", join(d, "result.json"), RUN, "rules", "https://example.test/pr/2"], { env: {} }).out.includes("Facts of this run: https://example.test/pr/2"), true);
    assert.equal(main(["body", join(d, "result.json"), RUN, "neither"], { env: {} }).rc, 2);
    // a rules base directory of its own: the tier-2 op is cut from it
    const rb = mkdtempSync(join(d, "rb-"));
    writeFileSync(join(rb, "CLAUDE.md"), MD.replace("- bash only.", "- bash only.\n- an earlier rule."));
    writeFileSync(join(w, "CLAUDE.md"), MD);
    const two = JSON.parse(main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl"), rb], { env: {} }).out);
    assert.equal(two.ruleTexts["CLAUDE.md"].includes("- an earlier rule."), true);
    writeFileSync(join(w, "CLAUDE.md"), MD);
    writeFileSync(join(d, "bad.json"), "{not json");
    const bad = main(["validate", join(d, "bad.json")], { env: {} });
    assert.equal(bad.rc, 1);
    assert.match(bad.out, /^not JSON: /);
    const badApply = main(["apply", join(d, "bad.json"), w, RUN, join(d, "entries.jsonl")], { env: {} });
    assert.equal(badApply.rc, 1);
    assert.match(JSON.parse(badApply.out).invalid, /^not JSON: /);
    writeFileSync(join(w, "CLAUDE.md"), gotchas(3, [...Array.from({ length: 112 }, (_, i) => `line ${i}`), ""]));
    const capped = JSON.parse(main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl")], { env: { MEMLINT_LINES: "200" } }).out);
    assert.equal(capped.applied.length, 1);   // MEMLINT_LINES raises the cap
    const full = gotchas(15);
    writeFileSync(join(w, "CLAUDE.md"), full);
    const no = JSON.parse(main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl")], { env: {} }).out);
    assert.equal(`${no.dropped[0].reason} ${no.files.length}`, "over the cap: ## Gotchas: 16 entries, over 15 0");
    assert.equal(readFileSync(join(w, "CLAUDE.md"), "utf8") === full, true);
    // a symlinked CLAUDE.md is no file: never read through, never written through
    const outside = join(d, "outside.md");
    writeFileSync(outside, MD); rmSync(join(w, "CLAUDE.md")); symlinkSync(outside, join(w, "CLAUDE.md"));
    const link = JSON.parse(main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl")], { env: {} }).out);
    assert.equal(link.dropped[0].reason, "no CLAUDE.md on the base");
    assert.equal(readFileSync(outside, "utf8") === MD, true);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("curator.mjs: .claude/CLAUDE.md is a third file: validated, capped and written as CLAUDE.md; a rules file is refused; never through a symlinked .claude/", () => {
  const dc = ".claude/CLAUDE.md", why = x => validate(JSON.stringify(x)).why;
  assert.equal(validate(JSON.stringify([op({ file: dc })])).ok, true);
  assert.equal(why([op({ file: ".claude/rules/x.md" })]), 'op 1: file ".claude/rules/x.md" is none of CLAUDE.md, .harness/project.md, .claude/CLAUDE.md');
  const md = gotchas(15);
  assert.equal(capCheck(dc, md, md + "- one more (r1 2026-11-07)\n"), "## Gotchas: 16 entries, over 15");
  assert.equal(capCheck(dc, gotchas(3, Array.from({ length: 116 }, (_, i) => `l${i}`)), gotchas(4, Array.from({ length: 116 }, (_, i) => `l${i}`))), ".claude/CLAUDE.md: 124 lines, over 120");
  const r = apply([op({ file: dc })], { "CLAUDE.md": null, ".harness/project.md": null, [dc]: MD }, ENTRIES, RUN);
  assert.equal(`${r.applied.length} ${r.dropped.length}`, "1 0");
  assert.equal(gotchasLines(r.texts[dc]).at(-1), `- ${FACT}`);
  assert.equal(r.texts["CLAUDE.md"], null);
  const d = mkdtempSync(join(tmpdir(), "curator-"));
  try {
    writeFileSync(join(d, "ops.json"), JSON.stringify([op({ file: dc })]));
    writeFileSync(join(d, "entries.jsonl"), ENTRIES.map(e => JSON.stringify(e)).join("\n") + "\n");
    const w = mkdtempSync(join(d, "w-")), cli = () => JSON.parse(main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl")], { env: {} }).out);
    mkdirSync(join(w, ".claude")); writeFileSync(join(w, dc), MD);
    const j = cli();
    assert.equal(`${j.applied.length} ${j.files.join()}`, "1 .claude/CLAUDE.md");
    assert.equal(gotchasLines(readFileSync(join(w, dc), "utf8")).at(-1), `- ${FACT}`);
    // a symlinked .claude/ is no directory of the worktree: its CLAUDE.md is never read through, never written through
    const out = join(d, "outside"); mkdirSync(out); writeFileSync(join(out, "CLAUDE.md"), MD);
    rmSync(join(w, ".claude"), { recursive: true }); symlinkSync(out, join(w, ".claude"));
    const link = cli();
    assert.equal(`${link.dropped[0]?.reason} ${link.files.length}`, "no .claude/CLAUDE.md on the base 0");
    assert.equal(readFileSync(join(out, "CLAUDE.md"), "utf8") === MD, true);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("curator.mjs: the curator prompt renders with no placeholder left", () => {
  const tpl = readFileSync(new URL("../../prompts/curator.md", import.meta.url), "utf8");
  const part = readFileSync(new URL("../../prompts/parts/where-things-go-readonly.md", import.meta.url), "utf8");
  for (const p of ["{{RUN_ID}}", "{{PROJECT}}", "{{RUN_DIR}}", "{{MEMORY_BASE}}", "{{MEMORY_ANSWERS}}"]) assert.equal(tpl.includes(p), true, p);
  const env = { HARNESS_RUN_ID: RUN, HARNESS_PROJECT: "p", HARNESS_RUN_DIR: ".harness/runs/r1", HARNESS_MEMORY_BASE: "/tmp/s/memory-base", HARNESS_DECISIONS: "one file per decision" };
  const out = assemble(tpl, [{ title: null, body: part }], env);
  assert.equal((out.match(/\{\{/g) ?? []).length, 0);
  for (const w of [".harness/runs/r1/memory-ops.json", "`add`", "`replace`", "`delete`", "write gate", "never a file", "/tmp/s/memory-base/CLAUDE.md", "/tmp/s/memory-base/.claude/CLAUDE.md", "This session is read-only"])
    assert.equal(out.includes(w), true, w);
  assert.equal(/^## Where things go/m.test(tpl), false);   // the part brings its own heading
});

// ---- Michael's answers (N2-03): rendered into the curator prompt and enforced by apply ----
const ans = o => ({ run: "r0", project: "p", n: 1, tier: 2, verdict: "declined", why: "the suite runs itself", file: "CLAUDE.md", section: "## Code rules", text: PROPOSAL, key: itemKey({ op: "add", text: PROPOSAL }), at: "2026-11-08T10:00:00Z", ...o });

test("curator.mjs answers: declined then accepted, newest first, (none yet) for none, cut at --max-bytes naming how many were left out", () => {
  assert.equal(answersText([], "p"), "(none yet)");
  // a hand-written row without a why reads as a verdict with none, never `: undefined`
  assert.equal(answersText([ans({ why: undefined })], "p").split("\n")[1], `- ${PROPOSAL} (r0/1)`);
  assert.equal(answersText([ans({ project: "q" })], "p"), "(none yet)");   // another project's verdicts are not this one's
  const rows = [ans({ n: 1, text: "old declined", at: "2026-11-01T00:00:00Z" }), ans({ n: 2, verdict: "accepted", text: "an accepted line", why: "placed", at: "2026-11-05T00:00:00Z" }),
    ans({ n: 3, text: "new declined", why: "no", at: "2026-11-07T00:00:00Z" })];
  assert.equal(answersText(rows, "p"), ["Michael declined (never propose again):", "- new declined (r0/3): no", "- old declined (r0/1): the suite runs itself", "",
    "Michael accepted (already his to place):", "- an accepted line (r0/2)"].join("\n"));
  // a replaced verdict is its latest row alone
  const re = answersText([...rows, ans({ n: 1, verdict: "accepted", text: "old declined", at: "2026-11-08T00:00:00Z" })], "p");
  assert.equal(`${re.includes("- old declined (r0/1): ")} ${re.split("\n").at(-2)}`, "false - old declined (r0/1)");
  const many = Array.from({ length: 60 }, (_, i) => ans({ n: i + 1, text: `declined line number ${i + 1} with some words to make it long`, at: `2026-11-08T10:${String(i).padStart(2, "0")}:00Z` }));
  const cut = answersText(many, "p", 1000);
  assert.equal(Buffer.byteLength(cut) <= 1000, true);
  assert.equal(cut.split("\n")[1], "- declined line number 60 with some words to make it long (r0/60): the suite runs itself");   // the newest kept
  const kept = cut.split("\n").filter(l => l.startsWith("- ")).length;
  assert.equal(cut.split("\n").at(-1), `(${60 - kept} more left out: the prompt's cap is 1000 bytes; ledger/memory-answers.jsonl has them all)`);
});

test("curator.mjs apply: an answered tier-2 or tier-3 op is dropped naming <run>/<n>; a tier-1 op and a different sentence never match, not even one sharing its 40-character key", () => {
  const rule = op({ section: "## Code rules", text: PROPOSAL, tier: 2 });
  const declined = apply([rule], T(MD), ENTRIES, RUN, { answers: [ans()] });
  assert.equal(`${declined.rules.length} ${reasons(declined)}`, "0 declined by Michael (r0/1: the suite runs itself)");
  const long = apply([rule], T(MD), ENTRIES, RUN, { answers: [ans({ why: "w".repeat(120) })] });
  assert.equal(reasons(long), `declined by Michael (r0/1: ${"w".repeat(80)}…)`);
  const accepted = apply([rule], T(MD), ENTRIES, RUN, { answers: [ans({ n: 4, verdict: "accepted" })] });
  assert.equal(`${accepted.rules.length} ${reasons(accepted)}`, "0 accepted by Michael (r0/4)");
  // the key alone decides: the same sentence under another heading is the same rule (a protected one: tier 3)
  const t3 = apply([op({ section: "## Live system", text: PROPOSAL, tier: 3 })], T(MD), ENTRIES, RUN, { answers: [ans()] });
  assert.equal(`${t3.proposed.length} ${reasons(t3)}`, "0 declined by Michael (r0/1: the suite runs itself)");
  // tier 1 is never matched: a fact is not a rule Michael declines
  const fact = apply([op()], T(MD), ENTRIES, RUN, { answers: [ans({ text: FACT, key: itemKey({ op: "add", text: FACT }) })] });
  assert.equal(`${fact.applied.length} ${fact.dropped.length}`, "1 0");
  // a different key: the rule lands
  const other = apply([rule], T(MD), ENTRIES, RUN, { answers: [ans({ text: "another rule entirely, of other words", key: itemKey({ op: "add", text: "another rule entirely, of other words" }) })] });
  assert.equal(`${other.rules.length} ${other.dropped.length}`, "1 0");
  // a sentence sharing the first 40 characters (lineKey) is another rule: the whole text decides, not the key's prefix
  const twin = "Run the fast tier once, last, after the suite is cached";
  assert.equal(itemKey({ op: "add", text: twin }), itemKey({ op: "add", text: PROPOSAL }));
  const near = apply([rule], T(MD), ENTRIES, RUN, { answers: [ans({ text: twin, key: itemKey({ op: "add", text: twin }) })] });
  assert.equal(`${near.rules.length} ${near.dropped.length}`, "1 0");
  // a declined delete matches a delete of that line only, never an add of it
  const del = { op: "delete", anchor: "bash only." };
  assert.equal(itemKey(del) === itemKey({ op: "add", text: "bash only." }), false);
  assert.equal(apply([rule], T(MD), ENTRIES, RUN, { answers: [ans({ key: itemKey({ op: "delete", anchor: PROPOSAL }) })] }).rules.length, 1);
});

test("curator.mjs main: apply --answers <file> --project <p> drops the project's answered rule; answers <file> <project> renders the prompt's block", () => {
  const d = mkdtempSync(join(tmpdir(), "curator-"));
  try {
    writeFileSync(join(d, "ops.json"), JSON.stringify([op({ section: "## Code rules", text: PROPOSAL, tier: 2 })]));
    writeFileSync(join(d, "entries.jsonl"), ENTRIES.map(e => JSON.stringify(e)).join("\n") + "\n");
    writeFileSync(join(d, "answers.jsonl"), `not json\n${JSON.stringify(ans())}\n`);
    const w = mkdtempSync(join(d, "w-"));
    writeFileSync(join(w, "CLAUDE.md"), MD);
    const run = p => JSON.parse(main(["apply", join(d, "ops.json"), w, RUN, join(d, "entries.jsonl"), "--answers", join(d, "answers.jsonl"), "--project", p], { env: {} }).out);
    assert.equal(run("p").dropped.map(x => x.reason).join(), "declined by Michael (r0/1: the suite runs itself)");
    assert.equal(run("q").rules.length, 1);
    assert.equal(main(["answers", join(d, "answers.jsonl"), "p", "--max-bytes", "4000"], { env: {} }).out, `Michael declined (never propose again):\n- ${PROPOSAL} (r0/1): the suite runs itself\n`);
    assert.equal(main(["answers", join(d, "missing.jsonl"), "p"], { env: {} }).out, "(none yet)\n");
    // a declined delete reads as one: the curator is told never to propose deleting that line
    writeFileSync(join(d, "del.jsonl"), JSON.stringify(ans({ text: "bash only.", key: itemKey({ op: "delete", anchor: "bash only." }) })) + "\n");
    assert.equal(main(["answers", join(d, "del.jsonl"), "p"], { env: {} }).out.split("\n")[1], "- delete: bash only. (r0/1): the suite runs itself");
  } finally { rmSync(d, { recursive: true, force: true }); }
});

// ---- a comment line is not a Gotcha (decisions/2026-11-09-thin-verify-and-comment-lines): the template's one-line HTML
// comment under `## Gotchas` counted as an entry, so capCheck saw 15 facts as over the cap (PR #137 evicted at 14 facts
// and the comment: at the cap by this count, not under it) ----
const COMMENT = "<!-- At most 15 lines, one fact each, edited in place: replace a wrong or least useful line, never rewrite the section. -->";
test("curator.mjs: the Gotchas comment line is no entry: at 15 facts and the comment a plain add is dropped and an anchored add evicts; at 14 a plain add lands; an add into a section holding only the comment lands under it", () => {
  const withC = n => gotchas(n).replace("## Gotchas\n\n", `## Gotchas\n${COMMENT}\n\n`), full = withC(15);
  assert.equal(sectionEntries(full, "## Gotchas").length, 15);
  assert.equal(reasons(apply([op()], T(full), ENTRIES, RUN)), "over the cap: ## Gotchas: 16 entries, over 15");
  const ev = apply([op({ anchor: G(3) })], T(full), ENTRIES, RUN);
  assert.equal(`${ev.applied.length} ${ev.applied[0]?.evicted} ${reasons(ev)}`, `1 - ${G(3)} `);
  assert.equal(`${gotchasLines(ev.texts["CLAUDE.md"]).length} ${ev.texts["CLAUDE.md"].includes(`${COMMENT}\n`)}`, "15 true");   // the comment stays
  const at = apply([op()], T(withC(14)), ENTRIES, RUN);
  assert.equal(`${at.applied.length} ${at.applied[0]?.evicted} ${reasons(at)} ${gotchasLines(at.texts["CLAUDE.md"]).length}`, "1 undefined  15");
  assert.equal(capCheck("CLAUDE.md", withC(14), at.texts["CLAUDE.md"]), null);
  const only = apply([op()], T(withC(0)), ENTRIES, RUN);
  assert.equal(only.texts["CLAUDE.md"].split("\n").slice(2, 6).join("|"), `## Gotchas|${COMMENT}|- ${FACT}|`);
});

// the reviewer's verdicts (decisions/2026-11-09-memory-reviewer): facts/<i> in apply's order, rules/<n> by number
const V = (...fails) => ({ ops: fails.map(([id, reason]) => ({ id, holds: !reason, reason: reason ?? null })) });
const F2 = "A second fact the stub's B entry states for itself (r1 2026-11-07)", F2E = E({ feature: "B", discoveries: [{ text: F2, affects: ["project"] }] });

test("curator.mjs apply: --verdicts drops a failed fact at its write with review: <reason> (<id>), after every other step; without verdicts nothing is dropped by verdict; the rules keep every op", () => {
  const es = [...ENTRIES, F2E], ops = [op(), op({ text: F2, from: "entries.jsonl:3" }), op({ section: "## Code rules", text: PROPOSAL, tier: 2 })];
  const dry = apply(ops, T(MD), es, RUN);
  assert.equal(`${dry.applied.length} ${dry.rules.length} ${reasons(dry)}`, "2 1 ");
  const v = V(["facts/1", "7 files (q2)"], ["facts/2"], [`rules/${dry.rules[0].n}`, "a duplicate (q4)"]);
  const r = apply(ops, T(MD), es, RUN, { verdicts: v });
  assert.equal(reasons(r), "review: 7 files (q2) (facts/1)");
  assert.equal(`${r.applied.map(o => o.text).join()} | ${r.rules.length}`, `${F2} | 1`);
  assert.equal(r.texts["CLAUDE.md"].includes(FACT), false);
  assert.equal(r.ruleTexts["CLAUDE.md"], dry.ruleTexts["CLAUDE.md"], "the rules PR carries every op under every policy");
  assert.equal(apply(ops, T(MD), es, RUN, { verdicts: V(["facts/1"], ["facts/2"]) }).texts["CLAUDE.md"], dry.texts["CLAUDE.md"]);
  assert.equal(reasons(apply(ops, T(MD), es, RUN, { verdicts: V(["facts/2"]) })), "review: not reviewed (facts/1)", "a fact with no verdict never lands");
  // the duplicate-key choice stays as the full list made it: the later entry's op kept, failed; the earlier one never lands
  const dup = [op({ text: "A third fact said twice by its two entries, the later one (r1 2026-11-07)", from: "entries.jsonl:3" }), op({ text: "A third fact said twice by its two entries (r1 2026-11-07)" })];
  const des = [ENTRIES[0], E({ discoveries: [{ text: "A third fact said twice by its two entries (r1 2026-11-07)", affects: ["project"] }] }), E({ feature: "B", discoveries: [{ text: "A third fact said twice by its two entries, the later one (r1 2026-11-07)", affects: ["project"] }] })];
  const dd = apply(dup, T(MD), des, RUN), dv = apply(dup, T(MD), des, RUN, { verdicts: V(["facts/1", "no incident (q1)"]) });
  assert.equal(`${dd.applied.length} ${dd.dropped.length}`, "1 1");
  assert.equal(`${dv.applied.length} ${reasons(dv)}`, "0 review: no incident (q1) (facts/1) | duplicate key; entries.jsonl:3 kept");
  assert.equal(dv.texts["CLAUDE.md"], MD);
});

test("curator.mjs apply: the landing with --verdicts is the dry run's texts minus the failed ops' writes; a held op the failed one made room for is dropped over the cap", () => {
  const es = [...ENTRIES, F2E], md = gotchas(13), ops = [op({ anchor: G(3) }), op({ text: F2, from: "entries.jsonl:3" }), op({ op: "replace", anchor: G(5), text: FACT.replace("needs", "wants") })];
  const xs = [E({ discoveries: [{ text: FACT, affects: ["project"] }, { text: FACT.replace("needs", "wants"), affects: ["project"] }] }), F2E];
  const dry = apply(ops, T(md), [ENTRIES[0], ...xs], RUN), ids = dry.applied.map((o, i) => [`facts/${i + 1}`, o.text]);
  assert.equal(ids.length, 3, reasons(dry));
  const fail = ids.find(([, t]) => t === F2)[0], r = apply(ops, T(md), [ENTRIES[0], ...xs], RUN, { verdicts: V(...ids.map(([id]) => [id, id === fail ? "a duplicate (q4)" : undefined])) });
  assert.equal(r.texts["CLAUDE.md"], dry.texts["CLAUDE.md"].replace(`- ${F2}\n`, ""));
  assert.equal(JSON.stringify(r.applied), JSON.stringify(dry.applied.filter(o => o.text !== F2)));
  // at 15: the delete makes room for the add; with the delete failed the add would be the 16th, so it goes too
  const full = gotchas(15), two = [op(), op({ op: "delete", text: undefined, anchor: G(4) })], d2 = apply(two, T(full), ENTRIES, RUN);
  assert.equal(d2.applied.map(o => o.op).join(), "delete,add");
  const r2 = apply(two, T(full), ENTRIES, RUN, { verdicts: V(["facts/1", "a check reads it (q2)"], ["facts/2"]) });
  assert.equal(reasons(r2), "review: a check reads it (q2) (facts/1) | over the cap once the review's failed ops were dropped: ## Gotchas: 16 entries, over 15");
  assert.equal(r2.texts["CLAUDE.md"], full);
});

test("curator.mjs body: --review puts ## Review after the head and before Applied; over BODY_MAX the review's table goes first and its one-line verdicts never", () => {
  const r = apply([op()], T(MD), ENTRIES, RUN), rv = "## Review\n\n1 reviewed · 0 held · 1 failed\n\n- facts/1 **fails**: 7 files (q2)\n\n| Op | Q | What you ran or read | What you saw | Holds |\n|---|---|---|---|---|\n| facts/1 | 2 | git grep | 7 files | no |\n";
  const b = body(r, RUN, "facts", "", rv), at = s => b.indexOf(s);
  assert.ok(at("Project memory curated") === 0 && at("Project memory curated") < at("## Review") && at("## Review") < at("- facts/1 **fails**: 7 files (q2)")
    && at("- facts/1 **fails**") < at("| facts/1 | 2 |") && at("| facts/1 | 2 |") < at("## Applied (tier 1)"), b);
  assert.equal(body(r, RUN, "facts", ""), body(r, RUN, "facts", "", ""), "no review, the body as before");
  const many = Array.from({ length: 50 }, (_, i) => op({ text: `${FACT.slice(0, -14)} number ${i} (r1 2026-11-07)`, why: "w".repeat(290) }));
  const big = { ...r, applied: many }, table = Array.from({ length: 200 }, (_, i) => `| facts/${i} | 1 | ${"r".repeat(150)} | ${"s".repeat(150)} | yes |`).join("\n");
  const huge = body(big, RUN, "facts", "", `## Review\n\n- facts/1 holds\n- facts/2 **fails**: x (q1)\n\n| Op | Q | What you ran or read | What you saw | Holds |\n|---|---|---|---|---|\n${table}\n`);
  assert.ok(Buffer.byteLength(huge) <= 60000);
  assert.equal(`${huge.includes("| facts/7 | 1 |")} ${huge.includes("- facts/2 **fails**: x (q1)")} ${huge.includes("number 49")}`, "false true true", "the table goes before any applied op");
  assert.ok(huge.includes("_The review's table was cut"), "a line says the table was cut");
});

test("curator.mjs body: a fact the review dropped is a failed one, named in ## Review alone: never in the head's dropped count or ## Dropped", () => {
  const es = [...ENTRIES, F2E], ops = [op(), op({ text: F2, from: "entries.jsonl:3" })];
  const r = apply(ops, T(MD), es, RUN, { verdicts: V(["facts/1", "7 files (q2)"], ["facts/2"]) });
  assert.equal(reasons(r), "review: 7 files (q2) (facts/1)");
  const b = body(r, RUN, "facts", "");
  assert.equal(`${b.includes(" · 0 dropped · ")} ${b.includes("## Dropped")} ${b.includes("7 files (q2)")}`, "true false false", b.split("\n")[0]);
  const g = apply([op(), op({ section: "## Nowhere" })], T(MD), ENTRIES, RUN, { verdicts: V(["facts/1"]) });
  assert.equal(`${g.dropped.length} ${body(g, RUN, "facts", "").includes(" · 1 dropped · ")}`, "1 true", "the gate's drops still count");
});

test("curator.mjs apply: in the --verdicts landing a held add that a failed replace leaves a duplicate of is dropped, never written twice", () => {
  const md = gotchas(3), es = [ENTRIES[0], E({ discoveries: [{ text: FACT, affects: ["project"] }, { text: G(2), affects: ["project"] }] })];
  const ops = [op({ op: "replace", anchor: G(2), text: FACT }), op({ text: G(2) })], dry = apply(ops, T(md), es, RUN);
  assert.equal(`${dry.applied.length} ${reasons(dry)}`, "2 ");
  const r = apply(ops, T(md), es, RUN, { verdicts: V(["facts/1", "a check reads it (q2)"], ["facts/2"]) });
  assert.equal(reasons(r), "review: a check reads it (q2) (facts/1) | review: already in ## Gotchas once the review's failed ops were dropped (facts/2)");
  assert.equal(r.texts["CLAUDE.md"], md);
});
