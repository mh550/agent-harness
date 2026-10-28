# What waits on Michael: one needs record per item, swept by its reason's rule

*(2026-10-28, run agent-harness-2026-10-28, feature U2-03; spec `docs/specs/2026-10-27-status-ux.md` §U2, plan
`docs/plans/2026-10-28-U2-needs-record.md` §1, §2, §4.1–4.3 and §7. Started by U2-03 (the record, the sweep, `harness
needs`); U2-04 adds the cards, U2-05 and U2-06 the openers, U2-07 the readers.)*

- **Finding:** what needed Michael lived in eight places with no shared shape: `parked.json`, `attempts.json`, the
  `needs-<m>`, `conflict-<m>` and `refused-<m>` markers, `lanes/<m>/need`, `ended`'s reason and a dead `driver.pid`.
  `harness parked` read two of them, `harness status` derived the rest, and nothing said when an item was dealt with.
- **Choice:**
  - One JSON file per item, `<state dir>/needs/<seq>.json`, written to a `.tmp` and renamed. Its first 13 keys are the
    n8n event v1's in order (`v id at kind project run feature title body priority click actions context`; `kind` is
    `park`, `needs_michael`, `blocked` or `limit`), so the record is the event; then `ref` (`<run>/<seq>`, what
    `harness needs done` takes), `key` (`<reason>:<subject>`), `reason`, `severity`, `milestone`, `seen`,
    `updated_at`, `card`, `resolved_at`, `resolved_by`, `resolved_why`. `seq` is one past the largest in `needs/` and
    `needs/done/`; `needs_open` (lib/needs.sh) runs under the record lock so two lanes never take one.
  - `open` with the `key` of an open item refreshes it (exit 3): `seen` +1, `updated_at`, title, body, card;
    `id`, `at` and `ref` stay. A new item exits 0.
  - The 15 reasons, their kind, severity (`block` · `warn`) and priority are `REASONS` in lib/needs.mjs (the plan's
    §2.1 table). Each has a rule `sweep` applies, moving the item to `needs/done/` (rename first, then the resolved
    fields written in place) with the rule's words: `feature unparked`, `feature passes`, `attempts reset`,
    `needs-<m> cleared`, `milestone verified`, `milestone merged`, `conflict cleared`, `refusal cleared`,
    `main merged cleanly`, `run continued` (`ended` gone). Every rule yields to `run removed`: the worktree and the
    local `harness/<run>` branch both gone.
  - **(*default*)** `list` is read-only: it applies only `run removed` in memory (a run removed by hand never shows),
    not the other rules; the sweeps the driver and `harness continue` run (U2-05) keep the files current.
  - **(*default*)** `list` adds unstored items the state implies: `driver_crash` (`<run>/crash`) for a `driver.pid`
    naming no live process with no `ended` (a SIGKILL: no trap ran), and `parked` (`<run>/parked:<id>`) for each
    `parked.json` feature that doesn't pass and has no open record (runs parked before U2, and the bridge until U2-05
    opens records). `harness needs done` on one exits 1 and says what resolves it.
  - Until U2-04's templates, a card has every key with the reason's headline only, and `harness needs` prints one
    line per item: `<glyph> <run> · <headline> · <ref>`.
- **Rejected:** a single `needs.json` per run (two lanes writing it race; a file per item renames atomically).
  Deriving items on every read, as status did (nothing records when an item was handled, or by whom). Sweeping in
  `harness needs` (a phone session runs it to look: it must write nothing).
