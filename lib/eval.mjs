// Replay evals: task validation, seeding, budget, compare and probe scoring. No dependencies.
//   validate <task.json | dir>…          → one line per error ("<file>: <field> …"), exit 1 if any; dirs: every */task.json
//   seed <task.json> <run-id>            → the run's feature_list.json on stdout (features verbatim, passes false)
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

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
    default:
      console.error("usage: eval.mjs validate|seed …");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
