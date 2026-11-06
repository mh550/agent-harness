// The mutation sample (docs/specs/2026-11-03-slim-suite.md S1-02): small changes to lines of lib/ a check file runs,
// each run against the check files that run its line (tests/tools/mutants.sh). A change no check turns red on is a
// line nothing asserts on.
//   node tests/tools/mutants.mjs pick <sets dir> <seed> [<per kind>]   → the sample, one JSON object per line:
//       {id, file, line, kind, before, after, files: [the check files that run the line], partial}   (after null: the line deleted)
//       stderr: each candidate passed over and why (it no longer parses; it shares a line with one drawn earlier)
//   node tests/tools/mutants.mjs apply <sample.jsonl> <id>              → the mutant written into the tree; exit 1 when
//       the line is no longer `before` (the tree moved under the sample). `git checkout -- <file>` takes it back
//   node tests/tools/mutants.mjs table <sample.jsonl> <out dir>         → the sample as a markdown table: what each mutant
//       changed and, from <out dir>/<id>.out (tests/tools/mutants.sh), the checks that caught it or `survived`
// Four kinds (the spec's): delete the line · && ↔ || · a comparison operator (-ge ↔ -gt, <= → <, == ↔ != …) · a
// literal (true ↔ false, a whole number + 1). The pick is seeded (mulberry32): the same sets, tree and seed give the
// same sample. Only logic is changed: never a comment, never message text (quoted text in node, double-quoted text in
// bash); a deleted bash line is a whole statement, never one line of a longer one; a mutant must still parse
// (bash -n, node --check). A line that deletes, kills, pushes or posts (rm, kill, git push, curl, gh …) is in no
// sample: pick counts those it left out.
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parseSet, shScan } from "./coverage.mjs";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
export const KINDS = ["delete", "andor", "compare", "literal"];

// a seeded generator of numbers in [0, 1): mulberry32
export const rng = seed => { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a;
  t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
export const shuffle = (list, rand) => { const a = [...list]; for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rand() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };

// where a line's code ends and its trailing comment begins (bash: ` # `, node: ` // `), outside quotes; the line's length when it has none
export const codeEnd = (line, lang) => {
  let q = "";
  for (let i = 0; i < line.length; i++) { const ch = line[i];
    if (q) { if (ch === "\\" && q !== "'") i++; else if (ch === q) q = ""; continue; }
    if (ch === "\\") { i++; continue; }
    if (ch === '"' || ch === "'" || (ch === "`" && lang === "mjs")) { q = ch; continue; }
    if (lang === "sh" ? ch === "#" && (i === 0 || /\s/.test(line[i - 1])) : ch === "/" && line[i + 1] === "/" && (i === 0 || /\s/.test(line[i - 1]))) return i;
  }
  return line.length;
};
// the characters of a line's code that are message text, where a change is no change of logic: in node, inside any
// quotes; in bash, inside double quotes (a single-quoted jq or awk program is code, and so is what stands bare)
export const textMask = (line, lang) => {
  const end = codeEnd(line, lang), mask = new Uint8Array(line.length); let q = "";
  for (let i = 0; i < end; i++) { const ch = line[i];
    if (q) { if (lang === "mjs" || q === '"') mask[i] = 1; if (ch === "\\" && q !== "'") { i++; if (lang === "mjs" || q === '"') mask[i] = 1; } else if (ch === q) q = ""; continue; }
    if (ch === "\\") { i++; continue; }
    if (ch === '"' || ch === "'" || (ch === "`" && lang === "mjs")) q = ch;
  }
  return mask;
};
// every [index, length, replacement] of one kind on a line's code
const SWAPS = {
  sh: [[/ -ge /g, " -gt "], [/ -gt /g, " -ge "], [/ -le /g, " -lt "], [/ -lt /g, " -le "], [/ -eq /g, " -ne "], [/ -ne /g, " -eq "],
    [/ == /g, " != "], [/ != /g, " == "], [/ <= /g, " < "], [/ >= /g, " > "]],
  mjs: [[/ === /g, " !== "], [/ !== /g, " === "], [/ == /g, " != "], [/ != /g, " == "], [/ <= /g, " < "], [/ >= /g, " > "], [/ < /g, " <= "], [/ > /g, " >= "]],
};
const NUM = /(?<![\w$.{&\-#:/@%+*<>\\]|\d)\d+(?![\w.><:}%#])/g;
export const edits = (line, kind, lang) => {
  const code = line.slice(0, codeEnd(line, lang)), text = textMask(line, lang), out = [];
  const all = (re, to) => { for (const m of code.matchAll(re)) if (!text.subarray(m.index, m.index + m[0].length).includes(1)) out.push([m.index, m[0].length, typeof to === "function" ? to(m[0]) : to]); };
  if (kind === "andor") { all(/&&(?!=)/g, "||"); all(/\|\|(?!=)/g, "&&"); }
  if (kind === "compare") for (const [re, to] of SWAPS[lang]) all(re, to);
  if (kind === "literal") { all(/\btrue\b/g, "false"); all(/\bfalse\b/g, "true"); all(NUM, d => String(Number(d) + 1)); }
  return out.sort((a, b) => a[0] - b[0]);
};
// one mutant of a line: the changed line, null for a deleted one, undefined when the kind has nothing to change on it
export const mutate = (line, kind, lang, rand) => {
  if (kind === "delete") return line.slice(0, codeEnd(line, lang)).trim() ? null : undefined;
  const e = edits(line, kind, lang); if (!e.length) return undefined;
  const [i, n, to] = e[Math.floor(rand() * e.length)]; return line.slice(0, i) + to + line.slice(i + n);
};
export const applyTo = (text, line, after) => { const l = text.split("\n"); if (after === null) l.splice(line - 1, 1); else l[line - 1] = after; return l.join("\n"); };

// a line the sample leaves alone: it deletes, kills, pushes or posts, and a mutant of it would be a harness doing
// one of those in a way nobody has read (the suite's throwaway directories and stubs bound the harm; this bounds it more)
const RISKY = /(^|[\s;&|(])(rm|rmdir|kill|pkill|curl)\s|\bgit\b.*\s(push|prune|gc|clean|reset --hard|worktree remove|branch -D|update-ref -d)\b|\$\{?(HARNESS_)?(CURL|GH)\b|\b(rmSync|unlinkSync|rmdirSync)\(|"(push|prune)"/;
export const risky = line => RISKY.test(line);

// the sample: perKind mutants of each kind, drawn in a seeded order from the lines a check file runs (lines: [{file,
// line, text, files, partial}], sorted), one per line at most; valid(file, mutated text) says whether it still parses
export const pick = (lines, seed, perKind, valid, texts) => {
  const out = [], passed = [], used = new Set();
  KINDS.forEach((kind, k) => {
    const rand = rng(seed + k); let n = 0;
    for (const c of shuffle(lines, rand)) {
      if (n >= perKind) break;
      const lang = c.file.endsWith(".mjs") ? "mjs" : "sh", after = mutate(c.text, kind, lang, rand), key = `${c.file}:${c.line}`;
      if (after === undefined || (kind === "delete" && c.whole === false)) continue;   // a part of a longer statement is not deleted alone
      if (used.has(key)) { passed.push({ ...c, kind, why: "its line already has a mutant" }); continue; }
      if (!valid(c.file, applyTo(texts[c.file], c.line, after))) { passed.push({ ...c, kind, after, why: "no longer parses" }); continue; }
      used.add(key); n++;
      out.push({ id: `${kind}-${String(n).padStart(2, "0")}`, file: c.file, line: c.line, kind, before: c.text, after, files: c.files, partial: c.partial });
    }
  });
  return { sample: out, passed };
};

// ---- the table ----
// what a mutant changed, as the token it changed: `-ge` → `-gt`; a deleted line says so
export const change = (before, after) => {
  if (after === null) return "the line deleted";
  let a = 0; while (a < before.length && a < after.length && before[a] === after[a]) a++;
  let b = 0; while (b < before.length - a && b < after.length - a && before[before.length - 1 - b] === after[after.length - 1 - b]) b++;
  // widen to the whole token: a word (-ge, true, 10) or a run of symbols (===, &&)
  const word = /[\w-]/.test(before.slice(a, before.length - b) + after.slice(a, after.length - b)), in_ = ch => ch !== undefined && (word ? /[\w-]/ : /[^\s\w]/).test(ch);
  while (a > 0 && in_(before[a - 1])) a--;
  while (b > 0 && in_(before[before.length - b])) b--;
  return `\`${before.slice(a, before.length - b)}\` → \`${after.slice(a, after.length - b)}\``;
};
// a tests/run.sh output → the checks that went red (conformance aside) and the check files they are in: a file's
// FAIL lines come before its `<file>: <n> checks, <s> s` line; a file stopped or cut short is named in its own FAIL line
export const caughtBy = out => {
  const names = [], files = []; let pending = 0;
  for (const l of out.split("\n")) {
    const t = /^([0-9A-Za-z_.-]+): \d+ checks, [\d.]+ s$/.exec(l);
    if (t) { if (pending && !files.includes(t[1])) files.push(t[1]); pending = 0; continue; }
    if (!l.startsWith("FAIL ") || l.startsWith("FAIL conformance: ")) continue;
    names.push(l.slice(5)); const own = /^FAIL ([0-9A-Za-z_.-]+): (still running after|exited \d+ before its end|killed before its end)/.exec(l);
    if (!own) pending++; else if (!files.includes(own[1])) files.push(own[1]);
  }
  return { names, files };
};
// the sample and each mutant's suite output (Map id → text; a mutant without one was not run) → the table's rows
export const tableRows = (sample, outputs) => sample.map(m => {
  const out = outputs.get(m.id), c = out === undefined ? null : caughtBy(out);
  const result = c === null ? "not run" : !c.names.length ? "**survived**"
    : `caught by ${c.names.length} check${c.names.length > 1 ? "s" : ""} in ${c.files.length} file${c.files.length > 1 ? "s" : ""}: ${c.names.slice(0, 3).map(n => `\`${n.replaceAll("|", "\\|").replaceAll("`", "'")}\``).join(", ")}${c.names.length > 3 ? `, and ${c.names.length - 3} more` : ""}`;
  return `| \`${m.id}\` | \`${m.file}:${m.line}\`${m.partial ? " (run in part)" : ""} | ${change(m.before, m.after)} | ${m.files.length} | ${result} |`;
});

const parses = (file, text) => {
  const d = mkdtempSync(join(tmpdir(), "mutant-")), f = join(d, basename(file));
  try { writeFileSync(f, text); return spawnSync(file.endsWith(".mjs") ? "node" : "bash", [file.endsWith(".mjs") ? "--check" : "-n", f], { stdio: "ignore" }).status === 0; }
  finally { rmSync(d, { recursive: true, force: true }); }
};

export async function main(argv, root = ROOT) {
  const [cmd, a, b, c] = argv;
  if (cmd === "pick" && a && /^\d+$/.test(b ?? "")) {
    const sets = readdirSync(a).filter(f => f.endsWith(".txt") && !f.startsWith("_") && !f.startsWith("unit-")).sort()
      .map(f => [basename(f, ".txt"), parseSet(readFileSync(join(a, f), "utf8"))]);
    const by = new Map(), part = new Map();
    for (const [name, s] of sets) {
      for (const [f, ls] of s.covered) for (const n of ls) { const k = `${f}:${n}`; by.set(k, [...(by.get(k) ?? []), name]); }
      for (const [f, ls] of s.partial) for (const n of ls) part.set(`${f}:${n}`, true);
    }
    const texts = {}, lines = []; let left = 0;
    for (const f of readdirSync(join(root, "lib")).filter(f => /\.(sh|mjs)$/.test(f)).sort().map(f => `lib/${f}`)) {
      texts[f] = readFileSync(join(root, f), "utf8");
      const first = f.endsWith(".sh") ? shScan(texts[f]).first : null;   // bash: a line is whole when its statement is that line alone
      texts[f].split("\n").forEach((text, i) => { const files = by.get(`${f}:${i + 1}`);
        if (!files) return; if (risky(text)) { left++; return; }
        lines.push({ file: f, line: i + 1, text, files, partial: part.has(`${f}:${i + 1}`), whole: !first || (first[i + 1] === i + 1 && first[i + 2] !== i + 1) }); });
    }
    const { sample, passed } = pick(lines, Number(b), Number(c ?? 10), parses, texts);
    return { out: sample.map(m => JSON.stringify(m) + "\n").join(""), err: passed.map(p => `passed over: ${p.kind} ${p.file}:${p.line} (${p.why})\n`).join("")
      + `pool: ${lines.length} lines${left ? ` (${left} more left out: they delete, kill, push or post)` : ""}\n` };
  }
  if (cmd === "apply" && a && b) {
    const m = readFileSync(a, "utf8").split("\n").filter(Boolean).map(l => JSON.parse(l)).find(m => m.id === b);
    if (!m) return { out: "", err: `mutants: no mutant ${b} in ${a}\n`, rc: 2 };
    const text = readFileSync(join(root, m.file), "utf8");
    if (text.split("\n")[m.line - 1] !== m.before) return { out: "", err: `mutants: ${m.file}:${m.line} is not the line the sample was drawn on\n`, rc: 1 };
    writeFileSync(join(root, m.file), applyTo(text, m.line, m.after));
    return { out: `${m.id} ${m.file}:${m.line} ${m.kind}\n` };
  }
  if (cmd === "table" && a && b) {
    const sample = readFileSync(a, "utf8").split("\n").filter(Boolean).map(l => JSON.parse(l)), outputs = new Map();
    for (const m of sample) { try { outputs.set(m.id, readFileSync(join(b, `${m.id}.out`), "utf8")); } catch { /* not run */ } }
    const rows = tableRows(sample, outputs), survived = rows.filter(r => r.endsWith("| **survived** |")).length, notRun = rows.filter(r => r.endsWith("| not run |")).length;
    return { out: ["| mutant | line | change | check files run | result |", "|---|---|---|---:|---|", ...rows, "",
      `${sample.length - survived - notRun} of ${sample.length} caught, ${survived} survived${notRun ? `, ${notRun} not run` : ""}.`].join("\n") + "\n" };
  }
  return { out: "", err: "usage: mutants.mjs pick <sets dir> <seed> [<per kind>] | apply <sample.jsonl> <id> | table <sample.jsonl> <out dir>\n", rc: 2 };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const r = await main(process.argv.slice(2)); if (r.err) process.stderr.write(r.err); process.stdout.write(r.out); process.exitCode = r.rc ?? 0;
}
