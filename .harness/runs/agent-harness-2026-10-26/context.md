# Context pack for `P0-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (init, affects run): The suite is one file, tests/run.sh (1634 lines, 50 `# ---- <title> ----` sections, 325 checks, all names unique and environment-independent) and takes about 10 min single-threaded on this box (init measured 597 s), so every session spends 10 min per full run until P0-02 lands; iterate on a subset (`bash lib/check.sh <args>` is never cached) and run the full suite once before flipping passes. → entries.jsonl:1
- Discovery (init, affects run): The pre-split suite output of this run's init is at /tmp/harness/agent-harness/agent-harness-2026-10-26/check.out (325 PASS lines): P0-01 generates tests/fixtures/check-names.txt from it instead of re-running the monolith. → entries.jsonl:1
- Discovery (init, affects run): Sections known to read an earlier section's state: run 15e (line 1145) reads $T/demo-hlog.md from run 1 (line 540); the gc section (755) and runs 2-14 reuse run 1's demo repo and tags; the eval sections share $ED; the debrief sections share a runner log. split.sh's grouping pairs are found by running each file alone, never by patching a check. → entries.jsonl:1
- Discovery (init, affects run): The driver loop is lib/driver.sh:567-719 (counters n, limits, repairs, gated as shell variables; verify_ready before each pick); verify is at 375, merge_one 314, merge_milestones 351, finish 484, restrict 87 (the revert pattern for a commit touching the record). bin/harness: cmd_continue 212, cmd_merge 227, cmd_status 236, cmd_gc 351 with record_only at 384 and the harness/ + harness-merge/ prefix passes at 449. → entries.jsonl:1
- Discovery (init, affects run): Helpers that already exist for the lanes work: `notify.mjs question <before> <after>` computes the INBOX lines a session added; `features.mjs` has unpass, repair, snapshot, milestone-done, touched-outside; scope.sh has mem_available_gb's reader (HARNESS_MEMINFO), scope_unit and scope_owns (role regex at line 27); metrics.mjs `usage` reads unifiedWindows from the real capture tests/fixtures/usage-limit.jsonl, which carries five_hour beside seven_day. → entries.jsonl:1
- Discovery (init, affects run): The stubs: tests/stub-claude.sh acts on the prompt's first line and STUB_* flags (set with `tmux set-environment -g` for sessions started in tmux, plain env otherwise); tests/stub-gh.sh keeps PRs as files under $STUB_DIR/prs and really merges into the bare origin; the record of git pushes is the bare origin itself. New stub behaviour must copy a real shape (fakes mirror the live API). → entries.jsonl:1
- Discovery (init, affects run): S4 of the suite-split spec (`--for` selection by `# covers:`) is deliberately not in the list: P1 and P2 are the run's bulk and a feature a milestone can't ship without would hold P0. It is a one-session interactive change if wanted. → entries.jsonl:1

## Lately in the run

- 2026-10-26 05:50 · init · passes: 17 features: P0 4 (suite split S1-S3 + review; S4 left out), P1 6 (plan, pure scheduler, record branch + slot, lane process + coordinator, continue/legacy/pr-held, review), P2 7 (plan, admission, re-base, slots + gc, record PR, status + summary + prompts, review). → entries.jsonl:1
