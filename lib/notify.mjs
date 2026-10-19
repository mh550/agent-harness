// Pure helpers for structured notifications (lib/notify.sh). No dependencies.
//
//   trim [cap]                     → stdin, capped at <cap> bytes (default 3500) and ending in "…" when cut
//   actions <label> <url> […]      → ntfy's actions header "view, <label>, <url>; …" (empty urls skipped, at most 3)
import { readFileSync } from "node:fs";
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
    default:
      console.error("usage: notify.mjs trim|actions …");
      return 2;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
