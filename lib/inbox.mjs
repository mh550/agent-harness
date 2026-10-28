// INBOX.md, read one way everywhere: the "## Answers" heading outside the steering comment, the questions above it.
//
//   repair <before> <after>      → <after> with its steering comment as in <before> and what a session wrote inside it
//                                  moved above "## Answers"; exit 3 when it changed the file, 0 otherwise
//   answers <file>               → the file from its "## Answers" line on (what answers_hash hashes)
//   insert <file>                → stdin (a question) and a blank line put above the file's "## Answers"
//   question <before> <after>    → the lines a session added above "## Answers" (a missing before = empty)
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HEADING = /^## Answers[ \t\r]*$/;

// Per line: does it start inside an HTML comment? Read as GitHub renders it: a "<!--" that starts a line (up to three
// spaces in) runs to its "-->" or the end of the file; one inside a line is a comment only when a "-->" follows, and one
// in `code` is text. So a question that mentions `<!--` never hides the heading below it.
function commentStarts(lines) {
  const m = lines.map(l => l.replace(/`[^`]*`/g, x => " ".repeat(x.length))).join("\n"), ranges = [];
  for (let i = 0; ;) {
    const s = m.indexOf("<!--", i); if (s < 0) break;
    const e = m.indexOf("-->", s + 4), block = /^ {0,3}$/.test(m.slice(m.lastIndexOf("\n", s - 1) + 1, s));
    if (e >= 0) { ranges.push([s, e + 3]); i = e + 3; }
    else if (block) { ranges.push([s, m.length + 1]); break; }
    else i = s + 4;
  }
  let o = 0;
  return lines.map(l => { const at = o; o += l.length + 1; return ranges.some(([s, e]) => s < at && at < e); });
}

// The 0-based index of the heading Michael answers under, -1 if none. A session that split the comment's text left
// `## Answers".` inside it (n8n-home 2026-10-27): that line is hidden on GitHub and is never the heading.
export function answersLine(text) {
  const lines = (text ?? "").split("\n"), inside = commentStarts(lines);
  return lines.findIndex((l, i) => !inside[i] && HEADING.test(l));
}

const above = t => { const l = (t ?? "").split("\n"), i = answersLine(t); return i < 0 ? l : l.slice(0, i); };
const offsetOf = (text, line) => text.split("\n").slice(0, line).reduce((n, l) => n + l.length + 1, 0);

// Line indexes of headings ("## ", "### ") outside ``` fences: a "# " comment in a code block is part of the text.
function headings(lines) {
  let fence = false;
  return lines.map((l, i) => { if (/^\s*```/.test(l)) fence = !fence; return !fence && /^#{2,3} /.test(l) ? i : -1; }).filter(i => i >= 0);
}

// What `question` cuts out of INBOX.md, as line indexes of the text: [first, end), or null.
function questionSpan(text, feature) {
  const all = (text ?? "").split("\n"), cut = answersLine(text);
  let idx = all.map((_, i) => i).slice(0, cut < 0 ? all.length : cut);
  if (/^status:/.test(all[0] ?? "")) idx = idx.slice(1);
  // comments go before the section search; a line keeps its index (a line that held one keeps what is outside it)
  const kept = [], src = idx.map(i => all[i]).join("\n").replace(/<!--[\s\S]*?-->/g, m => "\u0000".repeat(m.split("\n").length - 1));
  let k = 0;
  for (const piece of src.split("\n")) {
    const n = (piece.match(/\u0000/g) ?? []).length, at = idx[k];
    kept.push({ i: at, l: piece.replace(/\u0000/g, "") });
    k += n + 1;
  }
  let lines = kept;
  const answer = /^### \d{4}-\d\d-\d\d \d\d:\d\d \(local\)/, hs = headings(lines.map(x => x.l));
  const next = i => hs.find(h => h > i) ?? lines.length;
  lines = lines.filter((_, i) => !hs.some(h => h <= i && i < next(h) && answer.test(lines[h].l)));
  const esc = String(feature).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const after = "(?=[^A-Za-z0-9_.-]|\\.(?![A-Za-z0-9])|$)";   // "1.2" isn't "1.2.3"; "B." ends a sentence
  const names = new RegExp(`(^|[^A-Za-z0-9_.-])${esc}${after}`);
  const own = new RegExp(`^### ${esc}${after}`);   // "### B: …" beats "### A: needs B first"
  const ls = lines.map(x => x.l), hs2 = headings(ls).filter(i => ls[i].startsWith("### "));
  let at = hs2.findLast(i => own.test(ls[i])) ?? -1;   // a re-park's question is below the one already answered
  if (at < 0) at = hs2.findLast(i => names.test(ls[i].slice(4))) ?? -1;
  if (at >= 0) lines = lines.slice(at, headings(ls).find(h => h > at));
  while (lines.length && !lines[0].l.trim()) lines.shift();
  while (lines.length && !lines.at(-1).l.trim()) lines.pop();
  return lines;
}

// The part of INBOX.md that asks about <feature>: the newest "### " section headed by it (or else naming it), else
// everything the sessions wrote above "## Answers" (text under it, and the driver's "### <date> (local)" answer blocks
// when a session dropped the heading, are Michael's, never a question).
export function question(text, feature) { return questionSpan(text, feature).map(x => x.l).join("\n"); }

// The 1-based line of the question's first line in the file (the card's link), or null.
export function questionLine(text, feature) { const s = questionSpan(text, feature); return s.length ? s[0].i + 1 : null; }

// What the session asked: lines above "## Answers" that weren't there before it (below is Michael's), read after the
// repair and without comments, so a question written inside the comment is the question and the comment is not.
// A session that dropped the heading: every line of before counts as seen, so his old answers aren't "the question".
export function added(before, after) {
  after = repair(before, after).text;
  const seen = new Map(), shown = ls => ls.join("\n").replace(/<!--[\s\S]*?-->/g, "").split("\n");   // comments: never a question
  for (const l of shown(answersLine(after) < 0 ? (before ?? "").split("\n") : above(before))) seen.set(l, (seen.get(l) ?? 0) + 1);
  const out = shown(above(after)).filter(l => { const n = seen.get(l) ?? 0; if (n) seen.set(l, n - 1); return !n; });
  while (out.length && !out[0].trim()) out.shift();
  while (out.length && !out.at(-1).trim()) out.pop();
  return out.join("\n");
}

// The text from the heading on: byte for byte what `sed -n '/^## Answers/,$p'` printed when the first such line was
// the heading, so answers_hash didn't change for a run whose comment was never split.
export function answers(text) { const i = answersLine(text); return i < 0 ? "" : (text ?? "").slice(offsetOf(text, i)); }

// <q> and a blank line above the heading (at the end it would sit under the answers and change answers_hash).
export function insert(text, q) {
  const i = answersLine(text);
  if (i < 0) return `${text}\n${q}\n`;
  const at = offsetOf(text, i);
  return text.slice(0, at) + q + "\n\n" + text.slice(at);
}

// `Files: /abs/a.sh:48, /abs/b.md` lines (the harness's fill says `Files (harness, from the session): …`) → [{path, line}].
export function files(text) {
  const out = [];
  for (const m of (text ?? "").matchAll(/(?:^|\s)Files(?: \([^)]*\))?:[ \t]*(.+)$/gm))
    for (const item of m[1].split(/,\s*/)) {
      const x = /^`?(.+?)`?(?::(\d+))?`?\.?$/.exec(item.trim());
      if (x?.[1]) out.push({ path: x[1], line: x[2] ? Number(x[2]) : null });
    }
  return out;
}

// Where <before>'s steering comment <c> is in <after>: from its first line to its last (a "-->" in a question the session
// wrote inside it is not the end), else at the same place; null when the session took it away.
function locate(c, before, at, after) {
  const ls = c.split("\n"), head = ls[0];
  let s = after.indexOf(head);
  if (s < 0 && after.slice(0, at) === before.slice(0, at) && after.startsWith("<!--", at)) s = at;
  if (s < 0) return null;
  const t = ls.length > 1 ? after.indexOf(ls.at(-1), s + 4) : -1;
  if (t >= 0) return { s, e: t + ls.at(-1).length };
  const e = after.indexOf("-->", s + 4);
  return e < 0 ? null : { s, e: e + 3 };
}

// A pure insertion can sit anywhere along a repeated run (`"## ` + `Questions…## ` is also `"` + `## Questions…`): the
// place that keeps lines whole, then words whole, wins; else the greedy one (after the longest common prefix).
function place(ac, from, to) {
  const w = c => /\w/.test(c ?? ""), nl = i => i < 0 || i >= ac.length || ac[i] === "\n";
  const score = (f, t) => 2 * (nl(f - 1) || nl(f) || nl(t - 1) || nl(t)) + (!(w(ac[f - 1]) && w(ac[f])) && !(w(ac[t - 1]) && w(ac[t])));
  let best = [from, to];
  for (let f = from, t = to; f > 0 && ac[f - 1] === ac[t - 1];) { f--; t--; if (score(f, t) > score(...best)) best = [f, t]; }
  return best;
}

// The runs of <ac> outside its longest common subsequence with <bc>: what a session inserted between edits of its own.
function insertedRuns(bc, ac) {
  const n = bc.length, m = ac.length;
  if (n * m > 4e6) return [ac];   // no comment is this long; a session that wrote a book in it gets it all moved
  const L = new Uint32Array((n + 1) * (m + 1)), at = (i, j) => i * (m + 1) + j;
  for (let i = n - 1; i >= 0; i--)
    for (let j = m - 1; j >= 0; j--) L[at(i, j)] = bc[i] === ac[j] ? L[at(i + 1, j + 1)] + 1 : Math.max(L[at(i + 1, j)], L[at(i, j + 1)]);
  const runs = [];
  let i = 0, j = 0, cur = "";
  while (j < m) {
    if (i < n && bc[i] === ac[j]) { if (cur) runs.push(cur); cur = ""; i++; j++; }
    else if (i < n && L[at(i + 1, j)] >= L[at(i, j + 1)]) i++;
    else cur += ac[j++];
  }
  if (cur) runs.push(cur);
  return runs;
}

// The steering comment as <before> had it; what a session wrote inside it goes above "## Answers". A comment the session
// only reworded, or took away, is left as it is: nothing in it is a question.
export function repair(before, after) {
  before ??= ""; after ??= "";
  const none = { text: after, changed: false, moved: "" };
  const s0 = before.indexOf("<!--"), e0 = s0 < 0 ? -1 : before.indexOf("-->", s0 + 4);
  if (e0 < 0) return none;
  const bc = before.slice(s0, e0 + 3), a = locate(bc, before, s0, after);
  if (!a) return none;
  const ac = after.slice(a.s, a.e);
  if (bc === ac) return none;
  let p = 0;
  while (p < bc.length && p < ac.length && bc[p] === ac[p]) p++;
  let s = 0;
  while (s < bc.length - p && s < ac.length - p && bc[bc.length - 1 - s] === ac[ac.length - 1 - s]) s++;
  let moved;
  if (p + s === bc.length) { const [f, t] = place(ac, p, ac.length - s); moved = ac.slice(f, t).trim(); }
  else moved = insertedRuns(bc, ac).map(r => r.trim()).filter(r => r.replace(/\s/g, "").length >= 12).join("\n\n");
  if (!moved) return none;
  const text = insert(after.slice(0, a.s) + bc + after.slice(a.e), moved);
  return { text, changed: text !== after, moved };
}

function main([cmd, ...args]) {
  const read = f => existsSync(f) ? readFileSync(f, "utf8") : "";
  switch (cmd) {
    case "repair": {
      const r = repair(read(args[0]), readFileSync(args[1], "utf8"));
      if (!r.changed) return 0;
      writeFileSync(args[1], r.text);
      return 3;
    }
    case "answers":
      process.stdout.write(answers(read(args[0])));
      return 0;
    case "insert": {
      const q = readFileSync(0, "utf8").replace(/\n+$/, "");
      if (q) writeFileSync(args[0], insert(read(args[0]), q));
      return 0;
    }
    case "question": {
      const q = added(read(args[0]), readFileSync(args[1], "utf8"));
      if (q) console.log(q);
      return 0;
    }
    default:
      console.error("usage: inbox.mjs repair|answers|insert|question …");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
