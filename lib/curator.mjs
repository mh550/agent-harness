// The memory curator's rules (M2): a read-only session's operations on project memory (FILES), validated, each one's tier
// derived from its heading, gated by the run's entries and applied under the cap. The driver commits tier 1 and sends
// tier 2 and 3 to Michael in a PR body; the session never writes a project file (decisions/2026-11-07-memory-tiers).
//   validate <ops.json>                                → `ok` (0), or the first reason (1)
//   apply <ops.json> <worktree> <run> <entries.jsonl>  → one JSON line {ops, applied, proposed, dropped, rederived,
//                                                        run, files}, the changed files written into <worktree>; an
//                                                        invalid file is {invalid} (1). MEMLINT_LINES caps
//   body <result.json> <run>                           → the memory PR's body (Markdown)
import { lstatSync, readFileSync, realpathSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { captured, isMain, runCli } from "./cli.mjs";
import { factKey, factText, numbered, readEntries, resolvedText } from "./entries.mjs";
import { GOTCHAS_MAX, headingLines, lintText, sectionEntries } from "./memlint.mjs";

// never applied, matched by prefix on the heading text after `## ` (rane's carry a suffix); a fixed list, never inferred
export const PROTECTED = ["Live system", "Off-limits", "On-limits", "Hardware facts", "Hardware and Mixxx rules",
  "This repo runs Michael's harness runs"];
export const FILES = ["CLAUDE.md", ".harness/project.md", ".claude/CLAUDE.md"], MAX_OPS = 50, TEXT_MAX = 160, WHY_MAX = 300, ANCHOR_MAX = 1000, SECTION_MAX = 200;
export const BODY_MAX = 60000;   // GitHub's body limit is 65536
const KEYS = new Set(["op", "file", "section", "anchor", "text", "tier", "why", "from"]), OPS = ["add", "replace", "delete"];
const SUFFIX = /\([^()\s]+ \d{4}-\d{2}-\d{2}\)$/, FROM = /^entries\.jsonl:([1-9]\d*)$/;
const PROTECTED_WHY = "protected section: a proposal for Michael";
const chars = s => [...s].length, cut = (s, n) => (chars(s) > n ? [...s].slice(0, n).join("") + "…" : s);
const oneLine = s => typeof s === "string" && s.trim() !== "" && !/[\r\n]/.test(s);
const heading = s => String(s).replace(/\s+$/, "");
const bare = t => (typeof t === "string" ? t.replace(/^- /, "").trim() : t);   // the driver writes the bullet
// a line without its list marker and its (<run> <date>) suffix, so `- x (r1 …)`, `* x` and `1. x (r2 …)` say one thing
const said = s => String(s ?? "").replace(/^\s*(?:[-*+]|\d+\.)\s+/, "").replace(/\s*\([^()\s]+ \d{4}-\d{2}-\d{2}\)\s*$/, "");
const lineKey = s => factKey(said(s));
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

const count = t => String(t ?? "").replace(/\n$/, "").split("\n").length, CAPPED = ["CLAUDE.md", ".claude/CLAUDE.md"];

// a file's text before and after one tier-1 op → the first breach of the cap, or null. lintText's size and gotchas
// findings count only when that measure also grew, so a file already past the cap still takes a replace or a delete,
// and an add with an anchor (one line out, one in) passes. CLAUDE.md and its twin .claude/CLAUDE.md are capped, each on
// its own, as memlint lints them; .harness/project.md is not.
export function capCheck(file, before, after, maxLines = 120) {
  if (!CAPPED.includes(file) || after == null) return null;
  const f = lintText(file, after, { claude: true, maxLines }), has = c => f.some(x => x.check === c);
  const g = t => sectionEntries(t, "## Gotchas").length;
  if (has("size") && count(after) > count(before)) return `${file}: ${count(after)} lines, over ${maxLines}`;
  if (has("gotchas") && g(after) > g(before)) return `## Gotchas: ${g(after)} entries, over ${GOTCHAS_MAX}`;
  return null;
}

// the write gate: the text says what an item of the from entry says, whole or cut short (at least its first 40
// characters, or all of it), case, markup and the (<run> <date>) suffix aside; so no tail the entry never stated is
// written. A tier-1 op needs a project discovery; a proposed_changes string is Michael's (how to work here) and gates
// only a tier-2 or tier-3 op. No later entry's resolved may name it (the pack's rule). A line that arrived in a tool
// result or a file the session read is in no entry's discoveries, so it is dropped here.
function gateWhy(es, e, text, tier) {
  const t = factText(said(text)).replace(/…$/, "").trimEnd(), k = lineKey(text);
  const says = x => { const w = factText(said(x)); return w.startsWith(t) && chars(t) >= Math.min(40, chars(w)); };
  const facts = (e.discoveries ?? []).filter(d => (d.affects ?? []).includes("project")).map(d => d.text);
  if (!facts.some(says)) {
    if (!(e.proposed_changes ?? []).some(says)) return `not stated by entries.jsonl:${e.line}`;
    if (tier === 1) return `not stated by entries.jsonl:${e.line} as a project fact`;
  }
  const r = es.find(x => x.line > e.line && (x.resolved ?? []).some(y => lineKey(resolvedText(y)) === k));
  return r ? `resolved by entries.jsonl:${r.line}` : null;
}

// one op written into a text: an add after the section's last entry (with hit, in place of its anchor: the eviction), a
// replace in place of its anchor, a delete removing its anchor's lines (a wrapped entry whole)
// (a CRLF file keeps its line ends)
function write(text, o, hit, sec) {
  const ls = text.split("\n"), line = `- ${o.text}${text.includes("\r\n") ? "\r" : ""}`;
  if (hit) ls.splice(hit.line - 1, hit.last - hit.line + 1, ...(o.op === "delete" ? [] : [line]));
  else ls.splice(sec.length ? sec.at(-1).last : headingLines(text, o.section)[0] + 1, 0, line);
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

// ops (validate's), the files' texts on the base ({ <each of FILES>: text|null }), the
// run's entries (readEntries' list) and the run id → { texts, ops, applied, proposed, dropped: [{ op, reason }],
// rederived, run }. Every op carries the tier tierOf derives; its own is a claim, only counted (rederived).
// Steps, the first failing one dropping the op: the file, the section, the from entry and the gate (not for a delete);
// one op per key among those left (the latest entry's); the tier (3: dropped and proposed); the anchor; not already
// there; then tier 2 is proposed and tier 1 written, unless memlint finds a derivable count or run scope in its text,
// the write changes a protected section's raw lines, or it breaches the cap (capCheck on the text before and after this
// one op: that op alone dropped, the next tried on the text before it). The writes go delete, replace, anchored add,
// plain add (each group in the ops' order), so a delete frees the line an add needs; an anchored add appends while that
// fits the cap and evicts its anchor (`evicted`: the line it replaced) only when it would not; its anchor gone (a delete
// in the list took it), it still lands when it fits. ops = applied + tier 2 + dropped.
const ORDER = o => (o.op === "delete" ? 0 : o.op === "replace" ? 1 : o.anchor !== undefined ? 2 : 3);
export function apply(ops, texts, entries, run, { maxLines = 120 } = {}) {
  const es = numbered(entries), byLine = new Map(es.map(e => [e.line, e])), out = { ...texts };
  const applied = [], proposed = [], dropped = [], keep = new Map();
  let rederived = 0;
  // the file, the section and the gate first, so an op that fails them never takes its key from one that passes
  const early = ops.map(o => {
    const text = out[o.file], e = byLine.get(fromLine(o)), n = headingLines(text, o.section).length;
    if (text == null) return `no ${o.file} on the base`;
    if (!n) return `no section ${heading(o.section)} in ${o.file}`;
    if (n > 1) return `section ${heading(o.section)} appears ${n} times in ${o.file}`;   // which one is meant is Michael's
    if (!e) return `from ${o.from} names no entry`;
    return o.op === "delete" ? null : gateWhy(es, e, o.text, tierOf(o.section));
  });
  ops.forEach((o, i) => {   // one op per key: the latest entry's, so a fact stated then corrected gives the correction
    if (o.op === "delete" || early[i]) return;
    const k = lineKey(o.text), j = keep.get(k);
    if (j === undefined || fromLine(ops[j]) <= fromLine(o)) keep.set(k, i);
  });
  ops.map((o, i) => i).sort((i, j) => ORDER(ops[i]) - ORDER(ops[j]) || i - j).forEach(i => {
    const given = ops[i], tier = tierOf(given.section), o = { ...given, tier }, drop = reason => { dropped.push({ op: o, reason }); };
    if (given.tier !== tier) rederived++;
    if (early[i]) return drop(early[i]);
    if (o.op !== "delete" && keep.get(lineKey(o.text)) !== i) return drop(`duplicate key; ${ops[keep.get(lineKey(o.text))].from} kept`);
    if (tier === 3) { proposed.push(o); return drop(PROTECTED_WHY); }
    const text = out[o.file], sec = sectionEntries(text, o.section);
    let hit = null;
    // an add's anchor is only the line it may evict: gone (a delete in the list took it), the add still lands if it fits
    if (o.anchor !== undefined) {
      const m = matchAnchor(sec, o.anchor);
      if (m.why && !(o.op === "add" && tier === 1 && !capCheck(o.file, text, write(text, o, null, sec), maxLines))) return drop(m.why);
      hit = m.entry ?? null;
    }
    if (o.op === "add" && sec.some(x => lineKey(x.text) === lineKey(o.text))) return drop(`already in ${heading(o.section)}`);
    if (tier === 2) return proposed.push(o);
    // memlint's line lints hold at the write, as its cap does in capCheck (memlint-self's "lints clean", M3-04)
    const lf = o.op === "delete" ? [] : lintText(o.file, o.text);
    if (lf.length) return drop(`${lf[0].check}: ${lf[0].text}`);
    // an anchored add appends while that fits the cap, and evicts its anchor only when it would not
    const evict = o.op === "add" && hit && capCheck(o.file, text, write(text, o, null, sec), maxLines) !== null;
    const next = write(text, o, o.op === "add" && !evict ? null : hit, sec);
    const was = guarded(text), now = guarded(next);
    if (now.join("\0") !== was.join("\0")) return drop(`would change the protected section ${(was.find((b, j) => b !== now[j]) ?? now.find(b => !was.includes(b))).split("\n")[0].replace(/\r$/, "")}`);
    const over = capCheck(o.file, text, next, maxLines);
    if (over) return drop(`over the cap: ${over}`);
    out[o.file] = next;
    applied.push(evict ? { ...o, evicted: hit.text.replace(/\r/g, "") } : o);
  });
  return { texts: out, ops: ops.length, applied, proposed, dropped, rederived, run };
}

const fence = s => { const f = "`".repeat(Math.max(3, ...[...s.matchAll(/`+/g)].map(m => m[0].length + 1))); return `${f}\n${s}\n${f}`; };
// outside a fence an @login would notify that user when the PR opens
const quiet = s => String(s).replace(/@(?=[\w-])/g, "@\u200b");
const where = o => `\`${o.op}\` ${o.file} · ${quiet(heading(o.section))}`;   // a section is the session's text too
const line = o => quiet(o.op === "delete" ? o.anchor : o.text);
// a tier-2 or tier-3 op, ready to paste: what it does, why, then the line(s) in a fenced block
const paste = o => [`### ${where(o)} (${o.from})`, "", quiet(o.why),
  ...(o.anchor !== undefined ? ["", o.op === "delete" ? "Remove:" : "In place of:", "", fence(o.anchor)] : []),
  ...(o.op === "delete" ? [] : ["", o.op === "add" && o.anchor === undefined ? "Add:" : "Write:", "", fence(`- ${o.text}`)])].join("\n");

// apply's result (as the CLI prints it) and the run id → the memory PR's body: the counts, then the applied ops, the
// tier-2 ops to paste, the protected proposals and the dropped ops with their reasons, each with its from; an empty
// part left out, the body cut to BODY_MAX bytes with a line saying how many items were left out
export function body(r, run = r.run) {
  const t2 = r.proposed.filter(o => o.tier === 2), t3 = r.proposed.filter(o => o.tier === 3);
  const lost = r.dropped.filter(d => d.reason !== PROTECTED_WHY);
  const head = [`Project memory curated by run \`${run}\`: ${r.ops} ops · ${r.applied.length} applied · ${r.dropped.length} dropped · ${r.proposed.length} proposals.`,
    "", "Tier 1 (`## Gotchas`) is this branch's commit. Tier 2 is never committed: paste what you want. A protected section is never edited: its proposals are for you."];
  const parts = [
    ["## Applied (tier 1)", r.applied.map(o => `- ${where(o)}: ${line(o)}${o.op === "replace" || o.evicted !== undefined ? ` (in place of: ${quiet(o.op === "replace" ? o.anchor : o.evicted)})` : ""} — ${quiet(o.why)} (${o.from})`), "\n"],
    ["## For you to paste (tier 2)", t2.map(paste), "\n\n"],
    ["## Proposals (protected, tier 3)", t3.map(paste), "\n\n"],
    ["## Dropped", lost.map(({ op: o, reason }) => `- ${where(o)}: ${line(o)} — ${quiet(reason)} (${o.from})`), "\n"],
  ];
  let left = 0;
  const render = () => [head.join("\n"), ...parts.filter(p => p[1].length).map(([t, xs, sep]) => `${t}\n\n${xs.join(sep)}`),
    ...(left ? [`_${left} items left out: the body's cap is ${BODY_MAX} bytes; memory-result.json has them all._`] : [])].join("\n\n") + "\n";
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
  if (cmd === "apply" && a.length === 4) {
    const [opsFile, wt, run, ents] = a, v = validate(read(opsFile));
    if (!v.ok) { say(JSON.stringify({ invalid: v.why })); return 1; }
    const texts = Object.fromEntries(FILES.map(f => [f, plain(wt, f)]));
    const { texts: after, ...r } = apply(v.ops, texts, readEntries(ents), run, { maxLines: maxLinesOf(io.env) });
    const files = FILES.filter(f => after[f] !== texts[f]);
    for (const f of files) writeFileSync(join(wt, f), after[f]);
    say(JSON.stringify({ ...r, files }));
    return 0;
  }
  if (cmd === "body" && a.length === 2) { put(body(JSON.parse(read(a[0])), a[1])); return 0; }
  console.error("usage: curator.mjs validate <ops.json> | apply <ops.json> <worktree> <run> <entries.jsonl> | body <result.json> <run>");
  return 2;
});

if (isMain(import.meta.url)) runCli(main);
