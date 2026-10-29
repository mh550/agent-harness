// What waits on Michael: one record per item, <state dir>/needs/<seq>.json, resolved into needs/done/ (plan:
// docs/plans/2026-10-28-U2-needs-record.md §1-§3; decisions/2026-10-27-needs-record). node: built-ins and the harness's
// pure modules (view, inbox, notify, parked, features).
//
//   open <state dir> <run> <project> <reason> <subject> [key=value…]  → the ref; 0 new, 3 refreshed (same key open), 1 bad
//                                              (facts: feature, milestone, list, why, attempts, failed, end_reason, main, head, …)
//   sweep <state dir>…                         → "resolved <ref> (<why>)" per item its reason's rule resolves (moved to done/)
//   done <state dir> <ref> [--why <text>]      → "resolved <ref>"; 1 for an unknown, resolved or synthesized ref
//   list <state dir>… [--all] [--json] [--run <id>] [--runner 0|1] [--queue <dir>]  → the open items as cards, block
//                                              before warn, oldest first (read-only; --all: and those resolved in the
//                                              last 7 days), with the synthesized ones; a parked card's commands and run
//                                              state as of now (a queue runner up, a continuation queued in <dir>)
//   card <reason> <facts.json>                 → the card JSON the reason's template fills (list and inbox paths read)
//   md <state dir>                             → <record>/needs.md's text (open and sweep write it when it changes)
//   fields <state dir> <ref>                   → title, body, click, priority and actions, each NUL-ended (needs_notify)
// HARNESS_NOW (epoch seconds) stands in for the clock. A state dir's meta.env names its worktree and project (WT, RUN_ID,
// PROJECT_DIR); the record's feature_list.json is in the worktree.
import { existsSync, mkdirSync, readFileSync, readdirSync, renameSync, statSync, writeFileSync } from "node:fs";
import { basename, isAbsolute, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import { ago, card as viewCard, context, cut, cutFront, displayWidth, glyph, home, paint, rule as viewRule, section } from "./view.mjs";
import { question as inboxQuestion, questionLine, files as inboxFiles } from "./inbox.mjs";
import { compareUrl, githubUrls } from "./notify.mjs";
import { commandsFor, runState } from "./parked.mjs";
import { deps } from "./features.mjs";
import { branchesOf, busyRun, changes, envFile, gitIn, liveRun, pidAlive as alive } from "./overlap.mjs";

// The 15 reasons (plan §2.1): kind is the v1 event enum's, severity block or warn, priority ntfy's.
const R = (kind, severity, priority) => ({ kind, severity, priority });
const runEnd = "ended";   // the run-level reasons' title: the run-end notification's
export const REASONS = {
  parked: R("park", "block", "high"), given_up: R("blocked", "block", "high"),
  verify_thin: R("needs_michael", "block", "high"), verify_red: R("needs_michael", "block", "high"),
  verify_recheck: R("needs_michael", "block", "high"), merge_conflict: R("needs_michael", "block", "high"),
  merge_refused: R("needs_michael", "block", "high"), main_conflict: R("needs_michael", "block", "high"),
  base_conflict: R("needs_michael", "block", "high"), feature_list_edits: R("needs_michael", "block", "high"),
  initializer_failed: R("needs_michael", "block", "high"), driver_crash: R("needs_michael", "block", "high"),
  usage_limit: R("limit", "warn", ""), weekly_budget: R("limit", "warn", ""), overlap: R("needs_michael", "warn", ""),
};
const RUN_LEVEL = new Set(["feature_list_edits", "initializer_failed", "usage_limit", "weekly_budget"]);
const FEATURE_SUBJECT = new Set(["parked", "given_up"]), MILESTONE_SUBJECT = /^(verify_|merge_|main_conflict|base_conflict|driver_crash)/;

const isoAt = epoch => new Date(epoch * 1000).toISOString();
const nowOf = env => /^\d+$/.test(env.HARNESS_NOW ?? "") ? Number(env.HARNESS_NOW) : Date.now() / 1000;
const nul = v => v === undefined || v === "" ? null : v;

// ---- the cards (U2-04, plan §3): facts → every card field, one template per reason held as data below ----
const lines = (v, sep = "\n") => (Array.isArray(v) ? v : String(v ?? "").split(sep)).map(s => String(s).trim()).filter(Boolean);
const yes = v => v === true || v === "1" || v === "true";
const n_ = (n, w) => `${n} ${w}${n === 1 ? "" : "s"}`;
const cut40 = s => { s = String(s ?? "").replace(/\s+/g, " ").trim(); return s.length > 40 ? s.slice(0, 39) + "…" : s; };
const isRun = s => s === "run" || s === "record";

/** Pure: the ids of the unfinished features that wait on subject (a feature id; a milestone: its features; "run" or
 *  "record": all of them), through their deps (features.mjs: "after", else every feature before). */
export function waitsOn(features, subject) {
  const byId = new Map(features.map(f => [f.id, f]));
  const own = byId.has(subject) ? new Set([subject]) : new Set(features.filter(f => f.milestone === subject).map(f => f.id));
  if (isRun(subject) || !own.size) return isRun(subject) ? features.filter(f => !f.passes).map(f => f.id) : [];
  const out = new Set();
  for (let more = true; more;) {   // to a fixed point: an "after" may name a later feature
    more = false;
    for (const f of features) if (!own.has(f.id) && !out.has(f.id) && deps(features, f).some(d => own.has(d) || out.has(d))) { out.add(f.id); more = true; }
  }
  return features.filter(f => out.has(f.id) && !f.passes).map(f => f.id);
}

/** Pure: main's merge subjects as runs and milestones (`<run> M3 (PR #34)`, one run's consecutive ones `M1–M5 (PRs
 *  #32–#36)`, else `M1, M3 (PRs #32, #34)`), another PR as `PR #<n>`, ownRun's left out; none → "new commits". */
export function mergedBy(subjects, ownRun) {
  const runs = new Map(), other = new Set();
  for (const l of lines(subjects)) {
    // merge_one's head is harness-merge/<run>-<m> (m may be "default"): the run's own by its prefix, else split at the last -
    const h = /^Merge pull request #(\d+) from [^/\s]+\/harness-merge\/(.+)-([^-\s]+)$/.exec(l);
    if (h) {
      if (ownRun && h[2] === ownRun) continue;   // exactly: another run's id may start with this one's
      if (!runs.has(h[2])) runs.set(h[2], new Map());
      const ms = runs.get(h[2]); if (!ms.has(h[3])) ms.set(h[3], Number(h[1]));   // git log is newest first: a re-merge keeps its newest PR
      continue;
    }
    const p = /^Merge pull request #(\d+) /.exec(l); if (p) other.add(Number(p[1]));
  }
  const num = m => Number(/\d+$/.exec(m)?.[0] ?? NaN), pre = m => m.replace(/\d+$/, "");
  const parts = [...runs].map(([run, ms]) => {
    const xs = [...ms].map(([m, pr]) => ({ m, pr })).sort((a, b) => a.pr - b.pr), [a, z] = [xs[0], xs.at(-1)];
    if (xs.length === 1) return { pr: a.pr, s: `${run} ${a.m} (PR #${a.pr})` };
    const row = xs.every((x, i) => !i || pre(x.m) === pre(a.m) && num(x.m) === num(xs[i - 1].m) + 1 && x.pr === xs[i - 1].pr + 1);
    return { pr: a.pr, s: row ? `${run} ${a.m}–${z.m} (PRs #${a.pr}–#${z.pr})` : `${run} ${xs.map(x => x.m).join(", ")} (PRs ${xs.map(x => "#" + x.pr).join(", ")})` };
  });
  parts.push(...[...other].map(pr => ({ pr, s: `PR #${pr}` })));
  return parts.length ? parts.sort((a, b) => a.pr - b.pr).map(p => p.s).join("; ") : "new commits";
}

// The facts as the templates read them: lists split, files as {path, line}, waits computed when not given.
function factsOf(f) {
  const features = Array.isArray(f.features) ? f.features : [], s = String(f.subject ?? "");
  const rec = f.record || (f.worktree && f.run ? join(f.worktree, ".harness/runs", f.run) : "");
  return { ...f, s, features, rec, wt: f.worktree || "", home: f.home || "", rb: f.record_branch || (f.run ? `harness/${f.run}` : ""),
    b: f.branch || f.record_branch || "", mb: f.main_branch || "main", failed: lines(f.failed, /[\s,]+/),
    files: lines(f.files).map(x => { const m = /^(.*?):(\d+)$/.exec(x); return m ? { path: m[1], line: Number(m[2]) } : { path: x, line: null }; }),
    waits: f.waits ? lines(f.waits, /[\s,]+/) : waitsOn(features, s), log: f.log || (f.state ? join(f.state, "run.log") : "") };
}
// where rows: a worktree file (its blob on the branch, #L<line>), a record file (on the record branch), a plain path, a link
const inWt = (F, p) => p.startsWith("~/") && F.home ? join(F.home, p.slice(2)) : isAbsolute(p) || !F.wt ? p : join(F.wt, p);
function fileRow(F, p, line, label) {
  const abs = inWt(F, p), rel = F.wt && abs.startsWith(F.wt + "/") ? abs.slice(F.wt.length + 1) : null;
  const u = rel && githubUrls(F.origin, F.b, rel);
  return { path: abs, line: line ?? null, label, url: u ? u.blob + (line ? `#L${line}` : "") : null };
}
const recRow = (F, name, label) => F.rec ? { path: join(F.rec, name), line: null, label,
  url: githubUrls(F.origin, F.rb, `.harness/runs/${F.run}/${name}`)?.blob ?? null } : null;
const pathRow = (path, label) => path ? { path, line: null, label, url: null } : null;
const linkRow = (url, label) => url ? { path: null, line: null, label, url } : null;
const compare = F => linkRow(compareUrl(F.origin, F.mb, F.b), "compare");
const o = (text, why) => ({ text, why });   // the one with a why is the recommended one
const cont = F => `harness continue ${F.run}`;
// a shell word: as it is when it needs no quoting, else single-quoted (a path with a blank, a ; or a $ pastes as one word)
const sq = w => /^[\w@%+=:,./-]+$/.test(String(w)) ? String(w) : `'${String(w).replace(/'/g, "'\\''")}'`;
// a fix to a branch in a worktree of its own, from <base> as origin has it: never the slot (the next milestone reuses
// it, perhaps mid-session) nor the record worktree a live driver commits in; cmds run there, the last pushes it
const fixDir = F => join(F.fix_root || `/tmp/harness/${F.project || "project"}`, `fix-${F.run}-${F.s}`);
const onBranch = (F, base, ...cmds) => {
  if (!F.rec || !F.b) return [];
  const g = `git -C ${sq(F.rec)}`, d = sq(fixDir(F));
  return [`${g} fetch -q origin && ${g} worktree add --detach ${d} ${sq(base)}`, ...cmds.map(c => `cd ${d} && ${c}`)];
};
const mergeIn = (F, base, what) => onBranch(F, base, `git merge ${sq(what)}`, `git push origin HEAD:${sq(F.b)}`);
const waitN = F => n_(F.waits.length, "feature"), waitV = F => `${waitN(F)} wait${F.waits.length === 1 ? "s" : ""}`;
const nfiles = F => F.files.length ? ` (${n_(F.files.length, "file")})` : "";
const names = F => F.files.length ? F.files.slice(0, 4).map(f => basename(f.path)).join(", ") + (F.files.length > 4 ? ` and ${F.files.length - 4} more` : "") : "the same files";
const ofS = F => isRun(F.s) ? F.features : F.features.filter(f => f.milestone === F.s);
const passingOn = F => ofS(F).filter(f => f.passes).length, unfinished = F => isRun(F.s) ? 0 : ofS(F).filter(f => !f.passes).length;
const verifyWhere = F => [recRow(F, "progress.md", "progress"), pathRow(F.log, "log")];
const parkWhy = F => String(F.why ?? "").split("\n")[0].trim();

export const TEMPLATES = {
  parked: {
    headline: F => `${F.s} parked${parkWhy(F) ? ": " + parkWhy(F) : ""}`,
    cost: F => `${F.s} and what waits on it stay unbuilt until you answer`,
    why: F => `Its session parked it${parkWhy(F) ? ` (${parkWhy(F)})` : ""} and asked in INBOX.md. The lane loop (lib/lane.sh) skips it until the answers change (parked.json), then unparks it.`,
    where: (F, q) => [...q.files.map(x => fileRow(F, x.path, x.line, "file")), q.file ? { path: q.file, line: q.line, label: "question", url: q.url } : null],
    options: () => [o("answer in INBOX.md or with harness answer", "the session asked for exactly this"), o("leave it parked: other features go on")],
    commands: F => commandsFor(F.run, { running: yes(F.running), queued: yes(F.queued), runner: yes(F.runner) }),
  },
  given_up: {
    headline: F => `${F.s} given up${F.attempts ? ` after ${n_(Number(F.attempts), "attempt")}` : ""}`,
    cost: F => F.waits.length ? `${waitV(F)} behind it` : "nothing else waits behind it",
    why: F => `Each feature gets MAX_ATTEMPTS (${F.max_attempts || F.attempts || 2}) fresh sessions (the lane loop in lib/lane.sh, counted in attempts.json). ${F.s} used them without passing, and the features after it wait (F blocked in lib/features.mjs). Its sessions' entries say what failed.`,
    where: verifyWhere,
    options: F => [o("read its entries, fix or reword the feature by a brief, then continue", "a continue gives it fresh attempts"),
      o("a brief that drops or splits it, then continue"), o(`leave it: the run ends blocked on ${F.s}`)],
    commands: F => [`harness report ${F.run}`, cont(F)],
  },
  verify_thin: {
    headline: F => `${F.s} not verified: evidence too thin`,
    cost: F => `${F.s} doesn't merge; ${waitV(F)}`,
    why: F => `After ${F.s}'s features pass, a verify session re-runs every step and writes an evidence row per step (verify in lib/lane.sh). Too few rows after the escalated model means not verified. The features pass; only the evidence is short.`,
    where: verifyWhere,
    options: () => [o("read the verify entry; if the steps hold, continue: it re-verifies", "usually a step the verifier couldn't run"),
      o("fix the step wording by a brief, then continue")],
    commands: F => [cont(F)],
  },
  verify_red: {
    headline: F => `${F.s} not verified: suite red on the merged tree`,
    cost: F => `${F.s} doesn't merge; ${waitV(F)}`,
    why: F => F.variant === "rebase"
      ? `A milestone whose main moved is re-based onto main before it merges (rebase in lib/lane.sh). The suite was red after the re-base: main's newer commits and ${F.s} disagree.`
      : `The verify merges origin/main into the lane first (sync_main in lib/record.sh), so the suite runs on the tree that would land. It was red there: main's newer commits and ${F.s} disagree.`,
    where: F => [pathRow(F.wt, "worktree"), recRow(F, "harness-log.md", "log")],
    options: () => [o("run the suite in the worktree, fix, push, continue", "a red merged tree is a real disagreement until shown otherwise"),
      o("continue as is (a flake)")],
    commands: F => [...F.suite ? onBranch(F, `origin/${F.b}`, F.suite) : [], cont(F)],
  },
  verify_recheck: {
    headline: F => `${F.s}: ${F.failed.length ? F.failed.join(", ") + " failed the re-check" : "the re-check failed"}`,
    cost: F => `${F.s} doesn't merge; ${waitV(F)}`,
    why: F => F.variant === "tag"
      ? `A milestone whose main moved is re-based from its verified tag (rebase in lib/lane.sh). The tag is gone, so it can't be, and nothing of ${F.s} merges until it is verified again.`
      : F.variant === "rebase"
      ? `A milestone whose main moved is re-based and verified again (rebase in lib/lane.sh), a few rounds at most. ${F.s} used its rounds without a verified tree.`
      : `The verifier un-passes a feature whose steps don't hold, and the lane retries it once per verify round (MAX_VERIFY_ROUNDS, verify in lib/lane.sh). ${F.failed.length ? F.failed.join(", ") : "Its features"} failed in the last round.`,
    where: F => [recRow(F, "progress.md", "progress"), recRow(F, "feature_list.json", "list")],
    options: () => [o("read the verify entry, fix by a brief, continue", "the entry names the step that didn't hold"), o("continue as is (fresh attempts)")],
    commands: F => [cont(F)],
  },
  merge_conflict: {
    headline: F => `${F.s} conflicts with main${nfiles(F)}`,
    cost: F => `${F.s} doesn't merge; ${waitV(F)}`,
    why: F => F.variant === "rebase" || F.variant === "moving"
      ? `A verified milestone is re-based onto main before it merges (rebase in lib/lane.sh); ${F.variant === "moving" ? "main kept moving through every round" : "the re-base conflicted"}. Both sides change the files below.`
      : `Verified milestones merge into main through a PR (merge_one in lib/record.sh) only when git merge-tree finds no conflict. main moved since ${F.s} was verified, and both sides change the files below.`,
    where: F => [...F.files.map(x => fileRow(F, x.path, x.line, "conflict")), compare(F)],
    options: F => [o(`merge main into ${F.b || "the branch"} by hand, resolve, push, harness merge`, "verified work is kept"),
      o(`a new run from main whose brief names ${F.b || "the branch"}`), o("leave it: nothing of it merges")],
    commands: F => [...mergeIn(F, `origin/${F.b}`, `origin/${F.mb}`), `harness merge ${F.run}`],
    tried: F => F.tried,
  },
  merge_refused: {
    headline: F => `${F.s}: the merge was refused`,
    cost: F => `${F.s}'s PR is open; ${waitV(F)}`,
    why: () => "merge_one in lib/record.sh asks gh to merge the PR at the verified commit (--match-head-commit). GitHub refused: a branch rule, a check, or the head moved. The PR is open.",
    where: F => [linkRow(F.pr, "PR"), pathRow(F.log, "log")],
    options: () => [o("open the PR and merge it there", "the cause is on GitHub"), o("harness merge after fixing the rule")],
    commands: F => [...F.pr ? [`gh pr view ${F.pr}`] : [], `harness merge ${F.run}`],
  },
  main_conflict: {
    headline: F => `main conflicts with the run branch${nfiles(F)}`,
    cost: F => { const n = F.waits.length + unfinished(F); return `no milestone of this run can merge${n ? `; ${n_(n, "feature")} build${n === 1 ? "s" : ""} on a base main has moved past` : ""}`; },
    why: F => `Before each verify the driver merges origin/main into the run branch (sync_main in lib/record.sh), so the tree that is verified is the tree that lands. main gained ${mergedBy(F.subjects, F.run)}, and both sides change ${names(F)}; the driver aborted the merge and carried on.`,
    where: F => [...F.files.map(x => fileRow(F, x.path, x.line, "conflict")), compare(F)],
    options: F => [o("merge main into the branch by hand, resolve, push, continue", passingOn(F) ? `the branch holds ${n_(passingOn(F), "passing feature")} of ${F.s}, kept` : "the branch's work is kept"),
      o("stop it; a new run from main whose brief names the branch"), o("leave it: sessions go on, nothing merges")],
    commands: F => [...mergeIn(F, `origin/${F.b}`, `origin/${F.mb}`), cont(F)],
    tried: F => F.tried,
  },
  base_conflict: {
    headline: F => `${F.s} can't open: its base conflicts${F.with ? ` (${F.with})` : ""}`,
    cost: F => `${F.s} and ${waitV(F)}`,
    why: F => F.variant === "diverged"
      ? `A lane reuses its branch when origin's copy agrees (slot_open in lib/record.sh). ${F.with || "origin's branch"} and the local branch have diverged, so the lane never opened.`
      : F.variant === "slot"
      ? `A lane works in a slot worktree of its own (slot_open in lib/record.sh). The slot couldn't be checked out (slot_fail), so the lane never opened.`
      : `A lane starts from main plus every dependency's verified tag main lacks (slot_open in lib/record.sh). Merging ${F.with || "a dependency"} into it conflicted, so the lane never opened.`,
    where: F => [pathRow(F.wt, "worktree"), pathRow(F.log, "log")],
    options: F => [o(`merge ${F.with || "the dependency"} into ${F.b || "the lane branch"} by hand, push, continue`, "the lane then opens on the merged base"),
      o(`wait for ${F.with || "the dependency"} to merge into main, then continue`)],
    commands: F => [...F.with ? mergeIn(F, `origin/${F.mb}`, F.with) : [], cont(F)],   // the lane opens on origin's copy of its branch
  },
  feature_list_edits: {
    headline: () => "stopped: sessions kept editing the feature list",
    cost: F => `the run ended; ${waitN(F)} unbuilt`,
    why: () => "A session may only flip its own passes; F repair in lib/features.mjs restores the rest. MAX_REPAIRS sessions in a row did more, so the lane stopped the run (lib/lane.sh).",
    where: F => [recRow(F, "harness-log.md", "log"), recRow(F, "feature_list.json", "list")],
    options: () => [o("read the restored-the-feature-list notes; a brief that says what the sessions wanted; continue", "the notes show what they wanted"),
      o("change the list's wording in a new run")],
    commands: F => [cont(F)],
  },
  initializer_failed: {
    headline: () => "stopped: the initializer wrote no valid feature list",
    cost: () => "nothing was built",
    why: () => "A run starts with one initializer session that writes feature_list.json from the spec (the driver's first step, lib/driver.sh). Its output didn't parse (F summary in lib/features.mjs).",
    where: F => [pathRow(F.state ? join(F.state, "logs") : "", "log"), recRow(F, "feature_list.json", "list")],
    options: () => [o("read the init log, fix the spec or brief, continue", "the log shows what it wrote"), o("write the list by hand on the record branch")],
    commands: F => [cont(F)],
  },
  driver_crash: {
    headline: F => isRun(F.s) ? "the driver stopped without an end" : `lane ${F.s} exited unexpectedly`,
    cost: F => `the run is not going; ${waitN(F)} unbuilt`,
    why: F => isRun(F.s)
      ? "The driver records why it ended (finish in lib/driver.sh). Its EXIT trap wrote the default reason, or no trap ran at all (a SIGKILL). run.log's last lines say what it was doing."
      : `Each lane is a process of its own (lib/lane.sh) that the coordinator reaps (reap in lib/driver.sh). Lane ${F.s} exited without an end of its own. run.log's last lines say what it was doing.`,
    where: F => [pathRow(F.log, "log")],
    options: () => [o("read run.log's tail, then continue", "state is kept"), o("leave it")],
    commands: F => [...F.log ? [`tail -50 ${sq(F.log)}`] : [], cont(F)],
  },
  usage_limit: {
    headline: () => "ended on the usage limit",
    cost: F => `${waitN(F)} left; nothing runs until it continues`,
    why: () => "MAX_LIMIT_HITS sessions in a row were refused on the usage limit (MET limit in lib/metrics.mjs). The run ended rather than wait (lib/lane.sh).",
    where: F => [pathRow(F.log, "log")],
    options: F => [o("continue once the window resets", "the window resets by itself"), o(`queue it: harness queue add --continue ${F.run}`)],
    commands: F => [cont(F)],
  },
  weekly_budget: {
    headline: () => "ended on the weekly budget",
    cost: F => `${waitN(F)} left; nothing runs until it continues`,
    why: () => "Past WEEKLY_STOP_AT of the 7-day window (weekly_over in lib/config.sh), the run ends before its next session. Nothing failed.",
    where: F => [pathRow(F.log, "log")],
    options: () => [o("continue after the window", "the budget comes back as the window rolls"), o("raise WEEKLY_STOP_AT")],
    commands: F => [cont(F)],
  },
  overlap: {
    headline: F => `${F.run} and ${F.s} change the same files`,
    cost: () => "the second to merge will conflict",
    why: F => `Two runs that change the same files conflict when the second merges (merge_one in lib/record.sh). ${F.run} and ${F.s} both change ${names(F)} (harness start compared their branches and what their specs and briefs name).${F.second ? ` ${F.second} merges second: its merge conflicts on these files unless ${F.second === F.s ? F.run : F.s} is merged first and it continues from there.` : ""}`,
    where: F => [...F.files.map(x => fileRow(F, x.path, x.line, "file")), pathRow(F.wt, "worktree")],
    options: () => [o("let the first merge, then continue the second", "one conflict, resolved once"), o("stop one")],
    commands: F => [`harness show ${F.s}`],
  },
};

// "<subject> (<its description, or its count>); <n> features wait [in <milestones>]", or "; nothing else waits"
function blockedOf(F) {
  const f = F.features.find(x => x.id === F.s), mine = F.features.filter(x => x.milestone === F.s);
  const pass = xs => `${xs.filter(x => x.passes).length}/${xs.length} passing`;
  // a re-check's failed ids ride with the milestone's count: what to read first
  const failed = F.failed.length ? `; ${F.failed.join(", ")} failed the re-check` : "";
  const what = f ? (f.description ? `${F.s} (${cut40(f.description)})` : F.s) : mine.length ? `${F.s} (${pass(mine)}${failed})`
    : isRun(F.s) ? `${F.run}${F.features.length ? ` (${pass(F.features)})` : ""}` : F.s;
  const ms = [...new Set(F.waits.map(id => F.features.find(x => x.id === id)?.milestone).filter(Boolean))];
  return `${what}; ${F.waits.length ? `${waitV(F)}${ms.length > 1 ? ` in ${ms.join(", ")}` : ""}` : "nothing else waits"}`;
}

/** Pure: a card from the facts (plan §1.2, §3): the reason's template filled. facts: subject, run, features (the parsed
 *  list) and inbox_text (INBOX.md) as the I/O side reads them, and needs_open's key=value strings. */
export function card(reason, facts) {
  const t = TEMPLATES[reason]; if (!t) throw new Error(`unknown reason ${reason}`);
  if (!facts.run || !facts.subject) throw new Error("a card needs run and subject");
  const F = factsOf(facts);
  let q = { files: [] }, question = null, run_state = null, from = "question";
  if (reason === "parked") {
    const text = inboxQuestion(facts.inbox_text ?? "", F.s), line = text ? questionLine(facts.inbox_text, F.s) : null;
    const u = line && githubUrls(F.origin, F.rb, `.harness/runs/${F.run}/INBOX.md`);
    question = { file: nul(facts.inbox) ?? (F.rec ? join(F.rec, "INBOX.md") : null), line, url: u ? `${u.blob}?plain=1#L${line}` : null, text };
    q = { ...question, files: inboxFiles(text) };
    // a question without a Files: line points at the session's files (entries.mjs sessionFiles; decisions/2026-10-27-question-locations)
    if (!q.files.length) { q.files = lines(facts.session_files).map(path => ({ path, line: null })); from = "session"; }
    run_state = runState({ running: yes(F.running), ending: yes(F.ending), queued: yes(F.queued) });
  }
  const opts = t.options(F), rec = opts.findIndex(x => x.why);
  return { headline: t.headline(F), blocked: blockedOf(F), cost: t.cost(F), why: t.why(F),
    where: t.where(F, q).filter(Boolean), commit: { main: String(facts.main ?? "").slice(0, 7) || null, branch: String(facts.head ?? "").slice(0, 7) || null },
    branch: nul(F.b), question,
    options: opts.map((x, i) => ({ key: "abcdefgh"[i], text: x.text, recommended: i === rec, why: i === rec ? x.why : null })),
    commands: t.commands(F), files_from: reason === "parked" && q.files.length ? from : "driver", run_state,
    ...(t.tried && nul(t.tried(F)) ? { tried: t.tried(F) } : {}) };   // only when set: a key on every card changes status --json's
}
const title = (reason, subject, f, c) => RUN_LEVEL.has(reason) || reason === "driver_crash" && subject === "run"
  ? `[${f.run}] ${runEnd}: ${f.end_reason || c.headline}` : `[${f.run}] ${subject} needs you`;

/** Pure: a new item from the facts ({run, project, reason, subject, seq, feature, milestone, …}) at epoch seconds now. */
export function record(facts, now) {
  const { run, project, reason, subject, seq } = facts, r = REASONS[reason];
  if (!r) throw new Error(`unknown reason ${reason}`);
  if (!subject) throw new Error("no subject");
  const c = card(reason, { ...facts, subject }), at = isoAt(now);
  // the click is the record's needs.md on the record branch (a caller's click= wins: a refused merge's PR)
  const click = nul(facts.click) ?? githubUrls(facts.origin, facts.record_branch || `harness/${run}`, `.harness/runs/${run}/needs.md`)?.blob ?? null;
  const i = { v: 1, id: randomUUID(), at, kind: r.kind, project, run, feature: nul(facts.feature), title: title(reason, subject, facts, c),
    body: "", priority: r.priority, click, actions: nul(facts.actions), context: null,
    ref: `${run}/${seq}`, key: `${reason}:${subject}`, reason, severity: r.severity, milestone: nul(facts.milestone),
    seen: 1, updated_at: at, card: c, resolved_at: null, resolved_by: null, resolved_why: null };
  return { ...i, body: bodyOf(i, now, { HOME: facts.home ?? "" }, facts) };
}

/** Pure: an open item seen again; what the facts say now replaces what they said, id, at and ref stay. */
export function refresh(old, facts, now) {
  const n = record({ ...facts, seq: old.ref.slice(old.ref.lastIndexOf("/") + 1) }, now);
  return { ...old, title: n.title, body: n.body, priority: n.priority, click: n.click, actions: n.actions, card: n.card,
    seen: (old.seen ?? 1) + 1, updated_at: n.updated_at };
}

const subjectOf = i => i.key.slice(i.key.indexOf(":") + 1);
// The rule that resolves an open item (plan §2.1), its words, or null. st: { removed, ended, passing, parked, attempts,
// max_attempts, markers, and with open overlap items overlaps: {<run>: "open"|"merged"|"gone"}, self: the same of its own }
function rule(i, st) {
  const s = subjectOf(i), has = m => st.markers.includes(m), passes = st.passing.includes(s);
  if (st.removed) return "run removed";
  switch (i.reason) {
    case "parked": return passes ? "feature passes" : s in (st.parked ?? {}) ? null : "feature unparked";
    case "given_up": return passes ? "feature passes" : (st.attempts?.[s] ?? 0) < st.max_attempts ? "attempts reset" : null;
    // needs-<m> first: a re-base's failure (rebase in lib/lane.sh) leaves the old verified-<m> in place
    case "verify_thin": case "verify_red": case "verify_recheck":
      return has(`merged-${s}`) ? "milestone merged" : has(`needs-${s}`) ? null : has(`verified-${s}`) ? "milestone verified" : `needs-${s} cleared`;
    case "merge_conflict": return has(`merged-${s}`) ? "milestone merged" : has(`conflict-${s}`) || has(`needs-${s}`) ? null : "conflict cleared";
    case "merge_refused": return has(`merged-${s}`) ? "milestone merged" : has(`refused-${s}`) ? null : "refusal cleared";
    // a lane's marker goes only with its next verify: merged by hand or harness merge, none comes
    case "main_conflict": return has(`merged-${s}`) ? "milestone merged" : has(`main-conflict-${s}`) ? null : "main merged cleanly";
    case "base_conflict": return has(`needs-${s}`) ? null : `needs-${s} cleared`;
    case "driver_crash": return s !== "run" ? has(`needs-${s}`) ? null : `needs-${s} cleared` : st.ended ? null : "run continued";
    // either side's changes on main (or nothing left to merge), or the other run gone: no conflict left to predict
    case "overlap": { const o = st.overlaps?.[s];
      return o === "gone" ? "other run gone" : o === "merged" ? "other run merged" : o && st.self === "merged" ? "this run merged" : null; }
    default: return RUN_LEVEL.has(i.reason) && !st.ended ? "run continued" : null;
  }
}

/** Pure: the open items split into those that stay and those the state resolves (resolved_* filled, by sweep). */
export function sweep(items, st, now = Date.now() / 1000) {
  const keep = [], resolved = [];
  for (const i of items) {
    const why = rule(i, st);
    if (why) resolved.push({ ...i, resolved_at: isoAt(now), resolved_by: "sweep", resolved_why: why }); else keep.push(i);
  }
  return { keep, resolved };
}

/** Pure: the items the state implies and no open record holds (never stored): a SIGKILLed driver (driver.pid names no
 *  live process, no ended) and each parked.json feature that doesn't pass (none once the worktree is gone). st: { run,
 *  project, removed, driver ("live" · "dead" · null), ended, passing, parked, log_mtime, wt_gone, facts } */
export function synthesize(st, open) {
  if (st.removed) return [];
  const keys = new Set(open.map(i => i.key)), out = [];
  const one = (reason, subject, ref, at, f = {}) => {
    const i = record({ ...st.facts, run: st.run, project: st.project, reason, subject, seq: 0, ...f }, 0);
    return { ...i, id: ref, at, updated_at: at, ref };
  };
  for (const [id, v] of st.wt_gone ? [] : Object.entries(st.parked ?? {}))   // a gc'd worktree: nothing left to answer
    if (!st.passing.includes(id) && !keys.has(`parked:${id}`))
      out.push(one("parked", id, `${st.run}/parked:${id}`, Date.parse(v?.at) ? v.at : isoAt(st.log_mtime ?? 0), { feature: id, why: String(v?.why ?? "") }));
  if (st.driver === "dead" && !st.ended && !keys.has("driver_crash:run"))
    out.push(one("driver_crash", "run", `${st.run}/crash`, isoAt(st.log_mtime ?? 0), { end_reason: "the driver stopped without an end" }));
  return out;
}

const SEV = { block: 0, warn: 1 };
/** Pure: block before warn, oldest first (a stable sort: ties keep their order; an unreadable at last). */
const atOf = i => Date.parse(i.at) || Infinity;
export const order = items => [...items].sort((a, b) => SEV[a.severity] - SEV[b.severity] || (atOf(a) === atOf(b) ? 0 : atOf(a) - atOf(b)));

// ---- the text view (plan §3.1): one view.mjs card per item ----
const tilde = (cmd, env) => { const h = (env.HOME ?? "").replace(/\/+$/, ""); return h ? cmd.split(h + "/").join("~/") : cmd; };
// INBOX text as the card wraps it: a paragraph's lines joined; code (indented), headings, list items, quotes and table
// rows kept on lines of their own, and every line of a ``` fence as it is (tabs as spaces: the view measures no tab)
const own_ = l => /^( {4}|#|[-*+>|] |\d+[.)] |Files\b)/.test(l);
function reflow(t) {
  const out = []; let fence = false, more = false;
  for (const l of t.replace(/\t/g, "    ").split("\n")) {
    const f = /^\s*```/.test(l);
    if (fence || f || own_(l)) { out.push(l.trimEnd()); more = false; if (f) fence = !fence; continue; }
    if (!l.trim()) { more = false; continue; }
    if (more) out[out.length - 1] += " " + l.trim(); else out.push(l.trim());
    more = true;
  }
  return out.join("\n");
}
const hm = epoch => { const d = new Date(epoch * 1000), p = n => String(n).padStart(2, "0"); return `${p(d.getHours())}:${p(d.getMinutes())}`; };

/** Pure: an item as card lines: "<glyph> <run> · <headline> · since <HH:MM> (<ago>) · <ref>" (narrow, or too long: "… ·
 *  <ago>" and a ref field), then blocked, question (parked) or why, where (home as ~; narrow: cut at the front), each
 *  URL on its own line, options, do, run (parked) and, resolved, by whom. */
export function renderCard(i, ctx, env = {}, { only = null } = {}) {
  const c = i.card ?? {}, t = Date.parse(i.at) || Date.parse(i.updated_at), at = t / 1000, sep = ` ${glyph("sep", ctx)} `, h = p => home(p, env);
  const a = t ? ago(at, ctx.now) : "?", since = t ? `since ${hm(at)} (${a})` : "since ?";
  const head = `${glyph("needs", ctx)} ${i.run}${sep}${c.headline ?? i.title ?? i.reason}`, wide = `${head}${sep}${since}${sep}${i.ref}`;
  const fits = !ctx.narrow && displayWidth(wide) <= ctx.width, room = ctx.width - 13;
  const where = (c.where ?? []).filter(w => w.path).map(w => { const t = `${h(w.path)}${w.line ? ":" + w.line : ""}${["file", "conflict"].includes(w.label) ? "" : ` (${w.label})`}`;
    return ctx.narrow ? cutFront(t, room, ctx) : t; });
  if (c.commit?.main || c.commit?.branch)
    where.push([c.commit.main && `main ${c.commit.main}`, ["branch", c.branch, c.commit.branch && `@ ${c.commit.branch}`].filter(Boolean).join(" ")].filter(x => x && x !== "branch").join(sep));
  const q = c.question, ask = q ? reflow(tilde(q.text ?? "", env)) || "(none in INBOX.md)" : null;
  const fields = [
    { label: "ref", value: fits ? null : `${i.ref}${sep}${since}` },
    { label: "blocked", value: [c.blocked, c.cost].filter(Boolean) },
    q ? { label: "question", value: ask } : { label: "why", value: c.why },
    { label: "tried", value: c.tried },
    { label: "where", value: where },
    ...(c.where ?? []).filter(w => w.url).map(w => ({ label: "", url: w.url })),
    { label: "options", value: (c.options ?? []).map(x => `(${x.key}) ${x.text}${x.recommended ? ` (recommended: ${x.why})` : ""}`) },
    { label: "do", value: (c.commands ?? []).map(x => tilde(x, env)) },
    { label: "run", value: c.run_state },
    { label: "resolved", value: i.resolved_at ? `${hm(Date.parse(i.resolved_at) / 1000)} (${ago(Date.parse(i.resolved_at) / 1000, ctx.now)}) by ${i.resolved_by}: ${i.resolved_why}` : null },
  ];
  // only: those fields (a where's URLs with it), no header line (a park's notification body)
  if (only) return viewCard("", fields.filter(f => only.includes(f.label) || f.url && only.includes("where")), ctx, { rule: false }).slice(1);
  const out = viewCard(fits ? wide : `${cut(head, ctx.width - displayWidth(sep + a), ctx)}${sep}${a}`, fields, ctx, { rule: false });
  return i.resolved_at ? out.map(l => paint(l, "dim", ctx)) : out;
}

/** Pure: the whole view: "NEEDS YOU <n> · <runs> runs", the cards (open, then with --all the resolved), a rule and the
 *  footer; nothing open and nothing resolved shown: "nothing needs you[ in <run>]". */
export function renderList(items, ctx, { run = "", env = {} } = {}) {
  const open = items.filter(i => !i.resolved_at), done = items.filter(i => i.resolved_at), runs = new Set(open.map(i => i.run)).size;
  const head = section("NEEDS YOU", open.length, runs > 1 ? `${runs} runs` : "", ctx);
  if (!items.length) return [head, `nothing needs you${run ? " in " + run : ""}`];
  const foot = ["done by hand: harness needs done <ref>", "resolved too: harness needs --all"], one = foot.join(` ${glyph("sep", ctx)} `);
  return [head, ...[...open, ...done].flatMap(i => renderCard(i, ctx, env)), viewRule(ctx), ...displayWidth(one) <= ctx.width ? [one] : foot];
}

/** Pure: the notification body (plan §3.2), plain at 60 columns (Unicode glyphs, no colour): the card; a park's is
 *  "PARKED: <why>", the question, the card's blocked, where and do, and the answer line its checks read. */
export function bodyOf(i, now, env = {}, facts = {}) {
  const ctx = context({ env: { COLUMNS: "60", HARNESS_GLYPHS: "unicode", HARNESS_COLOR: "never", HARNESS_NOW: String(Math.floor(now)) } });
  if (i.reason !== "parked") return renderCard(i, ctx, env).join("\n");
  const why = parkWhy(facts) || i.card?.headline, q = String(i.card?.question?.text ?? "").trim();
  return [`PARKED: ${why}`, "", ...q ? [q, ""] : [], ...renderCard(i, ctx, env, { only: ["blocked", "where", "do"] }), "",
    `Answer: harness answer ${i.run} "…"`].join("\n");
}

const mdLink = w => { const t = `${w.path ?? w.label}${w.line ? ":" + w.line : ""}`; return w.url ? `[${t}](${w.url})` : `\`${t}\``; };
/** Pure: <record>/needs.md, the notifications' click: per open item "## ⚠ <headline>", its ref and since, then each
 *  card field as "**<label>** <value>", where and question as links, the commands in a fenced sh block. */
export function markdown(items, run) {
  const open = order(items.filter(i => !i.resolved_at));
  if (!open.length) return `Nothing needs Michael in ${run}.\n`;
  const out = [`# Needs Michael: ${run}`, ""];
  for (const i of open) {
    const c = i.card ?? {}, q = c.question;
    out.push(`## ⚠ ${c.headline ?? i.title ?? i.reason}`, "", `\`${i.ref}\` · since ${i.at}`, "");
    if (c.blocked) out.push(`**blocked** ${c.blocked}`, "");
    if (c.cost) out.push(`**cost** ${c.cost}`, "");
    if (q) out.push(`**question** ${q.url ? `[INBOX.md:${q.line}](${q.url})` : `INBOX.md${q.line ? ":" + q.line : ""}`}`, "", ...(q.text ? [q.text.split("\n").map(l => `> ${l}`.trimEnd()).join("\n"), ""] : []));
    else if (c.why) out.push(`**why** ${c.why}`, "");
    if (c.tried) out.push(`**tried** ${c.tried}`, "");
    const w = (c.where ?? []).map(mdLink);
    if (w.length) out.push(`**where** ${w.join(" · ")}`, "");
    if (c.commit?.main || c.commit?.branch) out.push(`**commits** ${[c.commit.main && `main ${c.commit.main}`, c.commit.branch && `${c.branch ?? "branch"} @ ${c.commit.branch}`].filter(Boolean).join(" · ")}`, "");
    for (const x of c.options ?? []) out.push(`- (${x.key}) ${x.text}${x.recommended ? ` **(recommended: ${x.why})**` : ""}`);
    if (c.options?.length) out.push("");
    if (c.commands?.length) out.push("```sh", ...c.commands, "```", "");
    if (c.run_state) out.push(`**run** ${c.run_state}`, "");
  }
  return out.join("\n");
}

// ---- the I/O side ----
const json = p => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return null; } };
const text = p => { try { return readFileSync(p, "utf8"); } catch { return null; } };
const seqOf = f => /^(\d+)\.json$/.exec(f)?.[1];
const files = d => { try { return readdirSync(d).filter(seqOf).sort((a, b) => seqOf(a) - seqOf(b)); } catch { return []; } };
const items = d => files(d).map(f => json(join(d, f))).filter(i => i?.key);
const meta = state => envFile(join(state, "meta.env"));   // as bin/harness writes it (printf %q)
// worktree and record branch both gone (gc, or by hand): nothing of the run is left to act on
function removed(m) {
  if (!m.WT || existsSync(m.WT)) return false;
  if (!m.PROJECT_DIR || !existsSync(m.PROJECT_DIR)) return true;
  try { execFileSync("git", ["-C", m.PROJECT_DIR, "rev-parse", "-q", "--verify", `refs/heads/harness/${m.RUN_ID}`], { stdio: "ignore" }); return false; }
  catch { return true; }
}
const originOf = dir => { try { return execFileSync("git", ["-C", dir, "config", "--get", "remote.origin.url"], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim(); } catch { return ""; } };
// a run's side of an overlap: gone (no state dir or no branch), open (live, not ended, or changes main lacks; unknown too), merged
function sideOf(dir, state, run) {
  if (!existsSync(join(state, "meta.env"))) return "gone";
  if (liveRun(state)) return "open";
  const git = gitIn(dir), head = git("symbolic-ref", "-q", "--short", "refs/remotes/origin/HEAD");
  const ch = changes(dir, run, `refs/remotes/${head.ok ? head.out.trim() : "origin/main"}`);
  if (ch === null) return branchesOf(git, run).length ? "open" : "gone";   // no main to compare with: open
  return ch.length || !existsSync(join(state, "ended")) ? "open" : "merged";   // not ended: a start before its first commit
}
/** The facts sweep and synthesize take, read from a state dir and its run's record; facts: what a synthesized card
 *  is built from (the origin asked of git only when something is parked). With open items: each overlap item's other
 *  run and this one as sideOf has them (git in PROJECT_DIR, only then). */
export function readState(state, open = []) {
  const m = meta(state), run = m.RUN_ID || basename(state), rec = join(m.WT ?? "", ".harness/runs", run), list = json(join(rec, "feature_list.json"));
  const fs = Array.isArray(list) ? list : list?.features ?? [], pid = text(join(state, "driver.pid"))?.trim();
  const parked = json(join(state, "parked.json")) ?? {};
  let log_mtime = 0; try { log_mtime = statSync(join(state, "run.log")).mtimeMs / 1000; } catch {}
  return { run, project: m.PROJECT_DIR ? basename(m.PROJECT_DIR) : basename(resolve(state, "..")), removed: removed(m),
    ended: existsSync(join(state, "ended")), passing: fs.filter(f => f.passes).map(f => f.id),
    parked, attempts: json(join(state, "attempts.json")) ?? {},
    max_attempts: Number(text(join(state, "max-attempts"))) || 2, markers: (() => { try { return readdirSync(state); } catch { return []; } })(),
    driver: pid === undefined ? null : alive(pid) ? "live" : "dead", log_mtime, wt_gone: !m.WT || !existsSync(m.WT),
    facts: { worktree: m.WT ?? "", branch: `harness/${run}`, record: rec, record_branch: `harness/${run}`, state, features: fs,
      inbox: join(rec, "INBOX.md"), inbox_text: text(join(rec, "INBOX.md")) ?? "", log: join(state, "run.log"),
      origin: Object.keys(parked).length && m.WT && existsSync(m.WT) ? originOf(m.WT) : "" }, ...overlapsOf(state, m, run, open) };
}
function overlapsOf(state, m, run, open) {
  const rs = open.filter(i => i.reason === "overlap").map(subjectOf);
  if (!rs.length || !m.PROJECT_DIR || !existsSync(m.PROJECT_DIR)) return {};
  try { return { overlaps: Object.fromEntries(rs.map(r => [r, sideOf(m.PROJECT_DIR, join(state, "..", r), r)])), self: sideOf(m.PROJECT_DIR, state, run) }; }
  catch { return {}; }   // git can't say: kept
}
// open's and card's facts: the feature list and INBOX.md read from their paths, unless given
function loaded(f) {
  const l = f.features ?? (f.list ? json(f.list) : null);
  return { ...f, home: f.home ?? process.env.HOME ?? "", features: Array.isArray(l) ? l : l?.features ?? [], inbox_text: f.inbox_text ?? (f.inbox ? text(f.inbox) ?? "" : "") };
}

const write = (p, o) => { writeFileSync(`${p}.tmp`, JSON.stringify(o, null, 2) + "\n"); renameSync(`${p}.tmp`, p); };
// moved by rename first (never open and resolved at once), then rewritten in place with resolved_* filled
function resolveTo(state, i) {
  const d = join(state, "needs", "done"), f = `${i.ref.slice(i.ref.lastIndexOf("/") + 1)}.json`;
  mkdirSync(d, { recursive: true });
  try { renameSync(join(state, "needs", f), join(d, f)); } catch (e) { if (e.code === "ENOENT") return false; throw e; }   // resolved meanwhile
  write(join(d, f), i); return true;
}

// <record>/needs.md from the state dir's open items, rewritten only when its text changes (the record commits it next);
// nothing when the record is gone (a gc'd run)
function writeMd(state, rec, run) {
  if (!rec || !existsSync(rec)) return;
  const p = join(rec, "needs.md"), open = items(join(state, "needs")), t = markdown(open, run), was = text(p);
  if (was === null && !open.length) return;   // a run that never had an item gets no file (nor a dirty worktree)
  if (was !== t) { writeFileSync(`${p}.tmp`, t); renameSync(`${p}.tmp`, p); }
}

function open(state, run, project, reason, subject, kv, now) {
  const facts = {};
  for (const a of kv) { const k = a.indexOf("="); if (k > 0) facts[a.slice(0, k)] = a.slice(k + 1); }
  Object.assign(facts, { run, project, reason, subject });
  // a feature's reasons name it, a milestone's name the milestone (the coordinator has no LANE); a feature's milestone
  // is its list's
  if (!facts.feature && FEATURE_SUBJECT.has(reason)) facts.feature = subject;
  if (!facts.milestone && MILESTONE_SUBJECT.test(reason) && !isRun(subject)) facts.milestone = subject;
  if (!facts.milestone && facts.feature && facts.list) { const l = json(facts.list);
    facts.milestone = (Array.isArray(l) ? l : l?.features ?? []).find(f => f.id === facts.feature)?.milestone ?? ""; }
  const d = join(state, "needs"), old = items(d).find(i => i.key === `${reason}:${subject}`);
  if (old) { const n = refresh(old, loaded(facts), now); write(join(d, `${old.ref.slice(old.ref.lastIndexOf("/") + 1)}.json`), n); writeMd(state, facts.record, run); return [3, n.ref]; }
  const seq = 1 + Math.max(0, ...[...files(d), ...files(join(d, "done"))].map(f => Number(seqOf(f))));
  const i = record({ ...loaded(facts), seq }, now);   // throws before anything is written
  mkdirSync(d, { recursive: true }); write(join(d, `${seq}.json`), i); writeMd(state, facts.record, run);
  return [0, i.ref];
}

// A parked card's commands and run words as of now (parked.mjs): a going run takes the answer by itself, a queued
// continuation too, and with a queue runner up a continue is a queue add; with another live run of the project, Michael
// picks the queue add or --now (parked.mjs commandsFor)
function asOfNow(i, st, { runner, queue }) {
  if (i.reason !== "parked" || i.resolved_at) return i;
  if (st.wt_gone) return null;   // gc'd: nothing left to answer or continue (harness parked skipped these too)
  const live = st.driver === "live", s = { running: live && !st.ended, ending: live && st.ended, runner, busy: busyRun(st.facts.state),
    queued: !!queue && (() => { try { return readdirSync(queue).some(f => f.endsWith(`-continue-${i.run}.args`)); } catch { return false; } })() };
  return { ...i, card: { ...i.card, commands: commandsFor(i.run, s), run_state: runState(s) } };
}

/** The open items of these state dirs (resolved ones too with all), synthesized ones included, ordered: `harness
 *  needs` and `harness status` (lib/status.mjs) read this. */
export function list(states, { all = false, now, runner = false, queue = "" }) {
  const out = [];
  for (const state of states) try {   // a state dir it can't make items of costs that run's, said, never the others'
    const st = readState(state), d = join(state, "needs"), open = items(d);
    const { keep, resolved } = st.removed ? sweep(open, st, now) : { keep: open, resolved: [] };
    out.push(...[...keep, ...synthesize(st, keep)].map(i => asOfNow(i, st, { runner, queue })).filter(Boolean));
    if (all) out.push(...resolved, ...items(join(d, "done")).filter(i => Date.parse(i.resolved_at) >= (now - 7 * 86400) * 1000));
  } catch (e) { console.error(`needs.mjs: ${state}: ${e.message}`); }
  return order(out);
}

function main([cmd, ...args], env = process.env) {
  const now = nowOf(env), die = m => { console.error(`needs.mjs: ${m}`); return 1; };
  const flag = k => { const i = args.indexOf(k); if (i < 0) return null; const v = args[i + 1] ?? ""; args.splice(i, 2); return v; };
  if (cmd === "open") {
    const [state, run, project, reason, subject, ...kv] = args;
    if (!state || !run) return die("usage: open <state dir> <run> <project> <reason> <subject> [key=value…]");
    try { const [rc, ref] = open(state, run, project, reason, subject, kv, now); console.log(ref); return rc; } catch (e) { return die(e.message); }
  }
  if (cmd === "sweep") {
    for (const state of args) {
      const open = items(join(state, "needs")), st = readState(state, open), { resolved } = sweep(open, st, now);
      for (const i of resolved) if (resolveTo(state, i)) console.log(`resolved ${i.ref} (${i.resolved_why})`);
      if (!st.removed) writeMd(state, st.facts.record, st.run);
    }
    return 0;
  }
  if (cmd === "done") {
    const why = flag("--why"), [state, ref] = args;
    if (!state || !ref) return die("usage: done <state dir> <ref> [--why <text>]");
    if (/\/(crash|parked:.+)$/.test(ref))
      return die(`${ref} is derived from the run's state; it resolves when ${ref.endsWith("/crash") ? "the run is continued (harness continue)" : "the feature is unparked or passes"}`);
    const i = items(join(state, "needs")).find(x => x.ref === ref);
    if (!i) return die(`no open item ${ref}`);
    // parked.json still holds the feature: list would put a synthesized twin in its place
    if (i.reason === "parked") return die(`${ref} resolves when the feature is unparked (a new answer, then harness continue) or passes`);
    if (!resolveTo(state, { ...i, resolved_at: isoAt(now), resolved_by: "michael", resolved_why: why || "done by hand" })) return die(`no open item ${ref}`);
    const st = readState(state); if (!st.removed) writeMd(state, st.facts.record, st.run);   // needs.md: the notification's click
    console.log(`resolved ${ref}`);
    return 0;
  }
  if (cmd === "list") {
    const run = flag("--run") ?? "", runner = flag("--runner") === "1", queue = flag("--queue") ?? "";
    const json_ = args.includes("--json"), all = args.includes("--all");
    const xs = list(args.filter(a => !a.startsWith("--")), { all, now, runner, queue });
    if (json_) { process.stdout.write(JSON.stringify(xs, null, 2) + "\n"); return 0; }
    const ctx = context({ env, isTTY: process.stdout.isTTY, columns: process.stdout.columns });
    process.stdout.write(renderList(xs, ctx, { run, env }).join("\n") + "\n");
    return 0;
  }
  if (cmd === "md") {
    const [state] = args; if (!state) return die("usage: md <state dir>");
    process.stdout.write(markdown(items(join(state, "needs")), readState(state).run)); return 0;
  }
  if (cmd === "fields") {   // the shell's notify: NUL-separated, so a body's newlines survive
    const [state, ref] = args, i = state && items(join(state, "needs")).find(x => x.ref === ref);
    if (!i) return die(`no open item ${ref ?? ""}`);
    process.stdout.write([i.title, i.body, i.click ?? "", i.priority, i.actions ?? ""].map(x => x + "\0").join("")); return 0;
  }
  if (cmd === "card") {
    const [reason, file] = args, f = json(file ?? "");
    if (!f) return die("usage: card <reason> <facts.json>");
    try { process.stdout.write(JSON.stringify(card(reason, loaded(f)), null, 2) + "\n"); return 0; } catch (e) { return die(e.message); }
  }
  console.error("usage: needs.mjs open|sweep|done|list|card|md|fields …");
  return 2;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) process.exit(main(process.argv.slice(2)));
