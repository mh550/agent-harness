// lib/cli.mjs: isMain, the CLI tail every served script shares, and what a served script may not do.   node --test tests/unit/cli.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { captured, isMain, readStdin } from "../../lib/cli.mjs";
import { mainOf } from "./cli-same.mjs";

const url = name => new URL(`../../lib/${name}`, import.meta.url).href;
const SERVED = ["features", "metrics", "treekey", "testcount", "entries", "inbox", "memlint", "render", "needs", "summary", "notify"].map(s => `${s}.mjs`);
const inTmp = fn => { const d = mkdtempSync(join(tmpdir(), "cli-")); try { return fn(d); } finally { rmSync(d, { recursive: true, force: true }); } };
const node = (argv, opts = {}) => { const r = spawnSync(process.execPath, argv, { encoding: "utf8", maxBuffer: 1 << 26, ...opts }); return { rc: r.status, out: r.stdout, err: r.stderr }; };
// a script whose main is the given body, run through the shared tail
const script = (d, body) => {
  const f = join(d, "s.mjs");
  writeFileSync(f, `import { isMain, runCli } from ${JSON.stringify(url("cli.mjs"))};\nconst main = (argv, io) => { ${body} };\nif (isMain(import.meta.url)) runCli(main);\n`);
  return f;
};

test("cli.mjs: isMain is true only for the process's entry script", () => inTmp(d => {
  const say = n => `import { isMain } from ${JSON.stringify(url("cli.mjs"))};\nconsole.log("${n} " + isMain(import.meta.url));\n`;
  writeFileSync(join(d, "other.mjs"), say("other"));
  writeFileSync(join(d, "entry.mjs"), `import "./other.mjs";\n${say("entry")}`);
  assert.equal(node([join(d, "entry.mjs")]).out, "other false\nentry true\n");
  assert.equal(node(["entry.mjs"], { cwd: d }).out, "other false\nentry true\n", "a relative argv[1]");
  assert.equal(isMain(url("cli.mjs")), false, "in this test process");
}));

test("cli.mjs: the tail writes main's out to stdout and exits its rc", () => inTmp(d => {
  const r = node([script(d, `return { rc: 7, out: "a\\nb" + argv.join("") };`), "x", "y"]);
  assert.deepEqual(r, { rc: 7, out: "a\nbxy", err: "" });
}));

test("cli.mjs: the tail awaits a main that returns a promise", () => inTmp(d => {
  const r = node([script(d, `return Promise.resolve({ rc: 3, out: "later\\n" });`)]);
  assert.deepEqual(r, { rc: 3, out: "later\n", err: "" });
}));

test("cli.mjs: the tail gives main the process's cwd, environment and stdin", () => inTmp(d => {
  const r = node([script(d, `return { rc: 0, out: [io.cwd, io.env.CLI_T, io.stdin()].join("|") };`)], { cwd: d, input: "in", env: { ...process.env, CLI_T: "e" } });
  assert.equal(r.out.replace(/^.*?\|/, ""), "e|in");
  assert.equal(r.out.split("|")[0], node(["-p", "process.cwd()"], { cwd: d }).out.trim());
}));

test("cli.mjs: a main that throws prints the message on stderr, nothing on stdout, and exits 70", () => inTmp(d => {
  const r = node([script(d, `throw new Error("the reason");`)]);
  assert.equal(r.rc, 70);
  assert.equal(r.out, "");
  assert.match(r.err, /the reason/);
  const a = node([script(d, `return Promise.reject(new Error("async reason"));`)]);
  assert.equal(a.rc, 70);
  assert.match(a.err, /async reason/);
}));

// `process.stdout.write(out); process.exit(rc)` cuts a pipe at 65536 bytes when the reader is not there yet
test("cli.mjs: an answer over a pipe's 64 KB reaches a slow reader whole, with main's rc", () => inTmp(d => {
  const f = script(d, `return { rc: 5, out: "x".repeat(1 << 20) };`);
  const r = node(["-e", `const { spawnSync: s } = require("node:child_process");
    const r = s("bash", ["-c", 'node "$1" | (sleep 0.3; wc -c); echo "\${PIPESTATUS[0]}"', "_", ${JSON.stringify(f)}], { encoding: "utf8" });
    process.stdout.write(r.stdout);`]);
  assert.deepEqual(r.out.trim().split(/\s+/), [String(1 << 20), "5"]);
}));

test("cli.mjs: a reader that has gone is no failure: main's rc and an empty stderr", () => inTmp(d => {
  const f = script(d, `return { rc: 5, out: "x".repeat(1 << 20) };`), e = join(d, "err");
  const r = spawnSync("bash", ["-c", 'node "$1" 2> "$2" | true; echo "${PIPESTATUS[0]}"', "_", f, e], { encoding: "utf8" });
  assert.equal(r.stdout.trim(), "5");
  assert.equal(readFileSync(e, "utf8"), "");
}));

test("cli.mjs: a CLI with no answer and a closed stdout still exits its rc", () => inTmp(d => {
  const r = spawnSync("bash", ["-c", 'node "$1" >&-; echo $?', "_", script(d, `return { rc: 4, out: "" };`)], { encoding: "utf8" });
  assert.equal(r.stdout.trim(), "4");
}));

test("cli.mjs: a deleted cwd stops only a main that reads it", () => inTmp(d => {
  const f = script(d, `return { rc: 0, out: "fine" };`);
  const r = spawnSync("bash", ["-c", 'mkdir "$1/x" && cd "$1/x" && rmdir "$1/x" && node "$2"', "_", d, f], { encoding: "utf8" });
  assert.equal(r.stdout, "fine");
}));

test("cli.mjs: captured's say prints as console.log does, its write as process.stdout.write does, and rc is the body's", () => {
  const main = captured((argv, io, say, write) => { say("x", 1); say(1.5); say(null); say(); say(undefined); say("100%"); write("raw"); write("\n"); return argv.length + io.n; });
  assert.deepEqual(main(["a"], { n: 2 }), { rc: 3, out: "x 1\n1.5\nnull\n\nundefined\n100%\nraw\n" });
});

test("cli.mjs: readStdin reads io's stdin, and an io without one throws instead of reading fd 0", () => {
  assert.equal(readStdin({ stdin: () => "in" }), "in");
  assert.throws(() => readStdin({}), /no stdin/);
});

test("cli.mjs: importing a served script runs nothing (no output, no exit), whatever process.argv holds", () => inTmp(d => {
  for (const s of SERVED) {
    const f = join(d, "imp.mjs");
    writeFileSync(f, `await import(${JSON.stringify(url(s))});\nconsole.log("reached");\n`);
    const r = node([f, "summary", "/nonexistent", "--total"]);
    assert.deepEqual(r, { rc: 0, out: "reached\n", err: "" }, s);
  }
}));

test("cli.mjs: a served script exports main, reads process.argv, exit, cwd and stdout nowhere, fd 0 nowhere, and has no module-level let or var", async () => {
  for (const s of SERVED) {
    const text = readFileSync(fileURLToPath(url(s)), "utf8");
    assert.equal(text.match(/process[.](argv|exit|cwd|stdout)|console[.]log|readFileSync[(]0/)?.[0], undefined, s);
    assert.equal(text.match(/^(let|var) .*$/m)?.[0], undefined, s);
    assert.match(text, /^if \(isMain\(import\.meta\.url\)\) runCli\(main\);$/m, s);
    assert.equal(typeof (await import(url(s))).main, "function", s);
  }
});

test("cli.mjs: main of a served script with a bad argument never exits the process: the usage is rc 2", async () => {
  for (const s of ["features.mjs", "metrics.mjs", "entries.mjs", "inbox.mjs", "notify.mjs", "needs.mjs", "summary.mjs", "memlint.mjs"]) assert.equal((await mainOf(s, [])).rc, 2, s);
});
