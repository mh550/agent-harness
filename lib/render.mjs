// Render a prompt: replace {{NAME}} with the environment variable HARNESS_NAME (empty if unset).
//   render.mjs <template> [--raw] [<file> | "<Title>=<file>"]…   → the template, then each file (as a "# Title" section
//   if titled, one blank line apart). The file after --raw is pasted as it is: gathered text (a debrief's context, a
//   brief) may contain "{{X}}".
//   A line opening {{?X}} stays (the marker cut) only when HARNESS_X is set and not empty; one opening {{!X}} only when
//   it isn't (a project with a fast tier gets its own Suite line, prompts/parts/run.md).
//   A template line that is exactly {{SECTIONS}} is where the files go instead of the end: the static part above it is
//   the shared prefix of every session's prompt (decisions/2026-10-21-static-first-prompts).
import { readFileSync, existsSync } from "node:fs";
import { captured, isMain, runCli } from "./cli.mjs";

const fill = (s, env) => s.replace(/^\{\{([?!])([A-Z_]+)\}\}(.*)(\n|$)/gm, (_, op, k, line, nl) => (op === "?") === !!env[`HARNESS_${k}`] ? line + nl : "")
  .replace(/\{\{([A-Z_]+)\}\}/g, (_, k) => env[`HARNESS_${k}`] ?? "");

// template text, sections [{ title: string|null, body, raw }], env (HARNESS_X → value) → the prompt
export function assemble(template, sections, env) {
  const parts = sections.map(({ title, body, raw }) => {
    const b = raw ? body : fill(body, env);
    return title ? `---\n\n# ${title}\n\n${b.trim()}` : b.trimEnd();
  });
  const lines = template.split("\n"), i = lines.indexOf("{{SECTIONS}}");
  if (i < 0) return parts.length ? `${[fill(template, env).trimEnd(), ...parts].join("\n\n")}\n` : fill(template, env);
  const above = lines.slice(0, i).join("\n").trimEnd(), below = lines.slice(i + 1).join("\n").trimStart();
  return [fill(above, env), ...parts, fill(below, env)].join("\n\n");
}

export const main = captured(([tpl, ...rest], io, _say, put) => {
  let raw = false;   // for the next file only
  const sections = [];
  for (const arg of rest) {
    if (arg === "--raw") { raw = true; continue; }
    const i = arg.indexOf("=");
    const [title, file] = i > 0 && !existsSync(arg) ? [arg.slice(0, i), arg.slice(i + 1)] : [null, arg];
    sections.push({ title, body: readFileSync(file, "utf8"), raw });
    raw = false;
  }
  put(assemble(readFileSync(tpl, "utf8"), sections, io.env ?? process.env));
  return 0;
});

if (isMain(import.meta.url)) runCli(main);
