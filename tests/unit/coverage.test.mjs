// tests/tools/coverage.mjs: the coverage map's reducers, on a real bash trace and a real NODE_V8_COVERAGE document
// (tests/fixtures/coverage/, this box's path replaced by /ROOT).   node --test tests/unit/coverage.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { beforeTrace, formatSet, lineCounts, lineStates, main, missingFrom, mjsExecutable, paint, parseSet, ranges, relOf, shAttribute, shExecutable,
  shFunctions, shScan, subsets, tracePair, traceSet, unionOf, unranges, v8Paint, v8Set } from "../tools/coverage.mjs";

const FX = join(dirname(fileURLToPath(import.meta.url)), "../fixtures/coverage");
const fx = f => readFileSync(join(FX, f), "utf8");
const nums = s => [...s].sort((a, b) => a - b).join(" ");
const set = o => ({ covered: new Map(Object.entries(o).map(([f, r]) => [f, new Set(unranges(r))])) });

test("coverage: a trace line gives its source path and line at any nesting depth; a command's own continued text and other lines give nothing", () => {
  assert.deepEqual(tracePair("+/ROOT/bin/harness:5: sample 1"), ["/ROOT/bin/harness", 5]);
  assert.deepEqual(tracePair("+++/ROOT/lib/record.sh:82: exec"), ["/ROOT/lib/record.sh", 82]);
  for (const l of ["sub2'", "line 1'", "", "2026-11-05 23:24:48 run runt1", "+ plain trace with no file", "x +/ROOT/lib/a.sh:1: y"]) assert.equal(tracePair(l), null);
});

test("coverage: a traced path counts when it is a lib/*.sh or bin/harness under the root, however it is spelled; a project's config.sh and a harness elsewhere do not", () => {
  assert.equal(relOf("/ROOT/bin/../lib/sample.sh", "/ROOT"), "lib/sample.sh");
  assert.equal(relOf("/ROOT/tests/../bin/harness", "/ROOT"), "bin/harness");
  assert.equal(relOf("/ROOTED/lib/sample.sh", "/ROOT"), null);
  assert.equal(relOf("lib/sample.sh", "/ROOT"), null);
  const { covered, outside } = traceSet(fx("sample.xtrace"), "/ROOT");
  assert.deepEqual([...covered.keys()].sort(), ["bin/harness", "lib/sample.sh"]);
  assert.equal(nums(covered.get("bin/harness")), "3 4 5");
  assert.equal(nums(covered.get("lib/sample.sh")), "4 5 6 9 10 11 16 17 20 24 26 27 28");
  assert.deepEqual([...outside], [["/ROOT/proj/.harness/config.sh", 2]]);
  assert.equal(traceSet(fx("sample.xtrace"), "/elsewhere").covered.size, 0);
});

test("coverage: shScan finds the lines that hold a command and each multi-line statement's first line", () => {
  const { can, first } = shScan(fx("lib/sample.sh"));
  assert.equal(nums(can), "5 6 8 10 11 13 15 17 18 20 23 25 26 27 28 32");   // 29, `done < <(…)`, holds none: its loop's line stands for it
  assert.equal(nums(shExecutable(fx("lib/sample.sh"))), nums(can));
  // a `\` continuation, a `[[` left open, a `$(` left open, a here-document's body, a quoted string left open
  assert.deepEqual([7, 9, 16, 21, 22, 24, 26].map(n => first[n]), [6, 8, 15, 20, 20, 23, 25]);
  assert.deepEqual([5, 10, 17, 32].map(n => first[n]), [5, 10, 17, 32]);
});

test("coverage: shScan leaves out comments, closing words, a case's bare pattern, a function's header and a comment's quote or backslash", () => {
  const t = ["# it's a comment \\", "f() {", "  x=1   # it's", "  case $x in", "    a|b)", "      : ;;", "    *) : ;;", "  esac; }", "g() { :; }",
    "if true; then", "  :", "else", "  :", "fi", "for i in 1; do", "  :", "done", "h=${#x} n=$# ok=1", "( cd /", ")",
    'case $1 in "blocked on"* | "waiting"*) : ;; *) : ;; esac', 'case $1 in a*)', "  : ;;", "esac", "while read -r l; do", "  :", "done < <(cat f)", "{ :; } > out",
    '( cd "$p" &&', '  run "$a" "$b" )', "while read -r l; do :; done < <(cat f); out=$(grep x f)", '} > "$f" 2>&1', "fi > /dev/null", "done < <(cat f); n=$(wc -l < f)", "done < <(cat f); }"].join("\n");
  // a `case … in <pattern>)` line is a command; `done < <(…)` and `} > file` are not; a subshell's closing line and a
  // command after `done < <(…);` are (a line ending in `)` is a case pattern only inside case … esac)
  assert.equal(nums(shScan(t).can), "3 4 6 7 9 10 11 13 15 16 18 19 21 22 23 25 26 28 29 30 31 34");
});

test("coverage: shScan keeps a multi-line array and a quoted string inside a $( ) inside a string as one statement; a case arm of only ;; holds no command", () => {
  const t = ["ALLOW=(", "  Read Grep", '  "Bash(cd:*)"   # files', ")", "x=1",
    'while read -r m; do :; done <<< "$(jq -r \'try ("a: \\(if .n > 0',
    "  then 1 else 2 end)\") catch empty' <<< \"$chunk\")\"", "y=2",
    "case $k in", "  0:*|1:passes) ;;", "  *) : ;;", "esac", 'arr+=("$x") z=(1 2)', "q=$(( (a + 1) * 2 )) r=$'it\\'s'", "s=3"].join("\n");
  const { can, first } = shScan(t);
  assert.equal(nums(can), "1 5 6 8 9 11 13 14 15");
  assert.deepEqual([2, 3, 4, 7].map(n => first[n]), [1, 1, 1, 6]);
  assert.deepEqual([5, 8, 13, 14, 15].map(n => first[n]), [5, 8, 13, 14, 15]);
  // bash numbers the array at its closing line and the string's command at its last: both count for the first line
  assert.equal(nums(shAttribute(t, [4, 7]).lines), "1 6");
});

test("coverage: beforeTrace names the lines a script runs before its trace starts, its option line to the guard; a file without the guard has none", () => {
  const guard = '[[ -z ${HARNESS_XTRACE:-} ]] || source "$HARNESS_HOME/lib/xtrace.sh"   # the coverage trace';
  assert.equal(nums(beforeTrace(["#!/usr/bin/env bash", "# c", "set -uo pipefail", ': "${HARNESS_HOME:?}"', guard, "x=1"].join("\n"))), "3 4 5");
  assert.equal(nums(beforeTrace(["f() {", "  :", "}", 'if [[ ${BASH_SOURCE[0]} == "$0" ]]; then', "  set -uo pipefail", "  HARNESS_HOME=x", "  " + guard, "  f", "fi"].join("\n"))), "5 6 7");
  assert.equal(nums(beforeTrace(["set -euo pipefail", guard].join("\n"))), "1 2");
  assert.equal(nums(beforeTrace(["x=1", guard].join("\n"))), "2");
  assert.equal(beforeTrace("set -uo pipefail\nx=1\n").size, 0);
});

test("coverage: shAttribute moves a traced number to the line that holds its command, the statement's first line; a number on a line with none is dropped", () => {
  const src = fx("lib/sample.sh"), traced = traceSet(fx("sample.xtrace"), "/ROOT").covered.get("lib/sample.sh");
  const a = shAttribute(src, traced);
  // 9 → 8 (a `[[` over two lines), 16 → 15 (a `$(` over two), 24 → 23 (a string over two), 26 → 25 and 26 (`\` then &&)
  assert.equal(nums(a.lines), "5 6 8 10 11 15 17 20 23 25 26 27 28");
  assert.equal(a.dropped, 1);   // 4: `echo fed` of `done < <(echo fed)`, which bash numbers at its function's header
  // a trap's commands are numbered from line 1 (a comment); `fi`, `esac` and a line past the end hold no command: none is given to a neighbour
  const b = shAttribute(src, [1, 19, 14, 400]);
  assert.equal(nums(b.lines), "");
  assert.equal(b.dropped, 4);
});

test("coverage: shFunctions names the function around each line, and none outside one", () => {
  const fn = shFunctions(fx("lib/sample.sh"));
  assert.deepEqual([1, 4, 5, 29, 30, 31, 32].map(n => fn[n]), ["", "sample", "sample", "sample", "sample", "unused", "unused"]);
  assert.deepEqual(shFunctions("one() { :; }\nx=1\ntwo() {\n  :\n}\ny=2").slice(1), ["one", "", "two", "two", "two", ""]);
});

test("coverage: V8's nested ranges paint the innermost count: a branch not taken and a function never called did not run", () => {
  const doc = JSON.parse(fx("v8.json")), src = fx("lib/sample.mjs");
  const r = doc.result.find(r => r.url === "file:///ROOT/lib/sample.mjs"), c = paint(src.length, r.functions);
  const ran = s => c[src.indexOf(s)];
  assert.deepEqual(['const kind', '"one"', "return kind", "export function never"].map(ran), [1, 1, 1, 1]);
  assert.deepEqual(['return "big"', '"other"', "return 0", "n * 2"].map(ran), [0, 0, 0, 0]);
  // whatever order the ranges come in
  const shuffled = r.functions.map(f => ({ ...f, ranges: [...f.ranges].reverse() })).reverse();
  assert.deepEqual([...paint(src.length, shuffled)], [...c]);
});

test("coverage: a line ran when code of it ran, not its punctuation or the declaration of a function never called; partial when some code of it did not", () => {
  const src = fx("lib/sample.mjs"), doc = JSON.parse(fx("v8.json"));
  const chars = v8Paint([doc], "/ROOT", rel => fx(rel)), s = v8Set(chars);
  assert.deepEqual([...chars.keys()], ["lib/sample.mjs"]);   // run.mjs is no lib file
  const { cov, starts } = chars.get("lib/sample.mjs");
  // by characters alone: the comments ran, and so did `export const twice =`, `export` of never, `const label =`, `second:`
  assert.deepEqual(lineStates(src, cov), { covered: [1, 2, 3, 4, 5, 6, 9, 10, 12, 15, 17, 19, 20, 22, 23, 24], partial: [4, 9, 12, 15, 19, 20] });
  // 16 is a whole function body whose only outer character is its `;`, 18 a getter then `,`, 25 `} else {`: punctuation runs nothing
  const dead = [...starts].filter(s => !cov[s]);
  assert.deepEqual(lineStates(src, cov, dead), { covered: [1, 2, 3, 5, 6, 9, 10, 17, 20, 22, 23, 24], partial: [9, 20] });
  assert.equal(nums(mjsExecutable(src)), "4 5 6 7 9 10 12 13 15 16 17 18 19 20 22 23 24 26");
  // the set: lines with code; 20 ran in part (`[].map(` ran, its callback never did), 17 whole
  assert.equal(nums(s.covered.get("lib/sample.mjs")), "5 6 9 10 17 20 22 23 24");
  assert.equal(nums(s.partial.get("lib/sample.mjs")), "9 20");
  assert.deepEqual(lineStates("a\n\n  b\n", Uint8Array.from([1, 0, 0, 0, 0, 0, 0])), { covered: [1], partial: [] });
});

test("coverage: two processes' V8 documents add up: a character ran when it did in either", () => {
  const doc = JSON.parse(fx("v8.json")), other = structuredClone(doc);
  const fns = other.result.find(r => r.url.endsWith("/lib/sample.mjs")).functions;
  fns.find(f => f.functionName === "never").ranges[0].count = 1;
  const pick = fns.find(f => f.functionName === "pick"); pick.ranges = [{ ...pick.ranges[0], count: 0 }];
  const s = v8Set(v8Paint([doc, other], "/ROOT", rel => fx(rel)));
  assert.equal(nums(s.covered.get("lib/sample.mjs")), "5 6 9 10 12 13 17 20 22 23 24");   // never ran in the other process: its declaration counts now
  assert.equal(nums(s.partial.get("lib/sample.mjs")), "9 20");
});

test("coverage: mjsExecutable leaves out blank lines, line and block comments, closing punctuation and a bare else, try or finally", () => {
  assert.equal(nums(mjsExecutable("// c\nimport x from 'y';\n\n/* a\n b */\nconst f = () => {\n  return 1;\n};\n/* one line */\n  });\nf();")), "2 6 7 11");
  assert.equal(nums(mjsExecutable("if (a) {\n} else {\n} else if (b) {\n}\ntry {\n  x();\n} finally {\n}\n[\n  1,\n];")), "1 3 6 10");
});

test("coverage: line numbers round-trip through ranges, and a set's text parses back to the same set, partial lines beside", () => {
  assert.equal(ranges([5, 1, 2, 3, 9, 3, 10]), "1-3,5,9-10");
  assert.deepEqual(unranges("1-3,5,9-10"), [1, 2, 3, 5, 9, 10]);
  assert.equal(ranges([]), ""); assert.deepEqual(unranges(""), []);
  const s = { covered: new Map([["lib/b.sh", new Set([2, 3, 4])], ["lib/a.mjs", new Set([1, 7])], ["lib/empty.sh", new Set()]]), partial: new Map([["lib/a.mjs", new Set([7])]]) };
  const text = formatSet(s);
  assert.equal(text, "lib/a.mjs 1,7\nlib/b.sh 2-4\n~lib/a.mjs 7\n");
  assert.equal(formatSet(parseSet(text)), text);
  assert.equal(formatSet({ covered: new Map() }), "");
});

test("coverage: lineCounts, unionOf and missingFrom give a line's check files, every set's union and what one set lacks of another", () => {
  const sets = new Map([["a", set({ "lib/x.sh": "1-3" })], ["b", set({ "lib/x.sh": "2-5", "lib/y.mjs": "9" })]]);
  const by = lineCounts(sets);
  assert.deepEqual(by.get("lib/x.sh:2"), ["a", "b"]); assert.deepEqual(by.get("lib/x.sh:1"), ["a"]); assert.deepEqual(by.get("lib/y.mjs:9"), ["b"]);
  const u = unionOf([...sets.values()]);
  assert.equal(formatSet(u), "lib/x.sh 1-5\nlib/y.mjs 9\n");
  assert.equal(formatSet(missingFrom(u, sets.get("a"))), "lib/x.sh 4-5\nlib/y.mjs 9\n");
  assert.equal(formatSet(missingFrom(sets.get("a"), u)), "");
});

test("coverage: subsets names each check file whose lines all lie in another's, smallest superset first; equal sets name each other; an empty set is no subset", () => {
  const sets = new Map([["small", set({ "lib/x.sh": "1-2" })], ["mid", set({ "lib/x.sh": "1-4" })], ["big", set({ "lib/x.sh": "1-9", "lib/y.sh": "1" })],
    ["twin", set({ "lib/x.sh": "1-4" })], ["apart", set({ "lib/z.sh": "1" })], ["none", set({})]]);
  assert.deepEqual(subsets(sets), [
    { name: "small", size: 2, inside: ["mid", "twin", "big"] },
    { name: "mid", size: 4, inside: ["twin", "big"] },
    { name: "twin", size: 4, inside: ["mid", "big"] },
  ]);
});

test("coverage.mjs reduce reads a raw directory's traces and V8 documents into one set; tables, counts, union, covering and missing read sets", async () => {
  const d = mkdtempSync(join(tmpdir(), "cov-"));
  try {
    // a root with the samples as its lib/ and bin/, the fixtures' /ROOT replaced by it
    mkdirSync(join(d, "root/lib"), { recursive: true }); mkdirSync(join(d, "root/bin")); mkdirSync(join(d, "root/tests/checks"), { recursive: true });
    mkdirSync(join(d, "raw/one/v8"), { recursive: true }); mkdirSync(join(d, "sets"));
    writeFileSync(join(d, "root/lib/sample.sh"), fx("lib/sample.sh")); writeFileSync(join(d, "root/lib/sample.mjs"), fx("lib/sample.mjs"));
    writeFileSync(join(d, "root/bin/harness"), "#!/usr/bin/env bash\n# the sample's caller\nsource x\nsource y\nsample 1\n");
    writeFileSync(join(d, "root/tests/checks/one.sh"), "#!/usr/bin/env bash\n# tier: fast\n");
    writeFileSync(join(d, "raw/one/1.xtrace"), fx("sample.xtrace").replaceAll("/ROOT", join(d, "root")));
    writeFileSync(join(d, "raw/one/v8/coverage-1.json"), fx("v8.json").replaceAll("/ROOT", join(d, "root")));
    writeFileSync(join(d, "raw/one/v8/broken.json"), "{");
    const root = join(d, "root"), r = await main(["reduce", join(d, "raw/one")], root);
    assert.equal(r.out, "bin/harness 3-5\nlib/sample.mjs 5-6,9-10,17,20,22-24\nlib/sample.sh 5-6,8,10-11,15,17,20,23,25-28\n~lib/sample.mjs 9,20\n");
    writeFileSync(join(d, "sets/one.txt"), r.out); writeFileSync(join(d, "sets/two.txt"), "lib/sample.sh 5-6\n");
    writeFileSync(join(d, "sets/unit-sample.txt"), "lib/sample.mjs 13\n"); writeFileSync(join(d, "sets/_suite.out"), "not a set");
    assert.equal((await main(["covering", join(d, "sets"), "lib/sample.sh", "5"], root)).out, "one\ntwo\n");
    assert.equal((await main(["covering", join(d, "sets"), "lib/sample.sh", "8"], root)).out, "one\n");
    assert.match((await main(["counts", join(d, "sets")], root)).out, /^bin\/harness:3 1\n[^]*lib\/sample\.sh:5 2\nlib\/sample\.sh:6 2\nlib\/sample\.sh:8 1\n/);
    const u = (await main(["union", join(d, "sets")], root)).out;
    assert.equal(u, "bin/harness 3-5\nlib/sample.mjs 5-6,9-10,17,20,22-24\nlib/sample.sh 5-6,8,10-11,15,17,20,23,25-28\n");
    writeFileSync(join(d, "u.txt"), u);
    assert.deepEqual(await main(["missing", join(d, "u.txt"), join(d, "sets/two.txt")], root), { out: "bin/harness 3-5\nlib/sample.mjs 5-6,9-10,17,20,22-24\nlib/sample.sh 8,10-11,15,17,20,23,25-28\n", rc: 1 });
    assert.deepEqual(await main(["missing", join(d, "sets/two.txt"), join(d, "u.txt")], root), { out: "", rc: 0 });
    const t = (await main(["tables", join(d, "sets")], root)).out;
    assert.match(t, /\| `one` \| fast \| 16 \| 9 \| 25 \| 23 \|/);                       // 3 + 13 bash lines, 9 node lines, 23 only it runs
    assert.match(t, /\| `two` \| – \| 2 \| 0 \| 2 \| 0 \|/);
    assert.match(t, /\| `sample` \| 1 \| 1 \|/);                                         // the unit row: its one line no check file runs
    assert.match(t, /\| `lib\/sample\.sh` \| 16 \| 13 \| 11 \| 2 \| 0 \| 0 \| 3 \|/);     // can run, run, by 1, by 2–4, by 5–19, by 20+, by none
    assert.match(t, /\| `two` \| 2 \| `one` \|/);                                        // table 3
    assert.match(t, /\| `lib\/sample\.sh` \| 3 \| sample: 13,18 · unused: 32 \|/);       // table 5, by function
    assert.match(t, /\| `lib\/sample\.mjs` \| 9 \| 4,7,12-13,15-16,18-19,26 \|/);
    assert.equal((await main(["nope"], root)).rc, 2);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

// the shape (decisions/2026-11-05-suite-shape) took the number off the unit tier's check file: its set is unit-tier.txt,
// beside the unit-<name>.txt sets of the tests/unit files run alone, which the tables read apart by that prefix
test("coverage.mjs: the unit tier's check file (unit-tier) is a check file's set, never a unit row, as 00-unit-tier was", async () => {
  const d = mkdtempSync(join(tmpdir(), "cov-"));
  try {
    mkdirSync(join(d, "root/lib"), { recursive: true }); mkdirSync(join(d, "root/bin")); mkdirSync(join(d, "sets")); mkdirSync(join(d, "old"));
    writeFileSync(join(d, "root/lib/a.mjs"), "export const x = 1;\nexport const y = 2;\n"); writeFileSync(join(d, "root/bin/harness"), "#!/usr/bin/env bash\ntrue\n");
    const root = join(d, "root");
    for (const [dir, tier] of [["sets", "unit-tier"], ["old", "00-unit-tier"]]) {
      writeFileSync(join(d, dir, `${tier}.txt`), "lib/a.mjs 1-2\n"); writeFileSync(join(d, dir, "unit-a.txt"), "lib/a.mjs 1\n");
      assert.equal((await main(["covering", join(d, dir), "lib/a.mjs", "2"], root)).out, `${tier}\n`, dir);
      assert.equal((await main(["union", join(d, dir)], root)).out, "lib/a.mjs 1-2\n", dir);
      const t = (await main(["tables", join(d, dir)], root)).out;
      assert.ok(t.includes(`| \`${tier}\` | – | 0 | 2 | 2 | 2 |`), `${dir}: the tier's row in table 1:\n${t.slice(0, 600)}`);
      assert.ok(t.includes("| `a` | 1 | 1 |"), `${dir}: the unit file's line is one no other check file runs`);
      assert.ok(!t.includes("| `tier` |"), `${dir}: no unit row named tier`);
    }
  } finally { rmSync(d, { recursive: true, force: true }); }
});
