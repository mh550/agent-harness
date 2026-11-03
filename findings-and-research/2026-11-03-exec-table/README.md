# Exec table (C1-01, 2026-11-03)

Raw counts behind the *Finding* of `journal/decisions/2026-10-31-fewer-node-starts.md`. The strace files themselves
(4 and 25 MB) stayed in the session's scratch, `/tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1`.

- `starthand.sh <kept $T> <run>`: file 13's first `harness start` by hand in a `KEEP=1` run's `$T`, under `time -v`
  and `strace -f -s 512 -e trace=execve,clone,clone3,fork,vfork` (the plain timing ran the same line without strace).
- `exectable.mjs <strace> <harness home>`: successful execs by program and, for node, by script and subcommand, each
  with its caller (the image the process ran before its exec) and class (stub, lane, driver, cli, tests/lib.sh).
- `mdtable.mjs <exectable output>`: the decision file's tables and the top callers.
- `start-execs.txt`, `start.time`, `start.out`: the one start (`demo-t` traced, `demo-u` timed).
- `file13-execs.txt`, `file13.time`: the whole of `tests/checks/13-run-2-michael-sets-desk.sh`, traced, then timed
  without strace.
