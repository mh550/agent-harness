// The tracked paths a spec or brief names, and where two runs' meet (decisions/2026-10-27-same-project-starts). Pure
// functions first; then the I/O the CLI, needs.mjs's sweep and show.mjs share (local git refs, the state dirs).
//
//   overlap.mjs named <tracked file> < text     the tracked paths the text names, one per line (a directory as dir/)
//   overlap.mjs overlap <file a> <file b>       the sorted intersection of two such lists
//   overlap.mjs names < files                   "a, b, … and <k> more" (6 at most): the warning's and queue list's words
//   overlap.mjs runs <project dir> <state root> <main> <new run or ""> <spec files> < brief
//                                               "<R>\t<file>" per file another run R of the project meets
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { basename, isAbsolute, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const PATHY = /[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_.*<>-]+)+\/?/g;   // path-shaped: at least one /
const GLOB = /[*<>]/;
const RECORD = ".harness/runs/";   // the runs' own records: every run writes there
const PLANS = "docs/plans/";   // as a directory: every run writes its own plan there (a plan file named exactly counts)

const clean = (t) => t.trim().replace(/:\d+$/, "").replace(/[.,:;)]+$/, "").replace(/^(\.\/)+/, "");
const TAG = /<\/?(?:a|b|br|code|em|i|kbd|li|p|pre|span|strong|sub|sup|td|th|tt|u)\b[^>]*>/gi;   // HTML, not a <slug> glob

// Every backticked span (one line) and every path-shaped word, inside backticks or not.
export function tokens(text) {
  text = text.replace(TAG, " ");
  const out = [];
  for (const m of text.matchAll(/`([^`\n]+)`/g)) out.push(clean(m[1]));
  for (const m of text.matchAll(PATHY)) out.push(clean(m[0]));
  return out.filter(Boolean);
}

// text, tracked paths → the sorted unique entries the text names: a tracked path it equals; for a word ending in / or
// holding a glob, the directory before its first glob segment as dir/, when that directory is tracked and has two or
// more segments (tests/checks/ yes; tests/ and lib/ no: every run touches those); a word without / names a top-level
// tracked file only. Never anything under .harness/runs/.
export function named(text, tracked) {
  const files = new Set(tracked);
  const found = new Set();
  for (const t of tokens(text)) {
    if (files.has(t)) { found.add(t); continue; }
    const bare = t.replace(/\*+$/, "");   // Markdown emphasis after a file (**lib/x.sh**), else a glob (dir/6*)
    if (files.has(bare)) { found.add(bare); continue; }
    if (!t.includes("/")) continue;
    const segs = t.replace(/\/$/, "").split("/");
    const g = segs.findIndex((s) => GLOB.test(s));
    if (!t.endsWith("/") && g < 0) continue;
    const dir = segs.slice(0, g < 0 ? segs.length : g);
    if (dir.length < 2) continue;
    const d = dir.join("/") + "/";
    if (tracked.some((p) => p.startsWith(d))) found.add(d);
  }
  return [...found].filter((p) => !p.startsWith(RECORD) && p !== PLANS).sort();
}

// two lists → the sorted intersection: a file meets the same file; a dir/ meets a file under it (the file is reported)
// or a dir/ at or under it (the deeper one)
export function overlap(a, b) {
  const out = new Set();
  for (const x of a) for (const y of b) {
    if (x === y || (y.endsWith("/") && x.startsWith(y))) out.add(x);
    else if (x.endsWith("/") && y.startsWith(x)) out.add(y);
  }
  return [...out].sort();
}

// files → "a, b, … and <k> more": at most 6 named
export function names(files) {
  return files.slice(0, 6).join(", ") + (files.length > 6 ? ` and ${files.length - 6} more` : "");
}

// ---- I/O: git in the project repo (local refs only, no fetch), the runs' state dirs ----
export function gitIn(dir, gitEnv = {}) {
  return (...a) => { const r = spawnSync("git", ["-C", dir, "-c", "core.quotePath=false", ...a], { encoding: "utf8", maxBuffer: 64 << 20, env: { ...process.env, GIT_OPTIONAL_LOCKS: "0", ...gitEnv } });
    return { ok: r.status === 0, status: r.status, out: r.stdout ?? "" }; };
}

// harness/<run> (a pre-lanes run's code, else its record), then harness-lane/<run>/<m> (an origin copy without a local
// branch counts too), by milestone
export function branchesOf(git, run) {
  const refs = git("for-each-ref", "--format=%(refname)", `refs/heads/harness/${run}`, `refs/heads/harness-lane/${run}/`, `refs/remotes/origin/harness-lane/${run}/`)
    .out.split("\n").filter(Boolean);
  const name = r => r.replace(/^refs\/(heads|remotes\/origin)\//, ""), local = new Set(refs.filter(r => r.startsWith("refs/heads/")).map(name));
  return refs.filter(r => r.startsWith("refs/heads/") || !local.has(name(r))).map(r => ({ ref: r, name: name(r), milestone: name(r).split("/")[2] ?? null }))
    .sort((a, b) => (a.milestone == null ? -1 : b.milestone == null ? 1 : a.milestone.localeCompare(b.milestone)));
}

// what a run's branches change outside .harness/runs/ that main lacks (each from its merge-base): sorted paths; null
// when it has no branch left, or main can't be compared with
export function changes(dir, run, main) {
  const git = gitIn(dir), bs = branchesOf(git, run), out = new Set();
  if (!bs.length || !git("rev-parse", "--verify", "-q", main).ok) return null;
  for (const b of bs) {
    const base = git("merge-base", main, b.ref); if (!base.ok) return null;
    for (const p of git("diff", "--no-renames", "--name-only", base.out.trim(), b.ref, "--", ".", ":!.harness/runs").out.split("\n")) if (p) out.add(p);
  }
  return [...out].sort();
}

// a KEY=value file as bin/harness writes it (printf %q): a backslash escapes the next character
export function envFile(f) {
  const m = {};
  let t = ""; try { t = readFileSync(f, "utf8"); } catch {}
  for (const l of t.split("\n")) {
    const x = /^([A-Z_]+)=(.*)$/.exec(l);
    if (x) m[x[1]] = x[2].replace(/^'(.*)'$/, "$1").replace(/\\(.)/g, "$1");
  }
  return m;
}
const read = f => { try { return readFileSync(f, "utf8"); } catch { return ""; } };
export const pidAlive = p => { if (!/^\d+$/.test(p ?? "")) return false; try { process.kill(Number(p), 0); return true; } catch (e) { return e.code === "EPERM"; } };
// a run's driver lives, or one of its lanes (a pid that is lib/lane.sh: a recycled one is not; bin/harness lane_live)
export function liveRun(state) {
  if (pidAlive(read(join(state, "driver.pid")).trim())) return true;
  let ls = []; try { ls = readdirSync(join(state, "lanes")); } catch {}
  return ls.some(m => { const p = read(join(state, "lanes", m, "pid")).trim();
    return pidAlive(p) && read(`/proc/${p}/cmdline`).replace(/\0/g, " ").includes("lib/lane.sh"); });
}
// the spec files' text (each in the project checkout, else on main), then the brief
export function specText(dir, spec, main, brief = "") {
  const git = gitIn(dir);
  return [...String(spec ?? "").split(/[\s,]+/).filter(Boolean).map(f => {
    const p = isAbsolute(f) ? f : join(dir, f);
    return existsSync(p) ? read(p) : git("show", `${main}:${f}`).out;
  }), brief].join("\n");
}

// a run's briefs: the one waiting in its state dir and those its driver committed to the record (lib/driver.sh moves them)
export function briefOf(state) {
  const m = envFile(join(state, "meta.env"));
  return [read(join(state, "brief.md")), m.WT && m.RUN_ID ? read(join(m.WT, ".harness/runs", m.RUN_ID, "brief.md")) : ""].join("\n");
}

/** I/O: each other run R of the project (a state dir under <stateRoot>/<project>/) that is alive, or ended with changes
 *  main lacks, whose files (its branches' changes and what its spec and brief name) meet what the new run's spec and
 *  brief name: [{run, files}]. Tracked: main's files and the compared runs' changes (a spec may name a file a branch adds). */
export function others(dir, stateRoot, main, newRun, spec, brief) {
  const ref = `refs/remotes/origin/${main}`, project = basename(dir), root = join(stateRoot, project), git = gitIn(dir);
  let runs = []; try { runs = readdirSync(root).filter(r => r !== newRun && existsSync(join(root, r, "meta.env"))).sort(); } catch {}
  const rs = runs.map(run => ({ run, state: join(root, run), live: liveRun(join(root, run)), ch: changes(dir, run, ref) ?? [] }))
    .filter(r => r.live || r.ch.length);
  if (!rs.length) return [];
  const tracked = [...new Set([...git("ls-tree", "-r", "--name-only", ref).out.split("\n").filter(Boolean), ...rs.flatMap(r => r.ch)])];
  const mine = named(specText(dir, spec, ref, brief), tracked);
  if (!mine.length) return [];
  return rs.map(r => ({ run: r.run, files: overlap(mine, [...r.ch, ...named(specText(dir, envFile(join(r.state, "run.env")).SPEC_FILES, ref,
    briefOf(r.state)), tracked)]) })).filter(r => r.files.length);
}

const lines = (f) => readFileSync(f, "utf8").split("\n").filter(Boolean);

function main(argv) {
  const [cmd, ...rest] = argv;
  if (cmd === "named" && rest.length === 1) {
    const out = named(readFileSync(0, "utf8"), lines(rest[0]));
    if (out.length) process.stdout.write(out.join("\n") + "\n");
    return 0;
  }
  if (cmd === "overlap" && rest.length === 2) {
    const out = overlap(lines(rest[0]), lines(rest[1]));
    if (out.length) process.stdout.write(out.join("\n") + "\n");
    return 0;
  }
  if (cmd === "names" && rest.length === 0) {
    process.stdout.write(names(readFileSync(0, "utf8").split("\n").filter(Boolean)) + "\n");
    return 0;
  }
  if (cmd === "runs" && rest.length === 5) {
    const [dir, stateRoot, main, newRun, spec] = rest;
    for (const r of others(dir, stateRoot, main, newRun, spec, readFileSync(0, "utf8")))
      for (const f of r.files) process.stdout.write(`${r.run}\t${f}\n`);
    return 0;
  }
  process.stderr.write("usage: overlap.mjs named <tracked file> < text | overlap <file a> <file b> | names < files | runs <project dir> <state root> <main> <new run> <spec files> < brief\n");
  return 2;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
