#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the trace switch (slim suite S1-01, decisions/2026-11-03-suite-coverage): HARNESS_XTRACE=<dir>, TEST_XTRACE_DIR=<dir> ----
# HARNESS_XTRACE=<dir>: every harness script that runs as a process of its own traces its commands to <dir>/<pid>.xtrace
# (lib/xtrace.sh). Off unless set: a run without it leaves no trace and logs what it always did. Two foreground runs of
# the same stub project, one plain and one traced, are compared; each sets or unsets the variable itself, so this file
# reads the same under the coverage measurement (TEST_XTRACE_DIR, which gives every check file's runs a trace).
HH=$(cd "$HERE/.." && pwd); LIB=$HH/lib
traces() { cat "$1"/*.xtrace 2> /dev/null; }                                    # <dir>: every trace in it
traced() { traces "$1" | grep -E "^\++/[^ :]*/$2:[0-9]+: " > /dev/null; }       # <dir> <file>: a line of that file is in one (a full path, as bash names it: $H is tests/../bin/harness)
anytrace() { grep -E "^\++/[^ :]+:[0-9]+: " "$1" > /dev/null; }                 # <file>: a trace line is in it
# a run's log with what differs between two runs of one project cut out: the run id, times, hashes, lengths, the
# port and the PR number (the second run's are the next ones)
norm() { hlog "$1" | sed -E "s/$1/RUN/g; s/[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2})?/TIME/g; s/[0-9]{2}:[0-9]{2}(:[0-9]{2})?/TIME/g; s/\b[0-9a-f]{7,40}\b/HASH/g; s/[0-9]+(\.[0-9]+)? ?(ms|s|min|h)\b/LEN/g; s/port [0-9]+/port N/g; s#/pr/[0-9]+#/pr/N#g"; }

env -u HARNESS_XTRACE "$H" start "$T/proj" runp1 --spec SPEC.md --foreground > "$T/plain.out" 2>&1; plain_rc=$?
HARNESS_XTRACE=$T/xt "$H" start "$T/proj" runt1 --spec SPEC.md --foreground > "$T/traced.out" 2>&1; traced_rc=$?

check "xtrace: a run without HARNESS_XTRACE leaves no trace file, and no trace line in its output" \
  '[[ $plain_rc == 0 && -z $(find "$T" -name "*.xtrace" -not -path "$T/xt/*") ]] && ! anytrace "$T/plain.out"'
check "xtrace: HARNESS_XTRACE=<dir> traces the CLI, the driver, a lane and the check runner, lines led by +<file>:<line>:" \
  '[[ $traced_rc == 0 ]] && traced "$T/xt" bin/harness && traced "$T/xt" lib/driver.sh && traced "$T/xt" lib/lane.sh && traced "$T/xt" lib/check.sh'
check "xtrace: a sourced file's lines are traced under its own name, by the process that sourced it (lib/record.sh)" \
  'traced "$T/xt" lib/record.sh && [[ $(ls "$T/xt" | grep -cvE "^[0-9]+\.xtrace$") == 0 ]]'
check "xtrace: the trace goes to its own descriptor: the traced run's output holds no trace line" \
  '[[ -s $T/traced.out ]] && ! anytrace "$T/traced.out" && ! cat "$T"/scratch/proj/runt1/helper-*.err "$T"/scratch/proj/runt1/lanes/*/helper-*.err 2> /dev/null | grep -E "^\++" > /dev/null'
TN="trace: this segment's harness processes write every command they run to $T/xt (HARNESS_XTRACE)"
check "xtrace: a traced segment's first note says where the trace goes; a plain run has no such note" \
  '[[ $(hlog runt1 | head -1) == "- "*" · $TN" && $(hlog runt1 | grep -c " · trace: ") == 1 ]] && ! hlog runp1 | grep " · trace: " > /dev/null'
check "xtrace: the traced run's harness-log.md is the plain run's plus that note, the run id, times, hashes and lengths aside" \
  '[[ -n $(norm runp1) && $(norm runp1) == "$(norm runt1 | sed 1d)" ]]'

# a start in tmux: its commands run in the tmux server's environment, which never saw the variable (a server already
# up, as Michael's is), so the CLI hands it on like the other overrides
env -u HARNESS_XTRACE tmux new-session -d -s warm
PAST=$(( $(date +%s) - 1 ))
HARNESS_XTRACE=$T/xt2 "$H" start "$T/proj" runt2 --spec SPEC.md --until-epoch "$PAST" --now --no-supervisor > "$T/tmux.out" 2>&1
tended "$HARNESS_STATE/proj/runt2"
check "xtrace: a run started in tmux traces its driver too: the CLI passes the variable to the tmux command" \
  'traced "$T/xt2" bin/harness && traced "$T/xt2" lib/driver.sh'

mkdir -p "$T/nodir" && : > "$T/nodir/file"
HARNESS_XTRACE=$T/nodir/file/sub "$H" status > "$T/nodir.out" 2>&1; nodir_rc=$?
check "xtrace: a directory that can't be made costs the trace, never the command" \
  '[[ $nodir_rc == 0 ]] && grep -q "^RUNNING" "$T/nodir.out" && ! grep -E "^\++" "$T/nodir.out" > /dev/null'

# every script that runs as a process of its own asks for itself (`set -x` does not cross a process): the executable
# files of lib/ and bin/harness, each with the guard line
guard='[[ -z ${HARNESS_XTRACE:-} ]] || source "'
check "xtrace: every executable script of lib/ and bin/harness sources lib/xtrace.sh under the guard, once" \
  'n=0; for f in "$LIB"/*.sh "$HH/bin/harness"; do [[ -x $f ]] || continue; n=$((n + 1)); [[ $(grep -cF "$guard" "$f") == 1 ]] && grep -F "$guard" "$f" | grep "xtrace\.sh\"" > /dev/null || { echo "no guard: $f"; n=-99; }; done; (( n >= 12 ))'

# TEST_XTRACE_DIR=<dir> (tests/tools/coverage.sh): a check file's stub runs and its own shell trace to <dir>/<file>/,
# node writes its coverage to <dir>/<file>/v8; without it, a HARNESS_XTRACE the suite inherited (a traced run's session
# running it) is dropped
mkdir -p "$T/tc" "$T/tu"
printf '%s\n' '#!/usr/bin/env bash' '# tier: fast' "source \"$HERE/lib.sh\" && suite_setup" \
  'check "tx: a call" "\"\$H\" status > /dev/null"' 'echo "seen: ${HARNESS_XTRACE-unset} ${NODE_V8_COVERAGE-unset}"' suite_end > "$T/tc/aa-file.sh"
TEST_CHECKS=$T/tc TEST_XTRACE_DIR=$T/tx bash "$HERE/run.sh" > "$T/tx.out" 2>&1
check "tests/lib.sh: TEST_XTRACE_DIR=<dir> traces a check file's harness calls and its own shell to <dir>/<file>/, node to <dir>/<file>/v8" \
  'grep -qx "seen: $T/tx/aa-file $T/tx/aa-file/v8" "$T/tx.out" && traced "$T/tx/aa-file" bin/harness && traces "$T/tx/aa-file" | grep -E "^\++$T/tc/aa-file\.sh:[0-9]+: " > /dev/null \
   && ls "$T/tx/aa-file/v8"/*.json > /dev/null 2>&1 && grep -qx "1/1 checks passed" "$T/tx.out"'
env -u TEST_XTRACE_DIR HARNESS_XTRACE=$T/leak TEST_CHECKS=$T/tc bash "$HERE/run.sh" > "$T/leak.out" 2>&1
check "tests/lib.sh: without TEST_XTRACE_DIR an inherited HARNESS_XTRACE is dropped: no trace, whoever runs the suite" \
  'grep -q "^seen: unset " "$T/leak.out" && [[ ! -e $T/leak ]] && grep -qx "1/1 checks passed" "$T/leak.out"'
printf '%s\n' 'import { test } from "node:test";' 'test("tu: one", () => {});' > "$T/tu/one.test.mjs"
TEST_UNIT_DIR=$T/tu TEST_XTRACE_DIR=$T/txu bash "$HERE/checks/00-unit-tier.sh" > "$T/txu.out" 2>&1
check "the unit tier: TEST_XTRACE_DIR=<dir> puts node's coverage in <dir>/00-unit-tier/v8" \
  'grep -qx "1/1 checks passed" "$T/txu.out" && ls "$T/txu/00-unit-tier/v8"/*.json > /dev/null 2>&1'
suite_end
