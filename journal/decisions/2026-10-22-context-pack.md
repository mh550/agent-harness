# Each coding and verify session reads a bounded, deterministic context pack first (the spec's D-H41)

*(2026-10-22, E4-05 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E4-memory.md` §3.7, §5, §7,
§9)*

- **Finding:** with E4-04 the record is complete (`entries.jsonl`, rendered into `progress.md` and
  `progress-archive.md`) but grows with the run. A fresh session oriented itself by reading the newest progress.md
  entries, which are about whatever ran last, not about its own feature. C's second attempt had to find C's first
  attempt's dead end among the other features' entries, or never saw it once it fell out of the 15.
- **Choice:** before every coding session (after the init) and every verify round (an escalated verify's pack has
  the first round's entry), the driver writes `<run>/context.md` with `node lib/entries.mjs pack <run dir> <feature or
  milestone> $CONTEXT_PACK_BYTES` (default 8192 bytes). It notes the size (`context.md for C: 812 bytes`, plus `, <k>
  items left out` when cut) and copies the pack beside the session's prompt (`logs/05-C.context.md`). The pack is
  committed with the run record. It is pure and deterministic (no LLM), in five parts in a fixed priority order:
  1. this feature's earlier attempts: dead ends, then failed evidence rows for it from any verify, then questions,
     then the entries themselves;
  2. Michael's INBOX answers;
  3. discoveries whose `affects` names the feature, its milestone or `run` (for a verify: the milestone and its
     features);
  4. the newest entry of each feature in its `after`;
  5. the run's last 3 entries.
  Each item is one bullet, at most 1024 bytes, ending `→ entries.jsonl:<line>` (`→ INBOX.md` for the answers), so a
  session can open the full entry. An entry shown once isn't repeated. Items are added while the total stays within
  the cap minus 160 bytes. The first item that doesn't fit ends the pack, so a lower part never pushes out a higher
  one. The answers are the exception: when at least 256 bytes are left they are cut to fit, keeping their newest
  (last) bytes, and they aren't held to 1024 bytes (Michael's word outranks every discovery). A last line counts
  what was left out, each entry once. If the pack fails, context.md says so and points at the full
  record, so the session never reads a stale one; a cap that isn't a whole number ≥ 1024 fails it (a typo'd
  `8k` would otherwise lift the cap). The driver commits the pack at once (`HARNESS: context pack for <id>`), so a
  session that commits only its own files doesn't leave a `WIP:` commit behind. `prompts/coding.md` and `verify.md` open their bearings with
  `Read context.md first; the full record is entries.jsonl / progress-archive.md (all in the run directory).`
  Verify is told the pack is not evidence. `harness eval run` saves the pack of the task's next feature (refs that
  have `pack`), and `harness eval probes` pastes it after the probe prompt, because a tool-less probe can't open the
  file and E4's probe score could not move otherwise.
- **Rejected:** an LLM curator (out of scope in the spec, not deterministic, costs a session); filling the room a cut
  item leaves with lower-priority items (the order would stop being monotonic and hard to test); pasting the pack
  into the prompt (the spec asks for a file, which a session can open again mid-session and which is committed with
  the run record); a pack for the initializer (it has no journal to read).
