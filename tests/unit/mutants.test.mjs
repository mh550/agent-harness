// tests/tools/mutants.mjs: the mutation sample's seeded pick and its four kinds of change.   node --test tests/unit/mutants.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { KINDS, applyTo, caughtBy, change, codeEnd, edits, main, mutate, pick, risky, rng, shuffle, tableRows } from "../tools/mutants.mjs";

const first = () => 0, last = () => 0.999;   // a generator that always takes the first, or the last, choice

test("mutants: the seeded generator repeats: one seed gives one order every time, another seed another", () => {
  const draw = seed => { const r = rng(seed); return [r(), r(), r(), r()]; };
  assert.deepEqual(draw(7), draw(7));
  assert.notDeepEqual(draw(7), draw(8));
  assert.ok(draw(7).every(x => x >= 0 && x < 1));
  const list = Array.from({ length: 30 }, (_, i) => i);
  assert.deepEqual(shuffle(list, rng(3)), shuffle(list, rng(3)));
  assert.notDeepEqual(shuffle(list, rng(3)), shuffle(list, rng(4)));
  assert.deepEqual([...shuffle(list, rng(3))].sort((a, b) => a - b), list);
});

test("mutants: a line's code ends where its trailing comment begins; a # or // inside quotes or a parameter is no comment", () => {
  assert.equal(codeEnd("x=1   # it's", "sh"), 6);
  assert.equal(codeEnd('echo "a # b" # c', "sh"), 13);
  assert.equal(codeEnd("n=${#x} m=$#", "sh"), 12);
  assert.equal(codeEnd("# all comment", "sh"), 0);
  assert.equal(codeEnd('const a = "http://x"; // c', "mjs"), 22);
  assert.equal(codeEnd("const b = a / 2;", "mjs"), 16);
  assert.equal(codeEnd("x = `a // b`; // c", "mjs"), 14);
});

test("mutants: && and || swap, a comparison flips, true, false and a whole number change; never a comment, a redirection's digit, a parameter or an arrow", () => {
  const after = (line, kind, lang) => edits(line, kind, lang).map(([i, n, to]) => line.slice(0, i) + to + line.slice(i + n));
  assert.deepEqual(after("a && b || c   # d && e", "andor", "sh"), ["a || b || c   # d && e", "a && b && c   # d && e"]);
  assert.deepEqual(after("x ||= y && z;", "andor", "mjs"), ["x ||= y || z;"]);
  assert.deepEqual(after('[[ $a -ge 2 ]] && (( b <= 3 )) && [[ $c == "$d" ]]', "compare", "sh"),
    ['[[ $a -gt 2 ]] && (( b <= 3 )) && [[ $c == "$d" ]]', '[[ $a -ge 2 ]] && (( b < 3 )) && [[ $c == "$d" ]]', '[[ $a -ge 2 ]] && (( b <= 3 )) && [[ $c != "$d" ]]']);
  assert.deepEqual(after("if (a === b && c < d) return x => y >= z;", "compare", "mjs"),
    ["if (a !== b && c < d) return x => y >= z;", "if (a === b && c <= d) return x => y >= z;", "if (a === b && c < d) return x => y > z;"]);
  assert.deepEqual(after("n=0; (( n >= 3 )) && exit 1 2>&1   # 5 true", "literal", "sh"),
    ["n=1; (( n >= 3 )) && exit 1 2>&1   # 5 true", "n=0; (( n >= 4 )) && exit 1 2>&1   # 5 true", "n=0; (( n >= 3 )) && exit 2 2>&1   # 5 true"]);
  assert.deepEqual(after('echo "$1 ${2:-} $(( 10#$x ))" | tail -1 > /dev/fd/3; printf "%02d" "$x"', "literal", "sh"), []);
  assert.deepEqual(after("return a ? true : x.slice(0, 5) + y[1] + 0.5;", "literal", "mjs"),
    ["return a ? false : x.slice(0, 5) + y[1] + 0.5;", "return a ? true : x.slice(1, 5) + y[1] + 0.5;", "return a ? true : x.slice(0, 6) + y[1] + 0.5;", "return a ? true : x.slice(0, 5) + y[2] + 0.5;"]);
  assert.deepEqual(after("plain words", "andor", "sh"), []);
});

test("mutants: mutate gives one change of a kind, the generator choosing which; delete gives null for a line with code and nothing for a blank or comment line", () => {
  assert.equal(mutate("a && b || c", "andor", "sh", first), "a || b || c");
  assert.equal(mutate("a && b || c", "andor", "sh", last), "a && b && c");
  assert.equal(mutate("a && b", "compare", "sh", first), undefined);
  assert.equal(mutate("  x=1", "delete", "sh", first), null);
  assert.equal(mutate("  # only a comment", "delete", "sh", first), undefined);
  assert.equal(mutate("", "delete", "mjs", first), undefined);
  assert.equal(applyTo("a\nb\nc\n", 2, "B"), "a\nB\nc\n");
  assert.equal(applyTo("a\nb\nc\n", 2, null), "a\nc\n");
});

test("mutants: pick draws each kind in a seeded order, one mutant per line, and passes over a candidate that no longer parses", () => {
  const text = ["a && b", "x=1", "[[ $x -ge 2 ]] || y=3", "true", "z=$(( 4 + 5 ))", "c || d", "[[ $p == q ]]", "(( k <= 9 )) && k=0"].join("\n") + "\n";
  const lines = text.split("\n").slice(0, 8).map((t, i) => ({ file: "lib/a.sh", line: i + 1, text: t, files: ["f1"], partial: false })), texts = { "lib/a.sh": text };
  const a = pick(lines, 11, 2, () => true, texts), b = pick(lines, 11, 2, () => true, texts);
  assert.deepEqual(a, b);
  for (const k of KINDS) { const ids = a.sample.filter(m => m.kind === k).map(m => m.id);   // numbered per kind, two at most
    assert.deepEqual(ids, ids.map((_, i) => `${k}-0${i + 1}`)); assert.ok(ids.length <= 2); }
  assert.equal(a.sample.filter(m => m.kind === "delete").length, 2);
  assert.equal(new Set(a.sample.map(m => m.line)).size, a.sample.length);         // no line has two mutants
  for (const m of a.sample) { assert.equal(m.before, lines[m.line - 1].text); assert.notEqual(m.after, m.before); assert.deepEqual(m.files, ["f1"]);
    assert.equal(m.after === null, m.kind === "delete"); }
  assert.ok(a.passed.every(p => p.why === "its line already has a mutant"));
  const seeds = [1, 2, 3, 4, 5].map(s => JSON.stringify(pick(lines, s, 2, () => true, texts).sample.map(m => `${m.kind}:${m.line}`)));
  assert.ok(new Set(seeds).size > 1);
  // nothing parses: nothing is drawn, every candidate is passed over and said
  const none = pick(lines, 11, 2, () => false, texts);
  assert.equal(none.sample.length, 0);
  assert.ok(none.passed.length >= 8 && none.passed.every(p => p.why === "no longer parses"));
  // only the changed text reaches valid, whole
  const seen = []; pick(lines.slice(1, 2), 11, 1, (f, t) => { seen.push([f, t]); return true; }, texts);
  assert.ok(seen.some(([f, t]) => f === "lib/a.sh" && t === text.replace("x=1\n", "")));
});

test("mutants.mjs pick reads the sets and the tree, drawing only lines a check file runs; apply writes the mutant and refuses a line that moved", async () => {
  const d = mkdtempSync(join(tmpdir(), "mut-"));
  try {
    mkdirSync(join(d, "root/lib"), { recursive: true }); mkdirSync(join(d, "sets"));
    const sh = "#!/usr/bin/env bash\nf() {\n  [[ $1 -ge 2 ]] && echo big\n  n=3\n  echo never\n}\n", js = "export const f = a => a === 1 || a > 5;\nexport const never = () => true;\n";
    writeFileSync(join(d, "root/lib/a.sh"), sh); writeFileSync(join(d, "root/lib/b.mjs"), js);
    writeFileSync(join(d, "sets/one.txt"), "lib/a.sh 3-4\nlib/b.mjs 1\n~lib/b.mjs 1\n"); writeFileSync(join(d, "sets/two.txt"), "lib/a.sh 3\n");
    writeFileSync(join(d, "sets/unit-b.txt"), "lib/b.mjs 2\n");   // a unit row is no check file: its line is not drawn
    const root = join(d, "root"), r = await main(["pick", join(d, "sets"), "5", "1"], root);
    const sample = r.out.split("\n").filter(Boolean).map(l => JSON.parse(l));
    assert.ok(sample.length >= 2 && sample.length <= 3);   // three lines in the pool, one mutant per line
    assert.match(r.err, /pool: 3 lines\n$/);
    for (const m of sample) {
      assert.ok((m.file === "lib/a.sh" && [3, 4].includes(m.line)) || (m.file === "lib/b.mjs" && m.line === 1));
      assert.deepEqual(m.files, m.file === "lib/a.sh" && m.line === 3 ? ["one", "two"] : ["one"]);
      assert.equal(m.partial, m.file === "lib/b.mjs");
    }
    assert.deepEqual((await main(["pick", join(d, "sets"), "5", "1"], root)).out, r.out);
    writeFileSync(join(d, "sample.jsonl"), r.out);
    const m = sample.find(m => m.file === "lib/a.sh" && m.after !== null) ?? sample[0], before = readFileSync(join(root, m.file), "utf8");
    assert.equal((await main(["apply", join(d, "sample.jsonl"), m.id], root)).out, `${m.id} ${m.file}:${m.line} ${m.kind}\n`);
    assert.equal(readFileSync(join(root, m.file), "utf8"), applyTo(before, m.line, m.after));
    assert.equal((await main(["apply", join(d, "sample.jsonl"), m.id], root)).rc, 1);   // the line is the mutant's now, not the sample's
    assert.equal((await main(["apply", join(d, "sample.jsonl"), "nope-01"], root)).rc, 2);
    assert.equal((await main(["pick", join(d, "sets")], root)).rc, 2);
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("mutants: a change never lands in message text: inside quotes in node, inside double quotes in bash (a single-quoted jq or awk program is code)", () => {
  const after = (line, kind, lang) => edits(line, kind, lang).map(([i, n, to]) => line.slice(0, i) + to + line.slice(i + n));
  assert.deepEqual(after('note "a && b: 3 tries" && (( n >= 3 ))', "andor", "sh"), ['note "a && b: 3 tries" || (( n >= 3 ))']);
  assert.deepEqual(after('note "a && b: 3 tries" && (( n >= 3 ))', "literal", "sh"), ['note "a && b: 3 tries" && (( n >= 4 ))']);
  assert.deepEqual(after(`awk 'index($0, "### ") == 1 { on = 1 }' "$f"`, "compare", "sh"), [`awk 'index($0, "### ") != 1 { on = 1 }' "$f"`]);
  assert.deepEqual(after(`[[ $a == "x == y" ]]`, "compare", "sh"), [`[[ $a != "x == y" ]]`]);
  const js = "if (a === 'b === c' && d) log(`e && f ${g} 1`, \"h || i\", 2);";
  assert.deepEqual(after(js, "andor", "mjs"), ["if (a === 'b === c' || d) log(`e && f ${g} 1`, \"h || i\", 2);"]);
  assert.deepEqual(after(js, "compare", "mjs"), ["if (a !== 'b === c' && d) log(`e && f ${g} 1`, \"h || i\", 2);"]);
  assert.deepEqual(after(js, "literal", "mjs"), ["if (a === 'b === c' && d) log(`e && f ${g} 1`, \"h || i\", 3);"]);
});

test("mutants: a line that deletes, kills, pushes or posts is never mutated: risky names it, and pick's pool leaves it out and counts it", async () => {
  for (const l of ['rm -rf "$d"', '  [[ -d $w ]] && rm -f "$o/info/alternates" && git -C "$1" prune --expire=now', 'kill -TERM "$p" 2> /dev/null', "pkill -f x",
    'git -C "$RWT" push -q origin "$RBRANCH"', "git reset --hard origin/main", 'git -C "$p" worktree remove --force "$w"', 'git branch -D "$b"', 'git update-ref -d "refs/x"',
    '"$CURL" -sS -d "$body" "$NTFY_URL"', '"$GH" pr merge "$n" --merge', "rmSync(d, { recursive: true });", "unlinkSync(f);", 'execFileSync("git", ["push", "origin", b]);']) assert.equal(risky(l), true, l);
  for (const l of ["format=$1", 'note "removed the lock"', "const term = x => x.trim();", 'git -C "$p" fetch -q origin', 'echo "kill switch"', "const pushed = list.push(x);", "skill=1"]) assert.equal(risky(l), false, l);
  const d = mkdtempSync(join(tmpdir(), "mut-"));
  try {
    mkdirSync(join(d, "root/lib"), { recursive: true }); mkdirSync(join(d, "sets"));
    writeFileSync(join(d, "root/lib/a.sh"), '#!/usr/bin/env bash\nn=3\nrm -rf "$d/$n" && n=4\n');
    writeFileSync(join(d, "sets/one.txt"), "lib/a.sh 2-3\n");
    for (const seed of ["1", "2", "3", "4"]) { const r = await main(["pick", join(d, "sets"), seed, "2"], join(d, "root"));
      assert.match(r.err, /pool: 1 lines \(1 more left out: they delete, kill, push or post\)\n$/);
      for (const l of r.out.split("\n").filter(Boolean)) assert.equal(JSON.parse(l).line, 2); }
  } finally { rmSync(d, { recursive: true, force: true }); }
});

test("mutants: delete takes a whole statement only: a line marked as part of a longer one gets no delete mutant", () => {
  const text = "a=1 \\\n  b=2\nc=3\n", texts = { "lib/a.sh": text };
  const lines = [{ file: "lib/a.sh", line: 1, text: "a=1 \\", files: ["f"], partial: false, whole: false }, { file: "lib/a.sh", line: 3, text: "c=3", files: ["f"], partial: false, whole: true }];
  for (const seed of [1, 2, 3, 4, 5, 6]) {
    const s = pick(lines, seed, 2, () => true, texts).sample;
    assert.deepEqual(s.filter(m => m.kind === "delete").map(m => m.line), [3]);
    assert.deepEqual(s.filter(m => m.kind === "literal").map(m => m.line), [1]);   // another kind still takes line 1
  }
});

test("mutants: the table names what changed and the checks that caught it, per file, or says survived", () => {
  assert.equal(change("  [[ $1 -ge 2 ]] && echo big", "  [[ $1 -gt 2 ]] && echo big"), "`-ge` → `-gt`");
  assert.equal(change("x = a && b;", "x = a || b;"), "`&&` → `||`");
  assert.equal(change("return 0;", "return 1;"), "`0` → `1`");
  assert.equal(change("n=3", null), "the line deleted");
  // tests/run.sh's own lines: a file's PASS/FAIL lines, then `<file>: <n> checks, <s> s`; a file stopped at its timeout; the totals
  const red = ["tmp: /tmp/x", "PASS a one", "FAIL a two", "FAIL a three", "14-run-2b-stop-records: 3 checks, 27.4 s", "tmp: /tmp/y", "PASS b one", "45-lanes-run: 1 checks, 45.2 s",
    "FAIL c one", "47-lanes-two: 1 checks, 300.1 s", "FAIL 47-lanes-two: still running after TEST_FILE_TIMEOUT=5m; stopped",
    "PASS conformance: every check a subset ran is in the fixture, once", "files that exited non-zero: 14-run-2b-stop-records 47-lanes-two", "HARNESS_FAILED=14-run-2b-stop-records 47-lanes-two",
    "slowest: 47-lanes-two 300.1 s; wall 300.2 s, 4 jobs, tier all", "4/8 checks passed"].join("\n");
  assert.deepEqual(caughtBy(red), { names: ["a two", "a three", "c one", "47-lanes-two: still running after TEST_FILE_TIMEOUT=5m; stopped"], files: ["14-run-2b-stop-records", "47-lanes-two"] });
  assert.deepEqual(caughtBy("PASS a one\n14-run-2b-stop-records: 1 checks, 2.0 s\nPASS conformance: every check a subset ran is in the fixture, once\n2/2 checks passed\n"), { names: [], files: [] });
  const sample = [{ id: "compare-01", file: "lib/a.sh", line: 2, kind: "compare", before: "[[ $1 -ge 2 ]]", after: "[[ $1 -gt 2 ]]", files: ["14-run-2b-stop-records", "45-lanes-run", "47-lanes-two"], partial: false },
    { id: "delete-01", file: "lib/b.mjs", line: 7, kind: "delete", before: "x();", after: null, files: ["45-lanes-run"], partial: true }];
  const rows = tableRows(sample, new Map([["compare-01", red], ["delete-01", "PASS b one\n45-lanes-run: 1 checks, 45.2 s\n1/1 checks passed\n"]]));
  assert.deepEqual(rows, [
    "| `compare-01` | `lib/a.sh:2` | `-ge` → `-gt` | 3 | caught by 4 checks in 2 files: `a two`, `a three`, `c one`, and 1 more |",
    "| `delete-01` | `lib/b.mjs:7` (run in part) | the line deleted | 1 | **survived** |"]);
  assert.deepEqual(tableRows(sample.slice(0, 1), new Map()), ["| `compare-01` | `lib/a.sh:2` | `-ge` → `-gt` | 3 | not run |"]);
});
