// lib/checkdecide.mjs: the suite runner's cache and rerun decisions, one test per branch.   node --test tests/unit/checkdecide.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sameAsCli } from "./cli-same.mjs";
import { cachedAnswer, failedNames, keepRed, partialPlan, redReason, rerunChoice } from "../../lib/checkdecide.mjs";

const KEY = "0123456789abcdef", REF = "1111111111111111", REDUCED = "fedcba9876543210";
const A = "a".repeat(40), B = "b".repeat(40), C = "c".repeat(64);
const inTmp = fn => async () => { const d = mkdtempSync(join(tmpdir(), "cd-")); try { return await fn(d); } finally { rmSync(d, { recursive: true, force: true }); } };

// ---- redReason: what a red exit means ----
const fact = o => ({ rc: 1, seconds: 5, own: 5, to: "15m", limit: 900, capped: false, max: "3G", ...o });

test("checkdecide.mjs: redReason: exit 124 is a timeout, however short the run", () => {
  assert.deepEqual(redReason(fact({ rc: 124 })), { kind: "timeout", line: "timed out after 15m, exit 124 after 5 s" });
});

test("checkdecide.mjs: redReason: 137 whose own seconds reach the limit is a timeout, not the cap", () => {
  assert.deepEqual(redReason(fact({ rc: 137, seconds: 900, own: 900, capped: true })), { kind: "timeout", line: "timed out after 15m, exit 137 after 900 s" });
});

test("checkdecide.mjs: redReason: 137 with no limit (a duration dur_s can't read) is never a timeout", () => {
  assert.deepEqual(redReason(fact({ rc: 137, seconds: 900, own: 900, limit: 0 })), { kind: "exit", line: "exit 137 after 900 s" });
});

test("checkdecide.mjs: redReason: 137 under the limit in a scope at its cap is the cap", () => {
  assert.deepEqual(redReason(fact({ rc: 137, own: 899, capped: true })), { kind: "cap", line: "killed at its 3G memory cap, exit 137 after 5 s" });
});

test("checkdecide.mjs: redReason: 137 under the limit with the scope under its cap is a plain exit", () => {
  assert.deepEqual(redReason(fact({ rc: 137, own: 899 })), { kind: "exit", line: "exit 137 after 5 s" });
});

test("checkdecide.mjs: redReason: any other code is a plain exit, a capped scope or not", () => {
  assert.deepEqual(redReason(fact({ capped: true, own: 900 })), { kind: "exit", line: "exit 1 after 5 s" });
});

test("checkdecide.mjs: redReason: own decides the timeout while seconds is what is printed", () => {
  assert.equal(redReason(fact({ rc: 137, seconds: 1000, own: 899 })).kind, "exit");
  assert.equal(redReason(fact({ rc: 137, seconds: 3, own: 900 })).line, "timed out after 15m, exit 137 after 3 s");
});

// ---- cachedAnswer: whether a marker answers ----
const none = { key: KEY, fast: false, green: null, red: null, fastMarker: null };
const redMarker = "1\na b\nwall 9\ncheck: RED (exit 1 after 9 s) — last lines of /s/check.out:\n";

test("checkdecide.mjs: cachedAnswer: no key runs, whatever markers exist", () => {
  assert.deepEqual(cachedAnswer({ ...none, key: "", green: "3 tests\n" }), { answer: "run" });
  assert.deepEqual(cachedAnswer({ ...none, key: "not-a-key", red: redMarker }), { answer: "run" });
});

test("checkdecide.mjs: cachedAnswer: no marker runs", () => {
  assert.deepEqual(cachedAnswer(none), { answer: "run" });
});

test("checkdecide.mjs: cachedAnswer: a green marker answers with its count", () => {
  assert.deepEqual(cachedAnswer({ ...none, green: "3 tests\nwall 9\n" }), { answer: "green", n: "3 tests" });
});

test("checkdecide.mjs: cachedAnswer: an older empty green marker answers with no count", () => {
  assert.deepEqual(cachedAnswer({ ...none, green: "" }), { answer: "green", n: "" });
  assert.deepEqual(cachedAnswer({ ...none, green: "\nwall 9\n" }), { answer: "green", n: "" });
});

test("checkdecide.mjs: cachedAnswer: green beats a red and a fast marker", () => {
  assert.equal(cachedAnswer({ ...none, fast: true, green: "3 tests\n", red: redMarker, fastMarker: "2 tests\n" }).answer, "green");
});

test("checkdecide.mjs: cachedAnswer: a red marker answers with its exit code, names and line", () => {
  assert.deepEqual(cachedAnswer({ ...none, red: "3\na b\nwall 9\ncheck: RED (x)\n" }), { answer: "red", rc: "3", names: "a b", line: "check: RED (x)" });
});

test("checkdecide.mjs: cachedAnswer: a red marker whose first line is no number exits 1", () => {
  for (const first of ["x", "0", "", "07", "1x"]) assert.equal(cachedAnswer({ ...none, red: `${first}\na\nwall 9\nl\n` }).rc, "1", JSON.stringify(first));
  assert.equal(cachedAnswer({ ...none, red: "" }).rc, "1", "an empty file");
});

test("checkdecide.mjs: cachedAnswer: a red marker with no names has none (the whole suite)", () => {
  assert.equal(cachedAnswer({ ...none, red: "1\n\nwall 9\nl\n" }).names, "");
});

test("checkdecide.mjs: cachedAnswer: a marker cut mid-write gives what it has, the rest empty", () => {
  assert.deepEqual(cachedAnswer({ ...none, red: "2\nabc" }), { answer: "red", rc: "2", names: "abc", line: "" });
});

test("checkdecide.mjs: cachedAnswer: a fast marker answers under --fast, with its count", () => {
  assert.deepEqual(cachedAnswer({ ...none, fast: true, fastMarker: "2 tests\nwall 3\n" }), { answer: "fast", n: "2 tests" });
});

test("checkdecide.mjs: cachedAnswer: a fast marker is never read without --fast", () => {
  assert.deepEqual(cachedAnswer({ ...none, fastMarker: "2 tests\n" }), { answer: "run" });
});

test("checkdecide.mjs: cachedAnswer: a red beats a fast marker under --fast", () => {
  assert.equal(cachedAnswer({ ...none, fast: true, red: redMarker, fastMarker: "2 tests\n" }).answer, "red");
});

test("checkdecide.mjs: cachedAnswer: read's trim takes outer spaces and tabs only, a no-break space and a CR stay", () => {
  assert.equal(cachedAnswer({ ...none, green: " \t3 tests \t\n" }).n, "3 tests");
  assert.equal(cachedAnswer({ ...none, green: "\u00a03 tests\r\n" }).n, "\u00a03 tests\r");
  assert.equal(cachedAnswer({ ...none, red: " 2 \n  a b  \nwall 9\n  l \\ m  \n" }).rc, "2");
  assert.equal(cachedAnswer({ ...none, red: " 2 \n  a b  \nwall 9\n  l \\ m  \n" }).line, "l \\ m");
});

// ---- partialPlan: whether a partial run may stand for the full one ----
const plan = o => partialPlan({
  map: "CLAUDE.md:memlint README.md:readme", blobs: [`${A} CLAUDE.md`, `${B} README.md`], reduced: REDUCED,
  sidecar: `${REF}\n${B} CLAUDE.md\n${B} README.md\n`, refGreen: true,
  entries: [{ path: "CLAUDE.md", names: ["memlint"] }, { path: "README.md", names: ["readme"] }], ...o });
const row = (o, r, why) => assert.deepEqual(plan(o), { go: false, row: r }, why);

test("checkdecide.mjs: partialPlan row 4: a blank map refuses", () => {
  row({ map: "" }, "4", "empty");
  row({ map: " \t\n\v\f\r " }, "4", "whitespace [[:space:]] takes");
});

test("checkdecide.mjs: partialPlan row 4: no blob lines refuses", () => row({ blobs: [] }, "4"));

test("checkdecide.mjs: partialPlan row 4: a reduced key that isn't 16 hex refuses", () => {
  row({ reduced: "" }, "4", "empty");
  row({ reduced: REDUCED.slice(1) }, "4", "15");
  row({ reduced: REDUCED.toUpperCase() }, "4", "upper case");
});

test("checkdecide.mjs: partialPlan row 5: no sidecar refuses", () => row({ sidecar: null }, "5"));

test("checkdecide.mjs: partialPlan row 6: a malformed reference refuses", () => {
  row({ sidecar: `xyz\n${B} CLAUDE.md\n${B} README.md\n` }, "6", "not a key");
  row({ sidecar: "" }, "6", "an empty sidecar");
});

test("checkdecide.mjs: partialPlan row 6: the reference's green marker gone refuses", () => row({ refGreen: false }, "6"));

test("checkdecide.mjs: partialPlan row 7: a malformed blob line refuses, on either side", () => {
  row({ sidecar: `${REF}\nabc CLAUDE.md\n${B} README.md\n` }, "7", "a short blob in the sidecar");
  row({ sidecar: `${REF}\n${B} CLAUDE.md\n\n${B} README.md\n` }, "7", "a blank line in the sidecar");
  row({ blobs: [`${A} CLAUDE.md`, `${B} two words`] }, "7", "a path with a space in the tree's");
});

test("checkdecide.mjs: partialPlan row 7: a path twice refuses, on either side", () => {
  row({ sidecar: `${REF}\n${B} CLAUDE.md\n${A} CLAUDE.md\n` }, "7", "the sidecar's");
  row({ blobs: [`${A} CLAUDE.md`, `${B} CLAUDE.md`] }, "7", "the tree's");
});

test("checkdecide.mjs: partialPlan row 7: a different path set refuses", () => {
  row({ sidecar: `${REF}\n${B} CLAUDE.md\n${B} OTHER.md\n` }, "7", "another path");
  row({ sidecar: `${REF}\n${B} CLAUDE.md\n` }, "7", "one fewer");
});

test("checkdecide.mjs: partialPlan row 7: a sidecar with no path lines refuses", () => row({ sidecar: `${REF}\n` }, "7"));

test("checkdecide.mjs: partialPlan row 8: nothing mapped differs refuses", () => row({ blobs: [`${B} README.md`, `${B} CLAUDE.md`] }, "8"));

test("checkdecide.mjs: partialPlan row 9: a differing path that is no entry's refuses", () => row({ entries: [{ path: "README.md", names: ["readme"] }] }, "9"));

test("checkdecide.mjs: partialPlan row 10: an entry with no names refuses", () => row({ entries: [{ path: "CLAUDE.md", names: [] }] }, "10"));

test("checkdecide.mjs: partialPlan row 11: the reference and the names of what differs", () => {
  assert.deepEqual(plan(), { go: true, ref: REF, names: ["memlint"] });
});

test("checkdecide.mjs: partialPlan row 11: names in map order, each once, whatever the blob lines' order", () => {
  const entries = [{ path: "b", names: ["x", "y"] }, { path: "a", names: ["y", "z"] }, { path: "c", names: ["w"] }];
  const r = plan({ entries, blobs: [`${A} a`, `${A} b`, `${B} c`], sidecar: `${REF}\n${B} a\n${B} b\n${B} c\n` });
  assert.deepEqual(r, { go: true, ref: REF, names: ["x", "y", "z"] });
});

test("checkdecide.mjs: partialPlan: a '-' blob (a deleted mapped file) and 40- and 64-hex blobs are valid", () => {
  const entries = [{ path: "a", names: ["x"] }, { path: "b", names: ["y"] }, { path: "c", names: ["z"] }];
  assert.deepEqual(plan({ entries, blobs: [`- a`, `${C} b`, `${A} c`], sidecar: `${REF}\n${A} a\n${C} b\n${A} c\n` }), { go: true, ref: REF, names: ["x"] });
});

test("checkdecide.mjs: partialPlan: a map spelled over two lines is still a map", () => {
  assert.equal(plan({ map: "\n  CLAUDE.md:memlint\n\tREADME.md:readme\n" }).go, true);
});

// ---- rerunChoice: whether to rerun ----
test("checkdecide.mjs: rerunChoice: auto reruns the failed names, else the whole suite", () => {
  assert.equal(rerunChoice({ rerun: "auto", names: ["a"], kind: "exit" }), "failed");
  assert.equal(rerunChoice({ rerun: "auto", names: [], kind: "exit" }), "suite");
});

test("checkdecide.mjs: rerunChoice: failed reruns only named files", () => {
  assert.equal(rerunChoice({ rerun: "failed", names: ["a"], kind: "exit" }), "failed");
  assert.equal(rerunChoice({ rerun: "failed", names: [], kind: "exit" }), "");
});

test("checkdecide.mjs: rerunChoice: suite reruns the whole suite, names or none", () => {
  assert.equal(rerunChoice({ rerun: "suite", names: ["a"], kind: "exit" }), "suite");
  assert.equal(rerunChoice({ rerun: "suite", names: [], kind: "exit" }), "suite");
});

test("checkdecide.mjs: rerunChoice: off never reruns", () => {
  assert.equal(rerunChoice({ rerun: "off", names: ["a"], kind: "exit" }), "");
  assert.equal(rerunChoice({ rerun: "off", names: [], kind: "exit" }), "");
});

test("checkdecide.mjs: rerunChoice: an unknown value is auto", () => {
  assert.equal(rerunChoice({ rerun: "sometimes", names: ["a"], kind: "exit" }), "failed");
  assert.equal(rerunChoice({ rerun: "", names: [], kind: "exit" }), "suite");
});

test("checkdecide.mjs: rerunChoice: no rerun after a timeout or a cap kill, under every setting", () => {
  for (const kind of ["timeout", "cap"]) for (const rerun of ["auto", "failed", "suite", "off", "x"])
    for (const names of [[], ["a"]]) assert.equal(rerunChoice({ rerun, names, kind }), "", `${kind} ${rerun} ${names.length}`);
});

// ---- keepRed: whether a red is cached ----
const keep = o => keepRed({ key: KEY, first: "exit 1 after 5 s", last: "exit 1 after 6 s", rc0: 1, rc: 1, ...o });

test("checkdecide.mjs: keepRed: both runs a plain exit under 128, with a key, is kept", () => assert.equal(keep(), true));
test("checkdecide.mjs: keepRed: no key is not kept", () => assert.equal(keep({ key: "" }), false));
test("checkdecide.mjs: keepRed: a first run that was no plain exit is not kept", () => {
  assert.equal(keep({ first: "timed out after 15m, exit 124 after 5 s" }), false);
  assert.equal(keep({ first: "" }), false, "no answer");
});
test("checkdecide.mjs: keepRed: a last run that was no plain exit is not kept", () => assert.equal(keep({ last: "killed at its 3G memory cap, exit 137 after 5 s" }), false));
test("checkdecide.mjs: keepRed: a first run's signal code (128 up) is not kept", () => {
  assert.equal(keep({ rc0: 143 }), false);
  assert.equal(keep({ rc0: 128 }), false);
  assert.equal(keep({ rc0: 127 }), true);
});
test("checkdecide.mjs: keepRed: a rerun's signal code (128 up) is not kept", () => {
  assert.equal(keep({ rc: 143 }), false);
  assert.equal(keep({ rc: 128 }), false);
});

// ---- failedNames: the last HARNESS_FAILED= line, as sed and tail -1 and read -ra have it ----
test("checkdecide.mjs: failedNames: the last whole line's names; no line is none", () => {
  assert.deepEqual(failedNames("PASS x\nHARNESS_FAILED=a b\nHARNESS_FAILED=c  d\t e \nend\n"), ["c", "d", "e"]);
  assert.deepEqual(failedNames("echo HARNESS_FAILED=a\nok\n"), []);
  assert.deepEqual(failedNames(""), []);
});

test("checkdecide.mjs: failedNames: an empty last line clears the names, and no final newline still counts", () => {
  assert.deepEqual(failedNames("HARNESS_FAILED=a\nHARNESS_FAILED=\n"), []);
  assert.deepEqual(failedNames("HARNESS_FAILED=a"), ["a"]);
});

// ---- main: each question, the helper's bytes as the CLI's ----
const lines = out => Object.fromEntries(out.trimEnd().split("\n").map(l => { const i = l.indexOf(" "); return i < 0 ? [l, ""] : [l.slice(0, i), l.slice(i + 1)]; }));
const cacheOf = (d, files = {}) => { const c = join(d, "c"); mkdirSync(c); for (const [f, t] of Object.entries(files)) writeFileSync(join(c, f), t); return c; };
const tk = [KEY, REDUCED, `${A} CLAUDE.md`, `${B} README.md`, ": CLAUDE.md memlint m2", ": README.md readme"];
const MAP = { HARNESS_CHECK_KEY_MAP: "CLAUDE.md:memlint:m2 README.md:readme" };

test("checkdecide.mjs: main before: a green marker answers green with its count", inTmp(async d => {
  const r = await sameAsCli("checkdecide.mjs", ["before", cacheOf(d, { [`green-${KEY}`]: "3 tests\nwall 9\n" }), "0", ...tk]);
  assert.equal(r.out, "answer green\nn 3 tests\n");
}));

test("checkdecide.mjs: main before: a red marker answers red with its fields", inTmp(async d => {
  const r = await sameAsCli("checkdecide.mjs", ["before", cacheOf(d, { [`red-${KEY}`]: "3\na b\nwall 9\ncheck: RED (x) — last lines of y:\n" }), "0", ...tk]);
  assert.deepEqual(lines(r.out), { answer: "red", rc: "3", names: "a b", line: "check: RED (x) — last lines of y:" });
}));

test("checkdecide.mjs: main before: a fast marker answers only with the fast flag", inTmp(async d => {
  const c = cacheOf(d, { [`fast-${KEY}`]: "2 tests\n" });
  assert.equal((await sameAsCli("checkdecide.mjs", ["before", c, "1", ...tk])).out, "answer fast\nn 2 tests\n");
  assert.equal((await sameAsCli("checkdecide.mjs", ["before", c, "0", ...tk], { env: { HARNESS_CHECK_KEY_MAP: "" } })).out, "answer run\nrow 4\n");
}));

test("checkdecide.mjs: main before: a tree that differs from a green one in mapped paths answers partial, map order", inTmp(async d => {
  const c = cacheOf(d, { [`part-${REDUCED}`]: `${REF}\n${B} CLAUDE.md\n${A} README.md\n`, [`green-${REF}`]: "3 tests\n" });
  const r = await sameAsCli("checkdecide.mjs", ["before", c, "0", ...tk], { env: MAP });
  assert.equal(r.out, `answer partial\nref ${REF}\nnames memlint m2 readme\n`);
}));

test("checkdecide.mjs: main before: --fast never reads the sidecar", inTmp(async d => {
  const c = cacheOf(d, { [`part-${REDUCED}`]: `${REF}\n${B} CLAUDE.md\n${A} README.md\n`, [`green-${REF}`]: "3 tests\n" });
  assert.equal((await sameAsCli("checkdecide.mjs", ["before", c, "1", ...tk], { env: MAP })).out, "answer run\n");
}));

test("checkdecide.mjs: main before: the reference's green marker gone answers run, row 6; no sidecar, row 5", inTmp(async d => {
  const c = cacheOf(d, { [`part-${REDUCED}`]: `${REF}\n${B} CLAUDE.md\n${A} README.md\n` });
  assert.equal((await sameAsCli("checkdecide.mjs", ["before", c, "0", ...tk], { env: MAP })).out, "answer run\nrow 6\n");
  rmSync(join(c, `part-${REDUCED}`));
  assert.equal((await sameAsCli("checkdecide.mjs", ["before", c, "0", ...tk], { env: MAP })).out, "answer run\nrow 5\n");
}));

test("checkdecide.mjs: main before: a tree key that isn't one answers run, whatever the cache holds", inTmp(async d => {
  const c = cacheOf(d, { "green-oops": "3 tests\n" });
  assert.equal((await sameAsCli("checkdecide.mjs", ["before", c, "0", "oops"], { env: MAP })).out, "answer run\n");
}));

test("checkdecide.mjs: main before: a directory where a marker should be is no marker", inTmp(async d => {
  const c = cacheOf(d); mkdirSync(join(c, `green-${KEY}`));
  assert.equal((await sameAsCli("checkdecide.mjs", ["before", c, "0", KEY], { env: { HARNESS_CHECK_KEY_MAP: "" } })).out, "answer run\nrow 4\n");
}));

const F7 = ["5", "6", "15m", "900", "0", "3G"];

test("checkdecide.mjs: main guard: the first run's words, the choice and the last HARNESS_FAILED= names", inTmp(async d => {
  const out = join(d, "o"); writeFileSync(out, "x\nHARNESS_FAILED=old\nHARNESS_FAILED=a b\n");
  const r = await sameAsCli("checkdecide.mjs", ["guard", "1", ...F7, "auto", out]);
  assert.equal(r.out, "first exit 1 after 5 s\nhow failed\nnames a b\n");
}));

test("checkdecide.mjs: main guard: a timeout still names what failed, and chooses no rerun", inTmp(async d => {
  const out = join(d, "o"); writeFileSync(out, "HARNESS_FAILED=a\n");
  const r = await sameAsCli("checkdecide.mjs", ["guard", "124", ...F7, "auto", out]);
  assert.equal(r.out, "first timed out after 15m, exit 124 after 5 s\nhow \nnames a\n");
}));

test("checkdecide.mjs: main guard: an output that isn't there has no names", inTmp(async d => {
  const r = await sameAsCli("checkdecide.mjs", ["guard", "1", ...F7, "auto", join(d, "none")]);
  assert.equal(r.out, "first exit 1 after 5 s\nhow suite\nnames \n");
}));

test("checkdecide.mjs: main last: the last run's words and whether its red is kept", async () => {
  const yes = await sameAsCli("checkdecide.mjs", ["last", "1", ...F7, "exit 1 after 4 s", "1", KEY]);
  assert.equal(yes.out, "last exit 1 after 5 s\nkeep 1\n");
  const no = await sameAsCli("checkdecide.mjs", ["last", "124", ...F7, "exit 1 after 4 s", "1", KEY]);
  assert.equal(no.out, "last timed out after 15m, exit 124 after 5 s\nkeep 0\n");
});

test("checkdecide.mjs: main why: the words alone", async () => {
  assert.equal((await sameAsCli("checkdecide.mjs", ["why", "137", "5", "6", "15m", "900", "1", "3G"])).out, "killed at its 3G memory cap, exit 137 after 5 s\n");
});

test("checkdecide.mjs: main: no question or an unknown one exits 2 with no answer", async () => {
  assert.deepEqual(await sameAsCli("checkdecide.mjs", []), { rc: 2, out: "" });
  assert.deepEqual(await sameAsCli("checkdecide.mjs", ["nope"]), { rc: 2, out: "" });
});
