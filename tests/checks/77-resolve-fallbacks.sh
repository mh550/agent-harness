#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- layer 2's bounds and fallbacks (N2-04): a resolve session that leaves a marker, gives up or edits outside the
# conflict; one refused by a limit is deferred; MAX_RESOLVES bounds it; sync_main at a lane's verify resolves too; the
# record branch and slot_open keep today's path. Plan: docs/plans/2026-10-29-N2-conflict-resolution.md ----
# Two lanes as in 76-resolve-session.sh: C first, M2's verify waits until M1 has merged, so M2's merge meets a main
# where A rewrote line 2 of README.md, as C did (STUB_CONFLICT).
waitf() { local i; for i in $(seq $(( $2 * 5 ))); do eval "$1" && return 0; sleep 0.2; done; return 1; }   # <bash expr> <s>
held() { rm -f "$T"/held-* "$T"/release-* "$T"/vwait-*; : > "$T/hold-coding"; }
tmp=$(mktemp -d); git clone -q "$T/origin.git" "$tmp" && printf '# demo\nline two\nline three\n' > "$tmp/README.md" && git -C "$tmp" add README.md \
  && git -C "$tmp" -c user.name=t -c user.email=t@test commit -qm "README.md" && git -C "$tmp" push -q origin HEAD:main; rm -rf "$tmp"
main0=$(git -C "$T/origin.git" rev-parse main)
echo 'MAX_LANES=2' >> "$T/user-config.sh"
two_lanes() {   # <run>: M2's re-base conflicts; origin's main back after it
  held
  STUB_CONFLICT=README.md STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 STUB_VERIFY_WAIT=M2:work-B.txt \
    "$H" start "$T/proj" "$1" --spec SPEC.md --foreground > "$T/$1.out" 2>&1 & P=$!
  waitf "[[ -f \$T/held-$1-A && -f \$T/held-$1-C ]]" 120; touch "$T/release-$1-C"
  waitf "[[ -f \$T/vwait-$1-M2 ]]" 120; touch "$T/release-$1"; wait "$P"; rm -f "$T/hold-coding"
  git -C "$T/origin.git" update-ref refs/heads/main "$main0"
}
slog() { cat "$T/scratch/proj/$1/sessions.log" 2> /dev/null; }
nj() { jq -rs "${2:-.}" "$HARNESS_STATE/proj/$1"/needs/*.json 2> /dev/null; }   # <run> [<jq over its open items>]

# how many stub-curl posts hold every one of the given strings (61-needs-git.sh's)
posts() { awk 'BEGIN { RS = "===\n"; split(ARGV[1], k, "\t"); ARGV[1] = "" } { for (i in k) if (!index($0, k[i])) next; n++ } END { print n + 0 }' "$(IFS=$'\t'; echo "$*")" "$T/curl.log"; }
# <run>: M2's lane branch on origin is its verified commit (the failed merge never pushed) and its record is the one
# merge_conflict, its card's tried as given (an ERE), seen and notified once
aborted() {
  [[ $(git -C "$T/origin.git" rev-parse "harness-lane/$1/M2") == $(git -C "$T/origin.git" rev-parse "run/$1/M2^{commit}") ]] \
  && [[ $(nj "$1" '[.[] | .key] | join(" ")') == merge_conflict:M2 && $(nj "$1" '.[0].seen') == 1 ]] && nj "$1" '.[0].card.tried' | grep -E "^$2$" > /dev/null \
  && [[ $(posts "Title: [$1] M2 needs you") == 1 ]] && hlog "$1" | grep -F "· lane M2 closed (M2 needs Michael: conflicts with main)" > /dev/null \
  && ! hlog "$1" | grep -F "· M2 merged into main" > /dev/null
}

STUB_MERGE_RESOLVE=markers two_lanes rmk
check "resolve fallbacks: a session that leaves a marker is aborted, the slot back at the verified commit, merge_conflict with tried, the lane closed" \
  'hlog rmk | grep -F "· M2: the resolve session did not resolve the merge (conflict markers left in README.md); merge aborted" > /dev/null \
  && aborted rmk "a resolve session \([a-z0-9.-]+, [0-9]+ min\): conflict markers left in README.md"'
STUB_MERGE_RESOLVE=give-up two_lanes rgu
check "resolve fallbacks: a session that gives up is aborted the same way and its card says why" \
  'hlog rgu | grep -F "· M2: the resolve session did not resolve the merge (UNRESOLVED: stub gives up); merge aborted" > /dev/null \
  && aborted rgu "a resolve session \([a-z0-9.-]+, [0-9]+ min\): UNRESOLVED: stub gives up" && [[ $(slog rgu | grep -c "^resolve M2 ") == 1 ]]'
check "resolve fallbacks: a session that gives up counts as escalated in summary.json and report.md's Conflicts row" \
  'R=$T/wt/proj/rgu/.harness/runs/rgu; jq -e ".conflicts.escalated == 1 and .conflicts.resolved == 0 and .conflicts.sessions == 1" "$R/summary.json" > /dev/null \
  && grep -Fx "| Conflicts | 0 resolved, 1 to Michael |" "$R/report.md" > /dev/null'

STUB_MERGE_RESOLVE=stray two_lanes rst
check "resolve fallbacks: a stray edit and new files are put back with a note naming them, and M2 merges" \
  'l=$(hlog rst | grep -F "· M2: the resolve session edited ") && [[ $l == *" outside the conflict; restored" ]] \
  && [[ $l == *work-A.txt* && $l == *" stray.txt"* && $l == *stray-added.txt* ]] \
  && hlog rst | grep -F "· M2 merged into main" > /dev/null && [[ $(git -C "$T/origin.git" show "run/rst/M2:work-A.txt") == $(git -C "$T/origin.git" show "run/rst/M1:work-A.txt") ]] \
  && ! git -C "$T/origin.git" log --format=%H -n 20 --all -- stray.txt stray-added.txt | grep . > /dev/null'

STUB_RESOLVE_LIMIT=1 STUB_MERGE_RESOLVE=both two_lanes rli
check "resolve fallbacks: a refused session is deferred: no needs record, rebase-M2 back, then it re-bases and merges after the wait" \
  'hlog rli | grep -E "· M2: the resolve session was refused \(.+\); deferred until [0-9]{2}:[0-9]{2}$" > /dev/null \
  && [[ $(hlog rli | grep -cF "· lane M2 opened (") == 2 && $(slog rli | grep -c "^resolve M2 ") == 2 ]] \
  && hlog rli | grep -F "· M2 merged into main" > /dev/null && [[ -z $(ls -A "$HARNESS_STATE/proj/rli/needs" 2> /dev/null | grep -v "^done$") ]] \
  && ! hlog rli | grep "needs Michael" > /dev/null'

printf 'MAX_RESOLVES=1\nMAX_REBASE_ROUNDS=2\n' >> "$T/user-config.sh"
STUB_MAIN_TOUCH=resolve-M2:README.md STUB_MERGE_RESOLVE=both two_lanes rmx
sed -i '/^MAX_RESOLVES=/d; /^MAX_REBASE_ROUNDS=/d' "$T/user-config.sh"
check "resolve fallbacks: past MAX_RESOLVES the next conflict takes today's path with the resolve session(s) used note" \
  '[[ $(slog rmx | grep -c "^resolve M2 ") == 1 ]] && hlog rmx | grep -F "· M2: its 1 resolve session(s) used; not merged (needs Michael)" > /dev/null \
  && hlog rmx | grep -F "· M2 verified on the re-based tree and re-tagged run/rmx/M2" > /dev/null \
  && aborted rmx "its 1 resolve session\(s\) used"'

# sync_main at M2's verify: C is released only once M1 has merged, so the verify's merge of main meets A's line 2
at_verify() {   # <run>
  held
  STUB_CONFLICT=README.md STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 \
    "$H" start "$T/proj" "$1" --spec SPEC.md --foreground > "$T/$1.out" 2>&1 & P=$!
  waitf "[[ -f \$T/held-$1-A ]]" 120; touch "$T/release-$1-A"; waitf "[[ -f \$T/held-$1-B ]]" 120; touch "$T/release-$1-B"
  waitf "hlog $1 2> /dev/null | grep -F '· M1 merged into main' > /dev/null" 120; touch "$T/release-$1"; wait "$P"; rm -f "$T/hold-coding"
  git -C "$T/origin.git" update-ref refs/heads/main "$main0"
}
STUB_MERGE_RESOLVE=both at_verify rsm
RL=$HARNESS_STATE/proj/rsm/run.log
check "resolve fallbacks: sync_main at verify resolves in the lane: the note before verify M2, one verify M2, merged with no re-base" \
  'a=$(grep -n "M2: 1 files conflict with main (README.md); a resolve session" "$RL" | head -1 | cut -d: -f1); b=$(grep -n " verify M2 · " "$RL" | head -1 | cut -d: -f1)
  [[ -n $a && -n $b ]] && (( a < b )) && [[ $(slog rsm | grep -c "^verify M2 ") == 1 && $(slog rsm | grep -c "^resolve M2 ") == 1 ]] \
  && hlog rsm | grep -F "· merged main into harness-lane/rsm/M2" > /dev/null && hlog rsm | grep -F "· M2 merged into main" > /dev/null \
  && ! hlog rsm | grep -F "re-based on" > /dev/null && [[ -z $(ls -A "$HARNESS_STATE/proj/rsm/needs" 2> /dev/null | grep -v "^done$") ]]'
check "resolve fallbacks: sync_main's resolution is noted with its files, model and minutes, and the verify going on" \
  'hlog rsm | grep -E "· M2: main merged in by a resolve session \(README.md; [a-z0-9.-]+, [0-9]+ min\); the verify goes on with main merged$" > /dev/null'
# the same, the session giving up: Michael's main_conflict, notified once; no merge lane re-bases onto that main again
STUB_MERGE_RESOLVE=give-up at_verify rsg
check "resolve fallbacks: a sync_main resolve that gives up is main_conflict with tried, notified once, and no re-base retries that main" \
  '[[ $(slog rsg | grep -c "^resolve M2 ") == 1 && $(posts "Title: [rsg] M2 needs you") == 1 ]] && ! hlog rsg | grep -F "re-based on" > /dev/null \
  && nj rsg ".[] | select(.key == \"main_conflict:M2\") | .card.tried" | grep -E "^a resolve session \([a-z0-9.-]+, [0-9]+ min\): UNRESOLVED: stub gives up$" > /dev/null \
  && hlog rsg | grep -F "· lane M2 closed (M2 needs Michael: main conflicts with its lane)" > /dev/null'

# units on a throwaway origin whose main and the checked-out branch `lane` both rewrite f
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
ur() {   # <dir>
  git init -q --bare -b main "$1/o.git"; git clone -q "$1/o.git" "$1/wt" 2> /dev/null; mkdir -p "$1/st"
  local g=(git -C "$1/wt"); echo base > "$1/wt/f"; "${g[@]}" add f; "${g[@]}" commit -qm base; "${g[@]}" push -q origin main
  "${g[@]}" checkout -q -b lane; echo lane > "$1/wt/f"; "${g[@]}" commit -qam lane
  "${g[@]}" checkout -q main; echo main > "$1/wt/f"; "${g[@]}" commit -qam main; "${g[@]}" push -q origin main; "${g[@]}" checkout -q lane
}
# resolve_ok with a merge in progress, after <bash> changed its inputs: yes, or why not
V=$T/v; ur "$V"; git -C "$V/wt" merge -q main > /dev/null 2>&1
ro() { ( cd "$V/wt" && HARNESS_HOME=$HH && source "$HH/lib/scope.sh" && source "$HH/lib/record.sh" && source "$HH/lib/resolve.sh"
  STATE=$V/st LANE=M1 CONFLICTS=resolve MAX_RESOLVES=2 RESOLVE_TIMEOUT=30m DEADLINE=$(( $(date +%s) + 86400 )); unset HARNESS_MERGE_ONLY
  eval "$1"; resolve_ok M1 && echo yes; rm -f "$STATE"/resolve* ) }
mh=$(git -C "$V/wt" rev-parse --short=7 MERGE_HEAD)
ro_all=$(ro ''; ro 'CONFLICTS=michael'; ro 'HARNESS_MERGE_ONLY=1'; ro 'LANE='; ro ': > "$STATE/resolve-M1-$(git rev-parse MERGE_HEAD)"'
  ro 'echo 2 > "$STATE/resolves-M1"'; ro 'DEADLINE=$(( $(date +%s) + 600 ))')
check "resolve fallbacks: resolve_ok says no for CONFLICTS=michael, harness merge, no lane, a marker for this main, MAX_RESOLVES used and the deadline" \
  '[[ $ro_all == "yes"$'"'"'\n'"'"'"CONFLICTS=michael"$'"'"'\n'"'"'"harness merge"$'"'"'\n'"'"'"not in a lane"$'"'"'\n'"'"'"a resolve session already ran for main $mh"$'"'"'\n'"'"'"its 2 resolve session(s) used"$'"'"'\n'"'"'"less than RESOLVE_TIMEOUT (30m) before the deadline" ]]'

# resolve alone, its session a function leaving a marker: aborted, the branch back where it was; the same main again
# runs no session and says what the first said (the card a later record replaces keeps it)
v_pre=$(git -C "$V/wt" rev-parse HEAD)
rv() { ( cd "$V/wt" && HARNESS_HOME=$HH && source "$HH/lib/scope.sh" && source "$HH/lib/record.sh" && source "$HH/lib/resolve.sh"
  STATE=$V/st SCRATCH=$V/sc LOGS=$V/sc LDIR=$V/sc REC=$V/sc USAGE=$V/sc/usage LIST=$V/sc/list.json RUN_DIR=.harness/runs/v RUN_ID=v LANE=M1 CONFLICTS=resolve MAX_RESOLVES=3 \
    RESOLVE_TIMEOUT=30m RESOLVE_MODEL=opus RESOLVE_MAX_TURNS=60 RESOLVE_BUDGET_USD=5 DEADLINE=$(( $(date +%s) + 86400 )) MAX_SESSIONS=50 MAX_LIMIT_HITS=6
  mkdir -p "$SCRATCH"; echo '{"features":[{"id":"A","milestone":"M1","description":"a"}]}' > "$LIST"; echo 0 > "$STATE/sessions"
  note() { echo "$*" >> "$V/notes"; }; log() { :; }; record() { "$@"; }; rec_commit() { :; }; journal() { :; }; materialize() { :; }; unmaterialize() { :; }
  weekly_over() { return 1; }; mem_gate() { return 0; }; prompt() { :; }; clock() { :; }; MET() { return 1; }; F() { echo opus; }
  session() { echo session >> "$V/sessions"; printf 'lane\nmain\n<<<<<<< HEAD\n' > f; git add f; S_WALL=130 S_EXIT=0 S_PEAK=""; }
  git merge -q main > /dev/null 2>&1; resolve M1 main; echo "rc=$? tried=$RESOLVE_TRIED" ) }
rv1=$(rv); rv1_head=$(git -C "$V/wt" rev-parse HEAD); rv1_mh=$(git -C "$V/wt" rev-parse -q --verify MERGE_HEAD); rv2=$(rv)
check "resolve fallbacks: resolve alone: a marker left aborts the merge, HEAD back at the lane's commit; this main again runs no session, same tried" \
  '[[ $rv1 == "rc=1 tried=a resolve session (opus, 3 min): conflict markers left in f" && $rv2 == "$rv1" && $rv1_head == "$v_pre" && -z $rv1_mh ]] \
  && [[ $(wc -l < "$V/sessions") == 1 && $(cat "$V/wt/f") == lane && -z $(git -C "$V/wt" status --porcelain) ]]'

# sync_main alone with resolve a stub (returning $SM_RC, saying $SM_TRIED): LANE empty (the record branch) or M1
W=$T/w; ur "$W"
sm() { rm -f "$W"/{notes,needs,resolve} "$W"/st/main-conflict-*; ( cd "$W/wt" && HARNESS_HOME=$HH && source "$HH/lib/record.sh"
  STATE=$W/st MAIN_BRANCH=main LANE=$1 CONFLICTS=resolve
  note() { echo "$*" >> "$W/notes"; }; log() { :; }; rec_commit() { :; }; sync_record() { :; }; needs_you() { :; }; needs_sweep() { :; }
  needs_open() { echo "$*" >> "$W/needs"; echo ref; }
  resolve() { echo "$*" >> "$W/resolve"; git merge --abort; RESOLVE_TRIED=${SM_TRIED:-} RESOLVE_END=""; return "$SM_RC"; }
  sync_main; echo "rc=$? mh=$(git rev-parse -q --verify MERGE_HEAD)" ) }
w_rec=$(SM_RC=0 sm ""); w_rec_r=$([[ -f $W/resolve ]] && echo called); w_rec_n=$(cat "$W/needs" 2> /dev/null)
check "resolve fallbacks: the record branch's sync_main keeps today's abort and main_conflict record" \
  '[[ $w_rec == "rc=1 mh=" && -z $w_rec_r && $w_rec_n == "main_conflict record files=f "* && $w_rec_n != *tried=* ]] \
  && grep -x "main conflicts with lane; carrying on without it (merges into main need Michael)" "$W/notes" > /dev/null'
w_def=$(SM_RC=2 sm M1); w_def_n=$([[ -f $W/needs || -n $(ls "$W"/st/main-conflict-* 2> /dev/null) ]] && echo some)
w_ur=$(SM_RC=1 SM_TRIED="a resolve session (opus, 2 min): UNRESOLVED: no" sm M1); w_ur_n=$(cat "$W/needs" 2> /dev/null)
check "resolve fallbacks: a lane's sync_main hands its conflict to resolve: refused is 2 with no record, unresolved the main_conflict record with tried" \
  '[[ $w_def == "rc=2 mh=" && -z $w_def_n && $w_ur == "rc=1 mh=" && $(cat "$W/resolve") == "M1 main" ]] \
  && [[ $w_ur_n == "main_conflict M1 files=f "*" tried=a resolve session (opus, 2 min): UNRESOLVED: no" ]]'

# slot_open alone (61-needs-git.sh's u_base): a dependency's tag that conflicts with main stays base_conflict
U=$T/u; mkdir -p "$U/st"; git init -q --bare -b main "$U/o.git"; git clone -q "$U/o.git" "$U/wt/run" 2> /dev/null
ug() { git -C "$U/wt/run" "$@"; }
echo base > "$U/wt/run/f"; ug add f; ug commit -qm base; ug push -q origin main
ug checkout -q -b m1; echo m1 > "$U/wt/run/f"; ug commit -qam m1; ug tag run/u/M1; ug checkout -q main; echo main2 > "$U/wt/run/f"; ug commit -qam main2; ug push -q origin main
ug checkout -q -b harness/u; mkdir -p "$U/wt/run/.harness/runs/u"
printf '{"features":[{"id":"A","milestone":"M1","passes":true},{"id":"B","milestone":"M2","after":["A"],"passes":false}]}\n' > "$U/wt/run/.harness/runs/u/feature_list.json"
printf 'status: run\n\n## Answers\n' > "$U/wt/run/.harness/runs/u/INBOX.md"
u_base=$( source "$HH/lib/record.sh"; HARNESS_HOME=$HH; source "$HH/lib/needs.sh"
  STATE=$U/st LS=$U/st LDIR="" RWT=$U/wt/run REC=$U/wt/run/.harness/runs/u RUN_DIR=.harness/runs/u RUN_ID=u PROJECT_NAME=proj MAIN_BRANCH=main RBRANCH=harness/u WT_ROOT_DIR=$U/wt PORT=7999
  LIST=$REC/feature_list.json CONFLICTS=resolve LANE=M2; F() { node "$HH/lib/features.mjs" "$@"; }; note() { echo "$*" >> "$U/notes"; }; log() { :; }
  resolve() { touch "$U/resolve-called"; git merge --abort; return 0; }
  slot_open M2; echo "rc=$?" )
check "resolve fallbacks: a slot_open base conflict keeps base_conflict and runs no resolve session" \
  '[[ $u_base == rc=1 && -f $U/st/needs-M2 && ! -e $U/resolve-called ]] && [[ $(jq -r .key "$U/st/needs/1.json") == base_conflict:M2 ]] \
  && grep -x "M2: its base conflicts (M1 vs main); needs Michael" "$U/notes" > /dev/null'

suite_end
