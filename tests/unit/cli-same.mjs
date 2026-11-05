// The unit tier's one comparison for a served script: main(argv, io) against the bytes and exit code of its CLI.
//   import { cli, sameAsCli } from "./cli-same.mjs"; await sameAsCli("features.mjs", ["summary", list], { cwd, env, input });
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const lib = script => fileURLToPath(new URL(`../../lib/${script}`, import.meta.url));

// what `node lib/<script> <argv…>` prints and exits with, from cwd; stderr swallowed (a usage line is not an answer)
export function cli(script, argv, { cwd, env, input = "" } = {}) {
  const r = spawnSync(process.execPath, [lib(script), ...argv], { cwd, input, env: { ...process.env, ...env }, maxBuffer: 1 << 28 });
  return { rc: r.status, out: r.stdout.toString() };
}

// main's answer in this process, with the io the CLI tail would give (stdin only when the call has one); its stderr
// swallowed as cli's is (a usage line in the tier's output is noise; node:test runs one test at a time)
export async function mainOf(script, argv, { cwd = process.cwd(), env, input } = {}) {
  const { main } = await import(lib(script)), err = console.error;
  console.error = () => {};
  try { return await main(argv, { cwd, env: { ...process.env, ...env }, ...input === undefined ? {} : { stdin: () => input } }); }
  finally { console.error = err; }
}

// the first byte that differs, never a deepEqual of a large value (a red's diff alone can take gigabytes)
export function sameBytes(got, want, what) {
  if (got === want) return;
  const a = Buffer.from(got), b = Buffer.from(want);
  let i = 0;
  while (i < a.length && i < b.length && a[i] === b[i]) i++;
  assert.fail(`${what}: ${a.length} bytes against the CLI's ${b.length}, first mismatch at ${i}: ${JSON.stringify(a.subarray(i, i + 40).toString())} against ${JSON.stringify(b.subarray(i, i + 40).toString())}`);
}

// asserts main's { rc, out } is the CLI's, and returns the CLI's answer so a test can also pin what it is
export async function sameAsCli(script, argv, opts = {}) {
  const want = cli(script, argv, opts), got = await mainOf(script, argv, opts), what = `${script} ${argv.join(" ")}`;
  assert.equal(got.rc, want.rc, `${what}: rc`);
  sameBytes(got.out, want.out, what);
  return want;
}
