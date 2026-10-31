# Test engineering, learned in the field (agent-harness)

*(Michael's study log, written during a tutoring session on 2026-10-30. One concept per entry: the idea in plain
words, where it lives in this repo, the trade, and the answer taken. Source material for a talk on the harness.)*

## 1. Performance assertions: CPU time versus wall time

- **Concept:** a test that says "under 1 s" has a hidden input: how busy the machine is. Wall time is a stopwatch and
  counts the time spent waiting for the CPU behind other test files. CPU time (user + system) counts only the time the
  CPU spent on the command. Wall measures "the command plus the box's queue"; CPU measures "the command".
- **In the repo:** `tests/checks/52-*` and `53-*`, the `time J` line with `TIMEFORMAT="%3U %3S %3R"` (user, system,
  real). Evidence: `findings-and-research/2026-10-30-suite-load-curve.md`, red only at 8 paired jobs (1367 ms and
  1151 ms wall, load average above 24 %) while `harness status` had not changed.
- **Trade:** lose "what the user feels at the terminal"; gain a check that fails only when the code got slower.
  Headroom about 438 ms CPU against 1000.
- **Answer (default 1):** keep. Resource-use bounds are how mature suites keep performance assertions alive under
  parallel runs. The rejected ratio-against-a-baseline is as noisy as wall and loses the 1 s meaning.
