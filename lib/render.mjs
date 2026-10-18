// Render a prompt: replace {{NAME}} with the environment variable HARNESS_NAME (empty if unset).
//   render.mjs <template> [--raw] [<file> | "<Title>=<file>"]…   → the template, then each file (as a "# Title" section
//   if titled). Files after --raw are pasted as they are: gathered text (a debrief's context) may contain "{{X}}".
import { readFileSync, existsSync } from "node:fs";

const [tpl, ...rest] = process.argv.slice(2);
const fill = s => s.replace(/\{\{([A-Z_]+)\}\}/g, (_, k) => process.env[`HARNESS_${k}`] ?? "");
let raw = false;
const section = arg => {
  const i = arg.indexOf("=");
  const [title, file] = i > 0 && !existsSync(arg) ? [arg.slice(0, i), arg.slice(i + 1)] : [null, arg];
  const text = readFileSync(file, "utf8"), body = raw ? text : fill(text);
  return title ? `---\n\n# ${title}\n\n${body.trim()}\n` : body;
};
const parts = [fill(readFileSync(tpl, "utf8"))];
for (const arg of rest) { if (arg === "--raw") raw = true; else parts.push(section(arg)); }
process.stdout.write(parts.join("\n\n"));
