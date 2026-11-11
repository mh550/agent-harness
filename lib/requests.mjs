// lib/requests.mjs: the request inbox's rules (v1 and v2): validate a request file, the backup window, the result JSON and the requests.log line.   node lib/requests.mjs validate|result …
//
//   node lib/requests.mjs validate <file> --runs <id,id,…> --done <dir> --now <epoch> --out <dir> [--memory <ledger/memory.jsonl>]
//     → labelled lines: verdict, name, id, verb, run, [pr, review, why: a v2 request's], window, reason (last, only when
//       there is one); for an ok verdict <out>/text (an answer), <out>/brief (a continue with one) or <out>/why (a close
//       with one: `why 1`) holds the value byte for byte, so bash parses no JSON
//   node lib/requests.mjs result --id <name|-> --verb <v|-> --run <r|-> --ok <0|1> --exit <n|-> --output <file>
//                                --runner-started <0|1> [--pr <url|-> [--state merged|closed|-]]
//                                [--refused <text> | --backup-window 1] --now <epoch> --log <requests.log>
//     → the result JSON on one line (v2's twelve keys with --pr), none for --id - (bash writes it to a temp name and
//       renames it); the log line appended to --log
//   node lib/requests.mjs declines --memory <ledger/memory.jsonl> --pr <url> --ledger <dir>
//     → what a close with a why declines, one `harness memory decline` item a line (declineItems); else one line on
//       stderr, exit 1
//
// The contract is docs/specs/2026-10-22-n8n-events.md §A3 (v1, fixed: n8n-home writes the requests and reads the
// results, docs/plans/2026-11-07-A3-request-inbox.md §1) and docs/specs/2026-11-10-review-surface.md §V2-01 (v2: the
// card's merge and close on a memory PR of ledger/memory.jsonl). A reason never quotes text, brief, a why or a value
// that failed its rule.
import { appendFileSync, closeSync, constants, fstatSync, openSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { parseArgs } from "node:util";
import { captured, isMain, labelled, runCli } from "./cli.mjs";
import { WHY_MAX, badWhy, readJsonl } from "./curator.mjs";

export const ID_RULE = /^[A-Za-z0-9-]{8,64}$/;
export const RUN_RULE = /^[A-Za-z0-9._-]+$/;
export const GRACE_SECONDS = 10;
export const TEXT_MAX = 4000;
export const BRIEF_MAX = 2000;
export const OUTPUT_MAX = 2000;
export const BACKUP_REFUSAL = "backup window 03:15–04:30: queued, runner not started";
// queue add and continue read --automatic, --now, --queued, … wherever they stand, not in pairs: a brief that is one
// such word would be read as the flag (the A3 review, docs/plans/2026-11-07-A3-review.md I1)
const OPTION_WORD = /^--[a-z][a-z-]*$/;
// a v2 pr is quoted in its refusals, so it passes a URL's shape first (*default*: decisions/2026-11-10-review-surface-verbs)
export const PR_RULE = /^https:\/\/[A-Za-z0-9.-]+\/[A-Za-z0-9._~\/-]+$/;
export const PR_MAX = 200;
export const STATES = ["merged", "closed"];
const none = v => v === undefined || v === null || v === "";

const hasNul = v => typeof v === "string" ? v.includes("\0")
  : v !== null && typeof v === "object" ? Object.entries(v).some(([k, x]) => k.includes("\0") || hasNul(x)) : false;

// text, { runs: Set, done: Set, ageSeconds, memory: ledger/memory.jsonl's rows } → { verdict: ok|wait|rejected|duplicate,
// reason, v, id, verb, run, text, brief, pr, why, review }. The rules in the plan's order (§1.1), v2's after the ones
// it shares (the id, the duplicate, the run); id, verb, run and pr are set only once each has passed its own rule, so
// nothing unvalidated reaches a path, a log line or a result.
export function validateRequest(text, { runs = new Set(), done = new Set(), ageSeconds = 0, memory = [] } = {}) {
  const r = { verdict: "rejected", reason: null, v: null, id: null, verb: null, run: null, text: null, brief: null, pr: null, why: null, review: null };
  const no = reason => ({ ...r, reason });
  let q;
  try { q = JSON.parse(text); }
  catch {
    // n8n writes the final file in one write (its D25): a young unparsable file may still be being written
    return ageSeconds < GRACE_SECONDS ? { ...r, verdict: "wait" } : no("the request is not JSON (still unparsable after 10 s)");
  }
  if (q === null || typeof q !== "object" || Array.isArray(q)) return no("the request is not a JSON object");
  if (hasNul(q)) return no("the request holds a NUL byte");
  if (q.v !== 1 && q.v !== 2) return no("v is not 1 or 2");
  r.v = q.v;
  if (typeof q.id !== "string" || !ID_RULE.test(q.id)) return no("id does not match ^[A-Za-z0-9-]{8,64}$");
  r.id = q.id;
  if (done.has(q.id)) return { ...r, verdict: "duplicate", reason: `duplicate id: done/${q.id}.json already exists` };
  // *default*: one shape per version, so a v2 answer and a v1 merge are refused (decisions/2026-11-10-review-surface-verbs)
  if (q.v === 1 && q.verb !== "answer" && q.verb !== "continue") return no("verb is not answer or continue");
  if (q.v === 2 && q.verb !== "merge" && q.verb !== "close") return no("v 2 carries merge or close");
  r.verb = q.verb;
  if (typeof q.run !== "string" || !RUN_RULE.test(q.run)) return no("run does not match ^[A-Za-z0-9._-]+$");
  if (!runs.has(q.run)) return no(`no run '${q.run}' (see: harness status)`);
  r.run = q.run;
  if (q.v === 2) return memoryRequest(q, r, memory);
  // *default*: a text on a continue and a brief on an answer are ignored, not refused; an empty brief is no brief
  if (q.verb === "answer") {
    if (typeof q.text !== "string" || q.text.length < 1 || q.text.length > TEXT_MAX) return no("text must be 1-4000 characters for answer");
    r.text = q.text;
  } else if (q.brief !== undefined && q.brief !== "") {
    if (typeof q.brief !== "string" || q.brief.length > BRIEF_MAX) return no("brief must be a string of at most 2000 characters");
    if (OPTION_WORD.test(q.brief)) return no("brief may not be an option word (--…): queue add and continue would read it as one");
    r.brief = q.brief;
  }
  return { ...r, verdict: "ok" };
}

// v2: the pr a row of ledger/memory.jsonl names, of the request's run; a close's why within the hand decline's bounds
// (WHY_MAX, harness memory decline), a merge's refused (*default*: its reason is in the override count, not a row)
function memoryRequest(q, r, memory) {
  const no = reason => ({ ...r, reason });
  if (typeof q.pr !== "string" || q.pr.length > PR_MAX || !PR_RULE.test(q.pr)) return no(`pr is not a PR URL (https://<host>/<path>, at most ${PR_MAX} characters)`);
  const row = (memory ?? []).find(x => x?.url === q.pr);
  if (!row) return no(`pr ${q.pr} is not a memory PR the ledger knows (ledger/memory.jsonl)`);
  // the row's run is quoted only when it passes the run rule (a hand-edited ledger row is never echoed)
  if (row.run !== q.run) return no(`pr ${q.pr} belongs to ${typeof row.run === "string" && RUN_RULE.test(row.run) ? `run ${row.run}` : "another run"}, not ${q.run}`);
  r.pr = q.pr;
  r.review = typeof row.review === "string" ? oneLine(row.review) : null;
  if (!none(q.why)) {
    if (q.verb === "merge") return no("a merge takes no why");
    if (badWhy(q.why)) return no(`why must be one line of at most ${WHY_MAX} characters`);
    r.why = q.why;
  }
  return { ...r, verdict: "ok" };
}

// a closed PR's ledger row and its run's memory-result.json (the ledger's copy, as harness memory proposals reads it, or
// null) → { items }: what `harness memory decline` takes for a close with a why: the run (the run-level row) for the
// facts PR, <run>/<n> per rules/<n> for the rules PR (its proposals are not on it); { why } for a rules PR with none
export function declineItems(row, result) {
  if (row?.tier !== "rules") return { items: [row.run] };   // a row before N1-01 carries no tier: a facts row
  if (!result) return { why: `no memory-result.json for ${row.run} in the ledger yet` };
  const ns = (Array.isArray(result.rules) ? result.rules : []).map(o => o?.n).filter(Number.isInteger);
  return ns.length ? { items: ns.map(n => `${row.run}/${n}`) } : { why: `${row.run}'s memory-result.json has no numbered rules` };
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

// the contract's result, its ten keys in order (v2: then pr and state, merged|closed|null, and no runner started); a
// rejection ran nothing, so its exit is null and its output ""
export const resultJson = ({ v = 1, id, verb = null, run = null, ok = false, exit = null, output = "", runnerStarted = false, refused = null, pr = null, state = null, now }) => ({
  v: v === 2 ? 2 : 1, id, at: new Date(now * 1000).toISOString(), verb, run, ok: ok === true, exit, output: cutBytes(output),
  runner_started: v !== 2 && runnerStarted === true, refused, ...v === 2 ? { pr, state: STATES.includes(state) ? state : null } : {},
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

// one requests.log line: local time, key=value fields (pr= for a v2 request: pr given, null or not), the status word,
// the reason last (it may hold spaces). It takes no text, brief or why at all, so it can't carry them.
export function logLine({ now, name, verb, run, pr, ok, exit, runnerStarted, refused }) {
  const status = refused && ok !== true ? "refused" : ok === true ? "ok" : "failed";
  return [localStamp(new Date(now * 1000)), `id=${dash(name)}`, `verb=${dash(verb)}`, `run=${dash(run)}`, ...pr !== undefined ? [`pr=${dash(pr)}`] : [], status, `exit=${dash(exit)}`,
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
    const a = opts(argv, str(["runs", "done", "now", "out", "memory"].map(k => [k, { type: "string" }])));
    const file = a?.positionals[0], v = a?.values;
    if (!file || !v.done || !v.out || !/^\d+$/.test(v.now ?? "")) {
      console.error("usage: node lib/requests.mjs validate <file> --runs <id,…> --done <dir> --now <epoch> --out <dir> [--memory <memory.jsonl>]");
      return 2;
    }
    // opened without following a link, then judged on that open file: a link swapped in after bash's -L test is never read
    let text, mtime, plain = true;
    try {
      const fd = openSync(file, constants.O_RDONLY | constants.O_NOFOLLOW | constants.O_NONBLOCK);
      try { const st = fstatSync(fd); plain = st.isFile(); mtime = st.mtimeMs / 1000; if (plain) text = readFileSync(fd, "utf8"); }
      finally { closeSync(fd); }
    } catch (e) {
      if (e.code !== "ELOOP") { console.error(`requests.mjs: ${file}: ${e.code ?? e.message}`); return 2; }
      plain = false;
    }
    const now = Number(v.now);
    const runs = new Set((v.runs ?? "").split(",").filter(Boolean));
    // the ledger's rows read here, in node (a missing file is no rows: every v2 pr is unknown)
    const memory = v.memory ? readJsonl(v.memory) : [];
    const r = plain ? validateRequest(text, { runs, done: doneIds(v.done), ageSeconds: now - mtime, memory })
      : { verdict: "rejected", reason: "the request is not a regular file", v: null, id: null, verb: null, run: null, text: null, brief: null, pr: null, why: null, review: null };
    if (r.verdict === "ok") {
      if (r.text !== null) writeFileSync(join(v.out, "text"), r.text);
      if (r.brief !== null) writeFileSync(join(v.out, "brief"), r.brief);
      if (r.why !== null) writeFileSync(join(v.out, "why"), r.why);
    }
    const name = resultName(r, file.split("/").pop());
    labelled(say, { verdict: r.verdict, name: dash(name), id: dash(r.id), verb: dash(r.verb), run: dash(r.run),
      ...r.v === 2 ? { pr: dash(r.pr), review: dash(r.review), why: r.verdict === "ok" && r.why !== null ? 1 : 0 } : {},
      window: inBackupWindow(new Date(now * 1000)) ? 1 : 0, ...r.reason ? { reason: oneLine(r.reason) } : {} });
    return 0;
  }
  if (cmd === "result") {
    const keys = ["id", "verb", "run", "ok", "exit", "output", "runner-started", "refused", "backup-window", "pr", "state", "now", "log"];
    const a = opts(argv, str(keys.map(k => [k, { type: "string" }]))), v = a?.values;
    if (!v?.id || !v.log || !/^\d+$/.test(v.now ?? "") || !/^-?\d+$|^-$/.test(v.exit ?? "-") || ![undefined, "-", ...STATES].includes(v.state)
      || (v.state !== undefined && v.pr === undefined)) {
      console.error("usage: node lib/requests.mjs result --id <name> --verb <v|-> --run <r|-> --ok <0|1> --exit <n|-> --output <file> --runner-started <0|1> [--pr <url|-> [--state merged|closed|-]] [--refused <text>] --now <epoch> --log <file>");
      return 2;
    }
    const und = x => x === undefined || x === "-" ? null : x;
    let output = "";
    if (v.output) try { output = readFileSync(v.output, "utf8"); } catch { output = ""; }
    const fields = { verb: und(v.verb), run: und(v.run), ok: v.ok === "1", exit: und(v.exit) === null ? null : Number(v.exit),
      runnerStarted: v["runner-started"] === "1", refused: v.refused || (v["backup-window"] === "1" ? BACKUP_REFUSAL : null), now: Number(v.now),
      ...v.pr !== undefined ? { v: 2, pr: und(v.pr), state: und(v.state) } : {} };
    // --id -: a request with no usable name gets no result file, only its log line
    if (v.id !== "-") say(JSON.stringify(resultJson({ id: v.id, output, ...fields })));
    appendFileSync(v.log, `${logLine({ name: und(v.id), ...fields })}\n`);
    return 0;
  }
  if (cmd === "declines") {
    const a = opts(argv, str(["memory", "pr", "ledger"].map(k => [k, { type: "string" }]))), v = a?.values;
    if (!v?.memory || !v.pr || !v.ledger) { console.error("usage: node lib/requests.mjs declines --memory <memory.jsonl> --pr <url> --ledger <dir>"); return 2; }
    const row = readJsonl(v.memory).find(x => x?.url === v.pr);
    // the row's run and project name a path only when each passes the run rule (a hand-edited row is never followed)
    if (!row || !RUN_RULE.test(String(row.run ?? "")) || !RUN_RULE.test(String(row.project ?? ""))) { console.error(`no ledger row for ${v.pr} with a run and a project`); return 1; }
    let result = null;
    try { result = JSON.parse(readFileSync(join(v.ledger, row.project, row.run, "memory-result.json"), "utf8")); } catch { result = null; }
    const d = declineItems(row, result);
    if (d.why) { console.error(d.why); return 1; }
    for (const x of d.items) say(x);
    return 0;
  }
  console.error("usage: node lib/requests.mjs validate|result|declines …");
  return 2;
});

if (isMain(import.meta.url)) runCli(main);
