// The CLI tail of a script lib/helper.mjs can serve, so the script's main answers alike in a helper and from a shell.
//   if (isMain(import.meta.url)) runCli(main);   main(argv, io) → { rc, out } or a promise of it; io: cwd, env, stdin, isTTY, columns
import { readFileSync, statSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { format } from "node:util";

export const isMain = url => !!process.argv[1] && fileURLToPath(url) === resolve(process.argv[1]);

// lazy: a script that asks nothing starts no stdout stream, and a deleted cwd stops only a main that reads it
const cliIo = () => ({
  env: process.env,
  stdin: () => readFileSync(0, "utf8"),
  get cwd() { return process.cwd(); },
  get isTTY() { return process.stdout.isTTY; },
  get columns() { return process.stdout.columns; },
});

// A throw is 70, never 1: 1 is an answer (passes, milestone-done, evidence, lint) that F's memo keeps (lib/record.sh).
// A write to a pipe is async: exiting before its callback cuts the answer at the pipe's 64 KB. A reader that has gone
// (EPIPE) ends the wait, not the answer's exit code, as console.log ignored it.
export async function runCli(main) {
  let r;
  try { r = await main(process.argv.slice(2), cliIo()); }
  catch (e) { console.error(e?.stack ?? String(e)); process.exit(70); }
  const { rc, out } = r, done = () => process.exit(rc);
  if (!out) done();
  process.stdout.on("error", done);
  process.stdout.write(out, done);
}

// main from a body that prints: say is console.log's formatting, put is process.stdout.write's, the bytes come back in
// out (never a hook on console.log: a library's stray write would join the answer); the body returns the exit code.
// say's text holds no NUL: a writer echoing a session's "\u0000" would be declined by the helper after it wrote, and run
// again by the spawn; $( ) drops a NUL anyway. put's bytes are as given (needs.mjs fields' separators).
export const captured = body => (argv, io) => {
  let out = "";
  const rc = body(argv, io, (...a) => { out += `${format(...a)}\n`.replaceAll("\0", ""); }, s => { out += s; });
  return { rc, out };
};

// The two pieces every question's main shares: a file's text, or null when it is no file (a [[ -f ]] that reads), and an
// answer of several values as labelled lines, `<label> <value>`, which bash reads with `while read -r k v`
export const textOf = p => { try { return statSync(p).isFile() ? readFileSync(p, "utf8") : null; } catch { return null; } };
export const labelled = (say, o) => Object.entries(o).forEach(([k, v]) => say(`${k} ${v}`));

// a call with no stdin (the helper's: fd 0 is its request pipe) throws this, so the helper declines and the caller
// spawns; it never reads fd 0
export class NoStdin extends Error {}
export const readStdin = io => {
  if (!io.stdin) throw new NoStdin("no stdin on this call");
  return io.stdin();
};
