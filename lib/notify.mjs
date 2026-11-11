// Pure helpers for structured notifications (lib/notify.sh) and the needs cards' links. Only inbox.mjs.
//
//   trim [cap]                     → stdin, capped at <cap> bytes (default 3500) and ending in "…" when cut
//   actions <label> <url> […]      → ntfy's actions header "view, <label>, <url>; …" (empty urls skipped, at most 3)
//   urls <origin> <branch> <path>  → "<blob url>\t<edit url>" of that file on GitHub; exit 1, nothing printed, otherwise
//   urls compare <origin> <base> <branch> → "https://github.com/<owner>/<repo>/compare/<base>...<branch>"; exit 1 otherwise
//   question <before> <after>      → inbox.mjs question: the lines a session added to INBOX.md above "## Answers"
//   event kind=… run=… project=… feature=… title=… body=… priority=… click=… actions=… [context=…] [id=…] [memory=<file>]
//                                  → the event JSON on one line (lib/notify.sh's routed post): v1, or v2 for kind=memory
//                                    with memory=<file> (memreview.mjs card's object); an unknown kind, memory= on
//                                    another kind, or the memory kind without a readable memory=: exit 2, nothing printed
import { randomUUID } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { added } from "./inbox.mjs";
import { captured, isMain, readStdin, runCli } from "./cli.mjs";

// ntfy.sh turns a message over 4,096 bytes into an attachment; the cap leaves room for the headers' text.
export function trimBody(text, cap = 3500) {
  if (Buffer.byteLength(text) <= cap) return text;
  let out = "", n = Buffer.byteLength("…");
  for (const ch of text) {   // by code point, so a cut never splits a UTF-8 character
    const b = Buffer.byteLength(ch);
    if (n + b > cap) break;
    out += ch; n += b;
  }
  return out + "…";
}

// ntfy shows three action buttons; an action without a URL (e.g. no GitHub origin) is left out.
export const actionsHeader = actions =>
  actions.filter(a => a?.url).slice(0, 3).map(a => `view, ${a.label}, ${a.url}`).join("; ");

// The phone opens these: only a GitHub origin has them. Branch and path are joined as-is (harness/<run> keeps its /).
const repoUrl = originUrl => {
  const m = /^(?:git@github\.com:|ssh:\/\/git@github\.com\/|https:\/\/github\.com\/)([^/\s]+)\/([^/\s]+?)(?:\.git)?\/?$/.exec(originUrl ?? "");
  return m ? `https://github.com/${m[1]}/${m[2]}` : null;
};
export function githubUrls(originUrl, branch, path) {
  const repo = repoUrl(originUrl);
  if (!repo || !branch) return null;
  return { blob: `${repo}/blob/${branch}/${path}`, edit: `${repo}/edit/${branch}/${path}` };
}

// What <branch> has that <base> lacks (a conflict card's link), or null off GitHub.
export function compareUrl(originUrl, base, branch) {
  const repo = repoUrl(originUrl);
  return repo && base && branch ? `${repo}/compare/${base}...${branch}` : null;
}

// What the session asked in INBOX.md (lib/inbox.mjs's `added`; the name stays for its callers and checks).
export const inboxQuestion = added;

// The v1 event n8n-home is live against (its docs/specs/2026-10-22-harness-reporter.md §4.3; tests/fixtures/n8n-event-v1.json):
// fixed keys in a fixed order. ROUTED go to EVENT_URL first; `paused` is not in v1 and is never routed. v2
// (docs/specs/2026-11-10-review-surface.md §V1-01; tests/fixtures/n8n-event-v2-memory.json) is the memory kind alone:
// v1's 13 keys, `v` 2 and a 14th, `memory`; ROUTED_V2 route once EVENT_V2 is set too, and no v1 kind moves a byte.
export const KINDS = ["park", "needs_michael", "blocked", "ended", "debrief", "verified", "merged", "started", "limit", "other", "memory"];
export const ROUTED = ["park", "needs_michael", "blocked", "debrief"];
export const ROUTED_V2 = [...ROUTED, "memory"];
const orNull = v => (v === undefined || v === "" ? null : v);
const ID_GUARD = /^[A-Za-z0-9-]{8,64}$/;   // n8n-home's intake's: a given id names the bundle's events/<id>/ too
// f.memory: the memory kind's object (the CLI reads it from memory=<file>); on any other kind a refusal, so no v1
// event can grow a key by a call-site slip
export function buildEvent(f, now = new Date(), uuid = randomUUID) {
  if (!KINDS.includes(f.kind)) throw new Error(`not an event kind: ${f.kind}`);
  const mem = f.kind === "memory", many = f.kind === "debrief";   // a debrief covers many runs: no project, run or feature
  if (!mem && f.memory != null) throw new Error("memory= is the memory kind's");
  if (mem && (f.memory === null || typeof f.memory !== "object" || Array.isArray(f.memory))) throw new Error("the memory kind needs memory=<file>");
  const e = {
    v: mem ? 2 : 1, id: typeof f.id === "string" && ID_GUARD.test(f.id) ? f.id : uuid(), at: now.toISOString(), kind: f.kind,
    project: many ? null : orNull(f.project), run: many ? null : orNull(f.run), feature: many ? null : orNull(f.feature),
    title: f.title ?? "", body: f.body ?? "", priority: f.priority ?? "",
    click: orNull(f.click), actions: orNull(f.actions), context: orNull(f.context),
  };
  return mem ? { ...e, memory: f.memory } : e;
}

export const main = captured(([cmd, ...args], io, say, put) => {
  switch (cmd) {
    case "trim":
      put(trimBody(readStdin(io), args[0] ? Number(args[0]) : undefined));
      return 0;
    case "actions": {
      const pairs = [];
      for (let i = 0; i + 1 < args.length; i += 2) pairs.push({ label: args[i], url: args[i + 1] });
      say(actionsHeader(pairs));
      return 0;
    }
    case "urls": {
      if (args[0] === "compare") { const c = compareUrl(args[1], args[2], args[3]); if (!c) return 1; say(c); return 0; }
      const u = githubUrls(args[0], args[1], args[2]);
      if (!u) return 1;
      say(`${u.blob}\t${u.edit}`);
      return 0;
    }
    case "question": {
      const q = inboxQuestion(existsSync(args[0]) ? readFileSync(args[0], "utf8") : "", readFileSync(args[1], "utf8"));
      if (q) say(q);
      return 0;
    }
    case "event": {
      const f = {};
      for (const a of args) { const i = a.indexOf("="); if (i > 0) f[a.slice(0, i)] = a.slice(i + 1); }
      if (!KINDS.includes(f.kind)) { console.error(`notify.mjs event: not an event kind: ${f.kind ?? "(none)"}`); return 2; }
      if (f.memory === "") delete f.memory;   // an empty memory= is none: notify_event passes every field
      if (f.memory !== undefined && f.kind !== "memory") { console.error("notify.mjs event: memory= is the memory kind's"); return 2; }
      if (f.kind === "memory") {
        if (f.memory === undefined) { console.error("notify.mjs event: the memory kind needs memory=<file>"); return 2; }
        try { f.memory = JSON.parse(readFileSync(f.memory, "utf8")); } catch (e) { console.error(`notify.mjs event: memory=: ${e.message}`); return 2; }
        if (f.memory === null || typeof f.memory !== "object" || Array.isArray(f.memory)) { console.error("notify.mjs event: memory= is not a JSON object"); return 2; }
      }
      say(JSON.stringify(buildEvent(f)));
      return 0;
    }
    default:
      console.error("usage: notify.mjs trim|actions|urls|question|event …");
      return 2;
  }
});

if (isMain(import.meta.url)) runCli(main);
