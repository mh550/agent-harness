// The memory curator's rules (M2, N1): a read-only session's operations on project memory (FILES), validated, each
// one's tier derived from its heading, gated by the run's entries and applied under the cap. The driver commits tier 1
// on harness-memory/<run> and tier 2 on harness-rules/<run> (a PR it never merges) and sends tier 3 to Michael in both
// bodies; the session never writes a project file (decisions/2026-11-07-memory-tiers, decisions/2026-11-08-memory-rules-pr).
//   validate <ops.json>                                → `ok` (0), or the first reason (1)
//   apply <ops.json> <worktree> <run> <entries.jsonl> [<rules base> [<rules merge-base> <main>]]
//                                                      → one JSON line {ops, applied, rules, proposed, dropped, rederived,
//                                                        run, files, ruleFiles, ruleTexts}, tier 1's changed files written
//                                                        into <worktree>, tier 2's in ruleTexts (cut from <rules base>, a
//                                                        directory of FILES, else the worktree; a stale rules tip's
//                                                        merge-base with main and main, two more, give the drift);
//                                                        an invalid file is {invalid} (1). MEMLINT_LINES caps
//         [--answers <memory-answers.jsonl> --project <p>] → that project's answered rules and proposals dropped
//   body <result.json> <run> [facts|rules|union] [<other PR url>] → a memory PR's body or memory.md's (Markdown)
//   answers <memory-answers.jsonl> <project> [--max-bytes <n>] → the curator prompt's {{MEMORY_ANSWERS}} (N2-03)
import { existsSync, lstatSync, readFileSync, realpathSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { captured, isMain, runCli } from "./cli.mjs";
import { FACT_MAX, factKey, factText, numbered, readEntries, resolvedText } from "./entries.mjs";
import { COMMENT_LINE, GOTCHAS_MAX, headingLines, lineKinds, lintText, sectionEntries } from "./memlint.mjs";

// never applied, matched by prefix on the heading text after `## ` (rane's carry a suffix); a fixed list, never inferred
export const PROTECTED = ["Live system", "Off-limits", "On-limits", "Hardware facts", "Hardware and Mixxx rules",
  "This repo runs Michael's harness runs"];
export const FILES = ["CLAUDE.md", ".harness/project.md", ".claude/CLAUDE.md"], MAX_OPS = 50, TEXT_MAX = FACT_MAX, WHY_MAX = 300, ANCHOR_MAX = 1000, SECTION_MAX = 200;
export const BODY_MAX = 60000;   // GitHub's body limit is 65536
const KEYS = new Set(["op", "file", "section", "anchor", "text", "tier", "why", "from"]), OPS = ["add", "replace", "delete"];
const SUFFIX = /\([^()\s]+ \d{4}-\d{2}-\d{2}\)$/, FROM = /^entries\.jsonl:([1-9]\d*)$/;
const PROTECTED_WHY = "protected section: a proposal for Michael";
export const chars = s => [...s].length, cut = (s, n) => (chars(s) > n ? [...s].slice(0, n).join("") + "…" : s);
const oneLine = s => typeof s === "string" && s.trim() !== "" && !/[\r\n]/.test(s);
const heading = s => String(s).replace(/\s+$/, "");
const bare = t => (typeof t === "string" ? t.replace(/^- /, "").trim() : t);   // the driver writes the bullet
// a line without its list marker and its (<run> <date>) suffix, so `- x (r1 …)`, `* x` and `1. x (r2 …)` say one thing
const said = s => String(s ?? "").replace(/^\s*(?:[-*+]|\d+\.)\s+/, "").replace(/\s*\([^()\s]+ \d{4}-\d{2}-\d{2}\)\s*$/, "");
const lineKey = s => factKey(said(s));
// a numbered item's key in memory-answers.jsonl, and an op's: its text's lineKey; a delete's is its anchor's, marked, so a
// declined delete never matches an add of that line (decisions/2026-11-08-memory-session-and-answers)
export const itemKey = o => (o.op === "delete" ? `delete ${lineKey(o.anchor)}` : lineKey(o.text));
// what a verdict matches: the whole normalized text, marked as the key is (two rules sharing a 40-character key are two)
const itemText = o => (o.op === "delete" ? `delete ${factText(said(o.anchor))}` : factText(said(o.text)));
// an item or an answers row ({key, text}: a delete's text is its anchor) as Michael and the curator read it
export const itemSaid = r => (String(r.key).startsWith("delete ") ? `delete: ${r.text}` : r.text);
const rowText = r => itemText(String(r.key).startsWith("delete ") ? { op: "delete", anchor: r.text } : { op: "add", text: r.text });
const VERDICTS = ["accepted", "declined"];
// memory-answers.jsonl's rows (a line that is no row passed over) → the latest per item, in the file's order: an item is
// its <run>/<n> and its key, since a continue numbers its own items from 1 (another item under an old number)
export function latestAnswers(rows) {
  const by = new Map();
  for (const r of rows ?? []) {
    if (!r || typeof r !== "object" || typeof r.run !== "string" || !Number.isInteger(r.n) || !VERDICTS.includes(r.verdict)) continue;
    const k = `${r.run}/${r.n}\0${r.key}`; by.delete(k); by.set(k, r);
  }
  return [...by.values()];
}
export const readJsonl = f => (existsSync(f) ? readFileSync(f, "utf8").split("\n").flatMap(l => { try { return l.trim() ? [JSON.parse(l)] : []; } catch { return []; } }) : []);
const fromLine = o => Number(FROM.exec(o.from)?.[1]);

function opWhy(o) {
  if (o === null || typeof o !== "object" || Array.isArray(o)) return "not an object";
  const extra = Object.keys(o).find(k => !KEYS.has(k));
  if (extra !== undefined) return `unknown key ${JSON.stringify(extra)}`;
  if (!OPS.includes(o.op)) return `op ${JSON.stringify(o.op)} is not add, replace or delete`;
  if (!FILES.includes(o.file)) return `file ${JSON.stringify(o.file)} is none of ${FILES.join(", ")}`;
  if (typeof o.section !== "string" || !/^## \S/.test(o.section) || /[\r\n]/.test(o.section)) return `section ${JSON.stringify(o.section)} is not one ## heading`;
  if (chars(o.section) > SECTION_MAX) return `section of ${chars(o.section)} characters, at most ${SECTION_MAX}`;
  if (o.anchor !== undefined && !oneLine(o.anchor)) return "anchor is not one non-blank line";
  if (o.anchor !== undefined && chars(o.anchor) > ANCHOR_MAX) return `anchor of ${chars(o.anchor)} characters, at most ${ANCHOR_MAX}`;
  if (o.op !== "add" && o.anchor === undefined) return `${o.op} without an anchor`;
  if (o.op !== "delete") {
    const t = bare(o.text);
    if (!oneLine(t)) return `${o.op} without a one-line text`;
    if (chars(t) > TEXT_MAX) return `text of ${chars(t)} characters, at most ${TEXT_MAX}`;
    if (heading(o.section) === "## Gotchas" && !SUFFIX.test(t)) return "a Gotchas text without its (<run> <date>) suffix";
  }
  if (![1, 2, 3].includes(o.tier)) return `tier ${JSON.stringify(o.tier)} is not 1, 2 or 3`;
  if (!oneLine(o.why) || chars(o.why) > WHY_MAX) return `why is not one non-blank line of at most ${WHY_MAX} characters`;
  if (typeof o.from !== "string" || !FROM.test(o.from)) return `from ${JSON.stringify(o.from)} is not entries.jsonl:<n>`;
  return null;
}

// memory-ops.json's text → { ok: true, ops } (each text without its leading `- `) or { ok: false, why }: an invalid file
// is refused whole, its first reason the one note (as the retro's proposals are)
export function validate(text) {
  let xs;
  try { xs = JSON.parse(text); } catch (e) { return { ok: false, why: `not JSON: ${e.message}` }; }
  if (!Array.isArray(xs)) return { ok: false, why: "not a JSON list" };
  if (xs.length > MAX_OPS) return { ok: false, why: `${xs.length} ops, at most ${MAX_OPS}` };
  for (const [i, o] of xs.entries()) { const why = opWhy(o); if (why) return { ok: false, why: `op ${i + 1}: ${why}` }; }
  return { ok: true, ops: xs.map(o => (o.op === "delete" ? { ...o } : { ...o, text: bare(o.text) })) };
}

// a `## ` heading → 3 (protected, by prefix: tested first), 1 (`## Gotchas` exactly) or 2 (every other heading)
export function tierOf(h) {
  const t = heading(h).replace(/^## /, "");
  if (PROTECTED.some(p => t.startsWith(p))) return 3;
  return t === "Gotchas" ? 1 : 2;
}

// a section's entries (sectionEntries) and an anchor → { entry }: the one line whose key is the anchor's, markers aside;
// else { why } naming the anchor (no line, or two)
export function matchAnchor(entries, anchor) {
  const k = lineKey(anchor), hits = entries.filter(e => lineKey(e.text) === k);
  if (hits.length === 1) return { entry: hits[0] };
  return { why: `anchor ${JSON.stringify(cut(anchor, 60))} matches ${hits.length ? `${hits.length} lines` : "no line"}` };
}

export const lineCount = t => String(t ?? "").replace(/\n$/, "").split("\n").length, CAPPED = ["CLAUDE.md", ".claude/CLAUDE.md"];

// a file's text before and after one tier-1 op → the first breach of the cap, or null. lintText's size and gotchas
// findings count only when that measure also grew, so a file already past the cap still takes a replace or a delete,
// and an add with an anchor (one line out, one in) passes. CLAUDE.md and its twin .claude/CLAUDE.md are capped, each on
// its own, as memlint lints them; .harness/project.md is not.
export function capCheck(file, before, after, maxLines = 120) {
  if (!CAPPED.includes(file) || after == null) return null;
  const f = lintText(file, after, { claude: true, maxLines }), has = c => f.some(x => x.check === c);
  const g = t => sectionEntries(t, "## Gotchas").length;
  if (has("size") && lineCount(after) > lineCount(before)) return `${file}: ${lineCount(after)} lines, over ${maxLines}`;
  if (has("gotchas") && g(after) > g(before)) return `## Gotchas: ${g(after)} entries, over ${GOTCHAS_MAX}`;
  return null;
}

// the write gate's rule (prompts/curator.md's write-gate paragraph says it in the same order): a line's first 40
// characters (or all of it, if shorter) are its entry's, and after that it may leave words of the entry's text out but
// never add, change or reorder one, and never leave out `not`, `never`, `no`, `without` or a word ending `n't`; case,
// markup and the (<run> <date>) suffix aside. So no tail the entry never stated is written, a long fact can be written
// short without losing its end, and no cut turns a rule around. A word is a run of letters and digits (an apostrophe
// inside kept), so punctuation and markup never part a line from its entry.
const WORD = /[\p{L}\p{N}]+(?:['’][\p{L}\p{N}]+)*/gu, NEGATION = /^(?:not|never|no|without)$|n['’]t$/u;
const wordsOf = s => s.match(WORD) ?? [];
// an item's normalized text and a line's → null (the line says what the item says), "" (its first 40 characters are not
// the item's) or where it parts from the item: `"<word>" is not the entry's next word`, `"not" left out`
export function partsWhy(item, line) {
  const n = Math.min(40, chars(item));
  if ([...line].slice(0, n).join("") !== [...item].slice(0, n).join("")) return "";
  const ws = wordsOf(item), left = (a, b) => ws.slice(a, b).find(x => NEGATION.test(x));
  let i = 0;
  for (const w of wordsOf(line)) {
    const j = ws.indexOf(w, i);
    if (j < 0) return `"${w}" is not the entry's next word`;
    const neg = left(i, j);
    if (neg) return `"${neg}" left out`;
    i = j + 1;
  }
  const neg = left(i);
  return neg ? `"${neg}" left out` : null;
}

// the write gate: the text says what an item of the from entry says, by the rule above; a drop names where the line
// parts from the nearest item (one sharing its first 40 characters), the plain reason when none does. A tier-1 op needs a
// project discovery; a proposed_changes string is Michael's (how to work here) and gates only a tier-2 or tier-3 op. No
// later entry's resolved may name it (the pack's rule). A line that arrived in a tool result or a file the session read
// is in no entry's discoveries, so it is dropped here.
function gateWhy(es, e, text, tier) {
  const t = factText(said(text)).replace(/…$/, "").trimEnd(), k = lineKey(text);
  const why = x => partsWhy(factText(said(x)), t);
  const fw = (e.discoveries ?? []).filter(d => (d.affects ?? []).includes("project")).map(d => why(d.text)), pw = (e.proposed_changes ?? []).map(why);
  if (!fw.includes(null)) {
    if (!pw.includes(null)) { const near = [...fw, ...(tier === 1 ? [] : pw)].find(Boolean); return `not stated by entries.jsonl:${e.line}${near ? ` (${near})` : ""}`; }
    if (tier === 1) return `not stated by entries.jsonl:${e.line} as a project fact`;
  }
  const r = es.find(x => x.line > e.line && (x.resolved ?? []).some(y => lineKey(resolvedText(y)) === k));
  return r ? `resolved by entries.jsonl:${r.line}` : null;
}

// one op written into a text: an add after the section's last entry (with hit, in place of its anchor: the eviction), a
// replace in place of its anchor, a delete removing its anchor's lines (a wrapped entry whole); into a section with no
// entry, under its heading and the comment lines right below it (the template's `<!-- At most 15 lines … -->`, no entry:
// memlint.mjs COMMENT_LINE) (a CRLF file keeps its line ends)
function write(text, o, hit, sec) {
  const ls = text.split("\n"), line = `- ${o.text}${text.includes("\r\n") ? "\r" : ""}`;
  const below = h => { let i = h + 1; while (COMMENT_LINE.test(ls[i] ?? "")) i++; return i; };
  if (hit) ls.splice(hit.line - 1, hit.last - hit.line + 1, ...(o.op === "delete" ? [] : [line]));
  else ls.splice(sec.length ? sec.at(-1).last : below(headingLines(text, o.section)[0]), 0, line);
  return ls.join("\n");
}

// a text's protected sections as raw lines, fences ignored (an unclosed fence must not hide one): each from its `## `
// line to the next; a write that changes them is dropped, whatever entry its anchor matched (invariant 2)
const guarded = t => {
  const out = [];
  let cur = null;
  for (const l of String(t ?? "").split("\n")) {
    if (/^##\s/.test(l)) { cur = tierOf(l.replace(/\r$/, "")) === 3 ? [] : null; if (cur) out.push(cur); }
    if (cur) cur.push(l);
  }
  return out.map(b => b.join("\n"));
};

// the union of the two PRs as one text: <rules> with its `## Gotchas` section (heading to the next `# `/`## ` heading,
// fences aside) put in place of <facts>' one, since tier 1 writes only there and tier 2 never does; <facts> when either
// lacks the section once (a continue's rules tip holds the earlier segments' rules, the facts tip their facts)
export function graft(rules, facts) {
  if (rules == null || facts == null || rules === facts) return facts;
  const span = t => {
    const ks = [...lineKinds(t)], h = headingLines(t, "## Gotchas");
    if (h.length !== 1) return null;
    const end = ks.find(k => k.i > h[0] && !k.code && /^#{1,2}\s/.test(k.line));
    return [h[0], end ? end.i : ks.length];
  };
  const a = span(rules), b = span(facts);
  if (!a || !b) return facts;
  const rl = rules.split("\n"), fl = facts.split("\n");
  return [...rl.slice(0, a[0]), ...fl.slice(b[0], b[1]), ...rl.slice(a[1])].join("\n");
}

// <base>, <main> → the lines main gained outside `## Gotchas` since <base> (a stale rules tip's merge-base with main):
// the merge takes them too, so the union shadow counts them; 0 when main lost lines or either is missing
export function drift(base, main) {
  if (base == null || main == null || base === main) return 0;
  const g = graft(base, main);   // base outside Gotchas, main's Gotchas; main itself when either lacks the one section
  return Math.max(0, lineCount(main) - lineCount(g === main ? base : g));
}

// ops (validate's), the files' texts on the base ({ <each of FILES>: text|null }), the run's entries (readEntries'
// list) and the run id → { texts, ruleTexts, ops, applied, rules, proposed, dropped: [{ op, reason }], rederived, run }.
// Every op carries the tier tierOf derives; its own is a claim, only counted (rederived). texts is the base plus tier 1,
// ruleTexts the rules base (ruleBase, the base unless given: a continue's harness-rules tip) plus tier 2, so the rules
// commit is cut from its own base and never stacked on the facts (decisions/2026-11-08-memory-rules-pr).
// Steps, the first failing one dropping the op: the file, the section, the from entry and the gate (not for a delete);
// one op per key among those left (the latest entry's); the tier (3: dropped and proposed); the anchor; not already
// there; memlint's derivable count or run scope in a tier-1 text; the write changing a protected section's raw lines;
// the cap (capCheck on the text before and after this one op: that op alone dropped, the next tried on the text before
// it). Tier 1 goes first, then tier 2; within each the writes go delete, replace, anchored add, plain add (each group in
// the ops' order), so a delete frees the line an add needs. A tier-2 op is capped on its rules text and then on the
// union shadow (graft: the rules base with tier 1's Gotchas, tier 2's ops on it, and drift's lines per file: what main
// gained under a stale rules tip), and a tier-1 op on the graft too, so merging both PRs never passes the cap. An
// anchored add appends while that fits the cap (on the shadow too) and evicts its anchor (`evicted`: the line it
// replaced) only when it would not; a tier-1 add whose anchor a delete or replace in the list took still lands when it fits. rules and proposed keep the
// ops' order and are numbered n (the rules first, then the proposals: <run>/<n>). ops = applied + rules + dropped.
const ORDER = o => (o.op === "delete" ? 0 : o.op === "replace" ? 1 : o.anchor !== undefined ? 2 : 3);
export function apply(ops, texts, entries, run, { maxLines = 120, ruleBase = texts, drift = {}, answers = [] } = {}) {
  const answered = new Map(latestAnswers(answers).map(r => [rowText(r), r]));   // a later verdict on the same line wins
  const es = numbered(entries), byLine = new Map(es.map(e => [e.line, e])), out = { ...texts }, rout = { ...ruleBase };
  const applied = [], rules = [], proposed = [], dropped = [], keep = new Map();
  let rederived = 0, shadow = null;
  const taken = [], pad = (f, t) => (t == null || !(drift[f] > 0) ? t : "\n".repeat(drift[f]) + t);   // main's lines the merge adds
  const placeWhy = (text, o) => {
    const n = headingLines(text, o.section).length;
    if (text == null) return `no ${o.file} on the base`;
    if (!n) return `no section ${heading(o.section)} in ${o.file}`;
    if (n > 1) return `section ${heading(o.section)} appears ${n} times in ${o.file}`;   // which one is meant is Michael's
    return null;
  };
  // the file, the section and the gate first, so an op that fails them never takes its key from one that passes
  const early = ops.map(o => {
    const e = byLine.get(fromLine(o)), w = placeWhy(out[o.file], o);
    if (w) return w;
    if (!e) return `from ${o.from} names no entry`;
    return o.op === "delete" ? null : gateWhy(es, e, o.text, tierOf(o.section));
  });
  ops.forEach((o, i) => {   // one op per key: the latest entry's, so a fact stated then corrected gives the correction
    if (o.op === "delete" || early[i]) return;
    const k = lineKey(o.text), j = keep.get(k);
    if (j === undefined || fromLine(ops[j]) <= fromLine(o)) keep.set(k, i);
  });
  const protectedWhy = (text, next) => {
    const was = guarded(text), now = guarded(next);
    return now.join("\0") === was.join("\0") ? null
      : `would change the protected section ${(was.find((b, j) => b !== now[j]) ?? now.find(b => !was.includes(b))).split("\n")[0].replace(/\r$/, "")}`;
  };
  const step = i => {
    const given = ops[i], tier = tierOf(given.section), o = { ...given, tier }, drop = reason => { dropped.push({ op: o, reason }); };
    if (given.tier !== tier) rederived++;
    if (early[i]) return drop(early[i]);
    if (o.op !== "delete" && keep.get(lineKey(o.text)) !== i) return drop(`duplicate key; ${ops[keep.get(lineKey(o.text))].from} kept`);
    // Michael's verdict closes a rule or a proposal by its line alone (any section); a fact is never his to decline
    const v = tier === 1 ? undefined : answered.get(itemText(o));
    if (v) return drop(v.verdict === "declined" ? `declined by Michael (${v.run}/${v.n}: ${cut(v.why, 80)})` : `accepted by Michael (${v.run}/${v.n})`);
    if (tier === 3) { proposed.push([i, o]); return drop(PROTECTED_WHY); }
    const set = tier === 2 ? rout : out, text = set[o.file];
    if (tier === 2) { const w = placeWhy(text, o); if (w) return drop(w); }
    const sec = sectionEntries(text, o.section);
    let hit = null;
    // an add's anchor is only the line it may evict: gone (a delete or replace in the list took it), a tier-1 add still
    // lands if it fits; one no op took is the curator's mistake, named
    if (o.anchor !== undefined) {
      const m = matchAnchor(sec, o.anchor);
      if (m.why && !(o.op === "add" && tier === 1 && matchAnchor(taken, o.anchor).entry && !capCheck(o.file, text, write(text, o, null, sec), maxLines))) return drop(m.why);
      hit = m.entry ?? null;
    }
    if (o.op === "add" && sec.some(x => lineKey(x.text) === lineKey(o.text))) return drop(`already in ${heading(o.section)}`);
    // memlint's line lints hold at a tier-1 write, as its cap does in capCheck (memlint-self's "lints clean", M3-04)
    const lf = o.op === "delete" || tier === 2 ? [] : lintText(o.file, o.text);
    if (lf.length) return drop(`${lf[0].check}: ${lf[0].text}`);
    // the union: the write on the shadow too (tier 1's: the rules text with this Gotchas), its anchor matched there
    // (none: a replace or delete leaves it as it was)
    const sh = tier === 2 ? shadow[o.file] : pad(o.file, graft(rout[o.file], text)), ssec = sectionEntries(sh, o.section);
    const shit = o.anchor !== undefined ? matchAnchor(ssec, o.anchor).entry ?? null : null;
    const fits = (t, s) => capCheck(o.file, t, write(t, o, null, s), maxLines) === null;
    // an anchored add appends while that fits the cap, on the union too, and evicts its anchor only when it would not
    const evict = o.op === "add" && hit !== null && !(fits(text, sec) && fits(sh, ssec));
    const next = write(text, o, o.op === "add" && !evict ? null : hit, sec);
    const pw = protectedWhy(text, next);
    if (pw) return drop(pw);
    const snext = o.op !== "add" && !shit ? sh : write(sh, o, o.op === "add" && !evict ? null : shit, ssec);
    const over = capCheck(o.file, text, next, maxLines) ?? capCheck(o.file, sh, snext, maxLines);
    if (over) return drop(`over the cap: ${over}`);
    set[o.file] = next;
    if (tier === 1 && o.op !== "add" && hit) taken.push(hit);
    const done = evict ? { ...o, evicted: hit.text.replace(/\r/g, "") } : o;
    if (tier === 2) { shadow[o.file] = snext; rules.push([i, done]); } else applied.push(done);
  };
  const sorted = ops.map((o, i) => i).sort((i, j) => ORDER(ops[i]) - ORDER(ops[j]) || i - j), two = i => tierOf(ops[i].section) === 2;
  sorted.filter(i => !two(i)).forEach(step);
  shadow = Object.fromEntries(Object.keys(out).map(f => [f, pad(f, graft(rout[f], out[f]))]));
  sorted.filter(two).forEach(step);
  let n = 0;
  const num = xs => xs.sort((x, y) => x[0] - y[0]).map(([, o]) => ({ ...o, n: ++n }));
  const rs = num(rules), ps = num(proposed);
  return { texts: out, ruleTexts: rout, ops: ops.length, applied, rules: rs, proposed: ps, dropped, rederived, run };
}

// memory-answers.jsonl's rows, a project and a byte cap → the curator prompt's block: what Michael declined, then what he
// accepted, newest first, each `- <text> (<run>/<n>)` (a decline with its why); cut to <maxBytes> oldest first (accepted
// before declined) with a line saying how many were left out; (none yet) for none
export function answersText(rows, project, maxBytes = 4000) {
  const xs = latestAnswers(rows).map((r, i) => [r, i]).filter(([r]) => r.project === project)
    .sort(([x, i], [y, j]) => String(y.at ?? "").localeCompare(String(x.at ?? "")) || j - i).map(([r]) => r);
  const why = r => (typeof r.why === "string" && r.why ? `: ${r.why}` : "");   // a hand-written row may carry none
  const groups = [["Michael declined (never propose again):", xs.filter(r => r.verdict === "declined").map(r => `- ${itemSaid(r)} (${r.run}/${r.n})${why(r)}`)],
    ["Michael accepted (already his to place):", xs.filter(r => r.verdict === "accepted").map(r => `- ${itemSaid(r)} (${r.run}/${r.n})`)]];
  if (!xs.length) return "(none yet)";
  let left = 0;
  const render = () => [...groups.filter(g => g[1].length).map(([h, ls]) => [h, ...ls].join("\n")),
    ...(left ? [`(${left} more left out: the prompt's cap is ${maxBytes} bytes; ledger/memory-answers.jsonl has them all)`] : [])].join("\n\n");
  let t = render();
  while (Buffer.byteLength(t) > maxBytes) {
    const g = groups.findLast(x => x[1].length);
    if (!g) break;
    g[1].pop(); left++; t = render();
  }
  return t;
}

const fence = s => { const f = "`".repeat(Math.max(3, ...[...s.matchAll(/`+/g)].map(m => m[0].length + 1))); return `${f}\n${s}\n${f}`; };
// outside a fence an @login would notify that user when the PR opens
const quiet = s => String(s).replace(/@(?=[\w-])/g, "@\u200b");
const where = o => `\`${o.op}\` ${o.file} · ${quiet(heading(o.section))}`;   // a section is the session's text too
const line = o => quiet(o.op === "delete" ? o.anchor : o.text);
// a tier-2 or tier-3 op as a diff reader or a paster wants it: its number (<run>/<n>), what it does, why, then the
// line(s) in a fenced block
const paste = o => [`### ${o.n !== undefined ? `${o.n} · ` : ""}${where(o)} (${o.from})`, "", quiet(o.why),
  ...(o.anchor !== undefined ? ["", o.op === "delete" ? "Remove:" : "In place of:", "", fence(o.anchor)] : []),
  ...(o.op === "delete" ? [] : ["", o.op === "add" && o.anchor === undefined ? "Add:" : "Write:", "", fence(`- ${o.text}`)])].join("\n");
const BODIES = ["facts", "rules", "union"];
const INTRO = {
  facts: "Tier 1 (`## Gotchas`) is this branch's commit. Tier 2 goes to its own PR, `memory rules: <run>` (named at the end; none when it did not open), yours to merge or close. A protected section is never edited: its proposals are for you.",
  rules: "Tier 2 (every other section) is this branch's commit, cut from the base without the facts: yours to merge or close, never the driver's. A protected section is never edited: its proposals are for you.",
  union: "Tier 1 (`## Gotchas`) is the `memory: <run>` PR's commit, tier 2 the `memory rules: <run>` PR's, each cut from the base. A protected section is never edited: its proposals are for you.",
};

// apply's result (as the CLI prints it), the run id, which body (facts: the memory PR's; rules: the memory rules PR's;
// union: memory.md's) and the other PR's URL → the body: the counts, then the applied ops (facts, union), the rules
// (rules, union), the protected proposals and the dropped ops with their reasons, each with its from, the rules and
// proposals numbered in one sequence; a facts body ends `Rules of this run: <url|none>`, a rules body `Facts of this run:
// …`. An empty part left out, the body cut to BODY_MAX bytes with a line saying how many items were left out
export function body(r, run = r.run, which = "union", other = "") {
  const rules = r.rules ?? [], t3 = r.proposed.filter(o => o.tier === 3);
  const lost = r.dropped.filter(d => d.reason !== PROTECTED_WHY);
  const head = [`Project memory curated by run \`${run}\`: ${r.ops} ops · ${r.applied.length} facts · ${rules.length} rules · ${r.dropped.length} dropped · ${t3.length} proposals.`,
    "", INTRO[which].replaceAll("<run>", run)];
  const parts = [
    ...(which === "rules" ? [] : [["## Applied (tier 1)", r.applied.map(o => `- ${where(o)}: ${line(o)}${o.op === "replace" || o.evicted !== undefined ? ` (in place of: ${quiet(o.op === "replace" ? o.anchor : o.evicted)})` : ""} — ${quiet(o.why)} (${o.from})`), "\n"]]),
    ...(which === "facts" ? [] : [["## Rules (tier 2)", rules.map(paste), "\n\n"]]),
    ["## Proposals (protected, tier 3)", t3.map(paste), "\n\n"],
    ["## Dropped", lost.map(({ op: o, reason }) => `- ${where(o)}: ${line(o)} — ${quiet(reason)} (${o.from})`), "\n"],
  ];
  const link = which === "facts" ? [`Rules of this run: ${other || "none"}`] : which === "rules" ? [`Facts of this run: ${other || "none"}`] : [];
  let left = 0;
  const render = () => [head.join("\n"), ...parts.filter(p => p[1].length).map(([t, xs, sep]) => `${t}\n\n${xs.join(sep)}`),
    ...(left ? [`_${left} items left out: the body's cap is ${BODY_MAX} bytes; memory-result.json has them all._`] : []), ...link].join("\n\n") + "\n";
  let b = render();
  while (Buffer.byteLength(b) > BODY_MAX) {
    const p = parts.findLast(x => x[1].length);
    if (!p) break;
    p[1].pop(); left++; b = render();
  }
  return b;
}

// <worktree>/<file>'s text, or null when it is missing or no plain file inside the worktree (a symlink, or one under a
// symlinked .harness or .claude): apply never reads or writes through a link
const plain = (wt, f) => {
  const p = join(wt, f);
  try { if (!lstatSync(p).isFile() || realpathSync(p) !== join(realpathSync(wt), f)) return null; } catch { return null; }
  return readFileSync(p, "utf8");
};

const maxLinesOf = env => { const n = Number(env?.MEMLINT_LINES); return Number.isInteger(n) && n > 0 ? n : 120; };

export const main = captured(([cmd, ...a], io, say, put) => {
  const read = f => readFileSync(f, "utf8");
  if (cmd === "validate" && a.length === 1) { const v = validate(read(a[0])); say(v.ok ? "ok" : v.why); return v.ok ? 0 : 1; }
  const opt = k => { const i = a.indexOf(k); if (i < 0) return undefined; const x = a[i + 1]; a.splice(i, 2); return x ?? ""; };
  if (cmd === "answers") {
    const mbs = opt("--max-bytes"), mb = mbs === undefined ? 4000 : Number(mbs);
    if (a.length === 2 && Number.isInteger(mb) && mb > 0) { say(answersText(readJsonl(a[0]), a[1], mb)); return 0; }
  }
  const af = cmd === "apply" ? opt("--answers") : undefined, ap = cmd === "apply" ? opt("--project") : undefined;
  if (cmd === "apply" && [4, 5, 7].includes(a.length)) {
    const [opsFile, wt, run, ents, rb, mb, mn] = a, v = validate(read(opsFile));
    const answers = af ? readJsonl(af).filter(r => ap === undefined || r?.project === ap) : [];
    if (!v.ok) { say(JSON.stringify({ invalid: v.why })); return 1; }
    const at = d => Object.fromEntries(FILES.map(f => [f, plain(d, f)])), texts = at(wt);
    const ruleBase = rb === undefined ? texts : at(rb), m0 = mb === undefined ? {} : at(mb), m1 = mn === undefined ? {} : at(mn);
    const dr = Object.fromEntries(FILES.map(f => [f, drift(m0[f], m1[f])]));
    const { texts: after, ruleTexts, ...r } = apply(v.ops, texts, readEntries(ents), run, { maxLines: maxLinesOf(io.env), ruleBase, drift: dr, answers });
    const files = FILES.filter(f => after[f] !== texts[f]), ruleFiles = FILES.filter(f => ruleTexts[f] !== ruleBase[f]);
    for (const f of files) writeFileSync(join(wt, f), after[f]);
    // the rules pass writes ruleTexts into its own worktree at the rules base (memory_pr)
    say(JSON.stringify({ ...r, files, ruleFiles, ruleTexts: Object.fromEntries(ruleFiles.map(f => [f, ruleTexts[f]])) }));
    return 0;
  }
  if (cmd === "body" && a.length >= 2 && a.length <= 4 && (a[2] === undefined || BODIES.includes(a[2]))) {
    put(body(JSON.parse(read(a[0])), a[1], a[2] ?? "union", a[3] ?? "")); return 0;
  }
  console.error("usage: curator.mjs validate <ops.json> | apply <ops.json> <worktree> <run> <entries.jsonl> [<rules base> [<rules merge-base> <main>]] [--answers <file> --project <p>] | body <result.json> <run> [facts|rules|union] [<other PR url>] | answers <answers.jsonl> <project> [--max-bytes <n>]");
  return 2;
});

if (isMain(import.meta.url)) runCli(main);
