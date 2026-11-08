// lib/requests.mjs: the request inbox's rules (v1): validate a request file, the backup window, the result JSON and the requests.log line.   node lib/requests.mjs validate|result …
//
//   node lib/requests.mjs validate <file> --runs <id,id,…> --done <dir> --now <epoch> --out <dir>
//     → labelled lines: verdict, name, id, verb, run, window, reason (last, only when there is one); for an ok verdict
//       <out>/text (an answer) or <out>/brief (a continue with one) holds the value byte for byte, so bash parses no JSON
//   node lib/requests.mjs result --id <name|-> --verb <v|-> --run <r|-> --ok <0|1> --exit <n|-> --output <file>
//                                --runner-started <0|1> [--refused <text>] --now <epoch> --log <requests.log>
//     → the result JSON on one line, none for --id - (bash writes it to a temp name and renames it); the log line appended to --log
//
// The contract is docs/specs/2026-10-22-n8n-events.md §A3, fixed: n8n-home writes the requests and reads the results
// (docs/plans/2026-11-07-A3-request-inbox.md §1). A reason never quotes text, brief or a value that failed its rule.
import { appendFileSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { parseArgs } from "node:util";
import { captured, isMain, labelled, runCli } from "./cli.mjs";

export const ID_RULE = /^[A-Za-z0-9-]{8,64}$/;
export const RUN_RULE = /^[A-Za-z0-9._-]+$/;
export const GRACE_SECONDS = 10;
export const TEXT_MAX = 4000;
export const BRIEF_MAX = 2000;
export const OUTPUT_MAX = 2000;
export const BACKUP_REFUSAL = "backup window 03:15–04:30: queued, runner not started";

const hasNul = v => typeof v === "string" ? v.includes("\0")
  : v !== null && typeof v === "object" ? Object.entries(v).some(([k, x]) => k.includes("\0") || hasNul(x)) : false;

// text, { runs: Set, done: Set, ageSeconds } → { verdict: ok|wait|rejected|duplicate, reason, id, verb, run, text, brief }.
// The rules in the plan's order (§1.1); id, verb and run are set only once each has passed its own rule, so nothing
// unvalidated reaches a path, a log line or a result.
export function validateRequest(text, { runs = new Set(), done = new Set(), ageSeconds = 0 } = {}) {
  const r = { verdict: "rejected", reason: null, id: null, verb: null, run: null, text: null, brief: null };
  const no = reason => ({ ...r, reason });
  let q;
  try { q = JSON.parse(text); }
  catch {
    // n8n writes the final file in one write (its D25): a young unparsable file may still be being written
    return ageSeconds < GRACE_SECONDS ? { ...r, verdict: "wait" } : no("the request is not JSON (still unparsable after 10 s)");
  }
  if (q === null || typeof q !== "object" || Array.isArray(q)) return no("the request is not a JSON object");
  if (hasNul(q)) return no("the request holds a NUL byte");
  if (q.v !== 1) return no("v is not 1 (this harness reads request v1)");
  if (typeof q.id !== "string" || !ID_RULE.test(q.id)) return no("id does not match ^[A-Za-z0-9-]{8,64}$");
  r.id = q.id;
  if (done.has(q.id)) return { ...r, verdict: "duplicate", reason: `duplicate id: done/${q.id}.json already exists` };
  if (q.verb !== "answer" && q.verb !== "continue") return no("verb is not answer or continue");
  r.verb = q.verb;
  if (typeof q.run !== "string" || !RUN_RULE.test(q.run)) return no("run does not match ^[A-Za-z0-9._-]+$");
  if (!runs.has(q.run)) return no(`no run '${q.run}' (see: harness status)`);
  r.run = q.run;
  // *default*: a text on a continue and a brief on an answer are ignored, not refused; an empty brief is no brief
  if (q.verb === "answer") {
    if (typeof q.text !== "string" || q.text.length < 1 || q.text.length > TEXT_MAX) return no("text must be 1-4000 characters for answer");
    r.text = q.text;
  } else if (q.brief !== undefined && q.brief !== "") {
    if (typeof q.brief !== "string" || q.brief.length > BRIEF_MAX) return no("brief must be a string of at most 2000 characters");
    r.brief = q.brief;
  }
  return { ...r, verdict: "ok" };
}

// local time 03:15:00 <= t < 04:30:00: the backup's window, when no runner is started
export function inBackupWindow(date) {
  const s = date.getHours() * 3600 + date.getMinutes() * 60 + date.getSeconds();
  return s >= 3 * 3600 + 15 * 60 && s < 4 * 3600 + 30 * 60;
}

// the first max bytes of s's UTF-8, never half a character
export function cutBytes(s, max = OUTPUT_MAX) {
  const b = Buffer.from(String(s ?? ""), "utf8");
  if (b.length <= max) return b.toString("utf8");
  let end = max;
  while (end > 0 && (b[end] & 0xc0) === 0x80) end--;
  return b.subarray(0, end).toString("utf8");
}

// the contract's result, its ten keys in order; a rejection ran nothing, so its exit is null and its output ""
export const resultJson = ({ id, verb = null, run = null, ok = false, exit = null, output = "", runnerStarted = false, refused = null, now }) => ({
  v: 1, id, at: new Date(now * 1000).toISOString(), verb, run, ok: ok === true, exit, output: cutBytes(output),
  runner_started: runnerStarted === true, refused,
});

// the name a result and a claimed request take in done/: the id, else the file's name when it passes the id rule
// (n8n names the file <id>.json, so its card looks there), else none
export function resultName(verdict, fileName) {
  if (verdict?.id) return verdict.id;
  const base = String(fileName ?? "").replace(/\.json$/, "");
  return ID_RULE.test(base) ? base : null;
}

const pad = n => String(n).padStart(2, "0");
const localStamp = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
const dash = v => v === null || v === undefined || v === "" ? "-" : String(v);
const oneLine = s => String(s).replace(/[\r\n]+/g, " ");

// one requests.log line: local time, key=value fields, the status word, the reason last (it may hold spaces). It takes
// no text or brief at all, so it can't carry them.
export function logLine({ now, name, verb, run, ok, exit, runnerStarted, refused }) {
  const status = refused && ok !== true ? "refused" : ok === true ? "ok" : "failed";
  return [localStamp(new Date(now * 1000)), `id=${dash(name)}`, `verb=${dash(verb)}`, `run=${dash(run)}`, status, `exit=${dash(exit)}`,
    ...runnerStarted ? ["runner=started"] : [], ...refused ? [`why=${oneLine(refused)}`] : []].join(" ");
}

// ids done/ already holds: a result <id>.json and a claim <id>.request.json both count, so a pass that died between
// the claim and the result never runs the request twice
const doneIds = dir => {
  try { return new Set(readdirSync(dir).filter(n => n.endsWith(".json")).map(n => n.replace(/(\.request)?\.json$/, ""))); }
  catch { return new Set(); }
};

const opts = (argv, spec) => {
  try { return parseArgs({ args: argv, options: spec, allowPositionals: true, strict: true }); } catch { return null; }
};
const str = Object.fromEntries;

export const main = captured(([cmd, ...argv], io, say) => {
  if (cmd === "validate") {
    const a = opts(argv, str(["runs", "done", "now", "out"].map(k => [k, { type: "string" }])));
    const file = a?.positionals[0], v = a?.values;
    if (!file || !v.done || !v.out || !/^\d+$/.test(v.now ?? "")) {
      console.error("usage: node lib/requests.mjs validate <file> --runs <id,…> --done <dir> --now <epoch> --out <dir>");
      return 2;
    }
    let text, mtime;
    try { text = readFileSync(file, "utf8"); mtime = statSync(file).mtimeMs / 1000; }
    catch (e) { console.error(`requests.mjs: ${file}: ${e.code ?? e.message}`); return 2; }
    const now = Number(v.now);
    const runs = new Set((v.runs ?? "").split(",").filter(Boolean));
    const r = validateRequest(text, { runs, done: doneIds(v.done), ageSeconds: now - mtime });
    if (r.verdict === "ok") {
      if (r.text !== null) writeFileSync(join(v.out, "text"), r.text);
      if (r.brief !== null) writeFileSync(join(v.out, "brief"), r.brief);
    }
    const name = resultName(r, file.split("/").pop());
    labelled(say, { verdict: r.verdict, name: dash(name), id: dash(r.id), verb: dash(r.verb), run: dash(r.run),
      window: inBackupWindow(new Date(now * 1000)) ? 1 : 0, ...r.reason ? { reason: oneLine(r.reason) } : {} });
    return 0;
  }
  if (cmd === "result") {
    const keys = ["id", "verb", "run", "ok", "exit", "output", "runner-started", "refused", "now", "log"];
    const a = opts(argv, str(keys.map(k => [k, { type: "string" }]))), v = a?.values;
    if (!v?.id || !v.log || !/^\d+$/.test(v.now ?? "") || !/^-?\d+$|^-$/.test(v.exit ?? "-")) {
      console.error("usage: node lib/requests.mjs result --id <name> --verb <v|-> --run <r|-> --ok <0|1> --exit <n|-> --output <file> --runner-started <0|1> [--refused <text>] --now <epoch> --log <file>");
      return 2;
    }
    const und = x => x === undefined || x === "-" ? null : x;
    let output = "";
    if (v.output) try { output = readFileSync(v.output, "utf8"); } catch { output = ""; }
    const fields = { verb: und(v.verb), run: und(v.run), ok: v.ok === "1", exit: und(v.exit) === null ? null : Number(v.exit),
      runnerStarted: v["runner-started"] === "1", refused: v.refused || null, now: Number(v.now) };
    // --id -: a request with no usable name gets no result file, only its log line
    if (v.id !== "-") say(JSON.stringify(resultJson({ id: v.id, output, ...fields })));
    appendFileSync(v.log, `${logLine({ name: und(v.id), ...fields })}\n`);
    return 0;
  }
  console.error("usage: node lib/requests.mjs validate|result …");
  return 2;
});

if (isMain(import.meta.url)) runCli(main);
