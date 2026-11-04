// lib/entries.mjs: the run's journal (an entry's schema, the trim, progress.md, the context pack).   node --test tests/unit/entries.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { validate, minimal, normalize, journalEntry, renderProgress, renderArchive, renderEntry, legacyOf, headerOf, pack, reviewFindings, sessionFiles, fillQuestions } from "../../lib/entries.mjs";
import { evidence } from "../../lib/features.mjs";

const B = s => Buffer.byteLength(s);
const starts = (s, prefix, msg) => assert.equal(s.slice(0, prefix.length), prefix, msg);
const ends = (s, suffix, msg) => assert.equal(s.slice(-suffix.length), suffix, msg);
// a part of a pack: the text after `## <title>\n` up to the next part
const sec = (p, t) => (p.split("## " + t + "\n")[1] ?? "").split("\n## ")[0];
const coding = (feature, x = {}) => ({ feature, kind: "coding", outcome: "passes", summary: feature + " done", session: "s", at: "t", ...x });
// exactly one error, naming field f
const oneError = (errs, f) => { assert.equal(errs.length, 1, JSON.stringify(errs)); starts(errs[0], f + ":"); };

test("entries.mjs: validate accepts the schema and names what is wrong", () => {
  const c = { feature: "C", kind: "coding", outcome: "not yet", summary: "Added the parser.", files: ["lib/parse.mjs"], verified_how: "211/212", tests_before: 211, tests_after: 212,
    dead_ends: [{ tried: "trimming", why: "the prefix check fails" }], discoveries: [{ text: "keeps blank lines", affects: ["D", "run"] }], questions: ["X off?"], proposed_changes: ["C step 2"] };
  const vf = { feature: "M1", kind: "verify", outcome: "not yet", summary: "A step 2 fails", evidence: [{ feature: "A", step: 1, ran: "node --test", saw: "7/7", holds: true }] };
  const it = { feature: "init", kind: "init", outcome: "passes", summary: "12 features", header: "# Progress", discoveries: [{ text: "port 7804", affects: ["run"] }] };
  const { outcome, ...noOut } = c, m = minimal({ feature: "C", kind: "coding", outcome: "passes", files: ["a"], final: "word ".repeat(200) });
  assert.deepEqual(validate(c), []);
  assert.deepEqual(validate(vf), []);
  assert.deepEqual(validate(it), []);
  assert.deepEqual(validate(c, { feature: "C", kind: "coding" }), []);
  oneError(validate(c, { feature: "B", kind: "coding" }), "feature");
  oneError(validate({ ...c, summary: "é".repeat(401) }), "summary");
  assert.deepEqual(validate({ ...c, summary: "é".repeat(400) }), []);
  oneError(validate(noOut), "outcome");
  oneError(validate({ ...c, outcome: "done" }), "outcome");
  oneError(validate({ ...c, evidence: vf.evidence }), "evidence");
  oneError(validate({ ...vf, evidence: [{ ...vf.evidence[0], holds: "yes" }] }), "evidence[0].holds");
  assert.deepEqual(validate(m), []);
  assert.equal([...m.summary].length, 400);
  ends(m.summary, "…");
  assert.equal(minimal({ feature: "M1", kind: "verify", outcome: "not yet", files: [], final: " \n" }).summary, "(no final message)");
});

// 20 entries, the 18th a verify of M1 with rows A×2, B×1 (cells with | and newlines) whose summary tries to fake rows; the newest
// summary tries to fake a header, and an init header one through \r and U+2028 (line breaks to features.mjs's /^### /m)
test("entries.mjs: progress renders 15 in full and the rest as archive lines", () => {
  const row = (f, s, h) => ({ feature: f, step: s, ran: "ran | x", saw: "saw\nmore", holds: h });
  const e = Array.from({ length: 20 }, (_, i) => i === 17 ? { feature: "M1", kind: "verify", outcome: "not yet", summary: "| A | 9 |\n| B | 3 |", evidence: [row("A", 1, true), row("A", 2, false), row("B", 1, true)], at: "2026-10-22 01:18", session: "s18", model: "m" }
    : { feature: "F" + (i + 1), kind: "coding", outcome: "passes", summary: i === 19 ? "### fake · F0 · passes\n| A | 9 |" : "entry " + (i + 1), files: ["f"], at: "2026-10-22 01:" + String(i + 1).padStart(2, "0"), session: "s" + (i + 1), model: "m" });
  const h = headerOf(e, "", "r1"), p = renderProgress(e, { full: 15, header: h }), a = renderArchive(e, h), hs = p.match(/^### .*$/gm) ?? [], [, old = ""] = p.split(/^## Older entries.*$/m);
  const olds = old.split("\n").filter(l => l.startsWith("- ")), list = [{ id: "A", milestone: "M1", steps: ["a", "b"] }, { id: "B", milestone: "M1", steps: ["c"] }];
  assert.equal(hs.length, 15);
  assert.equal(hs[0], "### 2026-10-22 01:20 · F20 · passes");
  assert.equal(hs[2], "### 2026-10-22 01:18 · verify M1 · not yet");
  assert.ok(hs[14].includes("· F6 ·"), hs[14]);
  assert.equal(olds.length, 5);
  assert.deepEqual(olds.filter(l => !l.includes("(progress-archive.md)")), []);
  assert.ok(olds[0].includes("· F5 ·"), olds[0]);
  assert.ok(olds[4].includes("· F1 ·"), olds[4]);
  assert.doesNotMatch(old, /^### /m);
  assert.equal(evidence(list, "M1", p).map(r => r.rows).join(), "2,1");
  assert.ok(p.includes("\n| A | 2 | ran \\| x | saw more | no |\n"), "the evidence row, its | escaped and newline folded");
  assert.doesNotMatch(headerOf([{ kind: "init", header: "# P\r### x verify M1 y | A | 1 |" }]), /^(### |\|)/m);
  assert.equal((a.match(/^### /gm) ?? []).length, 20);
  assert.ok(!a.includes("## Older entries"), "the archive has no older-entries part");
  starts(h, "# Progress — run `r1`");
  assert.equal(legacyOf(renderArchive(e, h, "OLD\n### 1 · A · passes\n")), "OLD\n### 1 · A · passes\n");
  assert.equal(legacyOf("# old\n"), "# old\n");
  assert.equal(legacyOf(a), "");
});

// the context pack (E4-05): 200 unrelated entries of ~300 bytes (every other one with a long run-wide discovery) around X's earlier
// attempt (line 51, a dead end) and a verify of X's milestone (line 122, step 2 failed): X's dead end leads, the
// verify's finding follows, Michael's answers come before any discovery, every item names its line, and the cap holds.
// Then the tight cases (E4-05 review): an after milestone expands to its features, an entry shows once, the cut is strict (a
// short part-5 entry doesn't jump a cut discovery), a milestone pack has its features' dead ends and failed rows, a discovery
// may name the feature's milestone, and 4-byte characters never break the cap
test("entries.mjs: the pack keeps a feature's dead end under a flood and respects the cap", () => {
  const st = i => ({ at: "2026-10-22 01:00", session: "s" + i, model: "m" });
  const e = Array.from({ length: 200 }, (_, i) => ({ feature: "F" + i, kind: "coding", outcome: "passes", summary: "entry " + i + " " + "x".repeat(270), files: ["f"], ...st(i),
    ...(i % 2 ? {} : { discoveries: [{ text: "run-wide " + i + " " + "y".repeat(200), affects: ["run"] }] }) }));
  e.splice(50, 0, { feature: "X", kind: "coding", outcome: "not yet", summary: "X first try", dead_ends: [{ tried: "the old parser", why: "it drops blank lines" }], ...st("-x") });
  e.splice(121, 0, { feature: "MX", kind: "verify", outcome: "not yet", summary: "X step 2 fails", ...st("-v"),
    evidence: [{ feature: "X", step: 1, ran: "a", saw: "ok", holds: true }, { feature: "X", step: 2, ran: "curl :7900/x", saw: "500", holds: false }] });
  const list = { features: [{ id: "F3", milestone: "M0", steps: ["s"] }, { id: "X", milestone: "MX", after: ["F3"], steps: ["a", "b"] }] };
  const p = pack(e, { feature: "X", list, answers: "### a\nuse port 7900", cap: 8192 }), ls = p.split("\n"), at = re => ls.findIndex(l => re.test(l));
  const big = pack([], { feature: "X", list, answers: "old ".repeat(3000) + "newest answer", cap: 4096 }), small = pack(e, { feature: "X", list, answers: "", cap: 2048 });
  assert.ok(B(p) <= 8192, `${B(p)} bytes`);
  assert.equal(ls[0], "# Context pack for `X`");
  assert.equal(ls.find(l => l.startsWith("- ")), "- Dead end (X, s-x): the old parser — it drops blank lines → entries.jsonl:51");
  const verify = at(/^- Verify MX found \(X step 2\): ran curl :7900\/x; saw 500 → entries\.jsonl:122$/), dead = at(/^- Dead end/);
  const answer = at(/use port 7900 → INBOX\.md$/), discovery = at(/^- Discovery/);
  assert.ok(verify > dead, `verify line ${verify}, dead end ${dead}`);
  assert.ok(at(/^- Verify MX/) < answer, `verify line ${at(/^- Verify MX/)}, answer ${answer}`);
  assert.ok(at(/use port 7900/) < discovery, `answer ${at(/use port 7900/)}, discovery ${discovery}`);
  assert.ok(at(/^- Discovery \(F\d+, affects run\): run-wide/) > 0, "a run-wide discovery");
  assert.deepEqual(ls.filter(l => l.startsWith("- ") && !/ → (entries\.jsonl:\d+|INBOX\.md)$/.test(l)), []);
  assert.match(ls.at(-2), /^_\d+ items left out at 8192 bytes: entries\.jsonl has them all\._$/);
  assert.ok(B(big) <= 4096, `big: ${B(big)} bytes`);
  assert.ok(big.includes("- …"), "big: the cut answers");
  assert.ok(big.includes("newest answer → INBOX.md"), "big: the newest answer");
  assert.ok(B(small) <= 2048, `small: ${B(small)} bytes`);
  assert.match(small.split("\n").find(l => l.startsWith("- ")), /^- Dead end \(X/);

  const c = (feature, x = {}) => ({ feature, kind: "coding", outcome: "passes", summary: feature + " done", session: "s-" + feature, at: "t", ...x });
  const list2 = { features: [{ id: "P", milestone: "M0" }, { id: "Q", milestone: "M0" }, { id: "X", milestone: "M9", after: ["M0"] }] };
  const e2 = [c("P", { dead_ends: [{ tried: "p1", why: "w" }] }), c("Q"), c("X", { outcome: "not yet", dead_ends: [{ tried: "x1", why: "w" }] }), c("Z", { discoveries: [{ text: "for M9", affects: ["M9"] }] }),
    { feature: "M0", kind: "verify", outcome: "not yet", summary: "P fails", session: "v", at: "t", evidence: [{ feature: "P", step: 1, ran: "r", saw: "s", holds: false }] }];
  const p2 = pack(e2.slice(0, 4), { feature: "X", list: list2, cap: 8192 }), part = t => (p2.split("## " + t)[1] ?? "").split("\n## ")[0], n = re => p2.split("\n").filter(l => re.test(l)).length;
  const flood = [c("X", { dead_ends: [{ tried: "x1", why: "w" }] }), c("Y", { discoveries: [{ text: "d".repeat(900), affects: ["run"] }] }), c("W")];
  const cut = pack(flood, { feature: "X", list: list2, cap: 1024 }), m = pack(e2, { feature: "M0", list: list2, cap: 8192 });
  const emo = Array.from({ length: 60 }, (_, i) => c("E" + i, { summary: "😀".repeat(399), discoveries: [{ text: "😀".repeat(400), affects: ["run"] }] }));
  assert.match(part("What it builds on"), /· P ·/);
  assert.match(part("What it builds on"), /· Q ·/);
  assert.doesNotMatch(part("Lately in the run"), /· [PQX] ·/);
  assert.match(part("Lately in the run"), /· Z ·/);
  assert.equal(n(/→ entries\.jsonl:3$/), 2);
  assert.equal(n(/→ entries\.jsonl:2$/), 1);
  assert.match(p2, /^- Discovery \(Z, affects M9\): for M9/m);
  assert.ok(cut.includes("- Dead end (X"), "cut: the dead end");
  assert.ok(!cut.includes("## Lately"), "cut: no Lately part");
  assert.ok(!cut.includes("## Discoveries"), "cut: no Discoveries part");
  assert.match(cut, /^_3 items left out at 1024 bytes/m);
  assert.ok(B(cut) <= 1024, `cut: ${B(cut)} bytes`);
  assert.match(m, /^- Dead end \(P, s-P\): p1/m);
  assert.match(m, /^- Verify M0 found \(P step 1\)/m);
  for (const k of [1024, 2000, 4096, 8192]) {
    const size = B(pack(emo, { feature: "E0", list: list2, answers: "😀".repeat(3000), cap: k }));
    assert.ok(size <= k, `4-byte characters: ${size} bytes at cap ${k}`);
  }
});

// resolved questions (M3-03): `resolved` is an array of strings kept by normalize only when non-empty; `project` is a valid affects
test("entries.mjs: resolved is an array of strings and normalize keeps it", () => {
  const c = { feature: "C", kind: "coding", outcome: "passes", summary: "s" };
  const r = normalize({ ...c, questions: ["q"], resolved: ["Should X default to off?"] }), k = Object.keys(r);
  assert.deepEqual(validate({ ...c, resolved: ["Should X default to off?"] }), []);
  assert.equal(validate({ ...c, resolved: "x" }).join(), "resolved: not an array of strings");
  assert.equal(JSON.stringify(r.resolved), "[\"Should X default to off?\"]");
  assert.equal(k.indexOf("resolved"), k.indexOf("questions") + 1);
  assert.equal("resolved" in normalize(c), false);
  assert.equal("resolved" in normalize({ ...c, resolved: [] }), false);
  assert.deepEqual(validate({ ...c, discoveries: [{ text: "t", affects: ["project"] }] }), []);
  assert.match(validate({ ...c, discoveries: [{ text: "t", affects: [] }] })[0], /"project"/);
});

// a question shows until a later entry resolves it (whitespace folded); an earlier entry's resolved doesn't count
test("entries.mjs: the pack drops a question a later entry resolves", () => {
  const c = (x = {}) => ({ feature: "X", kind: "coding", outcome: "not yet", summary: "x", session: "s", at: "t", ...x });
  const list = [{ id: "X", milestone: "M1" }], q = "Should X default to off?", has = es => pack(es, { feature: "X", list }).includes("Question (X): " + q);
  assert.equal(has([c({ questions: [q] })]), true);
  assert.equal(has([c({ questions: [q] }), c({ resolved: [" Should  X default\nto off? "] })]), false);
  assert.equal(has([c({ resolved: [q] }), c({ questions: [q] })]), true);
  assert.equal(has([c({ questions: [q] }), c({ resolved: ["Should X"] })]), true);
  assert.equal(has([c({ questions: [q] }), { feature: "M1", kind: "verify", outcome: "passes", summary: "v", resolved: [q] }]), false);
});

// Promote to Gotchas (M3-03): project discoveries in a coding pack, newest first, one per first 40 characters, left out once a
// Gotchas line carries them, at most cap/8 bytes (the rest counted, the pack goes on); a milestone pack has no such part
test("entries.mjs: Promote to Gotchas lists project facts until a Gotchas line carries them", () => {
  const c = (f, d) => coding(f, { discoveries: d });
  const list = [{ id: "X", milestone: "M1" }, { id: "Y", milestone: "M1" }], P = t => ({ text: t, affects: ["project"] });
  const e = [c("Y", [P("old fact about the port being 7900 for every run here"), { text: "for X only", affects: ["X"] }]), c("Y", [P("old fact about the port being 7900 for every run, newer wording")]), c("Y", [P("the stub writes work files")])];
  const p = pack(e, { feature: "X", list }), pr = sec(p, "Promote to Gotchas"), ls = pr.split("\n").filter(l => l.startsWith("- "));
  const g = pack(e, { feature: "X", list, gotchas: ["- note: the stub writes work files (r 2026-10-26)"] }), m = pack(e, { feature: "M1", list });
  const many = Array.from({ length: 30 }, (_, i) => c("Y", [P(i + " " + "z".repeat(300))])), f = pack([...many, c("Y", [{ text: "late run fact", affects: ["run"] }])], { feature: "X", list, cap: 4096 });
  assert.equal(ls.length, 2);
  assert.equal(ls[0], "- the stub writes work files → entries.jsonl:3");
  assert.ok(ls[1].includes("newer wording → entries.jsonl:2"), ls[1]);
  assert.ok(!sec(p, "Discoveries for this feature").includes("fact"), "a project fact among the feature's discoveries");
  assert.ok(sec(p, "Discoveries for this feature").includes("for X only"), "the feature's discovery");
  assert.ok(p.indexOf("## Promote to Gotchas") > p.indexOf("## Discoveries"), "Promote after Discoveries");
  assert.ok(p.indexOf("## Promote to Gotchas") < p.indexOf("## Lately"), "Promote before Lately");
  assert.ok(!sec(g, "Promote to Gotchas").includes("stub writes"), "a carried fact still promoted");
  assert.ok(sec(g, "Promote to Gotchas").includes("newer wording"), "an uncarried fact left out");
  assert.ok(!m.includes("Promote to Gotchas"), "a milestone pack with a Promote part");
  assert.ok(B(sec(f, "Promote to Gotchas")) <= 512, `${B(sec(f, "Promote to Gotchas"))} bytes`);
  assert.ok(f.includes("## Lately in the run"), "the pack goes on after the cut Promote part");
  assert.match(f, /^_\d+ items left out at 4096 bytes/m);
  for (const [k, n] of [[8192, 1000], [1024, 100]]) {
    const q = pack([c("Y", [P("a".repeat(n))])], { feature: "X", list, cap: k }), s = sec(q, "Promote to Gotchas");
    assert.match(s, /^- a+… → entries\.jsonl:1$/m);
    assert.ok(B(s) <= k / 8, `cap ${k}: ${B(s)} bytes`);
    assert.ok(!q.includes("items left out"), `cap ${k}: items left out`);
  }
});

// M3 review (M3-05): a Gotchas line carries a fact whatever its case, backticks or emphasis; a later entry's `resolved`
// dismisses a promoted fact (by its first 40 characters) or a question copied with the line's ` → entries.jsonl:<n>`,
// its `Question (<id>): ` lead or as cut with `…`; progress.md shows what an entry resolved
test("entries.mjs: a Gotchas line carries a fact in any case or markup, resolved dismisses a fact or a question as context.md shows it", () => {
  const c = coding, list = [{ id: "X", milestone: "M1" }, { id: "Y", milestone: "M1" }], P = t => ({ text: t, affects: ["project"] });
  const fact = "the stub writes work files at the repo root, one per feature", promoted = (es, g = []) => sec(pack(es, { feature: "X", list, gotchas: g }), "Promote to Gotchas").includes("stub writes");
  const q = "Should X default to off? It decides whether the queue starts a run on its own at night", long = "Is it " + "w".repeat(1100) + "?";
  const asked = (es, t = q) => pack(es, { feature: "X", list }).includes("Question (X): " + t.slice(0, 40));
  assert.equal(promoted([c("Y", { discoveries: [P(fact)] })]), true);
  assert.equal(promoted([c("Y", { discoveries: [P(fact)] })], ["- The `stub` **writes** work  files at the repo root, one per feature (r 2026-10-26)"]), false);
  assert.equal(promoted([c("Y", { discoveries: [P(fact)] }), c("X", { resolved: ["- " + fact + " → entries.jsonl:1"] })]), false);
  assert.equal(promoted([c("Y", { discoveries: [P(fact)] }), c("X", { resolved: [fact.slice(0, 45) + " (wrong now)"] })]), false);
  assert.equal(promoted([c("X", { resolved: [fact] }), c("Y", { discoveries: [P(fact)] })]), true);
  assert.equal(asked([c("X", { questions: [q] }), c("X", { resolved: ["- Question (X): " + q + " → entries.jsonl:1"] })]), false);
  assert.equal(asked([c("X", { questions: [q] }), c("X", { resolved: [q + " → entries.jsonl:1"] })]), false);
  assert.equal(asked([c("X", { questions: [long] })], long), true);
  assert.equal(asked([c("X", { questions: [long] }), c("X", { resolved: [long.slice(0, 900) + "…"] })], long), false);
  assert.equal(asked([c("X", { questions: [q] }), c("X", { resolved: ["Should X…"] })]), true);
  assert.ok(renderEntry(c("X", { resolved: [q] })).includes("- **Resolved:** " + q), "progress.md's Resolved line");
});

// the part: last, within cap/4 (and the room left), the rest one `older rules` line that isn't an item left out; a pack
// that already stopped has no rules part at all; an item is cut to 240 bytes
test("entries.mjs: Current rules is the last part within cap/4, the rest one older-rules line", () => {
  const c = coding, list = [{ id: "X", milestone: "M1" }];
  const rules = Array.from({ length: 12 }, (_, i) => ({ text: "D" + (12 - i) + " rule " + "r".repeat(180), ref: "docs/decisions.md:" + (100 - i) }));
  const p = pack([c("X")], { feature: "X", list, rules, rulesFrom: "docs/decisions.md" }), r = sec(p, "Current rules"), ls = r.split("\n").filter(l => l.startsWith("- "));
  const flood = Array.from({ length: 40 }, () => c("X", { summary: "x".repeat(300) })), st = pack(flood, { feature: "X", list, cap: 2048 });
  const long = sec(pack([], { feature: "X", list, rules: [{ text: "w".repeat(1000), ref: "docs/decisions.md:9" }], rulesFrom: "docs/decisions.md" }), "Current rules");
  const lref = sec(pack([], { feature: "X", list, rules: [{ text: "w", ref: "d/" + "é".repeat(300) }] }), "Current rules").split("\n").find(l => l.startsWith("- ")) ?? "";
  assert.equal(p.split("\n").filter(l => l.startsWith("## ")).at(-1), "## Current rules");
  assert.ok(B("\n## Current rules\n" + r) <= 2048, `${B("\n## Current rules\n" + r)} bytes`);
  assert.ok(ls.length >= 5, `${ls.length} rules`);
  starts(ls[0], "- D12 rule");
  ls.forEach((l, i) => { ends(l, " → docs/decisions.md:" + (100 - i), `rule ${i}`); assert.ok(B(l) <= 240, `rule ${i}: ${B(l)} bytes`); });
  ends(r.trimEnd(), "_" + (12 - ls.length) + " older rules: docs/decisions.md._");
  assert.ok(!p.includes("items left out"), "an older rule counted as an item left out");
  assert.ok(st.includes("items left out"), "the flood stops the pack");
  assert.equal(pack(flood, { feature: "X", list, cap: 2048, rules, rulesFrom: "d" }), st);
  assert.ok(!pack([c("X")], { feature: "X", list }).includes("Current rules"), "a rules part with no rules");
  assert.match(long, /^- w+… → docs\/decisions\.md:9$/m);
  const longItem = long.split("\n").find(l => l.startsWith("- "));
  assert.ok(B(longItem) <= 240, `long: ${B(longItem)} bytes`);
  assert.ok(!long.includes("older rules"), "long: an older-rules line");
  starts(lref, "- w → d/é");
  assert.ok(B(lref) <= 240, `long ref: ${B(lref)} bytes`);
  for (const k of [1024, 1500, 2048, 4096]) {
    const size = B(pack([c("X", { dead_ends: [{ tried: "t".repeat(300), why: "w" }] }), c("Y")], { feature: "X", list, rules, rulesFrom: "d", cap: k }));
    assert.ok(size <= k, `${size} bytes at cap ${k}`);
  }
});

// a milestone pack (verify) lists its failed rows before its features' dead ends; a feature pack keeps dead ends first
test("entries.mjs: a milestone pack lists failed verify rows before dead ends", () => {
  const list = [{ id: "P", milestone: "M0" }];
  const e = [{ feature: "P", kind: "coding", outcome: "passes", summary: "p", session: "s", at: "t", dead_ends: [{ tried: "p1", why: "w" }] },
    { feature: "M0", kind: "verify", outcome: "not yet", summary: "P fails", session: "v", at: "t", evidence: [{ feature: "P", step: 1, ran: "r", saw: "s", holds: false }] }];
  const at = (p, re) => p.split("\n").findIndex(l => re.test(l)), m = pack(e, { feature: "M0", list }), f = pack(e, { feature: "P", list });
  assert.ok(at(m, /^- Verify M0 found/) > 0, "milestone: the verify row");
  assert.ok(at(m, /^- Verify M0 found/) < at(m, /^- Dead end/), "milestone: the verify row before the dead end");
  assert.ok(at(f, /^- Dead end/) > 0, "feature: the dead end");
  assert.ok(at(f, /^- Dead end/) < at(f, /^- Verify M0 found/), "feature: the dead end before the verify row");
});

// E4 review F5, F9: a summary can't open a code fence or an HTML block, and a long id doesn't break the cap (the damaged
// journal of the same review stays a CLI check in tests/checks/12-journal-pure-e4-entrys.sh)
test("entries.mjs: a summary can't open a code fence or an HTML block, and a 2000-character id keeps the pack within its cap", () => {
  const e = s => renderEntry({ feature: "A", kind: "coding", outcome: "passes", summary: s });
  assert.ok(e("```js").includes("\n\\```js\n"), "```");
  assert.ok(e("~~~").includes("\n\\~~~\n"), "~~~");
  assert.ok(e("<!-- hide").includes("\n\\<!-- hide\n"), "<!--");
  assert.ok(e("<div>").includes("\n\\<div>\n"), "<div>");
  const size = B(pack([], { feature: "X".repeat(2000), cap: 1024 }));
  assert.ok(size <= 1024, `${size} bytes`);
});

// the trim (R2-02): a summary or init header over its cap, the only error, is cut to fit (399 + …, so readEntries keeps it)
// and the entry kept whole; any other error beside it is minimal as before
const o = { feature: "A", kind: "coding", outcome: "not yet", files: ["f"], final: "done", session: "01-A", model: "m", at: "t" };
const long = { feature: "A", kind: "coding", outcome: "not yet", summary: "A: " + "😀".repeat(407), dead_ends: [{ tried: "t", why: "w" }], questions: ["Q?"] };

test("journal: a 410-character summary is cut to 400 code points ending … and keeps dead_ends and questions, no minimal", () => {
  const r = journalEntry(JSON.stringify(long), o), s = r.entry.summary;
  assert.equal(r.why, "");
  assert.equal(r.entry.minimal, undefined);
  assert.equal([...s].length, 400);
  ends(s, "…");
  starts(s, "A: 😀");
  assert.equal(r.trimmed.join(), "summary 410");
  assert.equal(r.entry.dead_ends.length, 1);
  assert.equal(r.entry.questions[0], "Q?");
  assert.deepEqual(validate(r.entry), []);
});

test("journal: a 410-character summary and outcome \"maybe\" is minimal with why invalid (outcome", () => {
  const m = journalEntry(JSON.stringify({ ...long, outcome: "maybe" }), o);
  starts(m.why, "invalid: outcome");
  starts(m.entry.minimal, "invalid: outcome");
  assert.equal(m.entry.dead_ends.length, 0);
  assert.equal(m.trimmed?.length ?? 0, 0);
});

test("journal: a 2001-character init header is cut to 2000 and kept", () => {
  const it = journalEntry(JSON.stringify({ feature: "init", kind: "init", outcome: "passes", summary: "x".repeat(401), header: "# P\n" + "h".repeat(1997) }), { ...o, feature: "init", kind: "init" });
  const h = it.entry.header ?? "";
  assert.equal(it.why, "");
  assert.equal([...h].length, 2000);
  ends(h, "…");
  starts(h, "# P\n");
  assert.equal(it.trimmed.join(), "summary 401,header 2001");
  assert.equal([...it.entry.summary].length, 400);
  assert.deepEqual(validate(it.entry), []);
});

test("journal: a summary over its cap beside another fault is minimal for the other fault, never the cap", () => {
  const cw = journalEntry(JSON.stringify({ ...long, header: "# no" }), o);
  starts(cw.entry.minimal, "invalid: header", cw.why);
});

test("review gate: reviewFindings reads <n> Critical and <n> Important, null without either", () => {
  assert.deepEqual(reviewFindings("R: 2 Critical, 3 Important, 0 Minor"), { critical: 2, important: 3 });
  assert.deepEqual(reviewFindings("found 1 Important issue"), { critical: 0, important: 1 });
  assert.deepEqual(reviewFindings("0 Critical, 0 Important"), { critical: 0, important: 0 });
  assert.equal(Object.keys(reviewFindings("R: 2 Critical, 3 Important, 0 Minor")).join(), "critical,important");
  assert.equal(reviewFindings("R: stub work (1)"), null);
  assert.equal(reviewFindings(""), null);
  assert.equal(reviewFindings(undefined), null);
});

test("reviewFindings: reads Critical before Important in either order of word and count, never a step number or lowercase prose", () => {
  assert.deepEqual(reviewFindings("Critical 0 Important 2"), { critical: 0, important: 2 });
  assert.deepEqual(reviewFindings("Critical: 0, Important: 2"), { critical: 0, important: 2 });
  assert.deepEqual(reviewFindings("**2 Critical**, 3 Important"), { critical: 2, important: 3 });
  assert.equal(Object.keys(reviewFindings("Critical 0 Important 2")).join(), "critical,important");
  assert.equal(reviewFindings("M3-06 Critical regression fixed"), null);
  assert.equal(reviewFindings("Step 1 important: run the suite"), null);
  assert.equal(reviewFindings("fixed the 2 critical paths"), null);
});

// 63-question-locations.sh: the fill a park card's where falls back to
test("entries.mjs fill: a question without Files: gets the session's files appended (entry's first, absolute, deduplicated, 8 at most, no run dir); the rest byte for byte; a bold or backticked Files: counts", () => {
  const e = { feature: "A", kind: "coding", outcome: "not yet", summary: "s", files: ["lib/a.sh"], questions: ["Q one?", "Q two? Files: /x/b.md:4"], dead_ends: [] };
  const fs = sessionFiles(e.files, ["lib/a.sh", "/abs/c.mjs", ...Array.from({ length: 9 }, (_, i) => "d" + i)], "/wt");
  assert.equal(fs.length, 8);
  assert.deepEqual(fs.slice(0, 3), ["/wt/lib/a.sh", "/abs/c.mjs", "/wt/d0"]);
  const before = JSON.stringify(e), { entry, filled } = fillQuestions(e, fs);
  assert.equal(filled, 1);
  assert.equal(entry.questions[0], "Q one? Files (harness, from the session): " + fs.join(", "));
  assert.equal(entry.questions[1], e.questions[1]);
  assert.equal(JSON.stringify({ ...entry, questions: e.questions }), before);
  assert.equal(JSON.stringify(e), before);
  const none = fillQuestions(e, []);
  assert.equal(none.filled, 0);
  assert.equal(none.entry, e);
  const md = fillQuestions({ questions: ["Q? **Files:** /a/b.sh:4", "Q? `Files:` /a/c.sh", "Q? (Files: /a/d.sh)", "Should the Files: section stay?"] }, ["/wt/x"]);
  assert.equal(md.filled, 1);
  assert.ok(md.entry.questions[3].endsWith("Files (harness, from the session): /wt/x"), md.entry.questions[3]);
  assert.deepEqual(sessionFiles([".harness/runs/r/INBOX.md", "lib/a.sh"], [], "/wt"), ["/wt/lib/a.sh"]);
});
