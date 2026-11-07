// The context bundle's glossary: the IDs each run's own section of the gatherer's markdown names, resolved against its
// feature list and its docs (lib/glossary.mjs), merged across the runs (docs/plans/2026-11-07-A2-context-bundle.md §2.3).
//
//   node lib/context.mjs bundle <context.md> <runs.tsv> [--max-bytes <n>]   → the ## Glossary markdown on stdout
//
// runs.tsv (lib/context.sh's context_glossary): one run per line, tab-separated: state dir, run, project, ended,
// running (1/0), features, record, worktree, docs root, needs json (`harness needs <run> --json`).
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { captured, isMain, runCli } from "./cli.mjs";
import { findIds, fsReader, glossaryMarkdown, knownIds, resolveIds } from "./glossary.mjs";

const FIELDS = ["state", "run", "project", "ended", "running", "features", "record", "worktree", "docs", "needs"];

// the gatherer's markdown, run, project, ends (the other runs' headings and the sections after them) → the lines from
// `### <run> (<project>)` up to the next `### ` or `## ` heading outside its ~~~ fences (a fenced INBOX.md has headings
// of its own), or the next line of ends, fenced or not (a part cut mid-fence leaves an odd ~~~)
export function runSection(md, run, project, ends = []) {
  const lines = String(md ?? "").split("\n"), head = `### ${run} (${project})`, at = lines.indexOf(head);
  if (at < 0) return "";
  const stop = new Set(ends.filter(e => e !== head));
  let end = at + 1, fenced = false;
  for (; end < lines.length; end++) {
    if (stop.has(lines[end])) break;
    if (lines[end] === "~~~") fenced = !fenced;
    else if (!fenced && /^#{2,3} /.test(lines[end])) break;
  }
  return lines.slice(at, end).join("\n");
}

// a run's section, its open needs items → the text its IDs are found in: the section (never the gatherer's shared
// parts, which are other runs' words), then each open item's why and question
export function runText(section, needs = []) {
  const items = Array.isArray(needs) ? needs : [];
  const more = items.flatMap(n => [n?.card?.why, n?.card?.question?.text]).filter(x => typeof x === "string" && x);
  return [section, ...more].join("\n");
}

// [{ glossary, unresolved }] in run order → one: each (id, kind, source) once, and an ID unresolved in one run but
// resolved in another is not unresolved
export function mergeResults(results) {
  const glossary = [], seen = new Set(), unresolved = [];
  for (const r of results) for (const e of r.glossary ?? []) {
    const k = `${e.id}\0${e.kind}\0${e.source}`;
    if (!seen.has(k)) { seen.add(k); glossary.push(e); }
  }
  const resolved = new Set(glossary.map(e => e.id));
  for (const r of results) for (const id of r.unresolved ?? []) if (!resolved.has(id) && !unresolved.includes(id)) unresolved.push(id);
  return { glossary, unresolved };
}

// a runs.tsv line → its row ({ state, run, … }); a short line's missing fields are ""
export const parseRow = line => Object.fromEntries(FIELDS.map((k, i) => [k, line.split("\t")[i] ?? ""]));

const readJson = p => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return null; } };
const noDocs = { root: "", files: () => [], read: () => null };

// the gatherer's own headings after the runs (lib/context.sh's context_runs): a run's section never runs past them
const AFTER_RUNS = ["## Retro backlog (ledger/retro-backlog.jsonl)", "## Glossary"];

// one run's row, the gatherer's markdown, every run's heading → { glossary, unresolved }
function resolveRun(row, md, ends) {
  const listPath = join(row.record, "feature_list.json");
  let text = null;
  try { text = readFileSync(listPath, "utf8"); } catch { text = null; }
  let parsed = null;
  try { parsed = text ? JSON.parse(text) : null; } catch { parsed = null; }
  const ids = findIds(runText(runSection(md, row.run, row.project, ends), readJson(row.needs) ?? []), knownIds(parsed));
  const reader = row.docs && existsSync(row.docs) ? fsReader(row.docs) : noDocs;
  return resolveIds(ids, { featureList: text == null ? null : { path: listPath, text } }, reader);
}

export const main = captured(([cmd, ctx, tsv, ...rest], io, say, put) => {
  const usage = () => { console.error("usage: context.mjs bundle <context.md> <runs.tsv> [--max-bytes <n>]"); return 2; };
  if (cmd !== "bundle" || !ctx || !tsv) return usage();
  let max = Infinity;
  for (let i = 0; i < rest.length; i++) {
    if (rest[i] === "--max-bytes" && /^\d+$/.test(rest[i + 1] ?? "")) max = Number(rest[++i]);
    else return usage();
  }
  let md, rows;
  try { md = readFileSync(ctx, "utf8"); rows = readFileSync(tsv, "utf8").split("\n").filter(Boolean).map(parseRow); }
  catch (e) { console.error(`context: ${e.message}`); return 1; }
  const ends = [...rows.map(r => `### ${r.run} (${r.project})`), ...AFTER_RUNS];
  const out = glossaryMarkdown(mergeResults(rows.map(r => resolveRun(r, md, ends))), max);
  put(out);
  return 0;
});

if (isMain(import.meta.url)) runCli(main);
