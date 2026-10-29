// Would a file-based test subset have caught the reds the full suite caught? For each coding session: the files it
// changed (the run record's entries.jsonl) against the check files that went red in the session's own suite calls
// (the stream log's tool results: HARNESS_FAILED=, "red again on a rerun of", "flaky:", "files that exited non-zero").
// A red check file is "selected" by a file-based subset when its text names a changed file's basename (the subset rule a
// per-feature selection would use: run the check files that mention what changed), or when the session changed that
// check file itself; "flaker" when it is a repeat flaker (the rerun guard's rows and decisions/2026-10-29-rerun-guard);
// "missed" otherwise: a red the subset would not have run.
//   node escapes.mjs <repo> <state-root> <run>…
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, basename } from "node:path";

const [repo, stateRoot, ...runs] = process.argv.slice(2);
if (!repo || !stateRoot || !runs.length) { console.error("usage: node escapes.mjs <repo> <state-root> <run>…"); process.exit(2); }
const FLAKERS = new Set(["08", "13", "15", "28", "32", "38", "44", "46", "47", "48", "52", "74"]);   // by file number
const checksDir = join(repo, "tests", "checks");
const checkText = new Map(readdirSync(checksDir).filter(f => f.endsWith(".sh")).map(f => [f.replace(/\.sh$/, ""), readFileSync(join(checksDir, f), "utf8")]));
const RED = /(?:HARNESS_FAILED=|red again on a rerun of |flaky: |files that exited non-zero: )([^)\n]+)/g;

const rows = [], subsets = [];
for (const run of runs) {
  const rec = join(repo, ".harness", "runs", run, "entries.jsonl");
  if (!existsSync(rec)) continue;
  const entries = readFileSync(rec, "utf8").split("\n").filter(Boolean).map(l => JSON.parse(l)).filter(e => e.kind === "coding" || /^\d\d-/.test(e.session ?? ""));
  for (const e of entries) {
    const log = join(stateRoot, run, "logs", `${e.session}.jsonl`); if (!existsSync(log)) continue;
    const reds = new Set();
    for (const line of readFileSync(log, "utf8").split("\n")) {
      if (!line.includes("tool_result")) continue; let ev; try { ev = JSON.parse(line); } catch { continue; }
      for (const c of ev.message?.content ?? []) {
        if (c.type !== "tool_result") continue;
        const text = Array.isArray(c.content) ? c.content.map(x => x.text ?? "").join("\n") : String(c.content ?? "");
        for (const m of text.matchAll(RED)) for (const n of m[1].trim().split(/\s+/)) if (/^\d\d-[a-z0-9-]+$/.test(n)) reds.add(n);
      }
    }
    const files = e.files ?? [], names = files.map(f => basename(f).replace(/\.(sh|mjs|md|txt|json)$/, "")).filter(n => n.length > 3);
    // the subset a name match would run for this change: the check files naming any changed file, plus the changed check files
    const subset = [...checkText].filter(([f, t]) => names.some(n => t.includes(n)) || files.some(x => x.endsWith(`${f}.sh`))).length;
    if (files.length) subsets.push({ session: e.session, run, files: files.length, subset, of: checkText.size, code: files.filter(f => /^(lib|bin|tests|prompts|templates)\//.test(f)).length });
    for (const r of reds) {
      const own = files.some(f => f.endsWith(`${r}.sh`));
      const text = checkText.get(r) ?? "";
      const named = names.filter(n => text.includes(n));
      const how = own ? "own check file" : named.length ? `selected (names ${named.slice(0, 3).join(", ")})` : FLAKERS.has(r.slice(0, 2)) ? "flaker" : "MISSED";
      rows.push({ run, session: e.session, feature: e.feature, red: r, how, files: files.length });
    }
  }
}
const by = k => rows.filter(r => r.how.startsWith(k)).length;
for (const r of rows) console.log(`${r.run.replace("agent-harness-", "")} ${r.session} ${r.red}: ${r.how} (${r.files} files changed)`);
console.log(`\n${rows.length} reds in sessions' own suite calls: own check file ${by("own")}, selected by a name match ${by("selected")}, repeat flaker ${by("flaker")}, missed ${by("MISSED")}`);
console.log("missed = a red in a check file that neither names a changed file nor is a repeat flaker: a file-based subset would not have run it");
const sz = subsets.map(s => s.subset / s.of).sort((a, b) => a - b), pct = x => `${Math.round(x * 100)}%`;
console.log(`\nsubset size under the name rule, ${subsets.length} coding sessions with files: median ${pct(sz[sz.length >> 1])} of the check files, quartiles ${pct(sz[sz.length >> 2])}–${pct(sz[(sz.length * 3) >> 2])}, under half the suite in ${subsets.filter(s => s.subset / s.of < 0.5).length} sessions`);
for (const s of subsets.filter(s => s.subset / s.of < 0.5)) console.log(`  ${s.run.replace("agent-harness-", "")} ${s.session}: ${s.subset}/${s.of} check files (${s.code} code files of ${s.files} changed)`);
