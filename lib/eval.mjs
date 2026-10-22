// Replay evals: task validation, seeding, budget, compare and probe scoring. No dependencies.
//   validate <task.json | dir>…          → one line per error ("<file>: <field> …"), exit 1 if any; dirs: every */task.json
//   seed <task.json> <run-id>            → the run's feature_list.json on stdout (features verbatim, passes false)
//   spent <results dir>                  → the dollars its tasks' summary.json files report (<task>/ and <task>/r<N>/)
//   compare <result dir A> <result dir B> → the markdown table per task and metric, the totals, one verdict line per metric
//   target <feature_list.json>           → the feature a probe asks about: the first not passing, else the last
//   commits                              → git log --name-only --format=%x00%H%x09%s on stdin as [{sha, subject, files}]
//   questions <feature_list.json> <metrics.jsonl> <commits.json> → { target, questions: [{q, kind, feature, answer, key}] }
//   score <probes.json> <answer text file> [k=v…] → probes.json with answers and scores (stdout); "Q<n> <match> · …"
//                                          lines and "score <n>/<m>" on stderr
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { deps } from "./features.mjs";

const REQUIRED = ["id", "project", "repo", "base", "features", "policy", "why"];
const OPTIONAL = ["check_cmd", "model", "spec", "brief"];
const str = (v) => typeof v === "string" && v.trim() !== "";

// Every error starts with the field it is about, so a test (or Michael) sees what to fix.
export function validateTask(t) {
  if (!t || typeof t !== "object" || Array.isArray(t)) return ["task: a JSON object"];
  const errs = [];
  for (const k of REQUIRED) if (!(k in t)) errs.push(`${k}: required`);
  // an unknown key is a typo of an optional one, which would silently change the replay
  for (const k of Object.keys(t)) if (!REQUIRED.includes(k) && !OPTIONAL.includes(k)) errs.push(`${k}: unknown key`);
  if ("id" in t && !(typeof t.id === "string" && /^[a-z0-9][a-z0-9-]*$/.test(t.id))) errs.push("id: lowercase letters, digits and dashes");
  for (const k of ["repo", "why"]) if (k in t && !str(t[k])) errs.push(`${k}: a non-empty string`);
  // the replay's clone is named after it (the run's worktree and state paths): one path segment
  if ("project" in t && !(typeof t.project === "string" && /^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(t.project))) errs.push("project: a directory name (letters, digits, . _ -)");
  if ("base" in t && !(typeof t.base === "string" && /^[0-9a-f]{40}$/.test(t.base))) errs.push("base: a full commit sha");
  if ("policy" in t && t.policy !== "build-only") errs.push("policy: must be build-only");
  for (const k of OPTIONAL) if (k in t && !str(t[k])) errs.push(`${k}: a non-empty string`);
  if ("features" in t) {
    const fs = t.features;
    if (!Array.isArray(fs) || fs.length < 1 || fs.length > 3) errs.push("features: 1 to 3 entries");
    else {
      fs.forEach((f, i) => {
        const at = `features[${i}]`;
        if (!f || typeof f !== "object" || Array.isArray(f)) return errs.push(`${at}: an object`);
        for (const k of ["id", "milestone", "description"]) if (!str(f[k])) errs.push(`${at}.${k}: a non-empty string`);
        if (!Array.isArray(f.steps) || !f.steps.length || !f.steps.every(str)) errs.push(`${at}.steps: at least one, each a string`);
        if ("after" in f && !(Array.isArray(f.after) && f.after.every(str))) errs.push(`${at}.after: a list of ids`);
      });
      const ids = fs.map(f => f?.id).filter(str);
      if (new Set(ids).size !== ids.length) errs.push("features: ids must be unique");
    }
  }
  return errs;
}

// The replay's feature list: the task's features as they were (after lists included), none passing yet.
export function seedList(task, run) {
  return { run, branch: `harness/${run}`, features: task.features.map(f => ({ ...f, passes: false })) };
}

// What an eval has spent: the sessions' total of every repeat that wrote a summary (cents, as the summaries round).
export function spent(summaries) {
  return Math.round(summaries.reduce((a, s) => a + (Number(s?.cost?.total) || 0), 0) * 100) / 100;
}

// A results dir as compare reads it: { tasks: { <id>: [summary of r1, r2 …] } }; <task>/summary.json is one repeat,
// <task>/r<N>/summary.json repeat N. The eval makes a unit's dir before its run starts, so a dir without a readable
// summary is a run that failed ({ missing: true }); a repeat with no dir (a budget or weekly stop) is null.
const MISSING = Object.freeze({ missing: true });
export function loadResult(dir) {
  const read = (f) => { try { return JSON.parse(readFileSync(f, "utf8")); } catch { return MISSING; } };
  const tasks = {};
  for (const t of readdirSync(dir, { withFileTypes: true }).filter(d => d.isDirectory()).map(d => d.name).sort()) {
    const td = join(dir, t), ns = readdirSync(td).filter(r => /^r[0-9]+$/.test(r)).map(r => Number(r.slice(1)));
    if (existsSync(join(td, "summary.json")) || !ns.length) { tasks[t] = [read(join(td, "summary.json"))]; continue; }
    tasks[t] = Array.from({ length: Math.max(...ns) }, (_, i) => ns.includes(i + 1) ? read(join(td, `r${i + 1}`, "summary.json")) : null);
  }
  return { tasks };
}

// compare (plan §4): each metric per repeat from a summary.json, the direction that is better, how it is shown.
// pass rate is pass^N per task and the share of tasks passing in total; per verified feature totals are the sums
// over tasks / their verified features (`sum`); everything else is the mean.
const n = (v) => typeof v === "number" && Number.isFinite(v) ? v : null;
const r2 = (v) => v.toFixed(2), int = (v) => String(Math.round(v));
const tokenSum = (t) => t ? (t.in ?? 0) + (t.cache_read ?? 0) + (t.cache_write ?? 0) + (t.out ?? 0) : null;
export const METRICS = [
  { name: "pass rate", higher: true, pass: true, of: s => s.missing ? 0 : s.features ? (s.features.verified === s.features.total ? 1 : 0) : null, fmt: r2 },
  { name: "$ per verified feature", higher: false, of: s => n(s.per_verified_feature?.cost), sum: s => n(s.cost?.total), fmt: v => `$${r2(v)}` },
  { name: "tokens per verified feature", higher: false, of: s => n(s.per_verified_feature?.tokens), sum: s => tokenSum(s.tokens), fmt: int },
  { name: "cache hit rate", higher: true, of: s => n(s.tokens?.cache_hit_rate), fmt: r2 },
  { name: "orientation tokens", higher: false, of: s => n(s.orientation?.tokens), fmt: int },
  { name: "context peak", higher: false, of: s => n(s.tokens?.context_peak), fmt: int },
  { name: "wall time (h)", higher: false, of: s => n(s.time?.wall_h), fmt: r2 },
  { name: "rework", higher: false, of: s => Array.isArray(s.rework) ? s.rework.length : null, fmt: v => String(Math.round(v * 100) / 100) },
];
const mean = (xs) => xs.length ? xs.reduce((a, x) => a + x, 0) / xs.length : null;
const spread = (xs) => Math.max(...xs) - Math.min(...xs);

// The repeat indices every one of the tasks has: the totals use only those, so a partial last repeat (a budget or
// weekly stop) doesn't compare a sum over fewer tasks with a full one.
export function completeRepeats(result, ids) {
  if (!ids.length) return [];
  const len = Math.min(...ids.map(id => result.tasks[id].length));
  return Array.from({ length: len }, (_, r) => r).filter(r => ids.every(id => result.tasks[id][r]));
}

// One side of a metric from a list of summaries (nulls skipped): its per-repeat values and its value, pass^N for pass
// rate (1 only if every repeat passed), the mean otherwise.
function taskSide(m, sums) {
  const values = sums.filter(Boolean).map(m.of).filter(v => v != null);
  return { values, value: !values.length ? null : m.pass ? Math.min(...values) : mean(values) };
}

// The total's side: one value per complete repeat over all the tasks; its value is the mean of those, and for pass
// rate the share of tasks with pass^N 1 over those same repeats.
function totalSide(m, result, ids) {
  const reps = completeRepeats(result, ids);
  const per = (r) => {
    const ss = ids.map(id => result.tasks[id][r]);
    if (!m.sum) return mean(ss.map(m.of).filter(v => v != null));
    const ver = ss.reduce((a, s) => a + (s.features?.verified ?? 0), 0);
    return ver ? ss.reduce((a, s) => a + (m.sum(s) ?? 0), 0) / ver : null;
  };
  const values = reps.map(per).filter(v => v != null);
  const value = !values.length ? null : m.pass ? mean(ids.map(id => taskSide(m, reps.map(r => result.tasks[id][r])).value ?? 0)) : mean(values);
  return { values, value };
}

// B against A: `no data` when a side has no value, `one sample` when a side has one, otherwise `within noise` when
// the difference is inside the larger of the two spreads (max − min across repeats), else better or worse for B.
function verdict(m, a, b) {
  if (!a.values.length || !b.values.length) return "no data";
  if (a.values.length < 2 || b.values.length < 2) return "one sample";
  const d = b.value - a.value, noise = Math.max(spread(a.values), spread(b.values));
  if (Math.abs(d) <= noise + 1e-9) return "within noise";
  return (d > 0) === m.higher ? "better" : "worse";
}

// The ids compare uses: tasks with a repeat in both results.
const common = (A, B) => Object.keys(A.tasks).filter(id => id in B.tasks && A.tasks[id].some(Boolean) && B.tasks[id].some(Boolean));

// Rows { task, metric, a, b, verdict, a_values, b_values } for every task in both results and metric, then the totals
// (task "total") over those tasks. Tasks in only one result are left out (the text names them).
export function compare(A, B) {
  const ids = common(A, B);
  const row = (task, m, a, b) => ({ task, metric: m.name, a: a.value, b: b.value, verdict: verdict(m, a, b), a_values: a.values, b_values: b.values });
  const rows = ids.flatMap(id => METRICS.map(m => row(id, m, taskSide(m, A.tasks[id]), taskSide(m, B.tasks[id]))));
  if (ids.length) rows.push(...METRICS.map(m => row("total", m, totalSide(m, A, ids), totalSide(m, B, ids))));
  return rows;
}

const show = (row, side) => {
  const v = row[side], vs = row[`${side}_values`], m = METRICS.find(x => x.name === row.metric);
  if (v == null) return "–";
  if (m.pass && row.task !== "total") return `pass^${vs.length} ${v} (${vs.reduce((a, x) => a + x, 0)}/${vs.length})`;
  return m.fmt(v);
};

// The compare output: a header per side, one table line per task and metric, the totals block, notes (tasks in one
// result only, failed runs, repeats left out, unequal N), then one verdict line per metric. `meta`: each side's
// { dir, eval } (eval.json, or null).
export function compareText(A, B, meta = [{}, {}]) {
  const rows = compare(A, B), ids = common(A, B), sides = [["A", A], ["B", B]];
  const line = (r) => `| ${r.task} | ${r.metric} | ${show(r, "a")} | ${show(r, "b")} | ${r.verdict} |`;
  const head = ["| task | metric | A | B | verdict |", "|---|---|---|---|---|"];
  const reps = (X) => Math.max(0, ...Object.values(X.tasks).map(t => t.length)), plural = (k) => `${k} repeat${k === 1 ? "" : "s"}`;
  const out = [...sides.map(([k, X], i) => {
    const e = meta[i]?.eval;
    return `${k}: ${meta[i]?.dir ?? "?"}${e ? ` (${e.sha ?? "?"} ${e.label ?? "?"}, ${plural(reps(X))})` : ""}`;
  }), "", ...head, ...rows.filter(r => r.task !== "total").map(line), "", "## Totals", "", ...head, ...rows.filter(r => r.task === "total").map(line)];
  const notes = [];
  for (const [k, X] of sides) {
    const only = Object.keys(X.tasks).filter(id => !ids.includes(id));
    if (only.length) notes.push(`only in ${k}: ${only.join(", ")}`);
    for (const id of Object.keys(X.tasks)) X.tasks[id].forEach((s, i) => s?.missing && notes.push(`${k}: ${id} r${i + 1}: no summary (the run started and wrote none, or it is unreadable): counted as not passing`));
    const all = Math.max(0, ...ids.map(id => X.tasks[id].length)), used = completeRepeats(X, ids).length;
    if (used < all) notes.push(`${k}: ${all - used} repeat(s) left out of the totals (not every task has them)`);
  }
  if (reps(A) !== reps(B)) notes.push(`A: ${plural(reps(A))}, B: ${reps(B)}: pass^N with a larger N is harder to pass`);
  if (notes.length) out.push("", ...notes);
  out.push("", "## Verdicts (B against A; noise is the spread across repeats)", "",
    ...rows.filter(r => r.task === "total").map(r => `${r.metric}: ${r.verdict} (A ${show(r, "a")}, B ${show(r, "b")})`));
  return { rows, text: out.join("\n") };
}

// probes (plan §5): what a fresh session for the task's next feature should know at its start, with the answers the
// record holds. The target is the first feature not passing, else the last one.
export function target(list) {
  const fs = list?.features ?? [];
  return (fs.find(f => !f.passes) ?? fs.at(-1))?.id ?? null;
}

// `git log --reverse --name-only --format=%x00%H%x09%s <base>..<branch>` → [{ sha, subject, files }]
export function parseCommits(text) {
  return text.split("\0").slice(1).map(c => {
    const [head, ...files] = c.split("\n"), i = head.indexOf("\t");
    return { sha: head.slice(0, i), subject: head.slice(i + 1), files: files.map(f => f.trim()).filter(Boolean) };
  });
}

// A session's final text opens with a heading or bold status as often as with the cause: the first sentence of the
// first line that has words, markdown stripped, split only where a capital follows (so "e.g. foo" stays whole).
const firstSentence = (s) => {
  const line = String(s ?? "").split("\n").map(l => l.replace(/^\s*#+\s.*$/, "").replace(/[*_`]/g, "").trim()).find(Boolean) ?? "";
  return line.split(/(?<=[.!?])\s+(?=[A-Z])/)[0].replace(/[.!?]$/, "").trim().slice(0, 80);
};

// Pure: the questions, in order: the files each other feature changed (its `<id>:` commits, the run record left out:
// a session's flip of passes rides in the same commit), what the target depends on, and what the last attempt at a
// feature failed on (asked only when its last coding row that wasn't a limit or an outage didn't pass, and didn't
// park: a park is a question, not a failure). Each key is what scoring matches: a list of items, or a sentence.
export function questions(list, rows, commits) {
  const fs = list?.features ?? [], t = target(list), qs = [];
  for (const f of fs) {
    if (f.id === t) continue;
    const files = [...new Set(commits.filter(c => c.subject.startsWith(`${f.id}:`)).flatMap(c => c.files))]
      .filter(p => !p.startsWith(".harness/runs/")).sort();
    if (files.length) qs.push({ q: `Which files did ${f.id} change?`, kind: "files", feature: f.id, answer: files.join(", "), key: files });
  }
  const tf = fs.find(f => f.id === t), d = tf ? deps(fs, tf) : [];
  if (d.length) qs.push({ q: `What does ${t} depend on?`, kind: "depends", feature: t, answer: d.join(", "), key: d });
  for (const f of fs) {
    const last = rows.filter(r => r.kind === "coding" && r.feature === f.id && !r.env).at(-1);
    if (!last || last.passes || /^PARKED:/m.test(last.final ?? "")) continue;
    const key = firstSentence(last.final);
    if (key) qs.push({ q: `What did the last attempt at ${f.id} fail on?`, kind: "fails", feature: f.id, answer: last.final, key });
  }
  return { target: t, questions: qs };
}

const norm = (s) => String(s ?? "").toLowerCase().replace(/[`"']/g, "").replace(/\s+/g, " ").trim().replace(/\.$/, "");
const items = (s) => norm(s).split(/[,\s]+/).filter(Boolean);

// Pure: the answers are the text's `Q<n>:` lines (the last one per number: a model may restate the questions first).
// exact (1): the normalized answer is the key (a list: the same items); contains (1): every key item is one of the
// answer's items (so F1 isn't found in F10, nor a.txt in data.txt), or the key sentence is in it; else miss (0).
// No model judges.
export function score(probes, text) {
  const given = {};
  for (const l of String(text ?? "").split("\n")) {
    const m = l.match(/^\W*q(\d+)\W*?[:.)][*\s]*(.*)$/i);
    if (m) given[Number(m[1])] = m[2].trim();
  }
  const qs = probes.questions.map((q, i) => {
    const a = given[i + 1] ?? "", na = norm(a), keys = Array.isArray(q.key) ? q.key.map(norm) : [norm(q.key)];
    const exact = Array.isArray(q.key) ? new Set(items(a)).size === new Set(keys).size && keys.every(k => items(a).includes(k)) : na === keys[0];
    const has = Array.isArray(q.key) ? keys.every(k => items(a).includes(k)) : na.includes(keys[0]);
    const match = !na ? "miss" : exact ? "exact" : has ? "contains" : "miss";
    return { ...q, given: a, match, score: match === "miss" ? 0 : 1 };
  });
  const points = qs.reduce((s, q) => s + q.score, 0);
  return { ...probes, questions: qs, answers: text, points, score: `${points}/${qs.length}` };
}

// A task file's errors, plus the one rule a pure check can't see: the id is its directory's name.
function validateFile(file) {
  let t;
  try { t = JSON.parse(readFileSync(file, "utf8")); } catch (e) { return [`task: not readable JSON (${e.message})`]; }
  const errs = validateTask(t);
  const dir = basename(dirname(resolve(file)));
  if (typeof t?.id === "string" && t.id !== dir) errs.push(`id: "${t.id}" differs from its directory "${dir}"`);
  return errs;
}

function taskFiles(p) {
  if (!statSync(p).isDirectory()) return [p];
  return readdirSync(p).sort().filter(d => statSync(join(p, d)).isDirectory()).map(d => join(p, d, "task.json"));
}

function main([cmd, ...args]) {
  switch (cmd) {
    case "validate": {
      if (!args.length) { console.error("usage: eval.mjs validate <task.json | dir>…"); return 2; }
      let bad = 0, seen = 0;
      for (const p of args) {
        if (!existsSync(p)) { console.log(`${p}: no such file or directory`); bad++; continue; }
        const files = taskFiles(p);
        if (!files.length) { console.log(`${p}: no */task.json`); bad++; }
        for (const f of files) {
          seen++;
          if (!existsSync(f)) { console.log(`${f}: missing`); bad++; continue; }
          for (const e of validateFile(f)) { console.log(`${f}: ${e}`); bad++; }
        }
      }
      return bad ? 1 : (console.error(`${seen} task(s) valid`), 0);
    }
    case "seed": {
      if (args.length !== 2) { console.error("usage: eval.mjs seed <task.json> <run-id>"); return 2; }
      const errs = validateFile(args[0]);
      if (errs.length) { for (const e of errs) console.error(`${args[0]}: ${e}`); return 1; }
      console.log(JSON.stringify(seedList(JSON.parse(readFileSync(args[0], "utf8")), args[1]), null, 2));
      return 0;
    }
    case "spent": {
      if (args.length !== 1) { console.error("usage: eval.mjs spent <results dir>"); return 2; }
      console.log(spent(Object.values(loadResult(args[0]).tasks).flat()));
      return 0;
    }
    case "compare": {
      if (args.length !== 2) { console.error("usage: eval.mjs compare <result dir A> <result dir B>"); return 2; }
      const sides = args.map(d => ({ dir: d, res: loadResult(d), eval: (() => { try { return JSON.parse(readFileSync(join(d, "eval.json"), "utf8")); } catch { return null; } })() }));
      for (const x of sides) if (!Object.keys(x.res.tasks).length) { console.error(`${x.dir}: no task results (<task>/summary.json or <task>/r<N>/summary.json)`); return 1; }
      const { rows, text } = compareText(sides[0].res, sides[1].res, sides);
      if (!rows.length) { console.error("no task has results in both"); return 1; }
      console.log(text);
      return 0;
    }
    case "target": {
      if (args.length !== 1) { console.error("usage: eval.mjs target <feature_list.json>"); return 2; }
      const t = target(JSON.parse(readFileSync(args[0], "utf8")));
      return t ? (console.log(t), 0) : 1;
    }
    case "commits": {   // the git log on stdin
      console.log(JSON.stringify(parseCommits(readFileSync(0, "utf8")), null, 2));
      return 0;
    }
    case "questions": {
      if (args.length !== 3) { console.error("usage: eval.mjs questions <feature_list.json> <metrics.jsonl> <commits.json>"); return 2; }
      const rows = existsSync(args[1]) ? readFileSync(args[1], "utf8").split("\n").filter(l => l.startsWith("{")).flatMap(l => { try { return [JSON.parse(l)]; } catch { return []; } }) : [];
      console.log(JSON.stringify(questions(JSON.parse(readFileSync(args[0], "utf8")), rows, JSON.parse(readFileSync(args[2], "utf8"))), null, 2));
      return 0;
    }
    case "score": {   // extra fields (model, cost, note) as key=value; numbers stay numbers
      if (args.length < 2) { console.error("usage: eval.mjs score <probes.json> <answer text file> [<key>=<value>…]"); return 2; }
      const r = score(JSON.parse(readFileSync(args[0], "utf8")), readFileSync(args[1], "utf8"));
      for (const kv of args.slice(2)) { const i = kv.indexOf("="), v = kv.slice(i + 1); r[kv.slice(0, i)] = v !== "" && Number.isFinite(Number(v)) ? Number(v) : v; }
      console.log(JSON.stringify(r, null, 2));
      for (const [i, q] of r.questions.entries()) console.error(`Q${i + 1} ${q.match} · ${q.q} · ${q.given || "(no answer)"}${q.score ? "" : ` (expected: ${Array.isArray(q.key) ? q.key.join(", ") : q.key})`}`);
      console.error(`score ${r.score}`);
      return 0;
    }
    default:
      console.error("usage: eval.mjs validate|seed|spent|compare|target|commits|questions|score …");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
