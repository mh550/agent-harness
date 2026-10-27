// The run's journal (E4): a session's entry, its rules, and progress.md / progress-archive.md rendered from entries.jsonl.
// No dependencies. Plan: docs/plans/2026-10-21-E4-memory.md §1, §2, §4.
//
//   validate <entry.json> [<feature> <kind>] → the errors one per line ("<field>: <what is wrong>"), exit 1 if any
//   ingest <run dir> <kind> <feature> <session> <model> <outcome> <files file> <final file>
//                                           → <run dir>/entry.json checked, stamped and appended to entries.jsonl, then
//                                             deleted; missing or invalid: a minimal entry instead, "missing" or
//                                             "invalid (<first error>)" printed, exit 3 (the driver notes it)
//   render <run dir>                        → progress.md and progress-archive.md from <run dir>/entries.jsonl; without
//                                             entries.jsonl (a run from before the journal) nothing is written
//   pack <run dir> <feature> [<cap>]        → context.md on stdout: what the next session of <feature> (or verify of a
//                                             milestone) reads first, at most <cap> bytes (default 8192); plan §5
import { readFileSync, writeFileSync, renameSync, existsSync, appendFileSync, rmSync } from "node:fs";
import { resolve, basename, join } from "node:path";
import { fileURLToPath } from "node:url";
import { gotchasLines } from "./memlint.mjs";

export const KINDS = ["coding", "verify", "init"], OUTCOMES = ["passes", "not yet", "parked"];
export const SUMMARY_MAX = 400, HEADER_MAX = 2000;
export const MARK = "<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->";
export const LEGACY_MARK = "<!-- harness: progress.md before the journal, kept as it was -->";

const isObj = x => x !== null && typeof x === "object" && !Array.isArray(x);
const nonEmpty = x => typeof x === "string" && x.trim() !== "";
const chars = s => [...s].length;   // code points, so "é" is one
const flat = s => `${s ?? ""}`.replace(/\s+/g, " ").trim();
// a text line that could pass for an entry header, an evidence row or a marker gets a leading \ (§4.2)
const guard = l => (/^(### |\||<!-- harness:)/.test(l) ? "\\" + l : l);
// and a summary line can't open a code fence or an HTML block, which would hide the rest of the page on GitHub (E4 review F5)
const guardSummary = l => (/^(```|~~~|<)/.test(l) ? "\\" + l : guard(l));
const cut = (s, n) => (chars(s) > n ? [...s].slice(0, n).join("") + "…" : s);

/**
 * Pure: what is wrong with an entry a session wrote, one "<field>: <what>" per problem; [] when it is valid. With
 * `feature`/`kind`, also that it is the entry of the session the driver ran.
 */
export function validate(e, { feature, kind } = {}) {
  if (!isObj(e)) return ["not an object"];
  const errs = [], err = (f, m) => errs.push(`${f}: ${m}`);
  const req = (f, ok, what) => (e[f] === undefined ? err(f, "missing") : ok(e[f]) ? true : (err(f, what(e[f])), false));
  if (req("feature", nonEmpty, () => "not a non-empty string") && feature !== undefined && e.feature !== feature) err("feature", `expected ${feature}, got ${e.feature}`);
  if (req("kind", k => KINDS.includes(k), k => `${JSON.stringify(k)} is not ${KINDS.join(" · ")}`) && kind !== undefined && e.kind !== kind) err("kind", `expected ${kind}, got ${e.kind}`);
  req("outcome", o => OUTCOMES.includes(o), o => `${JSON.stringify(o)} is not ${OUTCOMES.join(" · ")}`);
  if (req("summary", s => typeof s === "string", () => "not a string")) {
    if (!nonEmpty(e.summary)) err("summary", "empty");
    else if (chars(e.summary) > SUMMARY_MAX) err("summary", `${chars(e.summary)} characters (at most ${SUMMARY_MAX})`);
  }
  const opt = (f, ok, what) => e[f] === undefined || ok(e[f]) || err(f, what);
  const strings = f => opt(f, a => Array.isArray(a) && a.every(x => typeof x === "string"), "not an array of strings");
  const rows = (f, check) => {
    if (e[f] === undefined) return;
    if (!Array.isArray(e[f])) return err(f, "not an array");
    e[f].forEach((r, i) => (isObj(r) ? check(r, (k, m) => err(`${f}[${i}].${k}`, m)) : err(`${f}[${i}]`, "not an object")));
  };
  strings("files");
  opt("verified_how", v => typeof v === "string", "not a string");
  for (const f of ["tests_before", "tests_after"]) opt(f, n => n === null || (Number.isInteger(n) && n >= 0), "not an integer ≥ 0 or null");
  rows("dead_ends", (r, bad) => ["tried", "why"].forEach(k => nonEmpty(r[k]) || bad(k, "not a non-empty string")));
  rows("discoveries", (r, bad) => {
    if (!nonEmpty(r.text)) bad("text", "not a non-empty string");
    if (!Array.isArray(r.affects) || !r.affects.length || !r.affects.every(nonEmpty)) bad("affects", "not a non-empty array of feature ids, milestone ids, \"run\" or \"project\"");
  });
  strings("questions");
  strings("resolved");
  strings("proposed_changes");
  // a coding entry that copied the schema's "evidence": [] isn't wrong; rows from it would be
  if (e.evidence !== undefined && e.kind !== "verify" && !(Array.isArray(e.evidence) && !e.evidence.length)) err("evidence", "only a verify entry has evidence");
  else rows("evidence", (r, bad) => {
    if (!nonEmpty(r.feature)) bad("feature", "not a non-empty string");
    if (!Number.isInteger(r.step) || r.step < 1) bad("step", "not an integer ≥ 1");
    for (const k of ["ran", "saw"]) if (typeof r[k] !== "string") bad(k, "not a string");
    if (typeof r.holds !== "boolean") bad("holds", "not a boolean");
  });
  if (e.header !== undefined && e.kind !== "init" && e.header !== "") err("header", "only an init entry has a header");
  else opt("header", h => typeof h === "string" && chars(h) <= HEADER_MAX, `not a string of at most ${HEADER_MAX} characters`);
  return errs;
}

/** Pure: the errors of an entry.json's text: not JSON, not an object, or validate's. */
export function validateText(text, expect = {}) {
  let e;
  try { e = JSON.parse(text); } catch (x) { return [`not JSON: ${x.message}`]; }
  return validate(e, expect);
}

/** Pure: a valid entry with its defaults filled and unknown keys dropped, in the schema's key order (stamps kept). */
export function normalize(e) {
  const n = {
    feature: e.feature, kind: e.kind, outcome: e.outcome, summary: e.summary, files: e.files ?? [], verified_how: e.verified_how ?? "",
    tests_before: e.tests_before ?? null, tests_after: e.tests_after ?? null, dead_ends: e.dead_ends ?? [], discoveries: e.discoveries ?? [],
    questions: e.questions ?? [], ...(e.resolved?.length ? { resolved: e.resolved } : {}), proposed_changes: e.proposed_changes ?? [],
  };
  if (e.kind === "verify") n.evidence = e.evidence ?? [];
  if (e.kind === "init" && e.header) n.header = e.header;
  for (const k of ["at", "session", "model", "minimal"]) if (e[k] !== undefined) n[k] = e[k];
  return n;
}

/** Pure: the entry the driver records for a session whose entry.json was missing or invalid (§1.3). Always valid. */
export function minimal({ feature, kind, outcome, files = [], final = "" }) {
  const s = flat(final);
  const summary = !s ? "(no final message)" : chars(s) > SUMMARY_MAX ? [...s].slice(0, SUMMARY_MAX - 1).join("") + "…" : s;
  return normalize({ feature, kind, outcome, summary, files: files.filter(nonEmpty) });
}

const pad = n => String(n).padStart(2, "0");
/** Pure: a Date as the journal's `at`, local time "YYYY-MM-DD HH:MM". */
export const stamp = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;

/**
 * Pure: the journal line for a session the driver ran (§1.2, §1.3). `text` is its entry.json (null when there is none):
 * valid → normalized and stamped (a session's own stamps and `minimal` are overwritten or dropped); else a minimal
 * entry from `outcome`, `files` and `final`, with `minimal` saying why. → { entry, why } (why "" when the entry was valid).
 */
export function journalEntry(text, { feature, kind, outcome, files = [], final = "", session, model, at }) {
  const errs = text === null ? [] : validateText(text, { feature, kind });
  const why = text === null ? "missing" : errs.length ? `invalid: ${flat(errs[0])}` : "";
  const st = { at, session, model };
  if (why) return { entry: { ...minimal({ feature, kind, outcome, files, final }), ...st, minimal: why }, why };
  const { minimal: _, ...own } = normalize(JSON.parse(text));
  return { entry: { ...own, ...st }, why };
}

const title = e => (e.kind === "verify" ? `verify ${flat(e.feature)}` : flat(e.feature));
const headLine = e => `${flat(e.at) || "?"} · ${title(e)} · ${flat(e.outcome)}`;
const cell = s => flat(s).replace(/\|/g, "\\|");

/** Pure: one entry in full (§4.2), ending in "\n". The evidence table is the five-column shape features.mjs counts. */
export function renderEntry(e) {
  const out = [`### ${headLine(e)}`, "", guardSummary(flat(e.summary)), ""];
  if (e.kind === "verify" && e.evidence?.length) {
    out.push("| Feature | Step | What you ran or read | What you saw | Holds |", "|---|---|---|---|---|");
    for (const r of e.evidence) out.push(`| ${cell(r.feature)} | ${cell(r.step)} | ${cell(r.ran)} | ${cell(r.saw)} | ${r.holds ? "yes" : "no"} |`);
    out.push("");
  }
  const items = [], files = e.files ?? [];
  if (files.length) items.push(`**Files:** ${files.slice(0, 12).map(flat).join(", ")}${files.length > 12 ? `, +${files.length - 12} more` : ""}`);
  if (flat(e.verified_how)) items.push(`**Verified:** ${flat(e.verified_how)}`);
  if (e.tests_before != null || e.tests_after != null) items.push(`**Tests:** ${e.tests_before ?? "?"} → ${e.tests_after ?? "?"}`);
  for (const d of e.dead_ends ?? []) items.push(`**Dead end:** ${flat(d.tried)} — ${flat(d.why)}`);
  for (const d of e.discoveries ?? []) items.push(`**Discovery** (affects ${(d.affects ?? []).map(flat).join(", ")}): ${flat(d.text)}`);
  for (const q of e.questions ?? []) items.push(`**Question for Michael:** ${flat(q)}`);
  for (const p of e.proposed_changes ?? []) items.push(`**Proposed change:** ${flat(p)}`);
  const by = [flat(e.session), flat(e.model)].filter(Boolean).join(" · ");
  if (by || e.minimal) items.push(`*${[by, e.minimal && `recorded by the harness: entry.json ${flat(e.minimal)}`].filter(Boolean).join(" · ")}*`);
  out.push(...items.map(i => `- ${i}`));
  return out.join("\n").replace(/\n+$/, "") + "\n";
}

const top = header => `${MARK}\n${header.replace(/\s+$/, "")}\n`;
const newest = entries => [...entries].reverse();

/**
 * Pure: the header (§4.1): the newest init entry's, else a continued legacy run's own up to its first entry, else the
 * default. Every line that could pass for an entry header or an evidence row is escaped.
 */
export function headerOf(entries, legacy = "", runId = "") {
  const init = newest(entries).find(e => e.kind === "init" && nonEmpty(e.header));
  // \r, U+2028 and U+2029 end a line for features.mjs's /^### /m too, so they become \n before the guard
  const lines = t => t.replace(/\r\n?|[\u2028\u2029]/g, "\n");
  const own = init ? lines(init.header) : lines(legacy).split(/^### /m)[0].trim();
  const text = own || `# Progress — run \`${runId}\`

Rendered by the harness from \`entries.jsonl\` after every session (sessions write \`entry.json\`; edits here are
overwritten). Newest first: the 15 newest entries in full, older ones one line each, every entry in full in
\`progress-archive.md\`. Steer from \`INBOX.md\` (first line \`status: run|pause|stop\`; answers under \`## Answers\`).`;
  return text.replace(/\s+$/, "").split("\n").map(guard).join("\n");
}

/** Pure: progress.md (§4.3): the `full` newest entries in full, newest first, then one line per older entry. */
export function renderProgress(entries, { full = 15, header = headerOf(entries) } = {}) {
  const all = newest(entries), shown = all.slice(0, full), older = all.slice(full);
  let s = top(header);
  if (shown.length) s += "\n" + shown.map(renderEntry).join("\n");
  if (older.length) s += "\n## Older entries (in full in progress-archive.md)\n\n"
    + older.map(e => `- ${headLine(e)} · ${cut(flat(e.summary), 100)} ([in full](progress-archive.md))\n`).join("");
  return s;
}

/** Pure: progress-archive.md (§4.4): every entry in full, newest first, then a continued legacy run's old record as it was. */
export function renderArchive(entries, header = headerOf(entries), legacy = "") {
  let s = top(header);
  if (entries.length) s += "\n" + newest(entries).map(renderEntry).join("\n");
  if (legacy) s += `\n${LEGACY_MARK}\n${legacy}`;
  return s;
}

/** Pure: the pre-journal part of a progress-archive.md: all of it if the harness didn't render it, else what follows the marker. */
export function legacyOf(text) {
  if (text.split("\n", 1)[0] !== MARK) return text;
  const i = text.indexOf(`\n${LEGACY_MARK}\n`);
  return i < 0 ? "" : text.slice(i + LEGACY_MARK.length + 2);
}

export const PACK_BYTES = 8192, ITEM_BYTES = 1024, PACK_RESERVE = 160;
const bytes = s => Buffer.byteLength(s);
// the first n bytes of s, "…" included, cut on a code point
const head = (s, n) => {
  if (bytes(s) <= n) return s;
  let out = "", b = bytes("…");
  for (const ch of s) { if ((b += bytes(ch)) > n) break; out += ch; }
  return out + "…";
};
// the last n bytes of s after "…" (the newest answers are at the bottom of INBOX.md)
const tail = (s, n) => {
  const cs = [...s]; let i = cs.length, b = bytes("…");
  while (i > 0 && (b += bytes(cs[i - 1])) <= n) i--;
  return "…" + cs.slice(i).join("");
};

/**
 * Pure: context.md (§5), the bounded pack a coding or verify session reads first. `entries` in file order (a null
 * stands for a line that isn't JSON, so every entry keeps its line number), `feature` a feature id or a milestone id,
 * `list` the feature list, `answers` INBOX.md's text after `## Answers`, `gotchas` the project CLAUDE.md's `## Gotchas`
 * lines, `cap` ≥ 1024. Six parts in a fixed priority order; the first item that doesn't fit ends the pack (answers
 * excepted: cut to the room left), so a lower part never pushes out a higher. A question a later entry lists in
 * `resolved` is left out; `Promote to Gotchas` (coding packs only) has a share of cap / 8 (M3-03).
 */
export function pack(entries, { feature, list = [], answers = "", gotchas = [], cap = PACK_BYTES }) {
  const feats = Array.isArray(list) ? list : list?.features ?? [];
  const ofM = m => feats.filter(f => f.milestone === m).map(f => f.id);
  const self = feats.find(f => f.id === feature), isM = !self && ofM(feature).length > 0;
  const T = new Set([feature, ...(isM ? ofM(feature) : [])]);
  const DT = new Set([...T, "run", ...(self?.milestone ? [self.milestone] : [])]);   // a discovery may name the feature's milestone
  const after = self?.after ?? [];   // a milestone's own features are in part 1 already
  const D = feats.filter(f => f.id !== feature && (after.includes(f.id) || after.includes(f.milestone))).map(f => f.id);
  const es = entries.map((e, i) => (isObj(e) ? { ...e, line: i + 1 } : null)).filter(Boolean), nw = newest(es);
  const item = (text, ref) => `- ${head(flat(text), ITEM_BYTES)} → ${ref}`;
  const at = e => `entries.jsonl:${e.line}`;
  const shown = new Set();
  const entryItem = e => {
    shown.add(e.line);
    const tests = e.tests_before != null || e.tests_after != null ? `; tests ${e.tests_before ?? "?"} → ${e.tests_after ?? "?"}` : "";
    const files = e.files?.length ? `; files ${e.files.slice(0, 5).map(flat).join(", ")}${e.files.length > 5 ? ", …" : ""}` : "";
    return item(`${headLine(e)}: ${flat(e.summary)}${tests}${files}`, at(e));
  };
  const mine = nw.filter(e => T.has(e.feature));
  // a question is answered once a later entry's `resolved` names it (exact after folding whitespace)
  const settled = q => es.some(r => r.line > q.line && (r.resolved ?? []).some(x => flat(x) === flat(q.text)));
  // a fact that outlives the run, until a `## Gotchas` line carries its first 40 characters (a verify can't write CLAUDE.md)
  const isP = d => !isM && (d.affects ?? []).includes("project"), key = d => [...flat(d.text)].slice(0, 40).join("");
  const carried = gotchas.map(flat), seen = new Set();
  const promote = nw.flatMap(e => (e.discoveries ?? []).filter(isP).map(d => ({ d, e }))).filter(({ d }) => {
    const k = key(d);
    if (seen.has(k) || carried.some(g => g.includes(k))) return false;
    seen.add(k);
    return true;
  });
  const parts = [
    ["This feature's earlier attempts", () => [
      ...mine.flatMap(e => (e.dead_ends ?? []).map(d => item(`Dead end (${flat(e.feature)}, ${flat(e.session)}): ${flat(d.tried)} — ${flat(d.why)}`, at(e)))),
      ...nw.filter(e => e.kind === "verify").flatMap(e => (e.evidence ?? []).filter(r => T.has(r.feature) && r.holds === false)
        .map(r => item(`Verify ${flat(e.feature)} found (${flat(r.feature)} step ${r.step}): ran ${flat(r.ran)}; saw ${flat(r.saw)}`, at(e)))),
      ...mine.flatMap(e => (e.questions ?? []).filter(q => !settled({ line: e.line, text: q })).map(q => item(`Question (${flat(e.feature)}): ${flat(q)}`, at(e)))),
      ...mine.map(e => () => entryItem(e)),
    ]],
    ["Michael's answers", () => (flat(answers) ? [{ answers: flat(answers) }] : [])],
    ["Discoveries for this feature", () => nw.flatMap(e => (e.discoveries ?? []).filter(d => !isP(d) && (d.affects ?? []).some(a => DT.has(a)))
      .map(d => item(`Discovery (${flat(e.feature)}, affects ${(d.affects ?? []).map(flat).join(", ")}): ${flat(d.text)}`, at(e))))],
    ["Promote to Gotchas", () => promote.map(({ d, e }) => item(d.text, at(e))), Math.floor(cap / 8)],
    ["What it builds on", () => D.flatMap(id => { const e = nw.find(x => x.feature === id); return e ? [() => (shown.has(e.line) ? null : entryItem(e))] : []; })],
    ["Lately in the run", () => nw.slice(0, 3).map(e => () => (shown.has(e.line) ? null : entryItem(e)))],
  ];
  let out = `# Context pack for \`${head(flat(feature), 200)}\`\n\nChosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.\n`;
  const room = cap - PACK_RESERVE;
  let left = 0, stopped = false;
  for (const [title, make, share = Infinity] of parts) {
    let heading = `\n## ${title}\n\n`, used = 0;
    for (let it of make()) {
      if (typeof it === "function") { if ((it = it()) === null) continue; }   // an entry already shown (or left out) isn't repeated
      if (stopped) { left++; continue; }
      if (it.answers !== undefined) {
        const whole = `- ${it.answers} → INBOX.md`, free = room - bytes(out + heading) - bytes("\n");
        if (bytes(whole) <= free) it = whole;
        else if (free >= 256) it = `- ${tail(it.answers, free - bytes("- " + " → INBOX.md"))} → INBOX.md`;
        else it = whole;   // doesn't fit: ends the pack below
      }
      if (used + bytes(heading + it + "\n") > share) { left++; continue; }   // past its share: counted, the pack goes on
      if (bytes(out + heading + it + "\n") > room) { stopped = true; left++; continue; }
      used += bytes(heading + it + "\n"); out += heading + it + "\n"; heading = "";
    }
  }
  if (left) out += `\n_${left} items left out at ${cap} bytes: entries.jsonl has them all._\n`;
  return out;
}

/**
 * entries.jsonl in file order, a null for each line that isn't a valid entry (blank, damaged, a session's edit), so
 * every entry keeps its line number and no reader trips on a wrong type (E4 review F1).
 */
export function readEntries(path) {
  if (!existsSync(path)) return [];
  return readFileSync(path, "utf8").replace(/\n$/, "").split("\n").map(l => { try { const e = JSON.parse(l); return validate(e).length ? null : e; } catch { return null; } });
}

const writeAtomic = (p, text) => { writeFileSync(p + ".tmp", text); renameSync(p + ".tmp", p); };   // a crash leaves the old file

const lines = p => (existsSync(p) ? readFileSync(p, "utf8").split("\n").filter(l => l.trim()) : []);

function main([cmd, a, b, c, ...rest]) {
  switch (cmd) {
    case "validate": {
      if (!existsSync(a)) { console.log("missing"); return 1; }
      const errs = validateText(readFileSync(a, "utf8"), b === undefined ? {} : { feature: b, kind: c });
      if (errs.length) console.log(errs.join("\n"));
      return errs.length ? 1 : 0;
    }
    case "ingest": {   // a, b, c = run dir, kind, feature; then session, model, outcome, files file, final file
      const [session, model, outcome, filesFile, finalFile] = rest, entryFile = join(a, "entry.json");
      const text = existsSync(entryFile) ? readFileSync(entryFile, "utf8") : null;
      const final = existsSync(finalFile) ? readFileSync(finalFile, "utf8") : "";
      const { entry, why } = journalEntry(text, { feature: c, kind: b, outcome, files: lines(filesFile), final, session, model, at: stamp(new Date()) });
      const jl = join(a, "entries.jsonl"), old = existsSync(jl) ? readFileSync(jl, "utf8") : "";
      // a last line without its newline would swallow this one (E4 review F2)
      try { appendFileSync(jl, (old && !old.endsWith("\n") ? "\n" : "") + JSON.stringify(entry) + "\n"); }
      catch (x) { console.log(x.message); return 1; }   // nothing appended, entry.json left: the driver moves it aside
      rmSync(entryFile, { force: true });
      if (why) console.log(why.replace(/^invalid: (.*)$/, "invalid ($1)"));
      return why ? 3 : 0;
    }
    case "render": {
      const dir = resolve(a), jsonl = join(dir, "entries.jsonl"), arch = join(dir, "progress-archive.md");
      if (!existsSync(jsonl)) return 0;
      const entries = readEntries(jsonl).filter(Boolean), legacy = existsSync(arch) ? legacyOf(readFileSync(arch, "utf8")) : "";
      const header = headerOf(entries, legacy, basename(dir));
      writeAtomic(join(dir, "progress.md"), renderProgress(entries, { header }));
      writeAtomic(arch, renderArchive(entries, header, legacy));
      return 0;
    }
    case "pack": {   // a, b, c = run dir, feature, cap
      const dir = resolve(a), jsonl = join(dir, "entries.jsonl"), inbox = join(dir, "INBOX.md"), fl = join(dir, "feature_list.json");
      const entries = readEntries(jsonl);
      let list = [];
      try { list = JSON.parse(readFileSync(fl, "utf8")); } catch { /* no list yet: the pack has no targets beyond the id */ }
      const text = existsSync(inbox) ? readFileSync(inbox, "utf8") : "", i = text.search(/^## Answers/m);   // as the driver's answers_hash finds it
      const answers = i < 0 ? "" : text.slice(i).replace(/^.*\n?/, "");
      const cap = c === undefined || c === "" ? PACK_BYTES : Number(c);
      // a typo'd CONTEXT_PACK_BYTES must not lift the cap (NaN compares false) or undercut the pack's own header
      if (!Number.isInteger(cap) || cap < 1024) { console.error(`pack: the cap ${JSON.stringify(c)} is not a whole number of bytes ≥ 1024`); return 2; }
      // the project's Gotchas only from a run dir at <worktree>/.harness/runs/<run> (an eval probe's or a check's reads none)
      const wt = resolve(dir, "../../.."), inRun = basename(resolve(dir, "..")) === "runs" && basename(resolve(dir, "../..")) === ".harness";
      const gotchas = inRun && existsSync(join(wt, "CLAUDE.md")) ? gotchasLines(readFileSync(join(wt, "CLAUDE.md"), "utf8")) : [];
      process.stdout.write(pack(entries, { feature: b, list, answers, gotchas, cap }));
      return 0;
    }
    default:
      console.error("usage: entries.mjs validate <entry.json> [<feature> <kind>] | ingest <run dir> <kind> <feature> <session> <model> <outcome> <files file> <final file> | render <run dir> | pack <run dir> <feature> [<cap>]");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
