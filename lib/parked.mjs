// What runs are waiting on Michael for, and the exact commands that answer them (`harness parked`). Only inbox.mjs.
//
//   report [--json] [--runner 0|1] [--run <id>]  → stdin: one line per run, "<run>\t<project>\t<state dir>\t<run record
//                                                   dir>\t<running 0|1|2>\t<continuation queued 0|1>" (2: ending); reads parked.json, feature_list.json, INBOX.md
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { question } from "./inbox.mjs";

const PAD = " ".repeat(12);   // the value column: "  question: " is 12 wide

// The part of INBOX.md that asks about <feature> (lib/inbox.mjs: cut at the "## Answers" outside the comment).
export const questionFor = question;

// A going run takes new answers before its next session and unparks by itself (D-H26); one that is ending (its driver
// is in finish: merge, suite, retro) has no next session, so it needs a continue once it has ended. With a queue
// runner going, a plain continue would race the runner's next start for MAX_PARALLEL_RUNS. A queued continuation
// (a session-cap end queues its own) takes the answer when it starts: a second one would restart the run twice.
export function commandsFor(run, { running = false, runner = false, queued = false } = {}) {
  const answer = `harness answer ${run} "…"`;
  if (running || queued) return [answer];
  return [answer, runner ? `harness queue add --continue ${run}` : `harness continue ${run}`];
}

// parked = parsed parked.json, list = parsed feature_list.json (null: every parked id counts), inbox = INBOX.md's text.
export function entriesFor({ run, project, parked, list, inbox, running = false, ending = false, queued = false, runner = false }) {
  const fs = Array.isArray(list) ? list : list?.features ?? [];
  return Object.entries(parked ?? {})
    .filter(([id]) => !fs.find(f => f.id === id)?.passes)
    .map(([id, v]) => ({ run, project, feature: id, since: v?.at ?? "", why: v?.why ?? "", question: questionFor(inbox, id), running, ending, queued, runner }));
}

const two = n => String(n).padStart(2, "0");
function sinceText(iso, now) {
  const t = Date.parse(iso);
  if (Number.isNaN(t)) return iso || "(unknown)";
  const d = new Date(t), min = Math.max(0, Math.floor((now - t) / 60000));
  const age = min < 60 ? `${min} min` : min < 48 * 60 ? `${Math.floor(min / 60)} h` : `${Math.floor(min / 1440)} d`;
  return `${d.getFullYear()}-${two(d.getMonth() + 1)}-${two(d.getDate())} ${two(d.getHours())}:${two(d.getMinutes())} (${age} ago)`;
}

// The whole output of `harness parked`, oldest park first.
export function parkedReport(entries, { json = false, now = Date.now(), run = "" } = {}) {
  const at = e => { const t = Date.parse(e.since); return Number.isNaN(t) ? Infinity : t; };
  const es = [...entries].sort((a, b) => at(a) - at(b));
  if (json) return JSON.stringify(es.map(e => ({ run: e.run, project: e.project, feature: e.feature, since: e.since, why: e.why,
    question: e.question ?? "", running: !!e.running, ending: !!e.ending, queued: !!e.queued, commands: commandsFor(e.run, e) })), null, 2) + "\n";
  if (!es.length) return run ? `nothing parked in ${run}\n` : "nothing parked\n";
  return es.map(e => {
    const [first, ...rest] = commandsFor(e.run, e);
    const q = e.question ? e.question.split("\n").join("\n" + PAD) : "(none in INBOX.md)";
    return [`${e.run} · ${e.project} · ${e.feature}`,
      `  since:    ${sinceText(e.since, now)}`,
      `  why:      ${String(e.why).split("\n")[0]}`,
      `  question: ${q}`,
      `  running:  ${e.running ? "yes (it takes the answer before its next session)"
        : e.queued ? `${e.ending ? "ending" : "no"} (continuation queued: it takes the answer when it starts)`
        : e.ending ? "ending (answer now; continue once harness status shows it ended)" : "no"}`,
      `  next:     ${first}`, ...rest.map(c => PAD + c)].join("\n") + "\n";
  }).join("\n");
}

const readOr = (p, parse, fallback) => { try { return existsSync(p) ? parse(readFileSync(p, "utf8")) : fallback; } catch { return fallback; } };

function main([cmd, ...args]) {
  if (cmd !== "report") { console.error("usage: parked.mjs report [--json] [--runner 0|1] [--run <id>]"); return 2; }
  const opt = k => { const i = args.indexOf(k); return i < 0 ? "" : args[i + 1] ?? ""; };
  const runner = opt("--runner") === "1", all = [];
  for (const line of readFileSync(0, "utf8").split("\n").filter(Boolean)) {
    const [run, project, state, record, running, queued] = line.split("\t");
    all.push(...entriesFor({ run, project, running: running === "1", ending: running === "2", queued: queued === "1", runner,
      parked: readOr(`${state}/parked.json`, JSON.parse, {}),
      list: readOr(`${record}/feature_list.json`, JSON.parse, null),
      inbox: readOr(`${record}/INBOX.md`, t => t, "") }));
  }
  process.stdout.write(parkedReport(all, { json: args.includes("--json"), run: opt("--run") }));
  return 0;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
