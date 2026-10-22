# progress.md is rendered from the journal; legacy runs are untouched until continued (the spec's D-H40)

*(2026-10-22, E4-04 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E4-memory.md` §3.5, §3.6, §4,
§6, §7, §8)*

- **Finding:** with E4-03, every session's entry lands in `entries.jsonl`, but the sessions still wrote `progress.md`
  as well: two records of the same session, one checked and one free text, and the driver's verify count and
  `F evidence` read the free one. A verify session that forgot its table, or wrote it in the wrong shape, cost an
  escalated verify even when its `entry.json` had every row.
- **Choice:** `journal()` ends with `node lib/entries.mjs render <run dir>`, so `progress.md` (a marker line, the
  header, the 15 newest entries in full, then one line per older entry) and `progress-archive.md` (every entry in full,
  newest first) are rewritten after each append: initializer, coding and verify. The prompts no longer ask for a
  progress.md entry (verify's table moves into `evidence`; the initializer's header text into `header`) and say
  progress.md is the harness's to write. `F evidence` reads the rendered file, where the verify entry just appended is
  the newest. Verify's `before`/after count is the number of `verify` lines for the milestone in `entries.jsonl`, not
  `### … verify <m>` headers in the rendered file: an earlier verify entry leaving the 15, or a just-continued legacy
  run, would otherwise read as "no new verify entry" and waste an escalated verify. `pr_body` quotes the verify entry
  from `progress-archive.md` when it exists (a milestone merged later may have left progress.md's 15). **Legacy runs**
  (a feature list, no `entries.jsonl`): nothing renders or ingests there until a start-up that drives sessions
  (`harness continue`, a queued continuation) runs past `harness merge`'s exit; that start-up copies `progress.md` to
  `progress-archive.md` byte for byte, creates an empty `entries.jsonl`, notes `journal started; progress.md kept as
  progress-archive.md` and commits `HARNESS: journal started`. progress.md stays as it was until the first append
  renders it; the old record then lives at the archive's end after a marker line, kept byte for byte by every render.
- **Rejected:** moving progress.md elsewhere (the phone link, the notifications' click, the desk, the retro and the
  debrief all read that path); a third `progress-legacy.md` (the spec keeps the old record as progress-archive.md);
  rendering at start-up (a start-up that ends at once must leave a legacy record as it was); counting verify headers
  in the rendered file (the two cases above); keeping the sessions' progress.md instructions alongside the entry (two
  writers of one file again).
