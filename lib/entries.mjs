// The run's journal (E4): a session's entry, its rules, and progress.md / progress-archive.md rendered from entries.jsonl.
// No dependencies. Plan: docs/plans/2026-10-21-E4-memory.md §1, §2, §4.
//
//   validate <entry.json> [<feature> <kind>] → the errors one per line ("<field>: <what is wrong>"), exit 1 if any
//   ingest <run dir> <kind> <feature> <session> <model> <outcome> <files file> <final file> [<worktree>]
//                                           → <run dir>/entry.json checked, stamped and appended to entries.jsonl, then
//                                             deleted; missing or invalid: a minimal entry instead, "missing" or
//                                             "invalid (<first error>)" printed, exit 3 (the driver notes it); a
//                                             question without Files: filled from the session, "filled <n>" printed
//   session-files <run dir> <feature> <files file> <worktree>
//                                           → the session's files for a question without Files: (its last entry's,
//                                             then the diff's), absolute, one per line, 8 at most
//   render <run dir>                        → progress.md and progress-archive.md from <run dir>/entries.jsonl; without
//                                             entries.jsonl (a run from before the journal) nothing is written
//   pack <run dir> <feature> [<cap>]        → context.md on stdout: what the next session of <feature> (or verify of a
//                                             milestone) reads first, at most <cap> bytes (default 8192); plan §5
import { readFileSync, writeFileSync, renameSync, existsSync, appendFileSync, rmSync } from "node:fs";
import { resolve, basename, join, isAbsolute } from "node:path";
import { fileURLToPath } from "node:url";
import { gotchasLines, readRules, decisionsStore } from "./memlint.mjs";
import { answers as answersOf, files as filesIn } from "./inbox.mjs";

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

export const FILL_MAX = 8;
/** Pure: where a question without a Files: line points (decisions/2026-10-27-question-locations): the entry's own files
 *  first, then the session's diff, absolute (relative ones joined to the worktree), deduplicated, at most FILL_MAX. The
 *  run directory's are left out, as the diff leaves them out (a lane's copy of it is thrown away). */
export function sessionFiles(entryFiles, diff, wt = "") {
  const abs = p => (isAbsolute(p) || !wt ? p : join(wt, p));
  return [...new Set([...(entryFiles ?? []), ...(diff ?? [])].map(p => `${p}`.trim()).filter(p => p && !/^(\.\/)?\.harness\/runs\//.test(p)).map(abs))].slice(0, FILL_MAX);
}
/** Pure: each question with no Files: line gets ` Files (harness, from the session): <files>` appended; nothing else of
 *  the entry changes (the same object back when nothing is filled). → { entry, filled } */
export function fillQuestions(e, files) {
  let filled = 0;
  if (!files?.length || !Array.isArray(e.questions)) return { entry: e, filled };
  const questions = e.questions.map(q => (filesIn(q).length ? q : (filled++, `${q} Files (harness, from the session): ${files.join(", ")}`)));
  return filled ? { entry: { ...e, questions }, filled } : { entry: e, filled };
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
  for (const q of e.resolved ?? []) items.push(`**Resolved:** ${flat(q)}`);
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

export const PACK_BYTES = 8192, ITEM_BYTES = 1024, PACK_RESERVE = 160, RULE_BYTES = 240;
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
 * lines, `rules` the decisions store's current rules (memlint.mjs currentRules) from `rulesFrom`, `cap` ≥ 1024. Seven parts
 * in a fixed priority order; the first item that doesn't fit ends the pack (answers excepted: cut to the room left), so
 * a lower part never pushes out a higher. A question a later entry lists in `resolved` is left out; a milestone pack
 * (verify) lists failed evidence rows before dead ends; `Promote to Gotchas` (coding packs only) has a share of cap / 8
 * (M3-03); `Current rules` comes last, at most cap / 4, the rest one `older rules` line (M3-04).
 */
export function pack(entries, { feature, list = [], answers = "", gotchas = [], rules = [], rulesFrom = "", cap = PACK_BYTES }) {
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
  // a later entry's `resolved`, as context.md shows an item: its `- `, `Question (<id>): ` and ` → entries.jsonl:<n>` dropped
  const res = es.flatMap(r => (r.resolved ?? []).map(x => ({ line: r.line, x: flat(x).replace(/^- /, "").replace(/^Question \([^)]*\): /, "").replace(/ → entries\.jsonl:\d+$/, "") })));
  // a question is answered once a later entry resolves it: exact after folding whitespace, or a prefix of it (40
  // characters at least) when copied as the pack cut it, with `…`
  const settled = q => res.some(({ line, x }) => line > q.line && (x === flat(q.text) || (x.endsWith("…") && chars(x) > 40 && flat(q.text).startsWith(x.slice(0, -1)))));
  // a fact that outlives the run, until a `## Gotchas` line carries its first 40 characters (case, backticks, emphasis and
  // spacing aside) or a later entry resolves it (a stale fact, or one a session dropped from a full section)
  const loose = t => flat(`${t ?? ""}`.toLowerCase().replace(/[`*_]/g, "")), key = t => [...loose(t)].slice(0, 40).join("");
  const isP = d => !isM && (d.affects ?? []).includes("project");
  const carried = gotchas.map(loose), seen = new Set();
  const promote = nw.flatMap(e => (e.discoveries ?? []).filter(isP).map(d => ({ d, e }))).filter(({ d, e }) => {
    const k = key(d.text);
    if (seen.has(k) || carried.some(g => g.includes(k)) || res.some(({ line, x }) => line > e.line && key(x) === k)) return false;
    seen.add(k);
    return true;
  });
  const deads = mine.flatMap(e => (e.dead_ends ?? []).map(d => item(`Dead end (${flat(e.feature)}, ${flat(e.session)}): ${flat(d.tried)} — ${flat(d.why)}`, at(e))));
  const rows = nw.filter(e => e.kind === "verify").flatMap(e => (e.evidence ?? []).filter(r => T.has(r.feature) && r.holds === false)
    .map(r => item(`Verify ${flat(e.feature)} found (${flat(r.feature)} step ${r.step}): ran ${flat(r.ran)}; saw ${flat(r.saw)}`, at(e))));
  const parts = [
    ["This feature's earlier attempts", () => [
      ...(isM ? [...rows, ...deads] : [...deads, ...rows]),
      ...mine.flatMap(e => (e.questions ?? []).filter(q => !settled({ line: e.line, text: q })).map(q => item(`Question (${flat(e.feature)}): ${flat(q)}`, at(e)))),
      ...mine.map(e => () => entryItem(e)),
    ]],
    ["Michael's answers", () => (flat(answers) ? [{ answers: flat(answers) }] : [])],
    ["Discoveries for this feature", () => nw.flatMap(e => (e.discoveries ?? []).filter(d => !isP(d) && (d.affects ?? []).some(a => DT.has(a)))
      .map(d => item(`Discovery (${flat(e.feature)}, affects ${(d.affects ?? []).map(flat).join(", ")}): ${flat(d.text)}`, at(e))))],
    ["Promote to Gotchas", () => promote.map(({ d, e }) => ({ fact: flat(d.text), ref: at(e) })), Math.floor(cap / 8)],
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
      if (it.fact !== undefined) {   // a fact is cut to the room left in its share, so a long one still shows
        const whole = item(it.fact, it.ref), free = share - used - bytes(heading + "- " + " → " + it.ref + "\n");
        it = used + bytes(heading + whole + "\n") <= share || free < 32 ? whole : `- ${head(it.fact, free)} → ${it.ref}`;
      }
      if (used + bytes(heading + it + "\n") > share) { left++; continue; }   // past its share: counted, the pack goes on
      if (bytes(out + heading + it + "\n") > room) { stopped = true; left++; continue; }
      used += bytes(heading + it + "\n"); out += heading + it + "\n"; heading = "";
    }
  }
  // Current rules, last: the decisions store's lines newest first in at most cap / 4 (and the room left); the rest is one
  // line naming the store, not counted as left out (entries.jsonl doesn't hold them). A pack that stopped has none.
  if (rules.length && !stopped) {
    const free = Math.min(Math.floor(cap / 4), room - bytes(out)), older = (k, gap) => (k ? `${gap ? "\n" : ""}_${k} older rules: ${flat(rulesFrom) || "the decisions store"}._\n` : "");
    let body = "", n = 0;
    for (const r of rules) {
      const ref = head(flat(r.ref), 120), line = `- ${head(flat(r.text), Math.max(RULE_BYTES - bytes(`- → ${ref}`) - 1, 40))} → ${ref}\n`;
      if (bytes(`\n## Current rules\n\n${body}${line}${older(rules.length - n - 1, true)}`) > free) break;
      body += line; n++;
    }
    const part = `\n## Current rules\n\n${body}${older(rules.length - n, body !== "")}`;
    if (bytes(part) <= free) out += part;
  }
  if (left) out += `\n_${left} items left out at ${cap} bytes: entries.jsonl has them all._\n`;
  return out;
}

/**
 * A review's "<n> Critical, <n> Important" → { critical, important } (a missing one of the two is 0), null without
 * either: the review gate escalates a Sonnet review on a count above 0 (M6). The pair first, count before or after the
 * word ("Critical: 0, Important: 2"), then either alone; capitalised words only, and a count is never the tail of an
 * id or a step ("M3-06 Critical", "step 1 important").
 */
export function reviewFindings(text) {
  const t = text ?? "";
  const pair = /(?<![\w.-])(\d+)\s+Critical\b.{0,40}?(?<![\w.-])(\d+)\s+Important\b/.exec(t) ?? /\bCritical:?\s*(\d+)\b.{0,40}?\bImportant:?\s*(\d+)\b/.exec(t);
  if (pair) return { critical: Number(pair[1]), important: Number(pair[2]) };
  const c = /(?<![\w.-])(\d+)\s+Critical\b/.exec(t), i = /(?<![\w.-])(\d+)\s+Important\b/.exec(t);
  return c || i ? { critical: c ? Number(c[1]) : 0, important: i ? Number(i[1]) : 0 } : null;
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
      const [session, model, outcome, filesFile, finalFile, wt] = rest, entryFile = join(a, "entry.json");
      const text = existsSync(entryFile) ? readFileSync(entryFile, "utf8") : null;
      const final = existsSync(finalFile) ? readFileSync(finalFile, "utf8") : "";
      const diff = lines(filesFile), j = journalEntry(text, { feature: c, kind: b, outcome, files: diff, final, session, model, at: stamp(new Date()) });
      const { why } = j, { entry, filled } = fillQuestions(j.entry, sessionFiles(j.entry.files, diff, wt));
      const jl = join(a, "entries.jsonl"), old = existsSync(jl) ? readFileSync(jl, "utf8") : "";
      // a last line without its newline would swallow this one (E4 review F2)
      try { appendFileSync(jl, (old && !old.endsWith("\n") ? "\n" : "") + JSON.stringify(entry) + "\n"); }
      catch (x) { console.log(x.message); return 1; }   // nothing appended, entry.json left: the driver moves it aside
      rmSync(entryFile, { force: true });
      if (why) console.log(why.replace(/^invalid: (.*)$/, "invalid ($1)"));
      if (filled) console.log(`filled ${filled}`);
      return why ? 3 : 0;
    }
    case "session-files": {   // a, b, c, rest[0] = run dir, feature, files file, worktree
      const last = readEntries(join(a, "entries.jsonl")).filter(e => e?.feature === b).pop();
      for (const f of sessionFiles(last?.files, lines(c), rest[0])) console.log(f);
      return 0;
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
    case "pack": {   // a, b, c, rest[0] = run dir, feature, cap, the worktree the session works in (a lane's slot)
      const dir = resolve(a), jsonl = join(dir, "entries.jsonl"), inbox = join(dir, "INBOX.md"), fl = join(dir, "feature_list.json");
      const entries = readEntries(jsonl);
      let list = [];
      try { list = JSON.parse(readFileSync(fl, "utf8")); } catch { /* no list yet: the pack has no targets beyond the id */ }
      const text = existsSync(inbox) ? readFileSync(inbox, "utf8") : "";
      const answers = answersOf(text).replace(/^.*\n?/, "");   // as the driver's answers_hash finds them
      const cap = c === undefined || c === "" ? PACK_BYTES : Number(c);
      // a typo'd CONTEXT_PACK_BYTES must not lift the cap (NaN compares false) or undercut the pack's own header
      if (!Number.isInteger(cap) || cap < 1024) { console.error(`pack: the cap ${JSON.stringify(c)} is not a whole number of bytes ≥ 1024`); return 2; }
      // the project's Gotchas only from a run dir at <worktree>/.harness/runs/<run> (a run's or an eval probe's clone; a check's $T/pk reads none),
      // or from the worktree named after the cap: a lane's slot, whose CLAUDE.md the session edits (the record worktree's is main's)
      const inRun = !!rest[0] || (basename(resolve(dir, "..")) === "runs" && basename(resolve(dir, "../..")) === ".harness");
      const wt = rest[0] ? resolve(rest[0]) : resolve(dir, "../../..");
      let gotchas = [];
      try { if (inRun) gotchas = gotchasLines(readFileSync(join(wt, "CLAUDE.md"), "utf8")); } catch { /* none, or unreadable: a pack without them */ }
      const rules = inRun ? readRules(wt) : [], rulesFrom = rules.length ? decisionsStore(wt).path : "";   // and its decisions store's rules
      process.stdout.write(pack(entries, { feature: b, list, answers, gotchas, rules, rulesFrom, cap }));
      return 0;
    }
    case "findings": {   // a, b, c = run dir, feature, final file → "<critical>\t<important>" from its last entry's summary, else the final message
      const last = readEntries(join(a, "entries.jsonl")).filter(e => e?.feature === b).pop();
      const f = reviewFindings(last?.summary) ?? reviewFindings(existsSync(c) ? readFileSync(c, "utf8") : "");
      if (!f) return 1;
      console.log(`${f.critical}\t${f.important}`);
      return 0;
    }
    default:
      console.error("usage: entries.mjs validate <entry.json> [<feature> <kind>] | ingest <run dir> <kind> <feature> <session> <model> <outcome> <files file> <final file> [<worktree>] | session-files <run dir> <feature> <files file> <worktree> | render <run dir> | pack <run dir> <feature> [<cap> [<worktree>]] | findings <run dir> <feature> <final file>");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
