#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the TTY forms (U3-07): report, trends and gc --dry-run render through view.mjs for a person (HARNESS_TTY=1 ----
# ---- or a terminal); off a TTY, and with --md, their output is byte for byte what it was ----
# summary-report.json: main's .harness/runs/agent-harness-2026-10-26/summary.json (that run's record, git show);
# summary-report.md: summary.mjs report of it, made before U3-07 changed summary.mjs
SM="node $HERE/../lib/summary.mjs" FX=$HERE/fixtures
unset HARNESS_TTY   # "off a TTY" is the checks' stdout (a file or a pipe), whatever the caller exported
mkdir -p "$HARNESS_LEDGER/agent-harness/agent-harness-2026-10-26"; cp "$FX/summary-report.json" "$HARNESS_LEDGER/agent-harness/agent-harness-2026-10-26/summary.json"
check "tty views: summary.mjs report --md and off a TTY, and harness report off a TTY, are the stored markdown byte for byte" '
  $SM report --md "$FX/summary-report.json" | cmp - "$FX/summary-report.md" &&
  HARNESS_TTY=1 $SM report --md "$FX/summary-report.json" | cmp - "$FX/summary-report.md" &&
  $SM report "$FX/summary-report.json" | cmp - "$FX/summary-report.md" &&
  "$H" report agent-harness-2026-10-26 | cmp - <(cat "$FX/summary-report.md"; echo) &&
  HARNESS_TTY=1 "$H" report --md agent-harness-2026-10-26 | cmp - <(cat "$FX/summary-report.md"; echo)'
HARNESS_TTY=1 HARNESS_COLOR=never COLUMNS=100 "$H" report agent-harness-2026-10-26 > "$T/rt.out" 2>&1
check "tty views: harness report on a TTY is a card and a feature table: no | table row, no **, the fields and the 9 rows" '
  ! grep "|" "$T/rt.out" > /dev/null && ! grep -F "**" "$T/rt.out" > /dev/null &&
  [[ $(head -1 "$T/rt.out") == "agent-harness-2026-10-26 · agent-harness" ]] &&
  grep -E "^  passing +8/17 · verified 4 \(P0\)" "$T/rt.out" > /dev/null && grep -E "^  spend +\\\$70.11 total" "$T/rt.out" > /dev/null &&
  grep -E "^  not passing +not reached 9$" "$T/rt.out" > /dev/null &&
  [[ $(grep -cE "^P[12]-0[1-7] +not reached +run ended: " "$T/rt.out") == 9 ]] &&
  node -e "process.exit(require(\"fs\").readFileSync(process.argv[1], \"utf8\").split(\"\n\").every(l => [...l].length <= 100) ? 0 : 1)" "$T/rt.out"'
mkdir -p "$T/mp"; cp "$FX/summary-report.json" "$T/mp/summary.json"
printf "%s\n" "{\"feature\":\"P0-02\",\"model\":\"opus\",\"mem_peak_mb\":3100}" "{\"feature\":\"P0-03\",\"model\":\"opus\",\"mem_peak_mb\":900}" > "$T/mp/metrics.jsonl"
check "tty views: the memory peaks over 2 GB are a section of the TTY report, as they are a list in the markdown" '
  HARNESS_TTY=1 HARNESS_COLOR=never $SM report "$T/mp/summary.json" > "$T/mp.out" && grep -E "^MEMORY PEAKS OVER 2 GB 1" "$T/mp.out" > /dev/null &&
  grep -xF "P0-02 · opus · 3100 MB" "$T/mp.out" > /dev/null && ! grep P0-03 "$T/mp.out" > /dev/null &&
  $SM report "$T/mp/summary.json" | grep -xF -- "- P0-02 · opus · 3100 MB" > /dev/null'
# 17 ledger rows, ended one day apart (r01 the oldest)
for i in $(seq -w 1 17); do jq -nc --arg i "$i" '{run: "r\($i)", project: "proj", passing: 2, total: 3, merged: 1, tests_start: 10, tests_end: 12,
  cost: 6, per_passing: 3, wall_h: 1.5, end_reason: "done", ended_at: "2026-10-\($i)T10:00:00.000Z", causes: {"not reached": 1}}'; done > "$HARNESS_LEDGER/runs.jsonl"
check "tty views: trends on a TTY shows the newest 15 runs as columns, 2 older: harness trends --all and the total over all 17" '
  HARNESS_TTY=1 HARNESS_COLOR=never COLUMNS=200 "$H" trends > "$T/tr.out" && [[ $(grep -cE "^r[0-9]{2}  " "$T/tr.out") == 15 ]] &&
  ! grep -E "^r0[12] " "$T/tr.out" > /dev/null && grep -E "^r17 +proj +2/3 " "$T/tr.out" > /dev/null && ! grep "|" "$T/tr.out" > /dev/null &&
  grep -xF "2 older: harness trends --all" "$T/tr.out" > /dev/null &&
  [[ $(tail -1 "$T/tr.out") == "17 runs · 34 features passed · \$102.00 · \$3.00 per passing feature · not passing by cause: not reached 17" ]] &&
  HARNESS_TTY=1 HARNESS_COLOR=never "$H" trends --all > "$T/tra.out" && [[ $(grep -cE "^r[0-9]{2}  " "$T/tra.out") == 17 ]] && ! grep older "$T/tra.out" > /dev/null'
check "tty views: trends at 60 columns keeps every line within 60, one or two lines a run, and the whole total line" '
  HARNESS_TTY=1 HARNESS_COLOR=never COLUMNS=60 "$H" trends > "$T/tn.out" &&
  node -e "const l = require(\"fs\").readFileSync(process.argv[1], \"utf8\").trimEnd().split(\"\n\");
    process.exit(l.every(x => [...x].length <= 60) && l.length <= 1 + 2 * 16 + 1 + 1 + 3 ? 0 : 1)" "$T/tn.out" &&
  sed -n "/^2 older/,\$p" "$T/tn.out" | tail -n +3 | paste -sd" " | grep -F "17 runs · 34 features passed" | grep -F "not passing by cause: not reached 17" > /dev/null'
check "tty views: trends off a TTY is the markdown table of all 17 rows, --all and --md the same bytes" '
  "$H" trends > "$T/tm.out" && [[ $(head -1 "$T/tm.out") == "| Run | Project | Passing | tests (baseline → end) | \$ | \$/feature | Wall h | Ended | Not passing |" ]] &&
  [[ $(grep -c "^| r[0-9][0-9] | proj | 2/3 (merged 1) | 10 → 12 | \$6.00 | \$3.00 | 1.5 | done | not reached 1 |$" "$T/tm.out") == 17 ]] &&
  "$H" trends --all | cmp - "$T/tm.out" && HARNESS_TTY=1 "$H" trends --md | cmp - "$T/tm.out" &&
  HARNESS_TTY=1 "$H" trends --by version | grep "^| Harness | Runs |" > /dev/null'
# gc --dry-run: a finished stub run (its worktree and branches go), a session worktree on another branch (keeps), a
# unit of the ended run and an unowned one
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 HARNESS_TTY=1 "$H" start "$T/proj" tv1 --spec SPEC.md --foreground > "$T/tv1.out" 2>&1
check "tty views: finish writes report.md as markdown under HARNESS_TTY=1" '
  grep "^| Passing | \*\*" "$HARNESS_STATE/proj/tv1/report.md" > /dev/null'
git -C "$T/proj" fetch -q origin; git -C "$T/proj" worktree add -q -b mine "$T/wt/proj/mine" origin/main > /dev/null 2>&1
# a merged lane branch, local and on origin: two would: lines, one branch
git -C "$T/proj" branch harness-lane/tv1/Z origin/main; git -C "$T/proj" push -q origin harness-lane/tv1/Z > /dev/null 2>&1
mkdir -p "$T/scope"; touch "$T/scope/harness-tv1-svc".{alive,running} "$T/scope/harness-zz".{alive,running}
"$H" gc "$T/proj" --dry-run > "$T/gp.out" 2> "$T/gp.err"
HARNESS_TTY=1 HARNESS_COLOR=never HARNESS_GLYPHS=unicode COLUMNS=300 "$H" gc "$T/proj" --dry-run > "$T/gt.out" 2> "$T/gt.err"
check "tty views: gc --dry-run on a TTY has the six headers in order and the footer; off a TTY no header, marker or footer" '
  [[ $(grep -oE "^(UNITS|TMUX|DESKS|WORKTREES|DEPS|BRANCHES)( [0-9]+)?" "$T/gt.out" | cut -d" " -f1 | paste -sd" ") == "UNITS TMUX DESKS WORKTREES DEPS BRANCHES" ]] &&
  grep -E "^WORKTREES 2 (─)+" "$T/gt.out" > /dev/null && grep -xE "DEPS 0" "$T/gt.out" > /dev/null &&
  b=$(grep -E "^would: git .* (branch -[dD]|push -q origin --delete) " "$T/gp.out" | awk "{ print \$NF }" | sort -u | wc -l) &&
  (( b == 1 )) && [[ $(tail -1 "$T/gt.out") == "would remove 1 worktree, 1 branch; keeps 1" ]] &&
  ! grep -E "^(UNITS|TMUX|DESKS|WORKTREES|DEPS|BRANCHES)|would remove|$(printf "\x1e")" "$T/gp.out" > /dev/null &&
  grep -x "would: systemctl --user stop harness-tv1-svc.scope (tv1 ended)" "$T/gp.out" > /dev/null'
check "tty views: the TTY form less its headers, rule and footer is the plain form, line for line in the same order" '
  grep -vE "^(UNITS|TMUX|DESKS|WORKTREES|DEPS|BRANCHES)( [0-9]+)?( (─)+)?$|^(─)+$|^would remove " "$T/gt.out" | diff - "$T/gp.out"'
u=$(git -C "$T/proj" remote get-url origin); git -C "$T/proj" remote set-url origin "$T/no-origin"
HARNESS_TTY=1 HARNESS_COLOR=never "$H" gc "$T/proj" --dry-run > "$T/gs.out" 2> "$T/gs.err"; gs=$?
git -C "$T/proj" remote set-url origin "$u"
check "tty views: a dry run that stops at the fetch says where it stopped, no empty sections after it and no footer" '
  (( gs != 0 )) && grep -E "^TMUX 0$" "$T/gs.out" > /dev/null && [[ $(tail -1 "$T/gs.out") == "gc stopped before DESKS (see the error above)" ]] &&
  ! grep -E "^(DESKS|WORKTREES|DEPS|BRANCHES)|would remove" "$T/gs.out" > /dev/null && [[ -s $T/gs.err ]]'
check "tty views: gcView shortens the home directory to a tilde and counts a branch named twice once" '
  node --input-type=module -e "
    import { gcView, context } from \"$HERE/../lib/view.mjs\";
    const ctx = context({ env: { COLUMNS: \"60\", HARNESS_GLYPHS: \"ascii\" } }), R = String.fromCharCode(30), d = \"-\".repeat(60);
    const out = gcView([R + \"UNITS\", R + \"TMUX\", R + \"DESKS\", R + \"WORKTREES\", \"would: git -C /h/u/my p worktree remove --force /h/u/wt/p/a\",
      \"keeps /h/u/wt/p/b: its desk is open (harness desk --close b)\", R + \"DEPS\", \"keeps the deps of /h/u/wt/p/b: its desk is open\",
      R + \"BRANCHES\", \"would: git -C /h/u/p branch -d harness/a\", \"would: git -C /h/u/p push -q origin --delete harness/a\", R + \"END\"].join(\"\n\"), ctx, { HOME: \"/h/u\" });
    const want = [\"UNITS 0\", \"TMUX 0\", \"DESKS 0\", \"WORKTREES 2 \" + d.slice(12), \"would: git -C ~/my p worktree remove --force ~/wt/p/a\",
      \"keeps ~/wt/p/b: its desk is open (harness desk --close b)\", \"DEPS 1 \" + d.slice(7), \"keeps the deps of ~/wt/p/b: its desk is open\",
      \"BRANCHES 2 \" + d.slice(11), \"would: git -C ~/p branch -d harness/a\", \"would: git -C ~/p push -q origin --delete harness/a\", d,
      \"would remove 1 worktree, 1 branch; keeps 1\"];
    if (JSON.stringify(out) !== JSON.stringify(want)) { console.error(JSON.stringify(out)); process.exit(1); }
    const cutShort = gcView([R + \"UNITS\", \"? x\", R + \"TMUX\"].join(\"\n\"), ctx, {});
    if (JSON.stringify(cutShort) !== JSON.stringify([\"UNITS 1 \" + d.slice(8), \"? x\", \"TMUX 0\", \"gc stopped before DESKS (see the error above)\"])) { console.error(JSON.stringify(cutShort)); process.exit(1); }"'
suite_end
