// Michael's answers to a run's numbered rules and proposals (N2-03): `harness memory accept|decline <run>/<n> --why`
// is one row of <ledger>/memory-answers.jsonl, the latest per <run>/<n>; `harness memory decline <run> --why` is the
// run-level row (the facts PR closed with a reason: n and key null, V2-01); lib/memory.sh holds the ledger lock and commits.
// The next curator reads them in its prompt and apply drops what they closed (lib/curator.mjs answersText, apply).
// decisions/2026-11-08-memory-session-and-answers
//   proposals <memory-result.json> <run> <memory-answers.jsonl> → the run's numbered items, each with any verdict
//   answer <memory-answers.jsonl> <memory-result.json> <project> <run> <n|-> <accepted|declined> <why>
//                                                    → the row written (an earlier one for <run>/<n> replaced; - the
//                                                      run-level row, a decline only), its line;
//                                                      a bad <n> or why: one line, exit 1, the file untouched
import { existsSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { captured, isMain, runCli } from "./cli.mjs";
import { WHY_MAX, badWhy, cut, itemKey, itemSaid, latestAnswers, readJsonl, runLevel } from "./curator.mjs";

/** Pure: memory-result.json → its numbered items (the rules, then the proposals: <run>/<n>), each with its key */
export const items = r => [...(r?.rules ?? []), ...(r?.proposed ?? [])].filter(o => Number.isInteger(o?.n))
  .map(o => ({ n: o.n, tier: o.tier, op: o.op, file: o.file, section: o.section, text: o.op === "delete" ? o.anchor : o.text, key: itemKey(o) }))
  .map(x => ({ ...x, said: itemSaid(x) }))
  .sort((x, y) => x.n - y.n);

/** Pure: a result and one verdict → { row } in memory-answers.jsonl's shape, or { why } (no such <n>, a bad why). No n
 *  is the run-level decline: the facts PR closed with a reason (tier 1 is not numbered), its file, section, text and
 *  key null, so apply matches no op by it and declinedRuns reads the close as none (*default*, decisions/2026-11-10-review-surface-verbs) */
export function answerRow(r, { run, project, n, verdict, why, at }) {
  if (n === undefined || n === null) {
    if (verdict !== "declined") return { why: "a run alone takes decline only: accept names <run>/<n>" };
    if (badWhy(why)) return { why: `--why must be one non-blank line of at most ${WHY_MAX} characters` };
    return { row: { run, project, n: null, tier: 1, verdict, why, file: null, section: null, text: null, key: null, at } };
  }
  const xs = items(r), it = xs.find(x => x.n === n);
  const span = xs.length > 1 ? `${run}/${xs[0].n} to ${run}/${xs.at(-1).n}` : `${run}/${xs[0]?.n}`;
  if (!it) return { why: xs.length ? `${run} has no item ${n} (its rules and proposals: ${span}; tier 1 is not numbered)` : `${run} has no item ${n} (it has no numbered rules or proposals)` };
  if (badWhy(why)) return { why: `--why must be one non-blank line of at most ${WHY_MAX} characters` };
  return { row: { run, project, n, tier: it.tier, verdict, why, file: it.file, section: it.section, text: it.text, key: it.key, at } };
}

/** Pure: the rows with <row> in place of an earlier one for its item (<run>/<n> and its key: a continue's renumbered
 *  item under an old number is another item, its answer beside the first's); it goes last, the newest */
export const upsert = (rows, row) => [...rows.filter(r => !(r?.run === row.run && r?.n === row.n && r?.key === row.key)), row];

/** Pure: the answers: tally line over the latest rows (of <runs> when given): a replaced verdict counted once */
export function answersTally(rows, runs) {
  const xs = latestAnswers(rows).filter(r => !runs || runs.includes(r.run)), k = v => xs.filter(r => r.verdict === v).length;
  return `answers: accepted ${k("accepted")} · declined ${k("declined")}`;
}

/** Pure: harness memory proposals' lines: `<run>/<n> · rules|proposal · <file> · <section> · <text>[ · <verdict>: <why>]`,
 *  then the run-level decline's `<run> · the facts PR · declined: <why>` when there is one */
export function proposalsView(r, run, rows) {
  const xs = items(r), mine = latestAnswers(rows).filter(a => a.run === run), whole = mine.find(runLevel);
  const v = new Map(mine.map(a => [`${a.n}\0${a.key}`, a])), of = x => v.get(`${x.n}\0${x.key}`);
  return [...xs.length ? xs.map(x => `${run}/${x.n} · ${x.tier === 3 ? "proposal" : "rules"} · ${x.file} · ${x.section} · ${x.said}${of(x) ? ` · ${of(x).verdict}: ${of(x).why}` : ""}`)
    : [`${run}: no numbered rules or proposals`], ...whole ? [`${run} · the facts PR · declined: ${whole.why}`] : []];
}

export const main = captured(([cmd, ...a], _io, say) => {
  if (cmd === "proposals" && a.length === 3) { say(proposalsView(JSON.parse(readFileSync(a[0], "utf8")), a[1], readJsonl(a[2])).join("\n")); return 0; }
  if (cmd === "answer" && a.length === 7 && /^([1-9]\d*|-)$/.test(a[4]) && ["accepted", "declined"].includes(a[5])) {
    const [file, res, project, run, n, verdict, why] = a;
    const { row, why: bad } = answerRow(JSON.parse(readFileSync(res, "utf8")), { run, project, n: n === "-" ? null : Number(n), verdict, why, at: new Date().toISOString() });
    if (bad) { say(bad); return 1; }
    // the file is rewritten whole: a line that is no JSON row (a hand edit) would be lost, so it stops the write
    const torn = existsSync(file) ? readFileSync(file, "utf8").split("\n").findIndex(l => { try { return l.trim() !== "" && !(JSON.parse(l) instanceof Object); } catch { return true; } }) : -1;
    if (torn >= 0) { say(`${file} line ${torn + 1} is not a JSON row: fix or remove it by hand first`); return 1; }
    // written whole and renamed: a reader never sees half a file (the caller holds the ledger lock)
    writeFileSync(`${file}.tmp`, upsert(readJsonl(file), row).map(r => JSON.stringify(r)).join("\n") + "\n");
    renameSync(`${file}.tmp`, file);
    say(row.n === null ? `memory: ${run} ${verdict} · the facts PR · ${cut(why, 60)}` : `memory: ${run}/${row.n} ${verdict} · ${row.section} · ${cut(row.text, 60)}`);
    return 0;
  }
  console.error("usage: memory.mjs proposals <memory-result.json> <run> <answers.jsonl> | answer <answers.jsonl> <memory-result.json> <project> <run> <n|-> <accepted|declined> <why>");
  return 2;
});

if (isMain(import.meta.url)) runCli(main);
