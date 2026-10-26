# A run's driver window saves its scrollback, ends the supervisor, and closes its tmux session after a keep window

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L3-03; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L3 item 2 (H1a of `docs/specs/2026-10-22-tmux-and-queue-hygiene.md`), plan
`docs/plans/2026-10-25-L3-scratch-and-tmux.md` §4, §6.2, §8)*

- **Finding:** the driver window of every tmux-started run ended in `…; echo '[driver exited — this window stays
  open]'; exec bash`, so `h-<run>` lived forever after its driver: the `log` window's `tail -F` and a manual start's
  supervisor `claude` (waiting on its prompt) with it. About ten ended runs' sessions piled up on the box until a reboot
  or a hand kill. Everything they show is on disk (`run.log`, `logs/*.jsonl`, the run record) except the driver
  window's scrollback.
- **Choice:**
  - **When the driver exits, its window** (the command `cmd_start` gives it, `bin/harness`): `tmux capture-pane -pJ -S
    - -t "$TMUX_PANE" > <state>/tmux-driver.txt` (the whole history; `-J` joins lines tmux wrapped at the pane's width,
    so the file is greppable), then `tmux kill-window -t =<s>:supervisor` (nothing is left to supervise; absent under
    `--no-supervisor`, the error ignored), prints `[driver exited — scrollback saved to <state>/tmux-driver.txt; this
    session self-destructs in <h> h, or sooner on harness gc]`, sleeps `TMUX_KEEP_HOURS` hours and kills its whole
    session (`kill-session -t =<s>`, exact target), the `log` window with it. No `exec bash`: nothing outlives the timer.
  - ***default*: `TMUX_KEEP_HOURS=24`**, whole hours (1 to 4 digits, read base 10 so `08` is 8; anything else is 24);
    `0` closes the session at once.
    The value is baked into the window's command at start, so a resume picks up a change. A resume kills the old
    session first, its timer with it.
  - **The window shell runs `trap : INT` first** (found by the feature's review): a Ctrl-C in the window ended the
    shell with the driver, or during the wait, so the cleanup never ran and the session leaked. A handler, not an
    ignore, so the driver still gets INT's default; a Ctrl-C during the keep window now closes the session at once.
  - **The supervisor prompt is rendered before the session starts** and the `log`/`supervisor` windows go to `=<s>:`
    (same review): a driver that dies at once could otherwise exit before its supervisor window existed (the kill
    finds nothing, a real supervisor lives through the keep window), and a plain `-t <s>` falls back to a prefix match.
    Only two tmux calls remain between the driver's start and its windows.
  - **The resume's kill takes an exact target** (`has-session`/`kill-session -t "=<s>"`): without `=`, tmux falls back
    to a prefix match, so resuming `tmux1` after its session had closed would have killed `h-tmux10`'s.
  - The suite puts a `claude` wrapper around `tests/stub-claude.sh` first on `PATH` (exported before the private tmux
    server starts, since windows get the server's environment): the supervisor window's bare `claude` is then the
    stub, which waits on its tty like the real one.
- **Rejected:**
  - Keeping `exec bash` (the session never goes) or letting only the driver window exit (the `log` and `supervisor`
    windows keep the session alive).
  - `TMUX_KEEP_HOURS=0` as the default: Michael may want to read a just-finished run's window; `tmux-driver.txt` is
    there after it closes.
  - Counting supervisors (and desks) against `MAX_PARALLEL_RUNS`: queue starts have no supervisor
    (`--no-supervisor`), this change ends a manual start's supervisor with its driver, and a desk is Michael's
    conversation, which `harness gc` closes when idle.
