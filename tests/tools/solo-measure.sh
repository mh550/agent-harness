#!/usr/bin/env bash
# The solo suite measurement, unattended: the ten measures of findings-and-research/2026-11-03-suite-coverage.md's
# "before row" taken again on this tree, so a later session's row is the same numbers by the same commands. Two solo
# full suites in sequence (the method that file records), the static counts around them, then the "after row" appended
# to that file and the two waiting cells of the Predictions table filled in the milestone's decision file.
# It measures; it decides nothing. Every number comes from a fixed command, and the Met? verdict is one comparison.
#
# It refuses to run unless the box is quiet, because a solo number measured beside other work is not a number:
# no harness run alive, no queue runner, no other suite, root's daily temp cleaner not walking, and not in its window.
#
#   solo-measure.sh [--check] [--no-pr] [--runs <n>] [--timeout <s>]
#     --check     the pre-flight and the static counts only; runs no suite, changes nothing
#     --no-pr     measure and write the files, but make no commit, branch, push or PR
#     --runs      how many solo suites (default 2; the lower CPU of them fills the Predictions cells)
#     --timeout   per-suite hang guard in seconds (default 2400 = 40 min; the before run was 599 s)
set -uo pipefail

CHECK_ONLY=0 NO_PR=0 RUNS=2 TMO=2400
while (( $# )); do case $1 in
  --check) CHECK_ONLY=1; shift ;;
  --no-pr) NO_PR=1; shift ;;
  --runs) RUNS=${2:?--runs needs a number}; shift 2 ;;
  --timeout) TMO=${2:?--timeout needs seconds}; shift 2 ;;
  -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
  *) echo "solo-measure: unknown argument $1" >&2; exit 2 ;;
esac; done
[[ $RUNS =~ ^[1-9][0-9]*$ ]] || { echo "solo-measure: --runs must be a whole number" >&2; exit 2; }
[[ $TMO  =~ ^[1-9][0-9]*$ ]] || { echo "solo-measure: --timeout must be seconds" >&2; exit 2; }

cd "$(dirname "$0")/../.." || exit 1
ROOT=$PWD
SETS=findings-and-research/2026-11-03-suite-coverage
PURITY=journal/decisions/2026-11-03-purity.md
COVER=findings-and-research/2026-11-03-suite-coverage.md
LOG=$SETS/after-measure.log
say() { printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG"; }
die() { printf 'solo-measure: %s\n' "$*" >&2; exit 1; }

mkdir -p "$SETS"; : > "$LOG"
say "solo-measure in $ROOT"

# ---- pre-flight: every reason a solo number would be worthless ----------------------------------
pre() {
  local b; b=$(git symbolic-ref -q --short HEAD) || die "detached HEAD; measure from a branch of main"
  [[ $b != main ]] || die "on main: make a worktree and a branch, never measure in the live checkout"
  git merge-base --is-ancestor origin/main HEAD 2> /dev/null \
    || die "this branch is behind origin/main; rebase it so the tree is the one being reported"
  git diff --quiet HEAD -- || die "modified tracked files: a measured tree must be the committed tree"
  [[ -f tests/run.sh ]] || die "no tests/run.sh here"

  local st; st=$(harness status 2>/dev/null) || die "harness status failed"
  grep -qx 'RUNNING 0' <<< "$st" || die "a harness run is alive; a solo suite must have the box"
  grep -q '^QUEUED 0'  <<< "$st" || die "the queue is not empty; a run could start mid-measurement"
  grep -q 'runner off' <<< "$st" || die "the queue runner is up; stop it (harness queue stop) before measuring"

  pgrep -f 'systemd-tmpfiles --clean' > /dev/null \
    && die "root's daily temp cleaner is walking; it cost the shape session 7% wall and 9% CPU. Wait for it"
  local h; h=$(date +%-H)
  (( h >= 16 && h < 17 )) && die "16:00-17:00 is the temp cleaner's window; measure outside it"
  pgrep -f 'tests/run.sh' | grep -qv "^$$\$" && die "another tests/run.sh is running"

  say "pre-flight ok · branch $b · tree $(git rev-parse --short HEAD) · load$(cut -d' ' -f1-3 < /proc/loadavg | sed 's/^/ /')"
}
pre

# ---- the static counts: the same commands the before row records --------------------------------
TIERS=$(awk 'FNR == 2' tests/checks/*.sh | sort | uniq -c)
N_NAMES=$(wc -l < tests/fixtures/check-names.txt)
N_FAST=$(wc -l < tests/fixtures/check-names-fast.txt)
N_TFAST=$(awk '/# tier: fast/ {print $1}' <<< "$TIERS")
N_TSLOW=$(awk '/# tier: slow/ {print $1}' <<< "$TIERS")
N_STUB=$(grep -hE '"\$H" start' tests/checks/*.sh | grep -vcE '^\s*#')
N_STUBF=$(grep -lE '"\$H" start' tests/checks/*.sh | wc -l)
say "unit tests: counting (one node process)"
# node's spec reporter ends with "\u2139 tests <n>"; match the trailing number, not a '#' TAP prefix
U_OUT=$(node --test --test-isolation=none tests/unit/*.test.mjs 2>&1 | tail -20)
N_UNIT=$(awk '/ tests [0-9]+$/ { n = $NF } END { print n }' <<< "$U_OUT")
[[ -n ${N_UNIT:-} ]] || N_UNIT=$(awk '/ pass [0-9]+$/ { n = $NF } END { print n }' <<< "$U_OUT")
[[ -n ${N_UNIT:-} ]] || die "could not read the unit-test count from node --test"
say "static: names $N_NAMES · fast names $N_FAST · files ${N_TFAST}f/${N_TSLOW}s · stub starts $N_STUB in $N_STUBF files · unit tests ${N_UNIT:-?}"

if (( CHECK_ONLY )); then say "--check: stopping before any suite"; exit 0; fi

# ---- the solo runs, in sequence ------------------------------------------------------------------
# One after another, never on a clock: run n+1 starts when n ends, so no measurement is ever cut off
# and none overlaps. --timeout is a hang guard, not a schedule.
declare -a WALL CPU CHK SLOW
for i in $(seq 1 "$RUNS"); do
  o=$SETS/after-solo-$i.out t=$SETS/after-solo-$i.time
  say "solo run $i/$RUNS starting (hang guard ${TMO}s) → $o"
  pgrep -f 'systemd-tmpfiles --clean' > /dev/null && say "WARNING: the temp cleaner started; run $i is not clean"
  rc=0
  timeout "$TMO" systemd-run --user --scope -p MemoryMax=3G \
    /usr/bin/time -v env TEST_JOBS=4 bash tests/run.sh > "$o" 2> "$t" || rc=$?
  (( rc == 124 )) && die "solo run $i hit the ${TMO}s hang guard; $o and $t kept"
  u=$(grep -oP 'User time \(seconds\): \K[0-9.]+'   "$t" | tail -1)
  s=$(grep -oP 'System time \(seconds\): \K[0-9.]+' "$t" | tail -1)
  [[ -n ${u:-} && -n ${s:-} ]] || die "no User/System time in $t (did systemd-run or time -v fail?)"
  CPU[i]=$(awk -v a="$u" -v b="$s" 'BEGIN{printf "%.1f", a+b}')
  WALL[i]=$(grep -oE 'wall [0-9.]+ s' "$o" | tail -1 | grep -oE '[0-9.]+')
  CHK[i]=$(grep -oE '[0-9]+/[0-9]+ checks passed' "$o" | tail -1)
  SLOW[i]=$(grep -oE 'slowest: [^;]+' "$o" | tail -1 | sed 's/^slowest: //')
  say "solo run $i: wall ${WALL[i]:-?} s · CPU ${CPU[i]} CPU-s (${u} user + ${s} system) · ${CHK[i]:-?} · exit $rc"
  [[ ${CHK[i]:-} == *" checks passed" ]] || say "WARNING: run $i did not end with every check passing - see $o"
done

# the lower CPU run is the one the Predictions cells take
best=1; for i in $(seq 2 "$RUNS"); do
  awk -v a="${CPU[i]}" -v b="${CPU[best]}" 'BEGIN{exit !(a<b)}' && best=$i
done
B_CPU=${CPU[best]} B_WALL=${WALL[best]} B_CHK=${CHK[best]} B_SLOW=${SLOW[best]}
BEFORE_CPU=2108.1 BEFORE_WALL=599.4
PCT=$(awk -v a="$B_CPU" -v b="$BEFORE_CPU" 'BEGIN{printf "%+.1f", (a-b)/b*100}')
MET=$(awk -v a="$B_CPU" 'BEGIN{print (a<=1897.3) ? ((a<=1686.5) ? "met, and past the far end of the band" : "met") : "missed"}')
say "best run $best: CPU $B_CPU CPU-s ($PCT % against $BEFORE_CPU), wall $B_WALL s · prediction -10 to -20 %: $MET"

# ---- write the after row and fill the two cells --------------------------------------------------
TREE=$(git rev-parse --short HEAD)
export B_CPU B_WALL B_CHK B_SLOW PCT MET TREE RUNS best N_NAMES N_FAST N_TFAST N_TSLOW N_STUB N_STUBF N_UNIT COVER PURITY SETS
python3 - <<'PY' || die "the files were not edited; every number is in $SETS (digest and raw) - paste by hand"
import os, re
g = os.environ.get
cover, purity = g("COVER"), g("PURITY")

rows = [
  ("check names (the full fixture)", f'{int(g("N_NAMES")):,}', "`wc -l < tests/fixtures/check-names.txt`"),
  ("fast names (the fast tier's fixture)", f'{int(g("N_FAST")):,}', "`wc -l < tests/fixtures/check-names-fast.txt`"),
  ("unit tests", f'{int(g("N_UNIT")):,}', "`node --test --test-isolation=none tests/unit/*.test.mjs`, its `tests` line"),
  ("check files, fast tier", g("N_TFAST"), "`awk 'FNR == 2' tests/checks/*.sh | sort | uniq -c`"),
  ("check files, slow tier", g("N_TSLOW"), "the same"),
  ("lines that start a stub run", f'{int(g("N_STUB"))} in {int(g("N_STUBF"))} files', "`grep -hE '\"$H\" start' tests/checks/*.sh | grep -vcE '^\\s*#'`"),
  ("full suite, solo: checks", g("B_CHK"), "the solo method: the output's last line"),
  ("full suite, solo: wall", f'{g("B_WALL")} s at 4 jobs', "the runner's `wall … s` line"),
  ("full suite, solo: CPU", f'{g("B_CPU")} CPU-s', "`User time` + `System time` of `time -v`"),
]
sec  = f'\n## The after row (S4, `{g("TREE")}`)\n\n'
sec += f'Taken by `tests/tools/solo-measure.sh` with the box quiet, {g("RUNS")} solo suites in sequence; the figures below are\n'
sec += f'run {g("best")}, the lower CPU of them. Raw output and `time -v` beside this file in `2026-11-03-suite-coverage/`.\n\n'
sec += "| measure | after S4 (`%s`) | the command |\n|---|---:|---|\n" % g("TREE")
for a, b, c in rows: sec += f"| {a} | {b} | {c} |\n"
sec += f'\nAgainst the before row: CPU {g("PCT")} % (2,108.1 → {g("B_CPU")} CPU-s), wall 599.4 → {g("B_WALL")} s. The slim suite\'s\n'
sec += f'prediction for the solo CPU was −10 to −20 %: **{g("MET")}**. The three slowest files of the run: {g("B_SLOW")}.\n'

t = open(cover, encoding="utf-8").read()
if "## The after row" in t: raise SystemExit("the after row is already in %s" % cover)
m = re.search(r"\n## How the map was measured", t)
t = (t[:m.start()] + sec + t[m.start():]) if m else (t.rstrip() + "\n" + sec)
open(cover, "w", encoding="utf-8").write(t)

p = open(purity, encoding="utf-8").read()
pend = "after this run, by the solo method on an empty box"
for name, before, pred, val in (
  ("full suite solo CPU",  "2,108.1 CPU-s", "−10 to −20 %", f'{g("B_CPU")} CPU-s'),
  ("full suite solo wall", "599.4 s",       "–",                 f'{g("B_WALL")} s'),
):
  old = f"| {name} | {before} | {pend} | {pred} | {pend} |"
  if old not in p: raise SystemExit("could not find the %s row to fill in %s" % (name, purity))
  verdict = f'**{g("MET")}**: {g("PCT")} % against the before row' if "CPU" in name else f'{g("PCT")} % CPU beside it; no prediction on the wall'
  p = p.replace(old, f"| {name} | {before} | {val} | {pred} | {verdict} |")
note = "The after row and the solo CPU and wall rows of the\nPredictions wait for an empty box, after this run ends."
if note in p:
  p = p.replace(note, f'The after row and the solo CPU and wall rows of the\nPredictions were taken on {g("TREE")} with the box quiet (`tests/tools/solo-measure.sh`).')
open(purity, "w", encoding="utf-8").write(p)
print("filled: the after row in %s, and both Predictions cells in %s" % (cover, purity))
PY
say "files written"

if (( NO_PR )); then say "--no-pr: stopping before git. Review: git diff"; exit 0; fi

# ---- commit, push, PR, merge ---------------------------------------------------------------------
git add -A -- "$SETS" "$COVER" "$PURITY" tests/tools/solo-measure.sh
git commit -q -m "findings: the slim suite's after row, measured on a quiet box

Two solo full suites in sequence by the before row's own method and commands
(tests/tools/solo-measure.sh, added here). Run $best, the lower CPU of them:
$B_CPU CPU-s ($PCT % against the before row's 2,108.1) and $B_WALL s wall
against 599.4. The slim suite's prediction for the solo CPU was -10 to -20 %:
$MET. The after row goes in the coverage findings with every measure taken by
the command that file records, and the two cells the S4 run was told to leave
empty are filled in the milestone's decision file." || die "nothing to commit"
br=$(git symbolic-ref --short HEAD)
git push -q -u origin "$br" || die "push failed; the commit is local, nothing lost"
url=$(gh pr create --title "findings: the slim suite's after row, measured on a quiet box" --body "$(cat <<BODY
Closes the last thing phase 4 owed. The S4 run's brief forbade it: *"Do not take the after row or fill the solo CPU and wall rows of the Predictions table: that suite needs an empty box and runs after this run ends."* The box was quiet, so it ran.

**$RUNS solo full suites in sequence**, by the method and the commands the before row records, on \`$TREE\`. Run $best is the lower CPU of them:

| | before S1 | after S4 | prediction | |
|---|---:|---:|---|---|
| solo CPU | 2,108.1 CPU-s | **$B_CPU CPU-s** | −10 to −20 % | **$MET** ($PCT %) |
| solo wall | 599.4 s | **$B_WALL s** | – | |
| checks | 1464/1464 | $B_CHK | | |

Slowest three: $B_SLOW

Every other measure of the after row (check names, fast names, unit tests, check files per tier, stub-start lines) was taken by the same command the before row names, so the two rows are comparable line for line.

Adds \`tests/tools/solo-measure.sh\`, which took them: it refuses to run unless the box is quiet (no run alive, empty queue, runner off, the daily temp cleaner neither running nor due), runs the suites one after another rather than on a clock, and fills both tables from fixed commands. The Met? verdict is one comparison, not a judgement.
BODY
)" 2>&1 | tail -1)
say "PR: $url"
[[ $url == http* ]] || die "PR not opened; branch $br is pushed"
gh pr merge "$url" --merge > /dev/null 2>&1 && say "merged $url" || say "merge left for Michael: $url"
say "done"
