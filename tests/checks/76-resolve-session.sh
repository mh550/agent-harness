#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- layer 2 of conflict resolution, the happy path (N2-03): a lane's re-base that conflicts with main runs a resolve
# session (lib/resolve.sh), the merge it commits takes one verify round, then merges; CONFLICTS=michael and
# `harness merge` keep today's needs path. Plan: docs/plans/2026-10-29-N2-conflict-resolution.md ----
# Two lanes, M2 after: [] (C): C goes first and M2's verify waits (STUB_VERIFY_WAIT) until M1 has merged work-B.txt, so
# M2's merge meets a main where A rewrote line 2 of README.md, as C did (STUB_CONFLICT): a real conflict.
waitf() { local i; for i in $(seq $(( $2 * 5 ))); do eval "$1" && return 0; sleep 0.2; done; return 1; }   # <bash expr> <s>
held() { rm -f "$T"/held-* "$T"/release-* "$T"/vwait-*; : > "$T/hold-coding"; }
tmp=$(mktemp -d); git clone -q "$T/origin.git" "$tmp" && printf '# demo\nline two\nline three\n' > "$tmp/README.md" && git -C "$tmp" add README.md \
  && git -C "$tmp" -c user.name=t -c user.email=t@test commit -qm "README.md" && git -C "$tmp" push -q origin HEAD:main; rm -rf "$tmp"
main0=$(git -C "$T/origin.git" rev-parse main)
echo 'MAX_LANES=2' >> "$T/user-config.sh"
two_lanes() {   # <run>: then the invariant, read before origin's main goes back
  held
  STUB_CONFLICT=README.md STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 STUB_VERIFY_WAIT=M2:work-B.txt \
    "$H" start "$T/proj" "$1" --spec SPEC.md --foreground > "$T/$1.out" 2>&1 & P=$!
  waitf "[[ -f \$T/held-$1-A && -f \$T/held-$1-C ]]" 120; touch "$T/release-$1-C"
  waitf "[[ -f \$T/vwait-$1-M2 ]]" 120; touch "$T/release-$1"; wait "$P"; rm -f "$T/hold-coding"
  git -C "$T/origin.git" diff --quiet "run/$1/M2" main 2> /dev/null && echo same > "$T/$1.inv"
}
slog() { cat "$T/scratch/proj/$1/sessions.log" 2> /dev/null; }

STUB_MERGE_RESOLVE=both two_lanes rs
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
S=$HARNESS_STATE/proj/rs REC=$T/wt/proj/rs/.harness/runs/rs
check "resolve: a re-base conflict gets a resolve session, noted with its file" \
  'hlog rs | grep -F "· M2: 1 files conflict with main (README.md); a resolve session" > /dev/null'
check "resolve: the resolved merge takes one verify round, then M2 merges (one resolve line, two verify lines)" \
  '[[ $(slog rs | grep -c "^resolve M2 ") == 1 && $(slog rs | grep -c "^verify M2 ") == 2 ]] && hlog rs | grep -F "· M2 merged into main · " > /dev/null \
  && hlog rs | grep -E "· M2 re-based on main [0-9a-f]{7}: [0-9]+ files, overlapping \(README.md\); one verify round \(1 of 1\)$" > /dev/null'
check "resolve: the tree on main is the tree verified as run/<run>/M2 (the invariant)" \
  '[[ $(cat "$T/rs.inv" 2> /dev/null) == same ]] && git -C "$T/origin.git" show run/rs/M2:README.md | grep -x "line two, from A" > /dev/null \
  && git -C "$T/origin.git" show run/rs/M2:README.md | grep -x "line two, from C" > /dev/null'
check "resolve: no needs record and one metrics row of kind resolve" \
  '[[ -z $(ls -A "$S/needs" 2> /dev/null | grep -v "^done$") && $(jq -s "[.[] | select(.kind == \"resolve\")] | length" "$REC/metrics.jsonl") == 1 ]] \
  && ! hlog rs | grep "needs Michael" > /dev/null && jq -e "select(.kind == \"resolve\" and .feature == \"M2\")" "$REC/entries.jsonl" > /dev/null'
check "resolve: the resolve prompt names README.md and a commit subject from each side" \
  'p=$(ls "$S"/logs/*-resolve-M2.prompt.md 2> /dev/null | head -1); [[ -n $p ]] && head -1 "$p" | grep -x "# Resolve session" > /dev/null \
  && grep -x "README.md" "$p" > /dev/null && grep -F "A: stub work (1)" "$p" > /dev/null && grep -F "C: stub work (1)" "$p" > /dev/null'
# visible, never asked about (N2-05): the note, summary.json's conflicts, report.md's row, the PR body; no needs-you post
check "resolve: the resolution's note names its files, model and minutes, and the verify round that follows" \
  'hlog rs | grep -E "· M2: main merged in by a resolve session \(README.md; [a-z0-9.-]+, [0-9]+ min\); one verify round follows$" > /dev/null'
check "resolve: summary.json counts the resolution and report.md has its Conflicts row" \
  'jq -e ".conflicts == {resolved: 1, escalated: 0, sessions: 1}" "$REC/summary.json" > /dev/null \
  && grep -Fx "| Conflicts | 1 resolved by sessions (M2: README.md), 0 to Michael |" "$REC/report.md" > /dev/null'
check "resolve: report.md's Spend by role names the resolve sessions' spend" \
  'grep -E "^\| Spend by role \| .*· resolve \\\$[0-9.]+ ·" "$REC/report.md" > /dev/null'
check "resolve: the PR body says main was merged in by a resolve session, and no needs-you post went out" \
  'grep -Fx "Merged main in with a resolve session: README.md" "$S/pr-body.md" > /dev/null && ! grep -E "^Title: \[rs\] .*needs you" "$T/curl.log" > /dev/null'
CFX='import { conflicts, resolutions, report } from "'$HERE'/../lib/summary.mjs"; import { readFileSync } from "node:fs";
  const fx = JSON.parse(readFileSync("'$HERE'/fixtures/summary-report.json", "utf8"));
  const log = ["- 2026-10-29 01:00 · M2: main merged in by a resolve session (a.txt, b c.txt; claude-opus-5-5, 3 min); one verify round follows",
    "- 2026-10-29 01:10 · M3: main merged in by a resolve session (d.txt; opus, 0 min); the verify goes on with main merged",
    "- 2026-10-29 01:20 · M4 conflicts with main; not merged (needs Michael)", "- 2026-10-29 01:30 · M4 conflicts with main; not merged (needs Michael)",
    "- 2026-10-29 01:40 · main conflicts with harness-lane/r/M5; carrying on without it (merges into main need Michael)",
    "- 2026-10-29 01:50 · main conflicts with harness/r; carrying on without it (merges into main need Michael)"].join("\n");
  const c = conflicts(log, [{ kind: "resolve" }, { kind: "resolve", env: true }, { kind: "coding" }]), rs = resolutions(log);
  const row = s => report(s).split("\n").find(l => l.startsWith("| Conflicts | "));
  process.exit(JSON.stringify(c) === JSON.stringify({ resolved: 2, escalated: 2, sessions: 2 })
    && JSON.stringify(rs) === JSON.stringify([{ milestone: "M2", files: "a.txt, b c.txt" }, { milestone: "M3", files: "d.txt" }])
    && row({ ...fx, conflicts: c, resolutions: rs }) === "| Conflicts | 2 resolved by sessions (M2: a.txt, b c.txt; M3: d.txt), 2 to Michael |"
    && row({ ...fx, conflicts: conflicts("", []), resolutions: [] }) === "| Conflicts | 0 resolved, 0 to Michael |" && row(fx) === undefined
    && report({ ...fx, flakes: { count: 0, names: {} }, conflicts: c, resolutions: rs }).split("\n").findIndex(l => l.startsWith("| Conflicts | "))
      === report({ ...fx, flakes: { count: 0, names: {} } }).split("\n").findIndex(l => l.startsWith("| Flakes | ")) + 1 ? 0 : 1);'
check "summary.mjs: conflicts counts resolutions, distinct escalated milestones and resolve rows; resolutions names the files; the Conflicts row after Flakes" \
  'node --input-type=module -e "$CFX"'
check "resolve: prompts/resolve.md renders through lib/prompt.sh as a command, first line # Resolve session, no {{ left" \
  '"$HH/lib/prompt.sh" "$S" resolve C > "$T/rs-prompt.md" 2> "$T/rs-prompt.err" && [[ $(head -1 "$T/rs-prompt.md") == "# Resolve session" ]] \
  && ! grep -F "{{" "$T/rs-prompt.md" > /dev/null && grep -F "Milestone: M2" "$T/rs-prompt.md" > /dev/null'

# merge_one alone (64-needs-review.sh's mo shape): in a lane under CONFLICTS=resolve its conflict is the re-base's (3,
# moved-<m>, no record); under HARNESS_MERGE_ONLY it is today's merge_conflict
U=$T/u; mkdir -p "$U/st"; git init -q --bare -b main "$U/o.git"; git clone -q "$U/o.git" "$U/wt/run" 2> /dev/null
ug() { git -C "$U/wt/run" -c user.name=t -c user.email=t@t "$@"; }
echo base > "$U/wt/run/f"; ug add f; ug commit -qm base; ug push -q origin main
ug checkout -q -b harness-lane/u/M1; echo m1 > "$U/wt/run/f"; ug commit -qam m1; ug tag -a run/u/M1 -m "harness run u: M1 verified (v3)"
ug push -q origin harness-lane/u/M1 run/u/M1; ug checkout -q main; echo main2 > "$U/wt/run/f"; ug commit -qam main2; ug push -q origin main
ug checkout -q -b harness/u; mkdir -p "$U/wt/run/.harness/runs/u" "$U/st/lanes/M1"
printf '{"features":[{"id":"A","milestone":"M1","passes":true}]}\n' > "$U/wt/run/.harness/runs/u/feature_list.json"
mo() {
  ( source "$HH/lib/record.sh"; HARNESS_HOME=$HH; source "$HH/lib/needs.sh"
    STATE=$U/st LS=$U/st RWT=$U/wt/run REC=$U/wt/run/.harness/runs/u RUN_DIR=.harness/runs/u RUN_ID=u PROJECT_NAME=proj MAIN_BRANCH=main RBRANCH=harness/u
    LIST=$REC/feature_list.json LBRANCH="" HARNESS_WT=$U/wt/run MERGE_POLICY=auto HARNESS_SCRATCH_ROOT=$U/fix CONFLICTS=resolve; F() { node "$HH/lib/features.mjs" "$@"; }
    note() { echo "$*" >> "$U/notes"; }; log() { :; }; sync_record() { :; }; notify() { :; }; desk() { :; }; pr_body() { echo body; }; gh_url() { :; }; lane_branch_gone() { :; }
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
    cd "$U/wt/run" && merge_one M1; echo "rc=$?" ); }
u1=$(mo); u1n=$(ls "$U/st/needs" 2> /dev/null | grep -c json)
u2=$(HARNESS_MERGE_ONLY=1 mo)
check "resolve: merge_one's conflict returns 3 with moved-<m> in a lane and opens merge_conflict under HARNESS_MERGE_ONLY" \
  '[[ $u1 == rc=3 && $u1n == 0 && $(cat "$U/st/moved-M1") == $(git -C "$U/o.git" rev-parse main) ]] \
  && [[ $u2 == rc=1 ]] && grep -l merge_conflict:M1 "$U"/st/needs/*.json > /dev/null && grep -x "M1 conflicts with main; not merged (needs Michael)" "$U/notes" > /dev/null'

# merge_one at the run's end (finish wrote ended; no lane can re-base): today's merge_conflict, whatever CONFLICTS says
rm -rf "$U/st/needs" "$U/st/moved-M1" "$U/st/conflict-M1" "$U/notes"; touch "$U/st/ended"; u3=$(mo); rm -f "$U/st/ended"
check "resolve: merge_one's conflict at the run's end keeps today's merge_conflict record" \
  '[[ $u3 == rc=1 && ! -f $U/st/moved-M1 ]] && grep -l merge_conflict:M1 "$U"/st/needs/*.json > /dev/null'

# resolve alone, its session a function: the conflict resolved, and what it did outside it put back as git merged it,
# whatever the path (a blank, a non-ASCII byte, a symlink, a file it created or added); the merge committed, the slot clean
V=$T/v; git init -q -b main "$V"; vg() { git -C "$V" -c user.name=t -c user.email=t@t "$@"; }
echo base > "$V/conf.txt"; echo one > "$V/a b.txt"; echo two > "$V/café.txt"; echo tgt > "$V/target.txt"; ln -s target.txt "$V/link"
vg add -A; vg commit -qm base; vg checkout -q -b lane; echo lane > "$V/conf.txt"; vg commit -qam "lane: conf"
vg checkout -q main; echo main > "$V/conf.txt"; echo "one, main" > "$V/a b.txt"; vg commit -qam "main: conf"; vg checkout -q lane
v_rc=$( cd "$V" && export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  git merge -q --no-edit main > /dev/null 2>&1; HARNESS_HOME=$HH; source "$HH/lib/scope.sh"; source "$HH/lib/record.sh"; source "$HH/lib/resolve.sh"
  STATE=$U/vst SCRATCH=$U/vsc LOGS=$U/vsc LDIR=$U/vsc LIST=$U/vsc/list.json RUN_DIR=.harness/runs/v RUN_ID=v LANE=M1 CONFLICTS=resolve MAX_RESOLVES=3 \
    RESOLVE_TIMEOUT=30m RESOLVE_MODEL=opus RESOLVE_MAX_TURNS=60 RESOLVE_BUDGET_USD=5 DEADLINE=$(( $(date +%s) + 86400 )) MAX_SESSIONS=50 MAX_LIMIT_HITS=6
  mkdir -p "$STATE" "$SCRATCH"; echo '{"features":[{"id":"A","milestone":"M1","description":"a"}]}' > "$LIST"
  note() { echo "$*" >> "$U/vnotes"; }; log() { :; }; record() { "$@"; }; rec_commit() { :; }; journal() { :; }; materialize() { :; }; unmaterialize() { :; }
  weekly_over() { return 1; }; mem_gate() { return 0; }; prompt() { :; }; clock() { :; }; MET() { return 1; }
  session() { echo both > conf.txt; git add conf.txt; echo stray >> "a b.txt"; rm "café.txt"; echo through >> link; rm link; echo file > link
    echo new > "new file.txt"; echo added > added.txt; git add added.txt; S_WALL=60 S_EXIT=0 S_PEAK=""; }
  resolve M1 main; echo "rc=$?" )
check "resolve: a resolved merge is committed and every edit outside the conflict is put back, whatever its path" \
  '[[ $v_rc == rc=0 && $(git -C "$V" rev-list --parents -n1 HEAD | wc -w) == 3 && $(cat "$V/conf.txt") == both ]] \
  && [[ $(cat "$V/a b.txt") == "one, main" && $(cat "$V/café.txt") == two && $(cat "$V/target.txt") == tgt && $(readlink "$V/link") == target.txt ]] \
  && [[ ! -e "$V/new file.txt" && ! -e $V/added.txt && -z $(git -C "$V" status --porcelain) ]] \
  && grep "^M1: the resolve session edited .* outside the conflict; restored$" "$U/vnotes" > /dev/null && [[ $(cat "$U/vst/resolves-M1") == 1 ]]'

# slot_open reusing a slot a lane was killed in mid-resolve (MERGE_HEAD, markers in the tree): the half-merge is undone,
# never committed as WIP and pushed onto the lane branch
W=$T/w; git init -q --bare -b main "$W/o.git"; git clone -q "$W/o.git" "$W/wt/run" 2> /dev/null
wg() { git -C "$W/wt/run" -c user.name=t -c user.email=t@t "$@"; }
echo base > "$W/wt/run/f"; wg add f; wg commit -qm base; wg push -q origin main; wg checkout -q -b harness/w
mkdir -p "$W/wt/run/.harness/runs/w" "$W/st"; printf '{"features":[{"id":"A","milestone":"M1","passes":false}]}\n' > "$W/wt/run/.harness/runs/w/feature_list.json"
wg worktree add -q -b harness-lane/w/M1 "$W/wt/lanes/w/slot-0" origin/main 2> /dev/null; sg() { git -C "$W/wt/lanes/w/slot-0" -c user.name=t -c user.email=t@t "$@"; }
echo lane > "$W/wt/lanes/w/slot-0/f"; sg commit -qam lane; sg push -q origin harness-lane/w/M1; sg checkout -q -b other HEAD~1
echo other > "$W/wt/lanes/w/slot-0/f"; sg commit -qam other; sg checkout -q harness-lane/w/M1; sg merge -q other > /dev/null 2>&1
w_pre=$(git -C "$W/o.git" rev-parse harness-lane/w/M1)
w_rc=$( source "$HH/lib/record.sh"; HARNESS_HOME=$HH; source "$HH/lib/needs.sh"
  STATE=$W/st LS=$W/st LDIR="" RWT=$W/wt/run REC=$W/wt/run/.harness/runs/w RUN_DIR=.harness/runs/w RUN_ID=w PROJECT_NAME=proj MAIN_BRANCH=main RBRANCH=harness/w WT_ROOT_DIR=$W/wt PORT=7999
  LIST=$REC/feature_list.json; F() { node "$HH/lib/features.mjs" "$@"; }; note() { echo "$*" >> "$W/notes"; }; log() { :; }
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  slot_open M1; echo "rc=$?" )
check "resolve: slot_open undoes a merge a killed lane left in progress in its slot, never committing its markers" \
  '[[ $(git -C "$W/o.git" rev-parse harness-lane/w/M1) == "$w_pre" ]] && ! git -C "$W/wt/lanes/w/slot-0" rev-parse -q --verify MERGE_HEAD > /dev/null \
  && ! git -C "$W/o.git" log --format=%s harness-lane/w/M1 | grep "^WIP" > /dev/null && grep -x "M1: its slot-0 had a merge left in progress; undone" "$W/notes" > /dev/null'

# CONFLICTS=michael: today's path, and `harness merge` on it (the default back) keeps it too
echo 'CONFLICTS=michael' >> "$T/user-config.sh"
STUB_MERGE_RESOLVE=both two_lanes rm
sed -i '/^CONFLICTS=/d' "$T/user-config.sh"
rm_needs=$(grep -l '"key": "merge_conflict:M2"' "$HARNESS_STATE"/proj/rm/needs/*.json 2> /dev/null | wc -l)
check "resolve: CONFLICTS=michael keeps today's merge_conflict record and runs no resolve session" \
  'hlog rm | grep -F "· M2 conflicts with main; not merged (needs Michael)" > /dev/null && [[ $rm_needs == 1 ]] \
  && [[ -f $HARNESS_STATE/proj/rm/pr-body.md ]] && ! grep -F "resolve session" "$HARNESS_STATE/proj/rm/pr-body.md" > /dev/null \
  && ! slog rm | grep "^resolve " > /dev/null && ! hlog rm | grep "a resolve session" > /dev/null'
STUB_MERGE_RESOLVE=both "$H" merge rm > "$T/rm-merge.out" 2>&1
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
check "resolve: harness merge on the conflicting milestone keeps the needs path and runs no session" \
  '[[ $(hlog rm | grep -c "· M2 conflicts with main; not merged (needs Michael)") == 2 ]] && ! slog rm | grep "^resolve " > /dev/null \
  && ! hlog rm | grep -F "· M2 merged into main" > /dev/null'
suite_end
