// Pure helpers for structured notifications (lib/notify.sh). No dependencies.
//
//   trim [cap]                     → stdin, capped at <cap> bytes (default 3500) and ending in "…" when cut
//   actions <label> <url> […]      → ntfy's actions header "view, <label>, <url>; …" (empty urls skipped, at most 3)
//   urls <origin> <branch> <path>  → "<blob url>\t<edit url>" of that file on GitHub; exit 1, nothing printed, otherwise
//   question <before> <after>      → the lines a session added to INBOX.md above "## Answers" (a missing before = empty)
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

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
export function githubUrls(originUrl, branch, path) {
  const m = /^(?:git@github\.com:|ssh:\/\/git@github\.com\/|https:\/\/github\.com\/)([^/\s]+)\/([^/\s]+?)(?:\.git)?\/?$/.exec(originUrl ?? "");
  if (!m || !branch) return null;
  const repo = `https://github.com/${m[1]}/${m[2]}`;
  return { blob: `${repo}/blob/${branch}/${path}`, edit: `${repo}/edit/${branch}/${path}` };
}

// What the session asked in INBOX.md: lines above "## Answers" that weren't there before it (below is Michael's).
// A session that dropped the heading: every line of before counts as seen, so his old answers aren't "the question".
export function inboxQuestion(before, after) {
  const cut = t => (t ?? "").split("\n").findIndex(x => /^## Answers/.test(x));
  const top = t => { const l = (t ?? "").split("\n"), i = cut(t); return i < 0 ? l : l.slice(0, i); };
  const seen = new Map();
  for (const l of cut(after) < 0 ? (before ?? "").split("\n") : top(before)) seen.set(l, (seen.get(l) ?? 0) + 1);
  const added = top(after).filter(l => { const n = seen.get(l) ?? 0; if (n) seen.set(l, n - 1); return !n; });
  while (added.length && !added[0].trim()) added.shift();
  while (added.length && !added.at(-1).trim()) added.pop();
  return added.join("\n");
}

function main([cmd, ...args]) {
  switch (cmd) {
    case "trim":
      process.stdout.write(trimBody(readFileSync(0, "utf8"), args[0] ? Number(args[0]) : undefined));
      return 0;
    case "actions": {
      const pairs = [];
      for (let i = 0; i + 1 < args.length; i += 2) pairs.push({ label: args[i], url: args[i + 1] });
      console.log(actionsHeader(pairs));
      return 0;
    }
    case "urls": {
      const u = githubUrls(args[0], args[1], args[2]);
      if (!u) return 1;
      console.log(`${u.blob}\t${u.edit}`);
      return 0;
    }
    case "question": {
      const q = inboxQuestion(existsSync(args[0]) ? readFileSync(args[0], "utf8") : "", readFileSync(args[1], "utf8"));
      if (q) console.log(q);
      return 0;
    }
    default:
      console.error("usage: notify.mjs trim|actions|urls|question …");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
