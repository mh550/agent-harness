# Re-baseline on main (D0, 2026-11-03, `6622952`)

Raw outputs behind §5 of `../2026-11-03-redesign-baseline.md`. The strace files themselves (34 MB for file 13) stayed in
the session's scratch; the parsed tables are here.

- `solo-<n>.out`, `solo-<n>.time`: the two solo full suites (`systemd-run --user --scope -p MemoryMax=3G /usr/bin/time -v
  env TEST_JOBS=4 bash tests/run.sh`), the runner's output and `time -v`'s summary.
- `file13.out`, `file13-strace.time`: `tests/checks/13-run-2-michael-sets-desk.sh` under `strace -f -s 512 -e
  trace=execve,clone,clone3,vfork,fork`; `file13-plain.time`: the same file timed without strace.
- `file13-execs.txt`: `exectable.mjs` over the trace (`../2026-11-03-exec-table/`); `file13-tables.md`: `mdtable.mjs`
  over that.
- `pure.out`, `pure.time`, `pure-strace.out`, `pure-execs.txt`: the eleven `-pure-` unit files, timed, then under
  `strace -f -e trace=execve` with node execs counted by script. `pure-wide.time`: the brief's substring spelling
  (`01- 02- …`), which also ran 08, 21 and 22; kept so the number is not mistaken for the unit layer's.
- `load-before-*.txt`: `uptime` before each run.
