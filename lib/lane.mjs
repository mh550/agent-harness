// The lane's verify verdict and exit table (lib/lane.sh), how a closed lane reads and how a run ends (lib/driver.sh).
//   node lib/lane.mjs verify-round <done> <new entry> <evidence> <last model> | suite-verdict <result> <green 0|1> <fix only: 1 or empty> | fix-round <mode> <rounds> <max> | verdict <result> <own 0|1> <mode> <failed id>… | lane-done <m> <main> <policy> <need> <marker>… | closed <exit file> | run-end <summary> <parked lines> <blocked lines> <next> <needs milestone>… | end-kind <reason>
// Flow and every note stay in bash: this answers a branch and its values, labelled lines `<label> <value>` where it answers several; fix-round answers by its exit code.
import { captured, isMain, labelled, runCli, textOf } from "./cli.mjs";

// One round of verify's model loop. Not done is fail whatever the rest says; `again` is the next model's round.
export function verifyRound({ done, newEntry, evidence, last }) {
  if (!done) return "fail";
  if (newEntry && evidence) return "hold";
  return last ? "thin" : "again";
}

// What the suite's answer does to the round's result. Bash runs the suite only for a hold, or a fail where fix features
// are all the verifier un-passed (fixOnly): a verifier performing a fix feature's steps un-passes it on a red suite, and
// that verdict is the suite's, not a re-check's.
export function suiteVerdict({ result, green, fixOnly }) {
  if (green) return result;
  return result === "hold" || (result === "fail" && fixOnly) ? "red" : result;
}

// A red under MAX_FIX_ROUNDS opens a fix round, no card. In a plain verify only: `once` is past the deadline (no session
// can follow), `rebase`'s caller is no lane loop.
export const fixRoundOpens = ({ mode, fixn, max }) => mode === "" && fixn < max;

// The lane's exit reason and the card's text; empty: no card.
export function verifyNeed({ result, own, failed }) {
  if (result === "thin") return "verify evidence too thin";
  if (result === "red") return own ? "suite red on the verified tree" : "suite red after merging main";
  if (result !== "fail" || !failed.length) return "";
  return failed.length === 1 ? `${failed[0]} fails verification` : `${failed.join(", ")} fail verification`;
}

// The needs_open line's reason and variant. A failed re-check names no variant, in any mode: rebase_fail has the words
// of a re-base's own failures. A red on a tree main brought nothing to is the milestone's own.
export function verifyCard({ result, own, mode }) {
  if (result === "fail") return { reason: "verify_recheck", variant: "" };
  return { reason: `verify_${result}`, variant: own && result === "red" ? "own" : mode };
}

// A verified milestone's exit: 0 merged, proposed or waiting; 12 what needs Michael. needs comes before waits, which
// stays. A conflict has its card; a merge that never started has none and needs no one yet (the coordinator's next merge
// re-bases it). The last row, which nothing should reach, is the one with a side effect in bash (merge_failed opens the
// card): a lane never closes "needs Michael" without one. Unit tests can't reach bash's own fallback for no answer here,
// which takes that same row.
export function laneDone({ m, main, policy, need, merged, needs, rebase, proposed, waits, nomerge, mainConflict, refused, conflict }) {
  const row = (code, reason, mergeFailed = false) => ({ code, reason, mergeFailed });
  const michael = what => row(12, `${m} needs Michael: ${what}`);
  if (merged) return row(0, `${m} merged`);
  if (needs) return michael(need);
  if (rebase) return row(0, `${m} verified; its re-base waits`);
  if (proposed) return row(0, `${m} proposed`);
  if (waits) return row(0, `${m} verified; its PR waits`);
  if (nomerge) return mainConflict ? michael(`${main} conflicts with its lane`) : row(0, `${m} verified; ${main} did not merge into its lane; its merge is tried again`);
  if (policy === "off") return row(0, `${m} verified`);
  if (refused) return michael("merge refused");
  if (conflict) return michael(`conflicts with ${main}`);
  return { ...michael("its merge"), mergeFailed: true };
}

// reap's reading of the exit file, its text or null, as `read -r code why` has it: read fails at end of file on a line
// with no newline, and trims blanks only (never .trim(): a CR and a no-break space stay). crash opens the card; ends
// ends the run (a session cap, a usage limit, the weekly budget, feature-list edits). Unit tests can't reach bash's own
// fallback for no answer, which reads as the crash.
export function closedLane(text) {
  const crash = "lane exited unexpectedly";
  const nl = text === null ? -1 : text.indexOf("\n");
  const [, code, why] = nl < 0 ? [, "12", crash] : /^[ \t]*([^ \t]*)[ \t]*(.*?)[ \t]*$/s.exec(text.slice(0, nl));
  return { code, why, crash: why === crash, ends: code === "13" || why === "feature-list edits" };
}

// The lists the run's end is told from; bash builds the reason. done: the summary's n/n, as written. blocked keeps the
// order given (bash's sort -u, by the driver's locale, whose order the end reason's bytes depend on). needs: features
// that could run but wait on a milestone that needs Michael, so only when next isn't empty.
export function runEnd({ summary, parked, blocked, next, needs }) {
  const m = /^([0-9]+)\/([0-9]+)/.exec(summary);
  return { done: !!m && m[1] === m[2], parked, blocked: blocked.filter(id => !parked.includes(id)), needs: next ? needs : [] };
}

// finish's maps, each a prefix as `case` has it: the end's card (usage limits and the like), the notification's high
// priority with its actions, the desk.
const NEEDS = [["feature-list edits", "feature_list_edits"], ["initializer failed", "initializer_failed"], ["usage limit", "usage_limit"], ["weekly budget", "weekly_budget"]];
const HIGH = ["blocked on", "waiting on Michael", "feature-list edits", "initializer failed"], DESK = ["blocked on", "waiting on Michael"];
export function endKind(reason) {
  const on = p => reason.startsWith(p);
  return { needs: NEEDS.find(([p]) => on(p))?.[1] ?? "", high: HIGH.some(on), desk: DESK.some(on) };
}

const lines = s => s.split("\n").filter(Boolean);
const bit = b => (b ? 1 : 0);
const whole = s => (/^(0|[1-9][0-9]*)$/.test(s ?? "") ? +s : NaN);   // what bash's (( )) took for a number here: 08 and 1e3 it refused

export const main = captured((args, io, say) => {
  const [q, ...a] = args;
  if (q === "verify-round") {
    const [done, newEntry, evidence, last] = a.map(x => x === "true");
    say(verifyRound({ done, newEntry, evidence, last }));
    return 0;
  }
  if (q === "suite-verdict") { say(suiteVerdict({ result: a[0], green: a[1] === "1", fixOnly: a[2] === "1" })); return 0; }
  if (q === "fix-round") return fixRoundOpens({ mode: a[0], fixn: whole(a[1]), max: whole(a[2]) }) ? 0 : 1;   // NaN: the card
  if (q === "verdict") {
    const [result, own, mode, ...failed] = a, o = { result, own: own === "1", mode };
    labelled(say, { need: verifyNeed({ ...o, failed }), ...verifyCard(o) });
    return 0;
  }
  if (q === "lane-done") {   // one line and no label: bash takes the reason whole, so an empty need keeps its colon and space
    const [m, main, policy, need, ...markers] = a, on = n => markers.includes(n);
    const r = laneDone({ m, main, policy, need, merged: on("merged"), needs: on("needs"), rebase: on("rebase"), proposed: on("proposed"), waits: on("waits"),
      nomerge: on("nomerge"), mainConflict: on("main-conflict"), refused: on("refused"), conflict: on("conflict") });
    say(`${r.code} ${bit(r.mergeFailed)} ${r.reason}`);
    return 0;
  }
  if (q === "closed") {
    const { code, why, crash, ends } = closedLane(textOf(a[0]));
    labelled(say, { code, why, crash: bit(crash), ends: bit(ends) });
    return 0;
  }
  if (q === "run-end") {
    const [summary, parked = "", blocked = "", next = "", ...needs] = a;
    const r = runEnd({ summary, parked: lines(parked), blocked: lines(blocked), next, needs });
    labelled(say, { done: bit(r.done), parked: r.parked.join(","), blocked: r.blocked.join(","), needs: r.needs.join(",") });
    return 0;
  }
  if (q === "end-kind") {
    const { needs, high, desk } = endKind(a[0] ?? "");
    labelled(say, { needs, high: bit(high), desk: bit(desk) });
    return 0;
  }
  console.error("usage: lane.mjs verify-round <done> <new entry> <evidence> <last model> | suite-verdict <result> <green 0|1> <fix only> | fix-round <mode> <rounds> <max> | verdict <result> <own 0|1> <mode> <failed id>… | lane-done <m> <main> <policy> <need> <marker>… | closed <exit file> | run-end <summary> <parked> <blocked> <next> <needs>… | end-kind <reason>");
  return 2;
});

if (isMain(import.meta.url)) runCli(main);
