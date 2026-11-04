// lib/eval.mjs: a replay task's validation, compare's verdicts and the probes' questions and scores.   node --test tests/unit/eval.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { validateTask as v, compare as c, completeRepeats as cr, compareText as ct, questions as q, score as s, target as tg } from "../../lib/eval.mjs";

// the replay set (E2): each error starts with the field it is about (the CLI over evals/tasks stays in 09-replay-set)
test("eval.mjs: validateTask accepts a task and names the field of each bad one", () => {
  const has = (e, f) => assert.ok(e.some(x => x.startsWith(f + ":")), `no error starts ${f}: in ${e.join("; ")}`);
  const ok = { id: "x1", project: "p", repo: "~/projects/p", base: "a".repeat(40), policy: "build-only", why: "w",
    features: [{ id: "X1", milestone: "X", description: "d", steps: ["s"] }] }, { features, ...nofeat } = ok;
  assert.deepEqual(v(ok), []);
  assert.equal(v(nofeat).length, 1);
  has(v(nofeat), "features");
  has(v({ ...ok, policy: "live-staged" }), "policy");
  has(v({ ...ok, base: "abc123" }), "base");
  has(v({ ...ok, features: Array(4).fill(features[0]) }), "features");
  has(v({ ...ok, features: [{ ...features[0], steps: [] }] }), "features[0].steps");
  has(v({ ...ok, chek_cmd: "x" }), "chek_cmd");
});

// compare (E2-05): noise is the spread across a task's repeats; B is judged against A, in each metric's direction;
// pass rate is pass^N (w passed once in two: 0), a started run without a summary ({ missing }) a failed one; the totals
// use only the repeats every task has, and per verified feature is the sums over tasks / their verified features
test("eval.mjs: compare verdicts", () => {
  const sm = (pass, cost, hit = 0.5) => { const ver = pass ? 2 : 1; return { features: { total: 2, verified: ver }, cost: { total: cost * ver }, per_verified_feature: { cost, tokens: 1000 / ver },
    tokens: { in: 900, cache_read: 50, cache_write: 50, out: 0, cache_hit_rate: hit, context_peak: 100 }, orientation: { tokens: 10 }, time: { wall_h: 1 }, rework: [] }; };
  const A = { tasks: { x: [sm(1, 1.0), sm(1, 1.4)], y: [sm(0, 2.0), sm(0, 2.1)], z: [sm(1, 1.0, 0.5), sm(1, 1.1, 0.5)], w: [sm(1, 1), sm(0, 1)], a: [sm(1, 1)] } };
  const B = { tasks: { x: [sm(1, 1.2), sm(1, 1.3)], y: [sm(1, 1.0), sm(1, 1.1)], z: [sm(0, 2.0, 0.8), sm(0, 2.1, 0.8)], w: [sm(1, 1), sm(1, 1)], b: [sm(1, 1)] } };
  const get = (rows, t, m) => rows.find(x => x.task === t && x.metric === m), r = c(A, B), vd = (t, m) => get(r, t, m)?.verdict, one = c({ tasks: { x: [sm(1, 1)] } }, B);
  const nul = { ...sm(1, 1), per_verified_feature: { cost: null, tokens: null } }, pv = a => get(c({ tasks: { x: a } }, B), "x", "$ per verified feature").verdict, tot = get(r, "total", "pass rate");
  const sums = { tasks: { p: [sm(1, 1), sm(1, 1)], q: [sm(0, 4), sm(0, 4)] } }, P = { tasks: { x: [sm(1, 1), sm(0, 1)], y: [sm(1, 1)] } }, pp = c(P, P);
  const crash = get(c({ tasks: { x: [sm(1, 1), { missing: true }] } }, B), "x", "pass rate");
  assert.equal(vd("x", "$ per verified feature"), "within noise");
  assert.equal(vd("x", "pass rate"), "within noise");
  assert.equal(vd("y", "$ per verified feature"), "better");
  assert.equal(vd("y", "pass rate"), "better");
  assert.equal(vd("z", "$ per verified feature"), "worse");
  assert.equal(vd("z", "pass rate"), "worse");
  assert.equal(vd("z", "cache hit rate"), "better");
  assert.equal(r.filter(x => x.task === "x").length, 8);
  assert.deepEqual(r.filter(x => x.task === "a" || x.task === "b"), []);
  assert.equal(vd("x", "rework"), "within noise");
  assert.deepEqual([...new Set(one.map(x => x.verdict))], ["one sample"]);
  assert.equal(pv([nul, sm(1, 1)]), "one sample");
  assert.equal(pv([nul, nul]), "no data");
  assert.equal(get(r, "w", "pass rate").a, 0);
  assert.equal(vd("w", "pass rate"), "within noise");
  assert.equal(tot.a, 0.5);
  assert.equal(tot.b, 0.75);
  assert.equal(tot.verdict, "within noise");
  assert.equal(r.filter(x => x.task === "total").length, 8);
  assert.equal(get(c(sums, sums), "total", "$ per verified feature").a, 2);
  assert.equal(get(c(sums, sums), "total", "tokens per verified feature").a, 2000 / 3);
  assert.equal(JSON.stringify(cr(P, ["x", "y"])), "[0]");
  assert.equal(JSON.stringify(cr(P, [])), "[]");
  assert.equal(get(pp, "total", "pass rate").a, 1);
  assert.equal(get(pp, "total", "pass rate").verdict, "one sample");
  assert.equal(crash.a, 0);
  assert.equal(JSON.stringify(crash.a_values), "[1,0]");
});

// a repeat that verified nothing still spent: per verified feature is Σ / Σ verified over every repeat, not a mean that
// drops it; an empty feature list is no pass (E2 review)
test("eval.mjs: per verified feature counts every repeat's cost (E2 review)", () => {
  const sm = (cost, ver) => ({ features: { total: 1, verified: ver }, cost: { total: cost }, per_verified_feature: { cost: ver ? cost / ver : null, tokens: ver ? 1000 / ver : null },
    tokens: { in: 1000, cache_read: 0, cache_write: 0, out: 0 } });
  const A = { tasks: { x: [sm(2, 1), sm(2, 1), sm(2, 1)] } }, B = { tasks: { x: [sm(1, 1), sm(1.1, 1), sm(20, 0)] } };
  const r = c(A, B), get = (t, m) => r.find(x => x.task === t && x.metric === m), t = ct(A, B).text;
  const near = (row, want) => { assert.ok(Math.abs(row.b - want) < 1e-9, `b ${row.b} is not ${want}`); assert.equal(row.verdict, "worse"); };
  const e = c({ tasks: { x: [{ features: { total: 0, verified: 0 } }] } }, { tasks: { x: [sm(1, 1)] } }).find(x => x.task === "x" && x.metric === "pass rate");
  near(get("x", "$ per verified feature"), 11.05);
  near(get("total", "$ per verified feature"), 11.05);
  near(get("x", "tokens per verified feature"), 1500);
  near(get("total", "tokens per verified feature"), 1500);
  assert.equal(e.a, 0);
  assert.match(t, /^B: x r3 verified nothing \(\$20\.00 spent\): counted in per verified feature, not in its noise$/m);
});

// the probes (E2): questions from the feature list, the session rows and the commits; answers scored per question
// (the harness eval probes run on a stub result stays in 10-harness-eval-run)
test("eval.mjs: probe questions derived from the list, the session rows and the commits; answers scored exact, contains or miss", () => {
  const list = { features: [{ id: "X1", milestone: "M", passes: true }, { id: "X2", milestone: "M", passes: false, after: ["X1"] }, { id: "X3", milestone: "M", passes: false }] };
  const rows = [{ kind: "coding", feature: "X2", passes: false, env: false, final: "The suite was red: test foo failed. Then I stopped." },
    { kind: "coding", feature: "X2", passes: false, env: true, final: "usage limit" }, { kind: "verify", feature: null, passes: false, env: false, final: "M not verified." }];
  const commits = [{ subject: "X1: work", files: ["a.txt", ".harness/runs/r/feature_list.json"] }, { subject: "X1: more", files: ["b.txt"] },
    { subject: "X10: other", files: ["c.txt"] }, { subject: "HARNESS: x", files: ["d.txt"] }];
  const p = q(list, rows, commits), k = p.questions.map(x => x.kind).join();
  const r = s(p, "Q1: `b.txt`, a.txt.\nQ2: it depends on X1 only\nQ3: no idea"), m = r.questions.map(x => x.match).join();
  const all = { features: [{ id: "Y1", passes: true }, { id: "Y2", passes: true }] };
  // a markdown final, an abbreviation; the last real attempt passed (X2: no question); a park is not a failure (X3)
  const f2 = q({ features: [{ id: "X1", passes: false }, { id: "X2", passes: true }, { id: "X3", passes: false }] }, [
    { kind: "coding", feature: "X1", passes: false, env: false, final: "## Summary\n\n**X1 is not done: the suite fails on e.g. foo.** More text." },
    { kind: "coding", feature: "X2", passes: false, env: false, final: "Red suite." }, { kind: "coding", feature: "X2", passes: true, env: false, final: "Done." },
    { kind: "coding", feature: "X3", passes: false, env: false, final: "Needs a token.\nPARKED: set the token" }], []);
  assert.equal(p.target, "X2");
  assert.equal(tg(all), "Y2");
  assert.equal(k, "files,depends,fails");
  assert.equal(JSON.stringify(p.questions[0].key), "[\"a.txt\",\"b.txt\"]");
  assert.equal(p.questions[0].q, "Which files did X1 change?");
  assert.equal(p.questions[2].key, "The suite was red: test foo failed");
  assert.equal(p.questions[2].feature, "X2");
  assert.equal(m, "exact,contains,miss");
  assert.equal(r.points, 2);
  assert.equal(r.score, "2/3");
  assert.equal(q(all, [], []).questions.map(x => x.key.join()).join(), "Y1");
  assert.equal(s(p, "Q2: X1").questions[0].match, "miss");
  assert.equal(s(p, "Q01: a.txt b.txt\nQ2: X10").questions.map(x => x.match).join(), "exact,miss,miss");
  assert.equal(s(p, "Q1: Which files did X1 change?\nQ1: data.txt, b.txt").questions[0].match, "miss");
  assert.equal(s(p, "Q1: the files a.txt and b.txt").questions[0].match, "contains");
  assert.equal(f2.questions.filter(x => x.kind === "fails").map(x => x.feature + "=" + x.key).join("|"), "X1=X1 is not done: the suite fails on e.g. foo");
  assert.deepEqual(f2.questions.filter(x => x.kind === "fails" && x.feature === "X2"), []);
});
