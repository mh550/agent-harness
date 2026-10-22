// The run's journal (E4): a session's entry, its rules, and progress.md / progress-archive.md rendered from entries.jsonl.
// No dependencies. Plan: docs/plans/2026-10-21-E4-memory.md §1, §2, §4.
//
//   validate <entry.json> [<feature> <kind>] → the errors one per line ("<field>: <what is wrong>"), exit 1 if any
//   render <run dir>                        → progress.md and progress-archive.md from <run dir>/entries.jsonl; without
//                                             entries.jsonl (a run from before the journal) nothing is written
import { readFileSync, writeFileSync, renameSync, existsSync } from "node:fs";
import { resolve, basename, join } from "node:path";
import { fileURLToPath } from "node:url";

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
    if (!Array.isArray(r.affects) || !r.affects.length || !r.affects.every(nonEmpty)) bad("affects", "not a non-empty array of feature ids, milestone ids or \"run\"");
  });
  strings("questions");
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
    questions: e.questions ?? [], proposed_changes: e.proposed_changes ?? [],
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

const title = e => (e.kind === "verify" ? `verify ${flat(e.feature)}` : flat(e.feature));
const headLine = e => `${flat(e.at) || "?"} · ${title(e)} · ${flat(e.outcome)}`;
const cell = s => flat(s).replace(/\|/g, "\\|");

/** Pure: one entry in full (§4.2), ending in "\n". The evidence table is the five-column shape features.mjs counts. */
export function renderEntry(e) {
  const out = [`### ${headLine(e)}`, "", guard(flat(e.summary)), ""];
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
  const own = init ? init.header : legacy.split(/^### /m)[0].trim();
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

/** entries.jsonl in file order; a line that isn't JSON is skipped (the driver is its only writer). */
export function readEntries(path) {
  if (!existsSync(path)) return [];
  return readFileSync(path, "utf8").split("\n").flatMap(l => { try { return l.trim() ? [JSON.parse(l)] : []; } catch { return []; } });
}

const writeAtomic = (p, text) => { writeFileSync(p + ".tmp", text); renameSync(p + ".tmp", p); };   // a crash leaves the old file

function main([cmd, a, b, c]) {
  switch (cmd) {
    case "validate": {
      if (!existsSync(a)) { console.log("missing"); return 1; }
      const errs = validateText(readFileSync(a, "utf8"), b === undefined ? {} : { feature: b, kind: c });
      if (errs.length) console.log(errs.join("\n"));
      return errs.length ? 1 : 0;
    }
    case "render": {
      const dir = resolve(a), jsonl = join(dir, "entries.jsonl"), arch = join(dir, "progress-archive.md");
      if (!existsSync(jsonl)) return 0;
      const entries = readEntries(jsonl), legacy = existsSync(arch) ? legacyOf(readFileSync(arch, "utf8")) : "";
      const header = headerOf(entries, legacy, basename(dir));
      writeAtomic(join(dir, "progress.md"), renderProgress(entries, { header }));
      writeAtomic(arch, renderArchive(entries, header, legacy));
      return 0;
    }
    default:
      console.error("usage: entries.mjs validate <entry.json> [<feature> <kind>] | render <run dir>");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
