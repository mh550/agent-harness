// The retro backlog (ledger/retro-backlog.jsonl): one row per proposal id across runs. No dependencies. Every command
// takes explicit paths; writes go to <store>.tmp, then rename (a reader never sees half a file). The caller holds the
// ledger lock (the driver's ledger(), lib/backlog.sh), not this file. decisions/2026-10-26-retro-backlog.
//
//   merge <store> <proposals.json> <run> <date> → "backlog: <a> new, <s> seen again"; invalid: "backlog: retro-proposals.json
//                                           invalid: <why>", exit 1, store untouched
//   set <store> <id> <status> [--spec <p>] [--pr <u>] [--note <t>] → "backlog: <id> → <status>"; an unknown id or status:
//                                           one line, exit 1
//   list <store> [--jsonl] [--max-bytes <n>] → one line per row (proposed first, most seen first; past the cap at least
//                                           `<id> · <status>` each), or the ordered rows as JSONL (a cut list ends
//                                           {"more": n}); a missing store is "(empty)"
//   import <store> <file.jsonl>           → merge rows by id, a status only forward: "backlog: imported <n> rows (<a> new,
//                                           <u> updated)"; a bad line: exit 1, store untouched
//   validate <proposals.json>             → exit 0, or the why line and exit 1
import { readFileSync, writeFileSync, renameSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const STATUSES = ["proposed", "specced", "queued", "merged", "dropped"];   // also the list order
const SLUG = /^[a-z0-9]+(-[a-z0-9]+)*$/, MAX_PROPOSALS = 10;
const KEYS = ["id", "title", "first_seen", "runs_seen", "status", "spec", "pr", "note"];
const slug = id => typeof id === "string" && id.length <= 60 && SLUG.test(id);
// one line of at most 200 characters: a retro's title goes into later retros' prompts, where a newline could end the
// fenced list and forge a row
const cut = s => s.length > 200 ? `${s.slice(0, 199)}…` : s;   // also a why line, which goes into harness-log.md
export const oneLine = t => cut(String(t).replace(/[\s\p{Cc}]+/gu, " ").trim());

// a row in the fixed key order, unset links null
const norm = r => Object.fromEntries(KEYS.map(k => [k, r[k] ?? null]));

export function parseRows(text) {
  return text.split("\n").flatMap((l, i) => {
    if (!l.trim()) return [];
    let r;
    try { r = JSON.parse(l); } catch (e) { throw new Error(`line ${i + 1}: not JSON (${e.message})`); }
    if (!r || typeof r !== "object" || Array.isArray(r)) throw new Error(`line ${i + 1}: not an object`);
    return [r];
  });
}

export const formatRows = rows => rows.map(r => JSON.stringify(norm(r)) + "\n").join("");

// the whole file or nothing, as an invalid entry.json is skipped whole; a repeated id counts once
export function validateProposals(text) {
  let list;
  try { list = JSON.parse(text); } catch (e) { return { ok: false, why: cut(`not JSON: ${e.message}`) }; }
  if (!Array.isArray(list)) return { ok: false, why: "not a JSON list" };
  if (list.length > MAX_PROPOSALS) return { ok: false, why: `${list.length} items, at most ${MAX_PROPOSALS}` };
  for (const [i, p] of list.entries()) {
    const n = i + 1;
    if (!p || typeof p !== "object" || Array.isArray(p)) return { ok: false, why: `item ${n} is not an object` };
    if (p.id === undefined) return { ok: false, why: `item ${n} has no id` };
    if (!slug(p.id)) return { ok: false, why: cut(`item ${n} id ${JSON.stringify(p.id)} is not a kebab-case slug`) };
    if (typeof p.title !== "string" || !p.title.trim()) return { ok: false, why: `item ${n} (${p.id}) has no title` };
    if (p.evidence !== undefined && typeof p.evidence !== "string") return { ok: false, why: `item ${n} (${p.id}) evidence is not a string` };
  }
  const seen = new Set();
  return { ok: true, proposals: list.filter(p => !seen.has(p.id) && seen.add(p.id)).map(p => ({ ...p, title: oneLine(p.title) })) };
}

// a known id gets the run once; its status, title and links stay (evidence stays in the run's retro-proposals.json)
export function mergeProposals(rows, proposals, run, date) {
  const out = rows.map(r => ({ ...r })), byId = new Map(out.map(r => [r.id, r]));
  let added = 0, seen = 0;
  for (const p of proposals) {
    const r = byId.get(p.id);
    if (r) {
      seen++;
      if (!(r.runs_seen ?? []).includes(run)) r.runs_seen = [...(r.runs_seen ?? []), run];
      continue;
    }
    const n = norm({ id: p.id, title: p.title, first_seen: { run, date }, runs_seen: [run], status: "proposed" });
    out.push(n); byId.set(n.id, n); added++;
  }
  return { rows: out, added, seen };
}

// only the links given change
export function setStatus(rows, id, status, links = {}) {
  if (!STATUSES.includes(status)) throw new Error(`status must be one of ${STATUSES.join(", ")}`);
  if (!rows.some(r => r.id === id)) throw new Error(`unknown id ${id}`);
  const set = Object.fromEntries(["spec", "pr", "note"].filter(k => links[k] !== undefined).map(k => [k, links[k]]));
  return rows.map(r => r.id === id ? { ...r, status, ...set } : r);
}

// status order, then more runs_seen, then older first_seen, then id
export function orderRows(rows) {
  const key = r => [STATUSES.indexOf(r.status), -(r.runs_seen ?? []).length, r.first_seen?.date ?? "", r.id];
  return [...rows].sort((a, b) => {
    const [x, y] = [key(a), key(b)];
    for (let i = 0; i < x.length; i++) if (x[i] !== y[i]) return x[i] < y[i] ? -1 : 1;
    return 0;
  });
}

// by id: a known row moves to a later status only (a re-import never undoes a `set`), takes the links given and keeps
// its own where the row has none, keeps first_seen and title; runs_seen the union in first-seen order
export function importRows(rows, incoming, date) {
  const out = rows.map(r => ({ ...r })), byId = new Map(out.map(r => [r.id, r]));
  let added = 0, updated = 0;
  for (const [i, x] of incoming.entries()) {
    const n = i + 1;
    if (!slug(x.id)) throw new Error(`row ${n}: id ${JSON.stringify(x.id)} is not a kebab-case slug`);
    if (!STATUSES.includes(x.status)) throw new Error(`row ${n} (${x.id}): status must be one of ${STATUSES.join(", ")}`);
    if (x.runs_seen !== undefined && !Array.isArray(x.runs_seen)) throw new Error(`row ${n} (${x.id}): runs_seen is not a list`);
    const r = byId.get(x.id);
    if (r) {
      updated++;
      Object.assign(r, { status: STATUSES[Math.max(STATUSES.indexOf(x.status), STATUSES.indexOf(r.status))],
        spec: x.spec ?? r.spec ?? null, pr: x.pr ?? r.pr ?? null, note: x.note ?? r.note ?? null, runs_seen: [...new Set([...(r.runs_seen ?? []), ...(x.runs_seen ?? [])])] });
      continue;
    }
    if (typeof x.title !== "string" || !x.title.trim()) throw new Error(`row ${n} (${x.id}): no title`);
    const r2 = norm({ ...x, title: oneLine(x.title), first_seen: x.first_seen ?? { run: "import", date }, runs_seen: x.runs_seen ?? [] });
    out.push(r2); byId.set(r2.id, r2); added++;
  }
  return { rows: out, added, updated };
}

const line = r => [r.id, r.status, `seen ${(r.runs_seen ?? []).length}`, oneLine(r.title ?? ""),
  ...["spec", "pr", "note"].filter(k => r[k] != null && r[k] !== "").map(k => `${k} ${oneLine(r[k])}`)].join(" · ");
const bytes = s => Buffer.byteLength(s);

// whole lines only. Past maxBytes every row keeps at least `<id> · <status>` (what a retro reuses and cites), full
// lines going to the first rows that fit; when even those don't fit, as many as do beside "… (<n> more rows)"
export function listLines(rows, { maxBytes = Infinity } = {}) {
  const o = orderRows(rows), ls = o.map(line), short = o.map(r => `${r.id} · ${r.status}`);
  if (!ls.length) return "(empty)";
  const b = l => bytes(l + "\n"), sum = a => a.reduce((n, l) => n + b(l), 0);
  if (sum(ls) <= maxBytes) return ls.join("\n");
  let rest = sum(short), used = 0;
  if (rest <= maxBytes) return ls.map((l, i) => { rest -= b(short[i]); const x = used + b(l) + rest <= maxBytes ? l : short[i]; used += b(x); return x; }).join("\n");
  const more = k => `… (${ls.length - k} more rows)`;
  let k = 0;
  while (k < ls.length && used + b(short[k]) + b(more(k + 1)) <= maxBytes) used += b(short[k++]);
  return [...short.slice(0, k), more(k)].join("\n");
}

const readRows = p => existsSync(p) ? parseRows(readFileSync(p, "utf8")) : [];
function writeRows(p, rows) { writeFileSync(`${p}.tmp`, formatRows(rows)); renameSync(`${p}.tmp`, p); }
const today = () => new Date().toISOString().slice(0, 10);
const fail = msg => { console.error(`backlog: ${msg}`); return 1; };

function main([cmd, ...args]) {
  try {
    switch (cmd) {
      case "merge": {
        const [store, file, run, date] = args;
        if (!date) return fail("usage: merge <store> <proposals.json> <run> <date>");
        const v = validateProposals(existsSync(file) ? readFileSync(file, "utf8") : "");
        if (!v.ok) { console.log(`backlog: retro-proposals.json invalid: ${v.why.split("\n")[0]}`); return 1; }
        const { rows, added, seen } = mergeProposals(readRows(store), v.proposals, run, date);
        writeRows(store, rows);
        console.log(`backlog: ${added} new, ${seen} seen again`);
        return 0;
      }
      case "validate": {
        const v = validateProposals(existsSync(args[0] ?? "") ? readFileSync(args[0], "utf8") : "");
        if (!v.ok) { console.log(v.why.split("\n")[0]); return 1; }
        return 0;
      }
      case "set": {
        const [store, id, status, ...rest] = args, links = {};
        if (!status) return fail("usage: set <store> <id> <status> [--spec <p>] [--pr <u>] [--note <t>]");
        for (let i = 0; i < rest.length; i += 2) {
          const k = rest[i].replace(/^--/, "");
          if (!["spec", "pr", "note"].includes(k) || rest[i + 1] === undefined) return fail(`set: unknown or empty option ${rest[i]}`);
          links[k] = rest[i + 1];
        }
        writeRows(store, setStatus(readRows(store), id, status, links));
        console.log(`backlog: ${id} → ${status}`);
        return 0;
      }
      case "list": {
        const [store, ...rest] = args, mb = rest.indexOf("--max-bytes");
        const maxBytes = mb >= 0 ? Number(rest[mb + 1]) : Infinity, rows = readRows(store ?? "");
        if (rest.includes("--jsonl")) {   // whole rows that fit in maxBytes (one too big is skipped), then {"more": n} if any didn't
          let out = "", more = 0;
          const tail = n => `${JSON.stringify({ more: n })}\n`;
          const ls = orderRows(rows).map(r => JSON.stringify(norm(r)) + "\n");
          if (bytes(ls.join("")) <= maxBytes) { process.stdout.write(ls.join("")); return 0; }
          for (const l of ls) if (bytes(out + l + tail(rows.length)) <= maxBytes) out += l; else more++;
          process.stdout.write(out + tail(more));
        } else console.log(listLines(rows, { maxBytes }));
        return 0;
      }
      case "import": {
        const [store, file] = args;
        if (!file) return fail("usage: import <store> <file.jsonl>");
        const incoming = parseRows(readFileSync(file, "utf8"));
        const { rows, added, updated } = importRows(readRows(store), incoming, today());
        writeRows(store, rows);
        console.log(`backlog: imported ${incoming.length} rows (${added} new, ${updated} updated)`);
        return 0;
      }
      default:
        console.error("usage: backlog.mjs merge|set|list|import|validate …");
        return 2;
    }
  } catch (e) { return fail(e.message.split("\n")[0]); }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
