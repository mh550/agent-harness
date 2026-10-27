#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the journal, pure (E4): an entry's schema, the minimal entry, and progress.md rendered from the entries ----
ENVA='import { validate as v, minimal } from "'$HERE'/../lib/entries.mjs"; const starts = (e, f) => e.length === 1 && e[0].startsWith(f + ":");
  const c = { feature: "C", kind: "coding", outcome: "not yet", summary: "Added the parser.", files: ["lib/parse.mjs"], verified_how: "211/212", tests_before: 211, tests_after: 212,
    dead_ends: [{ tried: "trimming", why: "the prefix check fails" }], discoveries: [{ text: "keeps blank lines", affects: ["D", "run"] }], questions: ["X off?"], proposed_changes: ["C step 2"] };
  const vf = { feature: "M1", kind: "verify", outcome: "not yet", summary: "A step 2 fails", evidence: [{ feature: "A", step: 1, ran: "node --test", saw: "7/7", holds: true }] };
  const it = { feature: "init", kind: "init", outcome: "passes", summary: "12 features", header: "# Progress", discoveries: [{ text: "port 7804", affects: ["run"] }] };
  const { outcome, ...noOut } = c, m = minimal({ feature: "C", kind: "coding", outcome: "passes", files: ["a"], final: "word ".repeat(200) });
  process.exit(v(c).length === 0 && v(vf).length === 0 && v(it).length === 0 && v(c, { feature: "C", kind: "coding" }).length === 0 && starts(v(c, { feature: "B", kind: "coding" }), "feature")
    && starts(v({ ...c, summary: "é".repeat(401) }), "summary") && v({ ...c, summary: "é".repeat(400) }).length === 0 && starts(v(noOut), "outcome") && starts(v({ ...c, outcome: "done" }), "outcome")
    && starts(v({ ...c, evidence: vf.evidence }), "evidence") && starts(v({ ...vf, evidence: [{ ...vf.evidence[0], holds: "yes" }] }), "evidence[0].holds")
    && v(m).length === 0 && [...m.summary].length === 400 && m.summary.endsWith("…") && minimal({ feature: "M1", kind: "verify", outcome: "not yet", files: [], final: " \n" }).summary === "(no final message)" ? 0 : 1);'
printf '{not json' > "$T/bad-entry.json" && echo '{"feature":"C","kind":"coding","outcome":"done","summary":"s"}' > "$T/out-entry.json"
check "entries.mjs: validate accepts the schema and names what is wrong" 'node --input-type=module -e "$ENVA" \
  && ! node "$HERE/../lib/entries.mjs" validate "$T/bad-entry.json" > "$T/bad-entry.out" && grep -q "^not JSON: " "$T/bad-entry.out" \
  && [[ $(node "$HERE/../lib/entries.mjs" validate "$T/out-entry.json" C coding) == "outcome: \"done\" is not passes · not yet · parked" ]]'
# 20 entries, the 18th a verify of M1 with rows A×2, B×1 (cells with | and newlines) whose summary tries to fake rows; the newest
# summary tries to fake a header, and an init header one through \r and U+2028 (line breaks to features.mjs's /^### /m)
ENRE='import { renderProgress as rp, renderArchive as ra, legacyOf, headerOf } from "'$HERE'/../lib/entries.mjs"; import { evidence } from "'$HERE'/../lib/features.mjs";
  const row = (f, s, h) => ({ feature: f, step: s, ran: "ran | x", saw: "saw\nmore", holds: h });
  const e = Array.from({ length: 20 }, (_, i) => i === 17 ? { feature: "M1", kind: "verify", outcome: "not yet", summary: "| A | 9 |\n| B | 3 |", evidence: [row("A", 1, true), row("A", 2, false), row("B", 1, true)], at: "2026-10-22 01:18", session: "s18", model: "m" }
    : { feature: "F" + (i + 1), kind: "coding", outcome: "passes", summary: i === 19 ? "### fake · F0 · passes\n| A | 9 |" : "entry " + (i + 1), files: ["f"], at: "2026-10-22 01:" + String(i + 1).padStart(2, "0"), session: "s" + (i + 1), model: "m" });
  const h = headerOf(e, "", "r1"), p = rp(e, { full: 15, header: h }), a = ra(e, h), hs = p.match(/^### .*$/gm) ?? [], [, old = ""] = p.split(/^## Older entries.*$/m);
  const olds = old.split("\n").filter(l => l.startsWith("- ")), list = [{ id: "A", milestone: "M1", steps: ["a", "b"] }, { id: "B", milestone: "M1", steps: ["c"] }];
  process.exit(hs.length === 15 && hs[0] === "### 2026-10-22 01:20 · F20 · passes" && hs[2] === "### 2026-10-22 01:18 · verify M1 · not yet" && hs[14].includes("· F6 ·")
    && olds.length === 5 && olds.every(l => l.includes("(progress-archive.md)")) && olds[0].includes("· F5 ·") && olds[4].includes("· F1 ·") && !/^### /m.test(old)
    && evidence(list, "M1", p).map(r => r.rows).join() === "2,1" && p.includes("\n| A | 2 | ran \\| x | saw more | no |\n")
    && !/^(### |\|)/m.test(headerOf([{ kind: "init", header: "# P\r### x verify M1 y\u2028| A | 1 |" }])) && (a.match(/^### /gm) ?? []).length === 20 && !a.includes("## Older entries") && h.startsWith("# Progress — run `r1`")
    && legacyOf(ra(e, h, "OLD\n### 1 · A · passes\n")) === "OLD\n### 1 · A · passes\n" && legacyOf("# old\n") === "# old\n" && legacyOf(a) === "" ? 0 : 1);'
mkdir -p "$T/jr/legacy" "$T/jr/new" && echo '# old progress' > "$T/jr/legacy/progress.md" \
  && echo '{"feature":"A","kind":"coding","outcome":"passes","summary":"did A","at":"2026-10-22 02:00","session":"01-A","model":"m"}' > "$T/jr/new/entries.jsonl"
check "entries.mjs: progress renders 15 in full and the rest as archive lines" 'node --input-type=module -e "$ENRE" \
  && node "$HERE/../lib/entries.mjs" render "$T/jr/legacy" && [[ $(ls "$T/jr/legacy") == progress.md && $(cat "$T/jr/legacy/progress.md") == "# old progress" ]] \
  && node "$HERE/../lib/entries.mjs" render "$T/jr/new" && grep -qx "### 2026-10-22 02:00 · A · passes" "$T/jr/new/progress.md" && grep -qx "### 2026-10-22 02:00 · A · passes" "$T/jr/new/progress-archive.md" && grep -q "^# Progress — run \`new\`" "$T/jr/new/progress.md"'
# the context pack (E4-05): 200 unrelated entries of ~300 bytes (every other one with a long run-wide discovery) around X's earlier
# attempt (line 51, a dead end) and a verify of X's milestone (line 122, step 2 failed): X's dead end leads, the
# verify's finding follows, Michael's answers come before any discovery, every item names its line, and the cap holds
ENPK='import { pack } from "'$HERE'/../lib/entries.mjs"; const st = i => ({ at: "2026-10-22 01:00", session: "s" + i, model: "m" });
  const e = Array.from({ length: 200 }, (_, i) => ({ feature: "F" + i, kind: "coding", outcome: "passes", summary: "entry " + i + " " + "x".repeat(270), files: ["f"], ...st(i),
    ...(i % 2 ? {} : { discoveries: [{ text: "run-wide " + i + " " + "y".repeat(200), affects: ["run"] }] }) }));
  e.splice(50, 0, { feature: "X", kind: "coding", outcome: "not yet", summary: "X first try", dead_ends: [{ tried: "the old parser", why: "it drops blank lines" }], ...st("-x") });
  e.splice(121, 0, { feature: "MX", kind: "verify", outcome: "not yet", summary: "X step 2 fails", ...st("-v"),
    evidence: [{ feature: "X", step: 1, ran: "a", saw: "ok", holds: true }, { feature: "X", step: 2, ran: "curl :7900/x", saw: "500", holds: false }] });
  const list = { features: [{ id: "F3", milestone: "M0", steps: ["s"] }, { id: "X", milestone: "MX", after: ["F3"], steps: ["a", "b"] }] };
  const p = pack(e, { feature: "X", list, answers: "### a\nuse port 7900", cap: 8192 }), ls = p.split("\n"), at = re => ls.findIndex(l => re.test(l));
  const big = pack([], { feature: "X", list, answers: "old ".repeat(3000) + "newest answer", cap: 4096 }), small = pack(e, { feature: "X", list, answers: "", cap: 2048 });
  process.exit(Buffer.byteLength(p) <= 8192 && ls[0] === "# Context pack for `X`" && ls.find(l => l.startsWith("- ")) === "- Dead end (X, s-x): the old parser — it drops blank lines → entries.jsonl:51"
    && at(/^- Verify MX found \(X step 2\): ran curl :7900\/x; saw 500 → entries\.jsonl:122$/) > at(/^- Dead end/) && at(/^- Verify MX/) < at(/use port 7900 → INBOX\.md$/)
    && at(/use port 7900/) < at(/^- Discovery/) && at(/^- Discovery \(F\d+, affects run\): run-wide/) > 0 && ls.filter(l => l.startsWith("- ")).every(l => / → (entries\.jsonl:\d+|INBOX\.md)$/.test(l))
    && /^_\d+ items left out at 8192 bytes: entries\.jsonl has them all\._$/.test(ls.at(-2)) && Buffer.byteLength(big) <= 4096 && big.includes("- …") && big.includes("newest answer → INBOX.md")
    && Buffer.byteLength(small) <= 2048 && small.split("\n").find(l => l.startsWith("- ")).startsWith("- Dead end (X") ? 0 : 1);'
# tight cases (E4-05 review): an after milestone expands to its features, an entry shows once, the cut is strict (a short
# part-5 entry doesn't jump a cut discovery), a milestone pack has its features' dead ends and failed rows, a discovery
# may name the feature's milestone, and 4-byte characters never break the cap
ENPK2='import { pack } from "'$HERE'/../lib/entries.mjs"; const c = (feature, x = {}) => ({ feature, kind: "coding", outcome: "passes", summary: feature + " done", session: "s-" + feature, at: "t", ...x });
  const list = { features: [{ id: "P", milestone: "M0" }, { id: "Q", milestone: "M0" }, { id: "X", milestone: "M9", after: ["M0"] }] };
  const e = [c("P", { dead_ends: [{ tried: "p1", why: "w" }] }), c("Q"), c("X", { outcome: "not yet", dead_ends: [{ tried: "x1", why: "w" }] }), c("Z", { discoveries: [{ text: "for M9", affects: ["M9"] }] }),
    { feature: "M0", kind: "verify", outcome: "not yet", summary: "P fails", session: "v", at: "t", evidence: [{ feature: "P", step: 1, ran: "r", saw: "s", holds: false }] }];
  const p = pack(e.slice(0, 4), { feature: "X", list, cap: 8192 }), sec = t => (p.split("## " + t)[1] ?? "").split("\n## ")[0], n = re => p.split("\n").filter(l => re.test(l)).length;
  const big = [c("X", { dead_ends: [{ tried: "x1", why: "w" }] }), c("Y", { discoveries: [{ text: "d".repeat(900), affects: ["run"] }] }), c("W")];
  const cut = pack(big, { feature: "X", list, cap: 1024 }), m = pack(e, { feature: "M0", list, cap: 8192 });
  const emo = Array.from({ length: 60 }, (_, i) => c("E" + i, { summary: "😀".repeat(399), discoveries: [{ text: "😀".repeat(400), affects: ["run"] }] }));
  process.exit(/· P ·/.test(sec("What it builds on")) && /· Q ·/.test(sec("What it builds on")) && !/· [PQX] ·/.test(sec("Lately in the run")) && /· Z ·/.test(sec("Lately in the run"))
    && n(/→ entries\.jsonl:3$/) === 2 && n(/→ entries\.jsonl:2$/) === 1 && /^- Discovery \(Z, affects M9\): for M9/m.test(p)
    && cut.includes("- Dead end (X") && !cut.includes("## Lately") && !cut.includes("## Discoveries") && /^_3 items left out at 1024 bytes/m.test(cut) && Buffer.byteLength(cut) <= 1024
    && /^- Dead end \(P, s-P\): p1/m.test(m) && /^- Verify M0 found \(P step 1\)/m.test(m) && [1024, 2000, 4096, 8192].every(k => Buffer.byteLength(pack(emo, { feature: "E0", list, answers: "😀".repeat(3000), cap: k })) <= k) ? 0 : 1);'
mkdir -p "$T/pk" && printf '%s\n' '{"feature":"A","kind":"coding","outcome":"not yet","summary":"a1","dead_ends":[{"tried":"t","why":"w"}],"at":"x","session":"01-A","model":"m"}' '{oops' \
  '{"feature":"A","kind":"coding","outcome":"passes","summary":"a2","at":"x","session":"02-A","model":"m"}' > "$T/pk/entries.jsonl" \
  && echo '{"features":[{"id":"A","milestone":"M1","steps":["s"]}]}' > "$T/pk/feature_list.json" && printf 'status: run\n## Answers\nuse 7900\n' > "$T/pk/INBOX.md"
check "entries.mjs: the pack keeps a feature's dead end under a flood and respects the cap" 'node --input-type=module -e "$ENPK" && node --input-type=module -e "$ENPK2" \
  && ! node "$HERE/../lib/entries.mjs" pack "$T/pk" A 8k 2> /dev/null && ! node "$HERE/../lib/entries.mjs" pack "$T/pk" A 100 2> /dev/null \
  && node "$HERE/../lib/entries.mjs" pack "$T/pk" A > "$T/pk.md" && grep -qx -- "- Dead end (A, 01-A): t — w → entries.jsonl:1" "$T/pk.md" \
  && grep -q -- "^- x · A · passes: a2 → entries.jsonl:3$" "$T/pk.md" && grep -qx -- "- use 7900 → INBOX.md" "$T/pk.md" \
  && [[ $(node "$HERE/../lib/entries.mjs" pack "$T/jr/legacy" Z | head -1) == "# Context pack for \`Z\`" ]]'
# resolved questions (M3-03): `resolved` is an array of strings kept by normalize only when non-empty; `project` is a valid affects
ENRS='import { validate as v, normalize as nz } from "'$HERE'/../lib/entries.mjs"; const c = { feature: "C", kind: "coding", outcome: "passes", summary: "s" };
  const r = nz({ ...c, questions: ["q"], resolved: ["Should X default to off?"] }), k = Object.keys(r);
  process.exit(v({ ...c, resolved: ["Should X default to off?"] }).length === 0 && v({ ...c, resolved: "x" }).join() === "resolved: not an array of strings"
    && JSON.stringify(r.resolved) === "[\"Should X default to off?\"]" && k.indexOf("resolved") === k.indexOf("questions") + 1 && !("resolved" in nz(c)) && !("resolved" in nz({ ...c, resolved: [] }))
    && v({ ...c, discoveries: [{ text: "t", affects: ["project"] }] }).length === 0 && /"project"/.test(v({ ...c, discoveries: [{ text: "t", affects: [] }] })[0]) ? 0 : 1);'
check "entries.mjs: resolved is an array of strings and normalize keeps it" 'node --input-type=module -e "$ENRS"'
# a question shows until a later entry resolves it (whitespace folded); an earlier entry's resolved doesn't count
ENRQ='import { pack } from "'$HERE'/../lib/entries.mjs"; const c = (x = {}) => ({ feature: "X", kind: "coding", outcome: "not yet", summary: "x", session: "s", at: "t", ...x });
  const list = [{ id: "X", milestone: "M1" }], q = "Should X default to off?", has = es => pack(es, { feature: "X", list }).includes("Question (X): " + q);
  process.exit(has([c({ questions: [q] })]) && !has([c({ questions: [q] }), c({ resolved: [" Should  X default\nto off? "] })]) && has([c({ resolved: [q] }), c({ questions: [q] })])
    && has([c({ questions: [q] }), c({ resolved: ["Should X"] })]) && !has([c({ questions: [q] }), { feature: "M1", kind: "verify", outcome: "passes", summary: "v", resolved: [q] }]) ? 0 : 1);'
check "entries.mjs: the pack drops a question a later entry resolves" 'node --input-type=module -e "$ENRQ"'
# Promote to Gotchas (M3-03): project discoveries in a coding pack, newest first, one per first 40 characters, left out once a
# Gotchas line carries them, at most cap/8 bytes (the rest counted, the pack goes on); a milestone pack has no such part
ENPG='import { pack } from "'$HERE'/../lib/entries.mjs"; const c = (f, d) => ({ feature: f, kind: "coding", outcome: "passes", summary: f + " done", session: "s", at: "t", discoveries: d });
  const list = [{ id: "X", milestone: "M1" }, { id: "Y", milestone: "M1" }], P = t => ({ text: t, affects: ["project"] }), sec = (p, t) => (p.split("## " + t + "\n")[1] ?? "").split("\n## ")[0];
  const e = [c("Y", [P("old fact about the port being 7900 for every run here"), { text: "for X only", affects: ["X"] }]), c("Y", [P("old fact about the port being 7900 for every run, newer wording")]), c("Y", [P("the stub writes work files")])];
  const p = pack(e, { feature: "X", list }), pr = sec(p, "Promote to Gotchas"), ls = pr.split("\n").filter(l => l.startsWith("- "));
  const g = pack(e, { feature: "X", list, gotchas: ["- note: the stub writes work files (r 2026-10-26)"] }), m = pack(e, { feature: "M1", list });
  const many = Array.from({ length: 30 }, (_, i) => c("Y", [P(i + " " + "z".repeat(300))])), f = pack([...many, c("Y", [{ text: "late run fact", affects: ["run"] }])], { feature: "X", list, cap: 4096 });
  process.exit(ls.length === 2 && ls[0] === "- the stub writes work files → entries.jsonl:3" && ls[1].includes("newer wording → entries.jsonl:2") && !sec(p, "Discoveries for this feature").includes("fact")
    && sec(p, "Discoveries for this feature").includes("for X only") && p.indexOf("## Promote to Gotchas") > p.indexOf("## Discoveries") && p.indexOf("## Promote to Gotchas") < p.indexOf("## Lately")
    && !sec(g, "Promote to Gotchas").includes("stub writes") && sec(g, "Promote to Gotchas").includes("newer wording") && !m.includes("Promote to Gotchas")
    && Buffer.byteLength(sec(f, "Promote to Gotchas")) <= 512 && f.includes("## Lately in the run") && /^_\d+ items left out at 4096 bytes/m.test(f)
    && [[8192, 1000], [1024, 100]].every(([k, n]) => { const q = pack([c("Y", [P("a".repeat(n))])], { feature: "X", list, cap: k }), s = sec(q, "Promote to Gotchas");
      return /^- a+… → entries\.jsonl:1$/m.test(s) && Buffer.byteLength(s) <= k / 8 && !q.includes("items left out"); }) ? 0 : 1);'
check "entries.mjs: Promote to Gotchas lists project facts until a Gotchas line carries them" 'node --input-type=module -e "$ENPG"'
# M3 review (M3-05): a Gotchas line carries a fact whatever its case, backticks or emphasis; a later entry's `resolved`
# dismisses a promoted fact (by its first 40 characters) or a question copied with the line's ` → entries.jsonl:<n>`,
# its `Question (<id>): ` lead or as cut with `…`; progress.md shows what an entry resolved
ENRV='import { pack, renderEntry } from "'$HERE'/../lib/entries.mjs"; const c = (f, x = {}) => ({ feature: f, kind: "coding", outcome: "passes", summary: f + " done", session: "s", at: "t", ...x });
  const list = [{ id: "X", milestone: "M1" }, { id: "Y", milestone: "M1" }], P = t => ({ text: t, affects: ["project"] }), sec = (p, t) => (p.split("## " + t + "\n")[1] ?? "").split("\n## ")[0];
  const fact = "the stub writes work files at the repo root, one per feature", promoted = (es, g = []) => sec(pack(es, { feature: "X", list, gotchas: g }), "Promote to Gotchas").includes("stub writes");
  const q = "Should X default to off? It decides whether the queue starts a run on its own at night", long = "Is it " + "w".repeat(1100) + "?";
  const asked = (es, t = q) => pack(es, { feature: "X", list }).includes("Question (X): " + t.slice(0, 40));
  process.exit(promoted([c("Y", { discoveries: [P(fact)] })]) && !promoted([c("Y", { discoveries: [P(fact)] })], ["- The `stub` **writes** work  files at the repo root, one per feature (r 2026-10-26)"])
    && !promoted([c("Y", { discoveries: [P(fact)] }), c("X", { resolved: ["- " + fact + " → entries.jsonl:1"] })]) && !promoted([c("Y", { discoveries: [P(fact)] }), c("X", { resolved: [fact.slice(0, 45) + " (wrong now)"] })])
    && promoted([c("X", { resolved: [fact] }), c("Y", { discoveries: [P(fact)] })])
    && !asked([c("X", { questions: [q] }), c("X", { resolved: ["- Question (X): " + q + " → entries.jsonl:1"] })]) && !asked([c("X", { questions: [q] }), c("X", { resolved: [q + " → entries.jsonl:1"] })])
    && asked([c("X", { questions: [long] })], long) && !asked([c("X", { questions: [long] }), c("X", { resolved: [long.slice(0, 900) + "…"] })], long)
    && asked([c("X", { questions: [q] }), c("X", { resolved: ["Should X…"] })])
    && renderEntry(c("X", { resolved: [q] })).includes("- **Resolved:** " + q) ? 0 : 1);'
check "entries.mjs: a Gotchas line carries a fact in any case or markup, resolved dismisses a fact or a question as context.md shows it" 'node --input-type=module -e "$ENRV"'
# Current rules (M3-04): the decisions store's lines newest first, from a directory (each file's `# ` title, by name) or
# a file in the three shapes the projects use (fixtures copied from rane-one-mixxx, voice-concierge, dj-crate-streaming)
MLCR='import { currentRules as cr } from "'$HERE'/../lib/memlint.mjs"; import { readFileSync as rf } from "node:fs"; const fx = n => rf("'$HERE'/fixtures/decisions-" + n + ".md", "utf8");
  const F = { path: "docs/decisions.md", kind: "file" }, s = r => r.map(x => x.text + " → " + x.ref).join("\n");
  const rane = cr(F, fx("rane")), vc = cr(F, fx("voice-concierge")), dj = cr(F, fx("dj"));
  const dir = cr({ path: "journal/decisions", kind: "dir" }, [{ name: "2026-10-20-a.md", text: "# Alpha rule\nbody" }, { name: "2026-10-26-b.md", text: "intro\n# Beta rule\n" }, { name: "2026-10-22-c.md", text: "no title\n" }, { name: "README.md", text: "# About this store\n" }]);
  process.exit(rane.length === 3 && rane.map(r => r.ref).join() === "docs/decisions.md:15,docs/decisions.md:13,docs/decisions.md:7"
    && rane[2].text.startsWith("D1 default · Playback model: hybrid. Mixxx") && rane[0].text.startsWith("D3 · Separate Mixxx dev profile at `~/.var/") && rane[1].text.endsWith("so it can be PR\x27d to `mixxxdj/mixxx` later. (2026-10-19)")
    && vc.map(r => r.ref).join() === "docs/decisions.md:7,docs/decisions.md:3" && vc[1].text.startsWith("D7 default: turn detection is silero VAD only (2026-10-20, C1-01) — Finding. B1 leaves")
    && dj.map(r => r.ref).join() === "docs/decisions.md:17,docs/decisions.md:16,docs/decisions.md:15,docs/decisions.md:14,docs/decisions.md:13" && dj[4].text.startsWith("D24 · One download quality. A file is acceptable")
    && dj[0].text.startsWith("D53 default · A matched release gives") && dj[1].text.startsWith("D36 default · The cleanup")
    && s(cr(F, fx("rane").replace(/\n/g, "\r\n"))) === s(rane)
    && s(dir) === "Beta rule → journal/decisions/2026-10-26-b.md\nAlpha rule → journal/decisions/2026-10-20-a.md\nAbout this store → journal/decisions/README.md" && cr(F, "# Decisions\nnone yet\n").length === 0 ? 0 : 1);'
check "memlint: currentRules reads a directory store and the three file shapes newest first" 'node --input-type=module -e "$MLCR"'
# a range or a group heading is no decision, however its dash is written, and a heading never replaces a row of the same n
MLGR='import { currentRules as cr } from "'$HERE'/../lib/memlint.mjs"; const F = { path: "d.md", kind: "file" };
  const r = cr(F, "## D1—D6 the early ones\n\n## D7 – D9 later\n\n## D10 to D12\n\n| D24 | **One quality** | x |\n\n## D24 on\n\ntext\n\n## D30: a rule\n\nwhy\n");
  process.exit(r.map(x => x.ref).join() === "d.md:13,d.md:7" && r[1].text.startsWith("D24 · One quality") ? 0 : 1);'
check "memlint: currentRules skips ranges written with any dash or to, and a heading never replaces a row" 'node --input-type=module -e "$MLGR"'
# the part: last, within cap/4 (and the room left), the rest one `older rules` line that isn't an item left out; a pack
# that already stopped has no rules part at all; an item is cut to 240 bytes
ENCR='import { pack } from "'$HERE'/../lib/entries.mjs"; const c = (f, x = {}) => ({ feature: f, kind: "coding", outcome: "passes", summary: f + " done", session: "s", at: "t", ...x });
  const list = [{ id: "X", milestone: "M1" }], B = s => Buffer.byteLength(s), sec = (p, t) => (p.split("## " + t + "\n")[1] ?? "").split("\n## ")[0];
  const rules = Array.from({ length: 12 }, (_, i) => ({ text: "D" + (12 - i) + " rule " + "r".repeat(180), ref: "docs/decisions.md:" + (100 - i) }));
  const p = pack([c("X")], { feature: "X", list, rules, rulesFrom: "docs/decisions.md" }), r = sec(p, "Current rules"), ls = r.split("\n").filter(l => l.startsWith("- "));
  const flood = Array.from({ length: 40 }, () => c("X", { summary: "x".repeat(300) })), st = pack(flood, { feature: "X", list, cap: 2048 });
  const long = sec(pack([], { feature: "X", list, rules: [{ text: "w".repeat(1000), ref: "docs/decisions.md:9" }], rulesFrom: "docs/decisions.md" }), "Current rules");
  const lref = sec(pack([], { feature: "X", list, rules: [{ text: "w", ref: "d/" + "é".repeat(300) }] }), "Current rules").split("\n").find(l => l.startsWith("- ")) ?? "";
  process.exit(p.split("\n").filter(l => l.startsWith("## ")).at(-1) === "## Current rules" && B("\n## Current rules\n" + r) <= 2048 && ls.length >= 5 && ls[0].startsWith("- D12 rule")
    && ls.every((l, i) => l.endsWith(" → docs/decisions.md:" + (100 - i)) && B(l) <= 240) && r.trimEnd().endsWith("_" + (12 - ls.length) + " older rules: docs/decisions.md._") && !p.includes("items left out")
    && st.includes("items left out") && pack(flood, { feature: "X", list, cap: 2048, rules, rulesFrom: "d" }) === st && !pack([c("X")], { feature: "X", list }).includes("Current rules")
    && /^- w+… → docs\/decisions\.md:9$/m.test(long) && B(long.split("\n").find(l => l.startsWith("- "))) <= 240 && !long.includes("older rules") && lref.startsWith("- w → d/é") && B(lref) <= 240
    && [1024, 1500, 2048, 4096].every(k => B(pack([c("X", { dead_ends: [{ tried: "t".repeat(300), why: "w" }] }), c("Y")], { feature: "X", list, rules, rulesFrom: "d", cap: k })) <= k) ? 0 : 1);'
check "entries.mjs: Current rules is the last part within cap/4, the rest one older-rules line" 'node --input-type=module -e "$ENCR"'
# a milestone pack (verify) lists its failed rows before its features' dead ends; a feature pack keeps dead ends first
ENVF='import { pack } from "'$HERE'/../lib/entries.mjs"; const list = [{ id: "P", milestone: "M0" }];
  const e = [{ feature: "P", kind: "coding", outcome: "passes", summary: "p", session: "s", at: "t", dead_ends: [{ tried: "p1", why: "w" }] },
    { feature: "M0", kind: "verify", outcome: "not yet", summary: "P fails", session: "v", at: "t", evidence: [{ feature: "P", step: 1, ran: "r", saw: "s", holds: false }] }];
  const at = (p, re) => p.split("\n").findIndex(l => re.test(l)), m = pack(e, { feature: "M0", list }), f = pack(e, { feature: "P", list });
  process.exit(at(m, /^- Verify M0 found/) > 0 && at(m, /^- Verify M0 found/) < at(m, /^- Dead end/) && at(f, /^- Dead end/) > 0 && at(f, /^- Dead end/) < at(f, /^- Verify M0 found/) ? 0 : 1);'
check "entries.mjs: a milestone pack lists failed verify rows before dead ends" 'node --input-type=module -e "$ENVF"'
# a journal a session or an editor damaged (E4 review F1, F2): a null line, wrongly typed fields and a blank line are
# skipped, never fatal; a last line without its newline doesn't swallow the next append; references stay real lines.
# A summary can't open a code fence or an HTML block, and a long id doesn't break the cap (F5, F9)
mkdir -p "$T/jb" && printf '%s\n' '{"feature":"A","kind":"coding","outcome":"not yet","summary":"a1","dead_ends":[{"tried":"t","why":"w"}],"at":"x","session":"01-A","model":"m"}' null \
  '{"feature":"B","kind":"coding","outcome":"passes","summary":"b","dead_ends":"x","files":"y","discoveries":[{"text":"t","affects":"run"}]}' '' > "$T/jb/entries.jsonl" \
  && printf '%s' '{"feature":"A","kind":"coding","outcome":"not yet","summary":"a2","at":"x","session":"02-A","model":"m"}' >> "$T/jb/entries.jsonl" \
  && echo '{"features":[{"id":"A","milestone":"M1","steps":["s"]}]}' > "$T/jb/feature_list.json" && printf 'status: run\n## Answers\n' > "$T/jb/INBOX.md" \
  && echo '{"feature":"A","kind":"coding","outcome":"passes","summary":"a3"}' > "$T/jb/entry.json" && printf 'a3 done\n' > "$T/jb-final"
ENGD='import { renderEntry as r, pack } from "'$HERE'/../lib/entries.mjs"; const e = s => r({ feature: "A", kind: "coding", outcome: "passes", summary: s });
  process.exit(e("```js").includes("\n\\```js\n") && e("~~~").includes("\n\\~~~\n") && e("<!-- hide").includes("\n\\<!-- hide\n") && e("<div>").includes("\n\\<div>\n")
    && Buffer.byteLength(pack([], { feature: "X".repeat(2000), cap: 1024 })) <= 1024 ? 0 : 1);'
check "entries.mjs: a damaged journal line is skipped, never fused or fatal" 'node --input-type=module -e "$ENGD" \
  && node "$HERE/../lib/entries.mjs" render "$T/jb" && [[ $(grep -c "^### " "$T/jb/progress.md") == 2 ]] \
  && node "$HERE/../lib/entries.mjs" pack "$T/jb" A > "$T/jb.md" && grep -qx -- "- Dead end (A, 01-A): t — w → entries.jsonl:1" "$T/jb.md" && grep -q -- "a2 → entries.jsonl:5$" "$T/jb.md" \
  && node "$HERE/../lib/entries.mjs" ingest "$T/jb" coding A 03-A m passes /dev/null "$T/jb-final" && [[ $(wc -l < "$T/jb/entries.jsonl") == 6 ]] \
  && node "$HERE/../lib/entries.mjs" pack "$T/jb" A | grep -- "a3 → entries.jsonl:6$" > /dev/null && node "$HERE/../lib/entries.mjs" pack "$T/jb" A | grep -- "a2 → entries.jsonl:5$" > /dev/null'
git init -q -b main "$T/vj" && echo '{"framework":"nextjs"}' > "$T/vj/vercel.json" && "$H" init "$T/vj" > "$T/init-vj.out" 2>&1 && "$H" init "$T/vj" > "$T/init-vj2.out" 2>&1
check "init: vercel.json gets git.deploymentEnabled harness/** false, other keys kept" 'jq -e ".framework == \"nextjs\" and .git.deploymentEnabled[\"harness/**\"] == false" "$T/vj/vercel.json" > /dev/null \
  && grep -q "added the deploy guard to vercel.json" "$T/init-vj.out" && grep -q "keep    vercel.json" "$T/init-vj2.out" && ! grep -q "added the deploy guard" "$T/init-vj2.out"'
git init -q -b main "$T/vd" && mkdir "$T/vd/.vercel" && "$H" init "$T/vd" > "$T/init-vd.out" 2>&1; git init -q -b main "$T/vn" && "$H" init "$T/vn" > "$T/init-vn.out" 2>&1
check "init: a Vercel project without vercel.json gets one" 'jq -e ".git.deploymentEnabled[\"harness/**\"] == false" "$T/vd/vercel.json" > /dev/null && grep -q "added the deploy guard to vercel.json" "$T/init-vd.out" \
  && [[ ! -e $T/vn/vercel.json && ! -e $T/vn/netlify.toml ]] && ! grep -q "deploy guard\|vercel\|netlify" "$T/init-vn.out"'
git init -q -b main "$T/nt" && printf '[build]\n  command = "make"\n  publish = "dist"\n\n[build.environment]\n  NODE_VERSION = "20"\n' > "$T/nt/netlify.toml" && "$H" init "$T/nt" > "$T/init-nt.out" 2>&1
ign() { sed -n 's/^ *ignore = "\(.*\)"$/\1/p' "$1" | sed 's/\\"/"/g'; }   # the [build] ignore command, unquoted
check "init: netlify.toml gets a [build] ignore for harness/* refs, other keys kept" 'grep -q "added the deploy guard to netlify.toml" "$T/init-nt.out" && grep -q "command = \"make\"" "$T/nt/netlify.toml" \
  && grep -q "NODE_VERSION = \"20\"" "$T/nt/netlify.toml" && c=$(ign "$T/nt/netlify.toml") && BRANCH=harness/x bash -c "$c" && ! BRANCH=main bash -c "$c"'

suite_end
