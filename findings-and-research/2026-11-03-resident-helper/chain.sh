#!/usr/bin/env bash
# H1-04's measurements, one at a time, each behind the gate
S=/tmp/harness/agent-harness/agent-harness-2026-11-05/lanes/H1 WT=/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-05/slot-0 BT=/tmp/harness/agent-harness/agent-harness-2026-11-05/lanes/H1/before P=/tmp/harness/agent-harness/agent-harness-2026-11-05/lanes/H1/proof
L=$P/proof.log; : > "$L"
say() { echo "$(date +%H:%M:%S) $*" >> "$L"; }
suite() { # <tree> <name>
  bash "$P/gate.sh" "suite-$2" >> "$L"; say "suite $2 start"
  ( sleep 300; TK_GAP=5 bash "$P/tk.sh" "$1" 20 "loaded-$2" >> "$L" ) &
  local tkj=$!
  ( cd "$1" && timeout 2400 systemd-run --user --scope -p MemoryMax=3G env TEST_JOBS=4 time -v bash tests/run.sh > "$S/$2.out" 2>&1 ); say "suite $2 rc $?"
  wait $tkj
}
f13() { # <tree> <name>
  bash "$P/gate.sh" "strace-$2" >> "$L"; say "file13 strace $2 start"
  ( cd "$1" && KEEP=${3:-} TEST_FILE_TIMEOUT=1150s timeout 1200 strace -f -s 512 -e trace=execve,clone,clone3,fork,vfork -o "$S/file13-$2.strace" bash tests/run.sh 13-run-2-michael-sets-desk > "$P/file13-$2-strace.out" 2>&1 ); say "file13 strace $2 rc $?"
  bash "$P/gate.sh" "plain-$2" >> "$L"; say "file13 plain $2 start"
  ( cd "$1" && timeout 1200 env time -v bash tests/run.sh 13-run-2-michael-sets-desk > "$P/file13-$2-plain.out" 2>&1 ); say "file13 plain $2 rc $?"
}
suite "$BT" before
suite "$WT" after
f13 "$BT" before
f13 "$WT" after 1
bash "$P/gate.sh" "treekey-idle" >> "$L"
bash "$P/tk.sh" "$BT" 20 idle-before >> "$L"; bash "$P/tk.sh" "$WT" 20 idle-after >> "$L"; bash "$P/tkask.sh" "$WT" 20 >> "$L"
say "chain done"
