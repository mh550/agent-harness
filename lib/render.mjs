// Render a prompt: replace {{NAME}} with the environment variable HARNESS_NAME (empty if unset).
//   render.mjs <template> [<file> | "<Title>=<file>"]…   → the template, then each file (as a "# Title" section if titled)
import { readFileSync, existsSync } from "node:fs";

const [tpl, ...rest] = process.argv.slice(2);
const fill = s => s.replace(/\{\{([A-Z_]+)\}\}/g, (_, k) => process.env[`HARNESS_${k}`] ?? "");
const section = arg => {
  const i = arg.indexOf("=");
  const [title, file] = i > 0 && !existsSync(arg) ? [arg.slice(0, i), arg.slice(i + 1)] : [null, arg];
  const body = fill(readFileSync(file, "utf8"));
  return title ? `---\n\n# ${title}\n\n${body.trim()}\n` : body;
};
process.stdout.write([fill(readFileSync(tpl, "utf8")), ...rest.map(section)].join("\n\n"));
