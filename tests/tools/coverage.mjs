// The suite's coverage map (docs/specs/2026-11-03-slim-suite.md S1-01): which lines of lib/ and bin/ each check file runs.
// Two sources, both built in: bash's `set -x` traces (HARNESS_XTRACE, lib/xtrace.sh: `+<source file>:<line>: <command>`)
// and node's own coverage (NODE_V8_COVERAGE: one JSON per process, byte ranges with counts). tests/tools/coverage.sh
// runs the suite with both on (TEST_XTRACE_DIR) and calls this per check file.
//   node tests/tools/coverage.mjs reduce <raw dir>          → one check file's set (<raw dir>/*.xtrace, <raw dir>/v8/*.json)
//   node tests/tools/coverage.mjs tables <sets dir>         → the five tables, markdown
//   node tests/tools/coverage.mjs counts <sets dir>         → `<file>:<line> <check files that cover it>` per covered line
//   node tests/tools/coverage.mjs union <sets dir>          → every set's union, as a set
//   node tests/tools/coverage.mjs missing <set a> <set b>   → the lines of a not in b, as a set; exit 1 when there are any
//   node tests/tools/coverage.mjs covering <sets dir> <file> <line>   → the check files whose set holds that line
// A set is text, one line per source file: `lib/record.sh 12-40,44,51-80`; `~lib/summary.mjs 17,23` beside it names the
// covered .mjs lines only part of which ran (a branch on the line that never did). <sets dir>/<check file>.txt is a
// check file's set; unit-<name>.txt is one tests/unit file's, run alone (a row of its own, never counted as a check file;
// unit-tier.txt is the unit tier's own check file's, a check file's set like any other).
// What a set can't say is in findings-and-research/2026-11-03-suite-coverage.md (*What the map can't see*).
import { closeSync, existsSync, openSync, readFileSync, readSync, readdirSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const SH = /^(lib\/[^/]+\.sh|bin\/harness)$/, MJS = /^lib\/[^/]+\.mjs$/;

// ---- sets ----
// sorted whole numbers → "1-3,5"; and back
export const ranges = nums => {
  const a = [...new Set(nums)].sort((x, y) => x - y), out = [];
  for (let i = 0; i < a.length; i++) { let j = i; while (j + 1 < a.length && a[j + 1] === a[j] + 1) j++; out.push(j > i ? `${a[i]}-${a[j]}` : `${a[i]}`); i = j; }
  return out.join(",");
};
export const unranges = s => s.split(",").filter(Boolean).flatMap(p => {
  const [a, b = a] = p.split("-").map(Number); return Array.from({ length: b - a + 1 }, (_, i) => a + i); });
// { covered: Map<file, Set<line>>, partial: Map<file, Set<line>> } ↔ the text
export const formatSet = ({ covered, partial = new Map() }) => {
  const rows = m => [...m].filter(([, s]) => s.size).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
  return [...rows(covered).map(([f, s]) => `${f} ${ranges(s)}`), ...rows(partial).map(([f, s]) => `~${f} ${ranges(s)}`)].map(l => l + "\n").join("");
};
export const parseSet = text => {
  const covered = new Map(), partial = new Map();
  for (const l of text.split("\n")) { const i = l.indexOf(" "); if (i < 1) continue;
    const p = l[0] === "~", f = l.slice(p ? 1 : 0, i); (p ? partial : covered).set(f, new Set(unranges(l.slice(i + 1)))); }
  return { covered, partial };
};
const add = (m, f, n) => { let s = m.get(f); if (!s) m.set(f, s = new Set()); s.add(n); };

// ---- bash: the trace ----
// one trace line → [source path, line], or null (a continuation of a traced command's own text, or anything else)
const TRACE = /^\++([^\n:]+):(\d+): /;
export const tracePair = l => { const m = TRACE.exec(l); return m ? [m[1], Number(m[2])] : null; };
// a traced source path → its path in the repo (`lib/record.sh`), or null: only a file under root counts, so a throwaway
// project's config.sh, a check file's own lines and a copy of the harness elsewhere are no line of lib/
export const relOf = (p, root) => {
  if (!p.startsWith("/")) return null;
  const a = resolve(p); return a.startsWith(root + "/") ? a.slice(root.length + 1) : null;
};
// trace text (a string, or an iterable of lines) → { covered: Map<lib file, Set<line>>, outside: Map<path, lines traced> }
export const traceSet = (lines, root) => {
  const seen = new Map(), covered = new Map(), outside = new Map();
  for (const l of typeof lines === "string" ? lines.split("\n") : lines) {
    const m = TRACE.exec(l); if (!m) continue;
    let s = seen.get(m[1]); if (!s) seen.set(m[1], s = new Set()); s.add(Number(m[2]));
  }
  for (const [p, s] of seen) { const r = relOf(p, root);
    if (r !== null && SH.test(r)) for (const n of s) add(covered, r, n); else outside.set(p, s.size); }
  return { covered, outside };
};
// a trace file's lines that begin with +, each cut at 600 bytes (the prefix is all that is read; a trace is gigabytes)
export function* traceFileLines(file) {
  const fd = openSync(file, "r"), buf = Buffer.allocUnsafe(1 << 22); let rest = Buffer.alloc(0), n;
  try {
    while ((n = readSync(fd, buf, 0, buf.length)) > 0) {
      const chunk = rest.length ? Buffer.concat([rest, buf.subarray(0, n)]) : buf.subarray(0, n); let from = 0, nl;
      while ((nl = chunk.indexOf(10, from)) >= 0) { if (chunk[from] === 43) yield chunk.latin1Slice(from, Math.min(nl, from + 600)); from = nl + 1; }
      rest = Buffer.from(chunk.subarray(from));
    }
    if (rest.length && rest[0] === 43) yield rest.latin1Slice(0, 600);
  } finally { closeSync(fd); }
}

// ---- node: V8's ranges ----
// one script's functions (V8's block coverage: nested ranges, each with a count) → a byte per character of the source,
// 1 where the innermost range around it ran. Outer ranges are painted first, so an inner one overrides
export const paint = (length, functions) => {
  const rs = functions.flatMap(f => f.ranges).sort((a, b) => a.startOffset - b.startOffset || b.endOffset - a.endOffset);
  const c = new Uint8Array(length);
  for (const r of rs) c.fill(r.count > 0 ? 1 : 0, r.startOffset, Math.min(r.endOffset, length));
  return c;
};
// a source and its painted characters → { covered: [line…], partial: [line…] }: a line is covered when code of it
// ran, partial when other code of it did not. Code is every character but white space, the punctuation `;,(){}[]`
// (the `;` after a function's body lies in the range around the function, and ran with it whether or not the body
// did), and the declaration in front of a function never called (dead: where each such function starts): `export `,
// `const f = `, `name: `, which the module's load "ran". A callback's call (`xs.map(` before `x => …`) is code.
const PUNCT = new Set(" \t\r;,(){}[]");
const DECL = /^(export\s+)?(default\s+)?(static\s+)?((const|let|var)\s+[\w$]+\s*=\s*|[\w$.]+\s*[:=]\s*)?(async\s*)?$/;
export const lineStates = (src, cov, dead = []) => {
  const quiet = new Uint8Array(src.length);
  for (const s of dead) {
    let a = src.lastIndexOf("\n", s - 1) + 1; for (let i = a; i < s; i++) if (",;{}(".includes(src[i])) a = i + 1;   // the declaration: from the last `, ; { } (` before it
    while (a < s && (src[a] === " " || src[a] === "\t")) a++;
    if (DECL.test(src.slice(a, s))) quiet.fill(1, a, s);
  }
  const covered = [], partial = []; let line = 1, ran = false, not = false;
  for (let i = 0; i <= src.length; i++) {
    const ch = src[i];
    if (i === src.length || ch === "\n") { if (ran) { covered.push(line); if (not) partial.push(line); } line++; ran = not = false; continue; }
    if (PUNCT.has(ch) || quiet[i]) continue;
    if (cov[i]) ran = true; else not = true;
  }
  return { covered, partial };
};
// V8 coverage documents (parsed) → Map<lib file, { src, cov: a byte per character, 1 when it ran in any process,
// starts: where each function starts }>
export const v8Paint = (docs, root, read) => {
  const chars = new Map();
  for (const d of docs) for (const r of d.result ?? []) {
    if (!r.url?.startsWith("file://")) continue;
    const rel = relOf(fileURLToPath(r.url), root); if (rel === null || !MJS.test(rel)) continue;
    let e = chars.get(rel); if (!e) { const src = read(rel); chars.set(rel, e = { src, cov: new Uint8Array(src.length), starts: new Set() }); }
    const c = paint(e.src.length, r.functions); for (let i = 0; i < c.length; i++) if (c[i]) e.cov[i] = 1;
    for (const f of r.functions) if (f.ranges[0] && f.ranges[0].startOffset > 0) e.starts.add(f.ranges[0].startOffset);
  }
  return chars;
};
// the painted characters as a set: the lines that hold code (mjsExecutable; a comment inside a function that ran "ran"
// too), a function that ran in no process counted dead
export const v8Set = chars => {
  const covered = new Map(), partial = new Map();
  for (const [f, { src, cov, starts }] of chars) { const s = lineStates(src, cov, [...starts].filter(i => !cov[i])), can = mjsExecutable(src);
    const c = s.covered.filter(n => can.has(n)), p = s.partial.filter(n => can.has(n));
    if (c.length) covered.set(f, new Set(c)); if (p.length) partial.set(f, new Set(p)); }
  return { covered, partial };
};

// ---- which lines can run at all ----
// bash: the lines that hold a command `set -x` can print. Not: a blank or comment line; a line that is only closing
// or opening words (fi, done, esac, then, else, do, {, }, ;;, a bare case pattern, a function's `name() {`); a closing
// word with a redirection (`done < <(cmd)`: bash numbers cmd at its function's header, so the loop's own line stands
// for it). A guess at bash's grammar from quotes, parentheses and backslashes, not a parser: the findings file says
// what it misses.
// A statement that spans lines (a `\` continuation, a quoted string, a `$( … )`, an array's `=( … )`, a `[[ … ]]` or a
// here-document left open at the line's end) is one group: bash numbers its commands at the first line, the last, or
// one past (5.2, tried), so the group's first line stands for it, and a later line counts by itself only when a `\`
// continuation starts a new command there (&&, ||, |).
//   shScan(text) → { can: Set<line>, first: first[n] = the first line of the statement line n is in }
// Each test reads the line's outline: its text with every quoted string and every `$( )`, `<( )`, `=( )` cut down to
// one Q, so what is inside them can't look like a closing word, a pattern or a `;`. A line ending in `)` is a case
// pattern only inside case … esac (outside one it closes a subshell and holds its last command); a closing word is
// alone on its line only when nothing but redirections follows it (`done < Q; out=Q` holds a command).
const STRUCT = /^((fi|done|esac|then|else|do|\{|\}|;;|\))\s*;?\s*)+&?$/;
const noCommand = (o, inCase) => STRUCT.test(o) || /^[A-Za-z_][A-Za-z0-9_:.-]*\(\)\s*\{?$/.test(o)
  || /^(done|fi|esac|\})(\s*[0-9&]?[<>]{1,3}&?[0-9-]?\s*[^\s;|&<>]*)+(\s*;\s*(fi|done|esac|\}))*\s*;?$/.test(o)
  || (inCase && /^\(?[^()\s][^()]*\)(\s*;;)?$/.test(o) && !/^([A-Za-z_][A-Za-z0-9_]*\+?=|case\s)/.test(o));
export const shScan = text => {
  // open: what is open at this point, innermost last: ' " $' (an ANSI string) or ( (a `$(`, `<(`, `>(` or `=(`, and any ( inside one)
  const lines = text.split("\n"), can = new Set(), first = new Int32Array(lines.length + 2), open = [];
  let here = null, cont = false, cond = false, head = 0, cases = 0;
  for (let n = 0; n < lines.length; n++) {
    const raw = lines[n], wasCont = cont;
    if (here === null && !open.length && !cont && !cond) head = n + 1;
    first[n + 1] = head;
    if (here !== null) { if ((here.strip ? raw.replace(/^\t+/, "") : raw) === here.word) here = null; continue; }
    let code = "", outline = "", hd = null, comment = false;
    for (let i = 0; i < raw.length; i++) {
      const ch = raw[i], top = open.at(-1), was = open.length;
      if (top === "'") { if (ch === "'") open.pop(); code += ch; continue; }
      if (ch === "\\") { code += ch + (raw[i + 1] ?? ""); if (!was) outline += ch + (raw[i + 1] ?? ""); i++; continue; }
      if (top === "$'") { if (ch === "'") open.pop(); code += ch; continue; }
      if (top === '"') {
        if (ch === '"') open.pop(); else if (ch === "$" && raw[i + 1] === "(") { open.push("("); code += ch; i++; }
        code += raw[i]; continue;
      }
      // code: the top level, or inside ( )
      if (ch === "'" || ch === '"') { open.push(ch === "'" && raw[i - 1] === "$" ? "$'" : ch); code += ch; if (!was) outline += "Q"; continue; }
      if (ch === "#" && (i === 0 || /[\s;(&|]/.test(raw[i - 1]))) { comment = true; break; }   // a comment to the line's end
      if ((ch === "$" || ch === "<" || ch === ">" || ch === "=") && raw[i + 1] === "(") {
        open.push("("); code += ch + "("; if (!was) outline += ch === "=" ? "=Q" : "Q"; i++; continue; }
      if (ch === "(" && top === "(") open.push("(");
      if (ch === ")" && top === "(") open.pop();
      if (!open.length && ch === "<" && raw[i + 1] === "<" && raw[i + 2] !== "<" && raw[i - 1] !== "<") {
        const m = /^<<(-?)\s*(['"]?)([A-Za-z_][A-Za-z0-9_]*)\2/.exec(raw.slice(i)); if (m) hd = { strip: m[1] === "-", word: m[3] };
      }
      code += ch; if (!was) outline += ch;
    }
    const t = code.trim(), o = outline.trim(), inCase = cases > 0;
    cont = !comment && !open.length && /(^|[^\\])(\\\\)*\\$/.test(raw);
    if (cond) { if (code.includes("]]")) cond = false; } else if (code.lastIndexOf("[[ ") > code.lastIndexOf("]]")) cond = true;
    if (/(^|[\s;({|&])case\s.*\sin(\s|;|$)/.test(o)) cases++;
    cases = Math.max(0, cases - (o.match(/(^|[\s;])esac(?=$|[\s;)}])/g) ?? []).length);
    if (hd && !open.length) here = hd;
    if (t === "" || t === "\\") continue;
    if (head === n + 1 ? !noCommand(o, inCase) : wasCont && /^(&&|\|\||\|)/.test(t)) can.add(n + 1);
  }
  return { can, first };
};
export const shExecutable = text => shScan(text).can;
// the lines a script runs before its trace starts, its `set -…o pipefail` line to the guard that sources lib/xtrace.sh:
// no trace can name them, so no table lists them as never run. None in a file without the guard
export const beforeTrace = text => {
  const l = text.split("\n"), g = l.findIndex(x => /\$\{HARNESS_XTRACE:-\} \]\] \|\| source /.test(x)); if (g < 0) return new Set();
  let s = g; while (s >= 0 && !/^\s*set -[a-z]*o pipefail/.test(l[s])) s--;
  if (s < 0) s = g;
  return new Set(Array.from({ length: g - s + 1 }, (_, i) => s + i + 1));
};
// the line numbers a trace named → the lines that hold the commands: a line inside a multi-line statement counts for
// the statement's first line (and for itself where it starts a command). A number on a line with no command is
// dropped, never given to a neighbour: bash numbers a trap's commands from line 1 and the commands of a `<( )` that
// feeds a loop at the function's header or the outer loop's `done` (5.2, tried), and the line that really ran is
// traced by its own command. → { lines: Set, dropped: how many numbers found no command }
export const shAttribute = (text, traced) => {
  const { can, first } = shScan(text), lines = new Set(); let dropped = 0;
  for (const l of traced) {
    const h = l > 0 && l < first.length ? first[l] : 0, here = can.has(l), head = h && h !== l && can.has(h);
    if (here) lines.add(l);
    if (head) lines.add(h);
    if (!here && !head) dropped++;
  }
  return { lines, dropped };
};
// node: a line with code on it (not blank, not a comment, not only punctuation or a bare else, try, finally or do)
export const mjsExecutable = text => {
  const out = new Set(); let block = false;
  text.split("\n").forEach((raw, n) => {
    let t = raw.trim();
    if (block) { const e = t.indexOf("*/"); if (e < 0) return; block = false; t = t.slice(e + 2).trim(); }
    if (t.startsWith("/*")) { if (!t.includes("*/")) block = true; return; }
    if (t === "" || t.startsWith("//") || /^[\s{}()[\];,]*((else|try|finally|do)[\s{]*)?$/.test(t)) return;
    out.add(n + 1);
  });
  return out;
};
// bash: the function each line is in (`name() {` at the line's start to the next `}` at a line's start), "" outside one
export const shFunctions = text => {
  const at = [""]; let cur = "";
  for (const raw of text.split("\n")) {
    const m = /^([A-Za-z_][A-Za-z0-9_:.-]*)\(\)\s*\{/.exec(raw);
    if (m) { at.push(m[1]); cur = /\}\s*(#.*)?$/.test(raw) && !/\{\s*(#.*)?$/.test(raw) ? "" : m[1]; continue; }
    at.push(cur); if (/^\}/.test(raw)) cur = "";
  }
  return at;
};

// ---- the tables ----
// sets: Map<name, { covered }> of the check files (unit-* rows are told apart by the caller) → Map<"file:line", [names…]>
export const lineCounts = sets => {
  const by = new Map();
  for (const [name, { covered }] of sets) for (const [f, s] of covered) for (const n of s) { const k = `${f}:${n}`; let a = by.get(k); if (!a) by.set(k, a = []); a.push(name); }
  return by;
};
const keysOf = ({ covered }) => { const k = new Set(); for (const [f, s] of covered) for (const n of s) k.add(`${f}:${n}`); return k; };
// each check file whose covered lines all lie in another's: [{ name, size, inside: [the supersets, smallest first] }], a
// file that covers nothing left out; two files with one set name each other
export const subsets = sets => {
  const ks = [...sets].map(([name, s]) => ({ name, keys: keysOf(s) })).filter(e => e.keys.size), out = [];
  for (const a of ks) {
    const inside = ks.filter(b => b !== a && b.keys.size >= a.keys.size && [...a.keys].every(k => b.keys.has(k)))
      .sort((x, y) => x.keys.size - y.keys.size || (x.name < y.name ? -1 : 1)).map(b => b.name);
    if (inside.length) out.push({ name: a.name, size: a.keys.size, inside });
  }
  return out.sort((x, y) => x.size - y.size || (x.name < y.name ? -1 : 1));
};
export const unionOf = list => {
  const covered = new Map();
  for (const { covered: c } of list) for (const [f, s] of c) for (const n of s) add(covered, f, n);
  return { covered };
};
export const missingFrom = (a, b) => {
  const covered = new Map();
  for (const [f, s] of a.covered) for (const n of s) if (!b.covered.get(f)?.has(n)) add(covered, f, n);
  return { covered };
};

// ---- the commands ----
// the unit tier's own check file is a check file, whatever its prefix says (00-unit-tier until the shape took the numbers off)
const UNIT_TIER = "unit-tier";
const readSets = dir => {
  const checks = new Map(), units = new Map();
  for (const f of readdirSync(dir).filter(f => f.endsWith(".txt") && !f.startsWith("_")).sort()) {
    const name = basename(f, ".txt"); (name.startsWith("unit-") && name !== UNIT_TIER ? units : checks).set(name, parseSet(readFileSync(join(dir, f), "utf8")));
  }
  return { checks, units };
};
const sources = root => [...readdirSync(join(root, "lib")).filter(f => /\.(sh|mjs)$/.test(f)).map(f => `lib/${f}`), "bin/harness"].sort();
const size = s => [...s.covered.values()].reduce((n, x) => n + x.size, 0);
const sizeOf = (s, re) => [...s.covered].reduce((n, [f, x]) => n + (re.test(f) ? x.size : 0), 0);
const tierOf = (root, name) => { try { return readFileSync(join(root, "tests/checks", `${name}.sh`), "utf8").split("\n")[1].replace("# tier: ", ""); } catch { return "–"; } };

function reduce(raw, root) {
  const files = existsSync(raw) ? readdirSync(raw).filter(f => f.endsWith(".xtrace")) : [];
  const lines = function* () { for (const f of files) yield* traceFileLines(join(raw, f)); };
  const sh = traceSet(lines(), root); let dropped = 0;
  for (const [f, s] of sh.covered) { const a = shAttribute(readFileSync(join(root, f), "utf8"), s); sh.covered.set(f, a.lines); dropped += a.dropped; }
  if (dropped) process.stderr.write(`coverage: ${basename(raw)}: ${dropped} traced line numbers name no command (bash's numbering), dropped\n`);
  const v8 = join(raw, "v8"), docs = function* () {
    for (const f of existsSync(v8) ? readdirSync(v8).filter(f => f.endsWith(".json")) : []) {
      try { yield JSON.parse(readFileSync(join(v8, f), "utf8")); } catch { process.stderr.write(`coverage: unreadable ${join(v8, f)}\n`); }
    }
  };
  const js = v8Set(v8Paint(docs(), root, rel => readFileSync(join(root, rel), "utf8")));
  const out = [...sh.outside].filter(([p]) => /\/(lib\/[^/]+\.sh|bin\/harness)$/.test(p));
  if (out.length) process.stderr.write(`coverage: ${basename(raw)}: harness files traced outside ${root}, not counted: ${out.map(([p, n]) => `${p} (${n} lines)`).join(", ")}\n`);
  return formatSet({ covered: new Map([...sh.covered, ...js.covered]), partial: js.partial });
}

function tables(dir, root) {
  const { checks, units } = readSets(dir), by = lineCounts(checks), out = [], p = l => out.push(l);
  const union = unionOf([...checks.values()]), uunion = unionOf([...units.values()]);
  const srcs = sources(root), text = Object.fromEntries(srcs.map(f => [f, readFileSync(join(root, f), "utf8")]));
  const can = Object.fromEntries(srcs.map(f => [f, f.endsWith(".mjs") ? mjsExecutable(text[f]) : shExecutable(text[f])]));
  // no trace can name the hook's own lines or what a script runs before it: in no table
  let untraceable = 0;
  for (const f of srcs) { if (f.endsWith(".mjs")) continue;
    for (const n of f === "lib/xtrace.sh" ? [...can[f]] : beforeTrace(text[f])) if (can[f].delete(n)) untraceable++; }
  const coveredIn = f => new Set([...(union.covered.get(f) ?? [])].filter(n => can[f].has(n)));
  const alone = new Map(); for (const [, names] of by) if (names.length === 1) alone.set(names[0], (alone.get(names[0]) ?? 0) + 1);

  p("### Table 1 · per check file: the lines of `lib/` and `bin/` it runs"); p("");
  p("| check file | tier | bash lines | node lines | all | only this file |"); p("|---|---|---:|---:|---:|---:|");
  for (const [name, s] of [...checks].sort(([, a], [, b]) => size(b) - size(a)))
    p(`| \`${name}\` | ${tierOf(root, name)} | ${sizeOf(s, SH)} | ${sizeOf(s, MJS)} | ${size(s)} | ${alone.get(name) ?? 0} |`);
  p(`| **the union of all ${checks.size}** | | **${sizeOf(union, SH)}** | **${sizeOf(union, MJS)}** | **${size(union)}** | |`);
  p(""); p("The unit tier's files, each run alone (rows of `unit-tier` above, split):"); p("");
  p("| unit test file | node lines | lines no stub-run or CLI check file runs |"); p("|---|---:|---:|");
  const nonUnit = unionOf([...checks].filter(([n]) => n !== UNIT_TIER && !n.startsWith("00-unit")).map(([, s]) => s));
  for (const [name, s] of units) p(`| \`${name.replace(/^unit-/, "")}\` | ${size(s)} | ${size(missingFrom(s, nonUnit))} |`);
  p(`| **the union of all ${units.size}** | **${size(uunion)}** | **${size(missingFrom(uunion, nonUnit))}** |`);

  p(""); p("### Table 2 · per source file: how many check files run each line"); p("");
  p("| source file | lines that can run | run by a check file | by 1 | by 2–4 | by 5–19 | by 20 or more | by none |"); p("|---|---:|---:|---:|---:|---:|---:|---:|");
  const tot = [0, 0, 0, 0, 0, 0, 0];
  for (const f of srcs) {
    const cov = coveredIn(f), b = [0, 0, 0, 0];
    for (const n of cov) { const k = by.get(`${f}:${n}`).length; b[k === 1 ? 0 : k < 5 ? 1 : k < 20 ? 2 : 3]++; }
    const row = [can[f].size, cov.size, ...b, can[f].size - cov.size]; row.forEach((v, i) => tot[i] += v);
    p(`| \`${f}\` | ${row.join(" | ")} |`);
  }
  p(`| **all** | ${tot.map(v => `**${v}**`).join(" | ")} |`);

  p(""); p("### Table 3 · check files whose lines all lie inside another's (candidates to merge)"); p("");
  const sub = subsets(checks);
  if (!sub.length) p("None."); else { p("| check file | its lines | inside (smallest first) |"); p("|---|---:|---|");
    for (const s of sub) p(`| \`${s.name}\` | ${s.size} | ${s.inside.slice(0, 6).map(n => `\`${n}\``).join(", ")}${s.inside.length > 6 ? `, and ${s.inside.length - 6} more` : ""} |`); }

  p(""); p("### Table 4 · lines run by 20 or more check files (every scenario pays them)"); p("");
  p("| source file | lines | which |"); p("|---|---:|---|");
  let hot = 0;
  for (const f of srcs) { const ns = [...coveredIn(f)].filter(n => by.get(`${f}:${n}`).length >= 20); if (!ns.length) continue; hot += ns.length; p(`| \`${f}\` | ${ns.length} | ${ranges(ns)} |`); }
  p(`| **all** | **${hot}** | |`);

  p(""); p("### Table 5 · lines no check file runs (dead, or untested)"); p("");
  p("| source file | lines | which (bash: by function) |"); p("|---|---:|---|");
  let none = 0;
  for (const f of srcs) {
    const cov = coveredIn(f), ns = [...can[f]].filter(n => !cov.has(n)).sort((a, b) => a - b); if (!ns.length) continue; none += ns.length;
    let which = ranges(ns);
    if (!f.endsWith(".mjs")) { const fn = shFunctions(text[f]), g = new Map(); for (const n of ns) { const k = fn[n] || "(top level)"; g.set(k, [...(g.get(k) ?? []), n]); }
      which = [...g].map(([k, v]) => `${k}: ${ranges(v)}`).join(" · "); }
    p(`| \`${f}\` | ${ns.length} | ${which} |`);
  }
  p(`| **all** | **${none}** | |`);
  p(""); p(`In no table: ${untraceable} lines no trace can name (what each script runs before its trace starts, its option line to its guard, and \`lib/xtrace.sh\` itself).`);
  return out.join("\n") + "\n";
}

export async function main(argv, root = ROOT) {
  const [cmd, a, b, c] = argv;
  if (cmd === "reduce" && a) return { out: reduce(resolve(a), root) };
  if (cmd === "tables" && a) return { out: tables(a, root) };
  if (cmd === "counts" && a) { const by = lineCounts(readSets(a).checks);
    return { out: [...by].map(([k, v]) => `${k} ${v.length}`).sort((x, y) => { const [fx, nx] = x.split(/[: ]/), [fy, ny] = y.split(/[: ]/); return fx < fy ? -1 : fx > fy ? 1 : nx - ny; }).join("\n") + "\n" }; }
  if (cmd === "union" && a) return { out: formatSet(unionOf([...readSets(a).checks.values()])) };
  if (cmd === "missing" && a && b) { const m = missingFrom(parseSet(readFileSync(a, "utf8")), parseSet(readFileSync(b, "utf8"))); return { out: formatSet(m), rc: size(m) ? 1 : 0 }; }
  if (cmd === "covering" && a && b && c) return { out: [...readSets(a).checks].filter(([, s]) => s.covered.get(b)?.has(Number(c))).map(([n]) => n + "\n").join("") };
  return { out: "", err: "usage: coverage.mjs reduce <raw dir> | tables|counts|union <sets dir> | missing <set a> <set b> | covering <sets dir> <file> <line>\n", rc: 2 };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const r = await main(process.argv.slice(2)); if (r.err) process.stderr.write(r.err); process.stdout.write(r.out); process.exitCode = r.rc ?? 0;
}
