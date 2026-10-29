#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- project names (U3-02): one resolver, project_dir, takes a path or a bare name: a git repository here, the ----
# ---- PROJECT_DIR of that name's newest run, then $HARNESS_PROJECTS/<name>; else an error naming the three places ----
mkdir -p "$T/away" && cd "$T/away"   # outside proj: a bare name is no repository here (from $T, proj is the path ./proj)
mkdir -p "$T/projects" && git init -q -b main "$T/projects/proj2" && git -C "$T/projects/proj2" commit -q --allow-empty -m init
mkdir -p "$T/projects/plain"   # a directory, not a repository
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 HARNESS_PROJECTS=$T "$H" start proj pn1 --spec SPEC.md --foreground > "$T/pn1.out" 2>&1
export HARNESS_PROJECTS=$T/projects   # from here on proj resolves through its run alone
check "project names: start proj from outside it (HARNESS_PROJECTS holding proj) runs in that repository" '
  grep -q "^PROJECT_DIR=$T/proj\$" "$HARNESS_STATE/proj/pn1/meta.env" && grep " run pn1 on harness/pn1 in $T/wt/proj/pn1 " "$HARNESS_STATE/proj/pn1/run.log" > /dev/null'
check "project names: gc proj --dry-run from outside resolves through the run's PROJECT_DIR (as gc <path> does)" '
  a=$("$H" gc proj --dry-run 2>&1) && b=$("$H" gc "$T/proj" --dry-run 2>&1) && [[ $a == "$b" ]] && [[ $a != *"no project"* ]]'
check "project names: a path that is a git repository still resolves to its top level (gc proj/<subdir>, gc .)" '
  mkdir -p "$T/proj/sub" && a=$("$H" gc "$T/proj/sub" --dry-run 2>&1) && b=$(cd "$T/proj" && "$H" gc . --dry-run 2>&1) &&
  c=$("$H" gc "$T/proj" --dry-run 2>&1) && [[ $a == "$c" && $b == "$c" ]]'
check "project names: status --project proj, -p proj and --project <path> list proj's run; a gone project falls back to its name" '
  j() { "$H" status --all --json "$@" | jq -r "[.running[], .finished[] | .run] | join(\" \")"; }
  [[ $(j --project proj) == pn1 && $(j -p proj) == pn1 && $(j --project "$T/proj") == pn1 && $(cd "$T/proj/sub" && j -p .) == pn1 ]] &&
  [[ -z $(j -p gone) ]]'
check "project names: queue add proj2 with no run of it resolves to \$HARNESS_PROJECTS/proj2 and stores the absolute path" '
  o=$("$H" queue add proj2 --brief x) && f=$(ls "$HARNESS_STATE"/queue/*-start-proj2.args) &&
  [[ $(sed -n 2p "$f") == "$T/projects/proj2" ]] && [[ $o == "queued: ${f##*/}" ]]'
check "project names: a run's PROJECT_DIR comes before \$HARNESS_PROJECTS (a proj there too is not taken)" '
  git init -q -b main "$T/projects/proj" && rm -f "$HARNESS_STATE"/queue/*.args && "$H" queue add proj --brief y > /dev/null &&
  [[ $(sed -n 2p "$HARNESS_STATE"/queue/*-start-proj.args) == "$T/proj" ]]; r=$?; rm -rf "$T/projects/proj"; (( r == 0 ))'
check "project names: gc nope exits 1; its stderr names the repository here, the runs, \$HARNESS_PROJECTS/nope and the projects with runs" '
  "$H" gc nope > "$T/nope.out" 2> "$T/nope.err"; (( $? == 1 )) && [[ ! -s $T/nope.out ]] &&
  [[ $(cat "$T/nope.err") == "harness: no project '"'"'nope'"'"': not a git repository here, no run of a project named nope, no $T/projects/nope (projects with runs: proj)" ]]'
check "project names: a directory that is not a repository (by name or by path) is no project" '
  "$H" gc plain 2> "$T/plain.err"; a=$?; "$H" gc "$T/projects/plain" 2> "$T/plain2.err"; b=$?
  (( a == 1 && b == 1 )) && grep "^harness: no project .plain.: .*(projects with runs: proj)\$" "$T/plain.err" > /dev/null &&
  [[ $(cat "$T/plain2.err") == "harness: no project '"'"'$T/projects/plain'"'"': not a git repository" ]] &&
  "$H" status -p "$T/projects/plain" > /dev/null 2> "$T/plain3.err"; (( $? == 1 )) && diff "$T/plain2.err" "$T/plain3.err"'
check "project names: memlint and init take a bare name too" '
  "$H" memlint proj > /dev/null 2>&1; m=$?; "$H" memlint nope 2> "$T/ml.err"; n=$?
  (( m == 0 && n == 1 )) && grep "^harness: no project .nope.: " "$T/ml.err" > /dev/null &&
  "$H" init proj2 > "$T/init.out" 2>&1 && [[ -f $T/projects/proj2/.harness/config.sh && -f $T/projects/proj2/CLAUDE.md ]]'
check "project names: with no project at all the list says none, and the projects directory shows ~ for the home directory" '
  e=$(HARNESS_STATE=$T/empty-state HARNESS_PROJECTS=$HOME/nonexistent-h "$H" gc nope 2>&1 >/dev/null)
  [[ $e == "harness: no project '"'"'nope'"'"': not a git repository here, no run of a project named nope, no ~/nonexistent-h/nope (projects with runs: none)" ]]'
check "project names: the newest run whose PROJECT_DIR is no repository any more is passed over for an older one" '
  mkdir -p "$HARNESS_STATE/proj/zz" && printf "PROJECT_DIR=%q\n" "$T/gone" > "$HARNESS_STATE/proj/zz/meta.env" &&
  touch -d "+1 minute" "$HARNESS_STATE/proj/zz/meta.env" && a=$("$H" gc proj --dry-run 2>&1) && [[ $a == "$("$H" gc "$T/proj" --dry-run 2>&1)" ]] &&
  rm -f "$HARNESS_STATE"/queue/*.args && "$H" queue add proj --brief z > /dev/null && [[ $(sed -n 2p "$HARNESS_STATE"/queue/*-start-proj.args) == "$T/proj" ]]'
suite_end
