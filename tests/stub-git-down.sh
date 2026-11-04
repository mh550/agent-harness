#!/usr/bin/env bash
# Stand-in for `git` while GitHub is down, put first on PATH as `git` (a symlink to this file) for a run: while
# $STUB_DIR/origin-down exists (a count, or `until <epoch>`), `fetch`, `push` and `ls-remote` whose remote is origin
# fail as they did in run agent-harness-2026-11-04: push prints fixtures/git-push-rejected.txt on stderr (its ref and
# url substituted) and exits 1, fetch and ls-remote print nothing and exit 128. A count goes down per failure and the
# file goes at 0. STUB_GIT_DOWN_ONLY=<ERE>: only the calls whose arguments (after -C/-c) match it fail and count.
# STUB_GIT_UP=1 (stub-gh's own git: GitHub's side) and every other call exec the real git.
here=$(cd "$(dirname "$(readlink -f "$0")")" && pwd) self=$(cd "$(dirname "$0")" && pwd) real=""
for g in $(type -ap git); do [[ $(cd "$(dirname "$g")" && pwd) == "$self" ]] || { real=$g; break; }; done
[[ -n $real ]] || { echo "stub-git-down: no real git on PATH" >&2; exit 127; }
f=${STUB_DIR:-/nonexistent}/origin-down
[[ ${STUB_GIT_UP:-} || ! -f $f ]] && exec "$real" "$@"
a=("$@"); i=0
while [[ ${a[i]:-} == -C || ${a[i]:-} == -c ]]; do i=$(( i + 2 )); done
sub=${a[i]:-} rest=("${a[@]:i+1}") remote="" ref=""
case $sub in fetch|push|ls-remote) ;; *) exec "$real" "$@" ;; esac
for x in "${rest[@]}"; do [[ $x == -* ]] && continue; if [[ -z $remote ]]; then remote=$x; else ref=$x; fi; done
[[ $remote == origin ]] || exec "$real" "$@"
[[ -n ${STUB_GIT_DOWN_ONLY:-} ]] && ! [[ "${a[*]:i}" =~ $STUB_GIT_DOWN_ONLY ]] && exec "$real" "$@"
# one failure, counted under a lock (a lane and the coordinator push at once); an `until` past its epoch is over
down=$( exec 7>> "$f.lock"; flock 7; v=$(cat "$f" 2> /dev/null) || exit 1
  if [[ $v == until\ * ]]; then (( $(date +%s) < ${v#until } )) || { rm -f "$f"; exit 1; }
  elif (( v <= 1 )); then rm -f "$f"; else echo $(( v - 1 )) > "$f"; fi; echo 1 )
[[ $down == 1 ]] || exec "$real" "$@"
# STUB_GIT_HANG=<s>: the call hangs that long first, an origin that takes the connection and never answers
[[ ${STUB_GIT_HANG:-} ]] && sleep "$STUB_GIT_HANG"
if [[ $sub == push ]]; then
  ref=${ref#+} ref=${ref##*:} ref=${ref#refs/heads/} ref=${ref#refs/tags/}
  url=$("$real" "${a[@]:0:i}" remote get-url origin 2> /dev/null)
  while IFS= read -r l; do l=${l//<ref>/$ref}; printf '%s\n' "${l//<url>/$url}"; done < "$here/fixtures/git-push-rejected.txt" >&2
  exit 1
fi
exit 128
