// lib/lane.mjs: the lane's verify verdict and exit table, how a closed lane reads, how a run ends; one test per branch.   node --test tests/unit/lane.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { sameAsCli } from "./cli-same.mjs";
import { closedLane, endKind, fixRoundOpens, laneDone, runEnd, suiteVerdict, verifyCard, verifyNeed, verifyRound } from "../../lib/lane.mjs";

const inTmp = fn => async () => { const d = mkdtempSync(join(tmpdir(), "lane-")); try { return await fn(d); } finally { rmSync(d, { recursive: true, force: true }); } };

// ---- verifyRound: what one verify session's round concluded ----
const round = o => verifyRound({ done: true, newEntry: true, evidence: true, last: false, ...o });

test("lane.mjs: verifyRound: a milestone not done is fail, whatever the rest says", () => {
  assert.equal(round({ done: false }), "fail");
  assert.equal(round({ done: false, newEntry: false, evidence: false, last: true }), "fail");
});
test("lane.mjs: verifyRound: a new entry with its evidence is hold, on any model", () => {
  assert.equal(round({}), "hold");
  assert.equal(round({ last: true }), "hold");
});
test("lane.mjs: verifyRound: no new verify entry on the last model is thin", () => {
  assert.equal(round({ newEntry: false, evidence: false, last: true }), "thin");
});
test("lane.mjs: verifyRound: a new entry short of the evidence on the last model is thin", () => {
  assert.equal(round({ evidence: false, last: true }), "thin");
});
test("lane.mjs: verifyRound: evidence short on an earlier model runs again", () => {
  assert.equal(round({ evidence: false }), "again");
});
test("lane.mjs: verifyRound: no new verify entry on an earlier model runs again", () => {
  assert.equal(round({ newEntry: false, evidence: false }), "again");
});

// ---- suiteVerdict: what the suite's answer does to the round's result ----
const suite = o => suiteVerdict({ result: "hold", green: true, fixOnly: false, ...o });

test("lane.mjs: suiteVerdict: hold on a green suite stays hold", () => assert.equal(suite({}), "hold"));
test("lane.mjs: suiteVerdict: hold on a red suite is red", () => assert.equal(suite({ green: false }), "red"));
test("lane.mjs: suiteVerdict: fail where only fix features were un-passed, on a red suite, is red", () => {
  assert.equal(suite({ result: "fail", fixOnly: true, green: false }), "red");
});
test("lane.mjs: suiteVerdict: fail where only fix features were un-passed, on a green suite, stays fail", () => {
  assert.equal(suite({ result: "fail", fixOnly: true }), "fail");
});
test("lane.mjs: suiteVerdict: fail with other features un-passed stays fail, whatever the suite", () => {
  assert.equal(suite({ result: "fail", green: false }), "fail");
});
test("lane.mjs: suiteVerdict: thin stays thin, whatever the suite", () => {
  assert.equal(suite({ result: "thin", green: false, fixOnly: true }), "thin");
});

// ---- fixRoundOpens: a red in a plain verify under the cap opens a fix round, no card ----
test("lane.mjs: fixRoundOpens: a plain verify under the cap opens one", () => {
  assert.equal(fixRoundOpens({ mode: "", fixn: 1, max: 2 }), true);
});
test("lane.mjs: fixRoundOpens: a plain verify at the cap is the card", () => {
  assert.equal(fixRoundOpens({ mode: "", fixn: 2, max: 2 }), false);
});
test("lane.mjs: fixRoundOpens: past the cap is the card, and a cap of 0 never opens one", () => {
  assert.equal(fixRoundOpens({ mode: "", fixn: 3, max: 2 }), false);
  assert.equal(fixRoundOpens({ mode: "", fixn: 0, max: 0 }), false);
});
test("lane.mjs: fixRoundOpens: once mode, past the deadline, is the card", () => {
  assert.equal(fixRoundOpens({ mode: "once", fixn: 0, max: 2 }), false);
});
test("lane.mjs: fixRoundOpens: rebase mode, whose caller is no lane loop, is the card", () => {
  assert.equal(fixRoundOpens({ mode: "rebase", fixn: 0, max: 2 }), false);
});

// ---- verifyNeed: the lane's exit reason and the card's text ----
test("lane.mjs: verifyNeed: thin", () => {
  assert.equal(verifyNeed({ result: "thin", own: false, failed: [] }), "verify evidence too thin");
});
test("lane.mjs: verifyNeed: red on a tree main brought nothing to is the milestone's own", () => {
  assert.equal(verifyNeed({ result: "red", own: true, failed: [] }), "suite red on the verified tree");
});
test("lane.mjs: verifyNeed: red with main merged in", () => {
  assert.equal(verifyNeed({ result: "red", own: false, failed: [] }), "suite red after merging main");
});
test("lane.mjs: verifyNeed: fail with one failed id", () => {
  assert.equal(verifyNeed({ result: "fail", own: false, failed: ["a"] }), "a fails verification");
});
test("lane.mjs: verifyNeed: fail with several failed ids", () => {
  assert.equal(verifyNeed({ result: "fail", own: false, failed: ["a", "b"] }), "a, b fail verification");
});
test("lane.mjs: verifyNeed: fail with none failed (each has an attempt left) is empty", () => {
  assert.equal(verifyNeed({ result: "fail", own: true, failed: [] }), "");
});
test("lane.mjs: verifyNeed: hold is empty", () => {
  assert.equal(verifyNeed({ result: "hold", own: true, failed: [] }), "");
});

// ---- verifyCard: the card's reason and variant ----
test("lane.mjs: verifyCard: fail is the re-check's card with no variant, in every mode", () => {
  for (const mode of ["", "once", "rebase"]) assert.deepEqual(verifyCard({ result: "fail", own: true, mode }), { reason: "verify_recheck", variant: "" }, mode);
});
test("lane.mjs: verifyCard: red and own says own, over the mode", () => {
  assert.deepEqual(verifyCard({ result: "red", own: true, mode: "once" }), { reason: "verify_red", variant: "own" });
});
test("lane.mjs: verifyCard: red and not own gives the mode", () => {
  assert.deepEqual(verifyCard({ result: "red", own: false, mode: "once" }), { reason: "verify_red", variant: "once" });
});
test("lane.mjs: verifyCard: thin gives the mode, own or not", () => {
  assert.deepEqual(verifyCard({ result: "thin", own: true, mode: "once" }), { reason: "verify_thin", variant: "once" });
  assert.deepEqual(verifyCard({ result: "thin", own: false, mode: "" }), { reason: "verify_thin", variant: "" });
});
test("lane.mjs: verifyCard: a re-base's red and thin give rebase", () => {
  assert.deepEqual(verifyCard({ result: "red", own: false, mode: "rebase" }), { reason: "verify_red", variant: "rebase" });
  assert.deepEqual(verifyCard({ result: "thin", own: false, mode: "rebase" }), { reason: "verify_thin", variant: "rebase" });
});

// ---- laneDone: the table in order, each row with the earlier markers absent and a later one present ----
const done = o => laneDone({ m: "M1", main: "main", policy: "auto", need: "", ...o });
const row = (code, reason, mergeFailed = false) => ({ code, reason, mergeFailed });

test("lane.mjs: laneDone: merged wins over every other marker", () => {
  assert.deepEqual(done({ merged: true, needs: true, conflict: true }), row(0, "M1 merged"));
});
test("lane.mjs: laneDone: needs Michael gives its need, before waits", () => {
  assert.deepEqual(done({ needs: true, need: "suite red on the verified tree", waits: true }), row(12, "M1 needs Michael: suite red on the verified tree"));
});
test("lane.mjs: laneDone: needs Michael with no need keeps its colon and space", () => {
  assert.deepEqual(done({ needs: true }), row(12, "M1 needs Michael: "));
});
test("lane.mjs: laneDone: a re-base waits, before proposed", () => {
  assert.deepEqual(done({ rebase: true, proposed: true }), row(0, "M1 verified; its re-base waits"));
});
test("lane.mjs: laneDone: proposed, before waits", () => {
  assert.deepEqual(done({ proposed: true, waits: true }), row(0, "M1 proposed"));
});
test("lane.mjs: laneDone: its PR waits, before nomerge", () => {
  assert.deepEqual(done({ waits: true, nomerge: true }), row(0, "M1 verified; its PR waits"));
});
test("lane.mjs: laneDone: main did not merge, with a main conflict, needs Michael", () => {
  assert.deepEqual(done({ nomerge: true, mainConflict: true, main: "trunk", policy: "off" }), row(12, "M1 needs Michael: trunk conflicts with its lane"));
});
test("lane.mjs: laneDone: main did not merge, with no conflict, is tried again", () => {
  assert.deepEqual(done({ nomerge: true, main: "trunk", refused: true }), row(0, "M1 verified; trunk did not merge into its lane; its merge is tried again"));
});
test("lane.mjs: laneDone: a main conflict alone, with nomerge gone, is not read", () => {
  assert.deepEqual(done({ mainConflict: true, policy: "off" }), row(0, "M1 verified"));
});
test("lane.mjs: laneDone: MERGE_POLICY=off is verified, before refused", () => {
  assert.deepEqual(done({ policy: "off", refused: true }), row(0, "M1 verified"));
});
test("lane.mjs: laneDone: merge refused, before conflict", () => {
  assert.deepEqual(done({ refused: true, conflict: true }), row(12, "M1 needs Michael: merge refused"));
});
test("lane.mjs: laneDone: conflicts with main", () => {
  assert.deepEqual(done({ conflict: true, main: "trunk" }), row(12, "M1 needs Michael: conflicts with trunk"));
});
test("lane.mjs: laneDone: no marker at all is the unknown merge failure, the one row with its side effect", () => {
  assert.deepEqual(done({}), row(12, "M1 needs Michael: its merge", true));
});

// ---- closedLane: reap's reading of the exit file, as `read -r code why` has it ----
const closed = (code, why, crash = false, ends = false) => ({ code, why, crash, ends });
const UNEXPECTED = closed("12", "lane exited unexpectedly", true);

test("lane.mjs: closedLane: a normal line", () => {
  assert.deepEqual(closedLane("0 M1 merged\n"), closed("0", "M1 merged"));
});
test("lane.mjs: closedLane: a code alone has an empty reason", () => {
  assert.deepEqual(closedLane("0\n"), closed("0", ""));
});
test("lane.mjs: closedLane: read's trim takes blanks around the fields, never a CR or a no-break space", () => {
  assert.deepEqual(closedLane(" \t0 \t M1  merged \t\n"), closed("0", "M1  merged"));
  assert.deepEqual(closedLane("0 M1\r\n"), closed("0", "M1\r"));
  assert.deepEqual(closedLane("0  M1 \n"), closed("0", " M1 "));
});
test("lane.mjs: closedLane: only the first line counts", () => {
  assert.deepEqual(closedLane("13 session cap (3)\n0 merged\n"), closed("13", "session cap (3)", false, true));
});
test("lane.mjs: closedLane: an empty first line reads as no code and no reason", () => {
  assert.deepEqual(closedLane("\n"), closed("", ""));
});
test("lane.mjs: closedLane: a missing exit file is unexpected, code 12 with a card", () => {
  assert.deepEqual(closedLane(null), UNEXPECTED);
});
test("lane.mjs: closedLane: an exit file with no final newline is unexpected, as read fails there", () => {
  assert.deepEqual(closedLane("0 M1 merged"), UNEXPECTED);
  assert.deepEqual(closedLane(""), UNEXPECTED);
});
test("lane.mjs: closedLane: the card opens on exactly the words a crash has, whatever the code", () => {
  assert.deepEqual(closedLane("12 lane exited unexpectedly\n"), UNEXPECTED);
  assert.deepEqual(closedLane("0 lane exited unexpectedly\n"), closed("0", "lane exited unexpectedly", true));
  assert.deepEqual(closedLane("12 the lane exited unexpectedly\n"), closed("12", "the lane exited unexpectedly"));
});
test("lane.mjs: closedLane: code 13 ends the run", () => {
  assert.deepEqual(closedLane("13 usage limit (3 sessions refused in a row)\n"), closed("13", "usage limit (3 sessions refused in a row)", false, true));
});
test("lane.mjs: closedLane: feature-list edits end the run, under its code 12", () => {
  assert.deepEqual(closedLane("12 feature-list edits\n"), closed("12", "feature-list edits", false, true));
});
test("lane.mjs: closedLane: a code 0 neither opens a card nor ends the run", () => {
  assert.deepEqual(closedLane("0 M1 verified\n"), closed("0", "M1 verified"));
});

// ---- runEnd: the lists the run's end reason is built from ----
const ending = o => runEnd({ summary: "2/3 passing", parked: [], blocked: [], next: "", needs: [], ...o });
const answer = o => ({ done: false, parked: [], blocked: [], needs: [], ...o });

test("lane.mjs: runEnd: every feature passing is done", () => {
  assert.deepEqual(ending({ summary: "3/3 passing" }), answer({ done: true }));
});
test("lane.mjs: runEnd: fewer passing is not done, and nothing else is no feature left to try", () => {
  assert.deepEqual(ending({}), answer({}));
});
test("lane.mjs: runEnd: an empty list, 0/0, is done, as the regex has it", () => {
  assert.equal(ending({ summary: "0/0 passing" }).done, true);
});
test("lane.mjs: runEnd: the counts compare as written, and a summary that is no count is not done", () => {
  assert.equal(ending({ summary: "03/3 passing" }).done, false);
  assert.equal(ending({ summary: "" }).done, false);
  assert.equal(ending({ summary: "passing 3/3" }).done, false);
});
test("lane.mjs: runEnd: a parked id leaves blocked, the rest keep the order given", () => {
  assert.deepEqual(ending({ parked: ["b"], blocked: ["c", "b", "a"] }), answer({ parked: ["b"], blocked: ["c", "a"] }));
});
test("lane.mjs: runEnd: a parked id that isn't blocked changes nothing, and an id only equal to a whole one matches", () => {
  assert.deepEqual(ending({ parked: ["a"], blocked: ["a2", "b"] }), answer({ parked: ["a"], blocked: ["a2", "b"] }));
});
test("lane.mjs: runEnd: needs with an empty next is empty", () => {
  assert.deepEqual(ending({ needs: ["M1"] }), answer({}));
});
test("lane.mjs: runEnd: needs with a next are the milestones", () => {
  assert.deepEqual(ending({ needs: ["M1", "M2"], next: "F1\topus\tM3" }), answer({ needs: ["M1", "M2"] }));
});
test("lane.mjs: runEnd: blocked, parked and needs all at once", () => {
  assert.deepEqual(ending({ parked: ["p"], blocked: ["p", "b"], needs: ["M1"], next: "F1\topus\tM3" }), answer({ parked: ["p"], blocked: ["b"], needs: ["M1"] }));
});

// ---- endKind: finish's reason → card kind, notification priority, desk ----
const kind = (needs = "", high = false, desk = false) => ({ needs, high, desk });

test("lane.mjs: endKind: feature-list edits have their card and the high priority", () => {
  assert.deepEqual(endKind("feature-list edits"), kind("feature_list_edits", true));
});
test("lane.mjs: endKind: initializer failed has its card and the high priority", () => {
  assert.deepEqual(endKind("initializer failed (exit 3)"), kind("initializer_failed", true));
});
test("lane.mjs: endKind: usage limit has its card, no high priority", () => {
  assert.deepEqual(endKind("usage limit (3 sessions refused in a row)"), kind("usage_limit"));
});
test("lane.mjs: endKind: weekly budget has its card, no high priority", () => {
  assert.deepEqual(endKind("weekly budget (90% used)"), kind("weekly_budget"));
});
test("lane.mjs: endKind: blocked on is high and the desk, no card of its own", () => {
  assert.deepEqual(endKind("blocked on F1,F2"), kind("", true, true));
});
test("lane.mjs: endKind: waiting on Michael is high and the desk, no card of its own", () => {
  assert.deepEqual(endKind("waiting on Michael: M1; blocked on F1"), kind("", true, true));
});
test("lane.mjs: endKind: done, the deadline and a session cap have none", () => {
  for (const r of ["done", "deadline", "session cap (3)", "no feature left to try", ""]) assert.deepEqual(endKind(r), kind(), r);
});
test("lane.mjs: endKind: a reason holding the words later in its text has none, each is a prefix", () => {
  for (const r of ["stopped by Michael: usage limit", "stopped by Michael: blocked on F1", "stopped by Michael: feature-list edits"]) assert.deepEqual(endKind(r), kind(), r);
});
test("lane.mjs: endKind: a prefix holds across a newline, as case's star does", () => {
  assert.deepEqual(endKind("usage limit\nand more"), kind("usage_limit"));
});

// ---- main: the served answer against the CLI's, one per question ----
test("lane.mjs: main: verify-round through the CLI", async () => {
  assert.equal((await sameAsCli("lane.mjs", ["verify-round", "true", "true", "true", "false"])).out, "hold\n");
  assert.equal((await sameAsCli("lane.mjs", ["verify-round", "true", "false", "false", "true"])).out, "thin\n");
  assert.equal((await sameAsCli("lane.mjs", ["verify-round", "false", "false", "false", "false"])).out, "fail\n");
  assert.equal((await sameAsCli("lane.mjs", ["verify-round", "true", "true", "false", "false"])).out, "again\n");
});
test("lane.mjs: main: suite-verdict through the CLI", async () => {
  assert.equal((await sameAsCli("lane.mjs", ["suite-verdict", "hold", "0", ""])).out, "red\n");
  assert.equal((await sameAsCli("lane.mjs", ["suite-verdict", "fail", "0", "1"])).out, "red\n");
  assert.equal((await sameAsCli("lane.mjs", ["suite-verdict", "fail", "1", "1"])).out, "fail\n");
});
test("lane.mjs: main: fix-round answers by its exit code", async () => {
  assert.equal((await sameAsCli("lane.mjs", ["fix-round", "", "0", "1"])).rc, 0);
  assert.equal((await sameAsCli("lane.mjs", ["fix-round", "once", "0", "1"])).rc, 1);
});
test("lane.mjs: main: verdict gives the need and the card, in labelled lines", async () => {
  assert.equal((await sameAsCli("lane.mjs", ["verdict", "fail", "1", "rebase", "a", "b"])).out, "need a, b fail verification\nreason verify_recheck\nvariant \n");
  assert.equal((await sameAsCli("lane.mjs", ["verdict", "red", "1", ""])).out, "need suite red on the verified tree\nreason verify_red\nvariant own\n");
  assert.equal((await sameAsCli("lane.mjs", ["verdict", "thin", "0", "once"])).out, "need verify evidence too thin\nreason verify_thin\nvariant once\n");
});
test("lane.mjs: main: lane-done gives the code, the side effect and the reason's exact bytes", async () => {
  assert.equal((await sameAsCli("lane.mjs", ["lane-done", "M1", "main", "auto", "", "needs"])).out, "12 0 M1 needs Michael: \n");
  assert.equal((await sameAsCli("lane.mjs", ["lane-done", "M1", "main", "auto", "two\nlines", "needs", "waits"])).out, "12 0 M1 needs Michael: two\nlines\n");
  assert.equal((await sameAsCli("lane.mjs", ["lane-done", "M1", "trunk", "auto", "", "nomerge", "main-conflict"])).out, "12 0 M1 needs Michael: trunk conflicts with its lane\n");
  assert.equal((await sameAsCli("lane.mjs", ["lane-done", "M1", "main", "auto", ""])).out, "12 1 M1 needs Michael: its merge\n");
});
test("lane.mjs: main: closed reads the exit file, or its absence", inTmp(async d => {
  const f = join(d, "exit");
  assert.equal((await sameAsCli("lane.mjs", ["closed", f])).out, "code 12\nwhy lane exited unexpectedly\ncrash 1\nends 0\n");
  assert.equal((await sameAsCli("lane.mjs", ["closed", d])).out, "code 12\nwhy lane exited unexpectedly\ncrash 1\nends 0\n");
  writeFileSync(f, "13 session cap (3)\n");
  assert.equal((await sameAsCli("lane.mjs", ["closed", f])).out, "code 13\nwhy session cap (3)\ncrash 0\nends 1\n");
  writeFileSync(f, "0 M1 merged");
  assert.equal((await sameAsCli("lane.mjs", ["closed", f])).out, "code 12\nwhy lane exited unexpectedly\ncrash 1\nends 0\n");
}));
test("lane.mjs: main: run-end takes lines and answers the lists comma-joined", async () => {
  assert.equal((await sameAsCli("lane.mjs", ["run-end", "2/3 passing", "p\nq", "b\np\na", "F1\topus\tM3", "M1", "M2"])).out, "done 0\nparked p,q\nblocked b,a\nneeds M1,M2\n");
  assert.equal((await sameAsCli("lane.mjs", ["run-end", "3/3 passing", "", "", ""])).out, "done 1\nparked \nblocked \nneeds \n");
});
test("lane.mjs: main: end-kind gives the card, the priority and the desk", async () => {
  assert.equal((await sameAsCli("lane.mjs", ["end-kind", "feature-list edits"])).out, "needs feature_list_edits\nhigh 1\ndesk 0\n");
  assert.equal((await sameAsCli("lane.mjs", ["end-kind", "blocked on F1"])).out, "needs \nhigh 1\ndesk 1\n");
  assert.equal((await sameAsCli("lane.mjs", ["end-kind", "done"])).out, "needs \nhigh 0\ndesk 0\n");
});
test("lane.mjs: main: an unknown question is the usage line and exit 2", async () => {
  assert.deepEqual(await sameAsCli("lane.mjs", ["nope"]), { rc: 2, out: "" });
  assert.deepEqual(await sameAsCli("lane.mjs", []), { rc: 2, out: "" });
});
