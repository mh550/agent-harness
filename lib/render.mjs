// Render a prompt: replace {{NAME}} with the environment variable HARNESS_NAME (empty if unset).
//   render.mjs <template> [<more files appended as-is>...]
import { readFileSync } from "node:fs";

const [tpl, ...rest] = process.argv.slice(2);
const fill = s => s.replace(/\{\{([A-Z_]+)\}\}/g, (_, k) => process.env[`HARNESS_${k}`] ?? "");
process.stdout.write([fill(readFileSync(tpl, "utf8")), ...rest.map(f => fill(readFileSync(f, "utf8")))].join("\n\n"));
