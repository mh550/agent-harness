#!/usr/bin/env bash
# harness requests: the request inbox (<state>/requests/*.json, from n8n), each one under flock, oldest first: answer →
# harness answer, continue → queue add --continue and queue start (never 03:15–04:30); a result in done/<id>.json.   requests.sh
#
# The contract is docs/specs/2026-10-22-n8n-events.md §A3 (v1, fixed: n8n-home writes the requests and reads the
# results); docs/plans/2026-11-07-A3-request-inbox.md §2 is how. lib/requests.mjs parses and judges every file, so no
# JSON is parsed here, and a request's text and brief reach a command only as quoted argv elements, never through a shell.
# Writes only under requests/: done/ (results and claimed requests), rejected/, requests.log, .lock; never a run's record.
set -uo pipefail
: "${HARNESS_HOME:?harness requests runs from bin/harness}"
[[ -z ${HARNESS_XTRACE:-} ]] || source "$HARNESS_HOME/lib/xtrace.sh"   # the coverage trace, off unless set (lib/xtrace.sh)
STATE_ROOT=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}
R=$STATE_ROOT/requests H=$HARNESS_HOME/bin/harness MJS=$HARNESS_HOME/lib/requests.mjs
ID_RULE='^[A-Za-z0-9-]{8,64}$'

# The path unit's PATH has no nvm directory (lib/debrief.sh's lines): node for the CLIs, the rest for queue start's runner
missing() { local c m=(); for c in node jq flock tmux; do command -v "$c" > /dev/null 2>&1 || m+=("$c"); done; echo "${m[*]}"; }
if [[ -n $(missing) ]]; then
  # shellcheck source=/dev/null
  [[ -s ${NVM_DIR:-$HOME/.nvm}/nvm.sh ]] && { set +u; . "${NVM_DIR:-$HOME/.nvm}/nvm.sh" > /dev/null 2>&1; set -u; }
  PATH=$HOME/.local/bin:$PATH
  [[ -z $(missing) ]] || { echo "requests: cannot run, missing: $(missing) (PATH=$PATH)" >&2; exit 1; }
fi
export PATH

# requests/ is made mode 700 with its two directories; one that exists keeps its mode (*default*)
(umask 077; mkdir -p "$R/done" "$R/rejected") || { echo "requests: cannot make $R" >&2; exit 1; }
exec 9> "$R/.lock"
flock -w 60 9 || { echo "requests: $R/.lock held for 60 s" >&2; exit 1; }   # held for the whole call, its waits too
tmp=$(mktemp -d) || exit 1; trap 'rm -rf "$tmp"' EXIT

# state_of's rule as a list (bin/harness project_dir's with=): every <state>/<project>/<run>/meta.env, queue/ left out
runs=$(for m in "$STATE_ROOT"/*/*/meta.env; do d=${m%/meta.env}; [[ -f $m && ${d##*/} != queue ]] || continue; echo "${d##*/}"; done | paste -sd,)
ndone=0 nrej=0 nwait=0 seen=0 bad=0

free() { local d=$1 n=$2 i=1; [[ -e $d/$n || -L $d/$n ]] || { echo "$d/$n"; return; }   # <dir> <name> → a path no move overwrites
  while [[ -e $d/${n%.json}.$i.json || -L $d/${n%.json}.$i.json ]]; do i=$(( i + 1 )); done; echo "$d/${n%.json}.$i.json"; }
move() { mv -- "$1" "$2" || { echo "requests: could not move $1 to $2" >&2; bad=1; return 1; }; }

# <name|-> <verb|-> <run|-> <ok 0|1> <exit|-> <runner started 0|1> [<refused>]: the result (written to a temp name in
# done/ and renamed, so n8n's poll never reads half of one; never over an existing result) and the log line, echoed
result() {
  local n=$1 dest=/dev/null r=()
  [[ -n ${7:-} ]] && r=(--refused "$7")
  [[ $n != - && ! -e $R/done/$n.json ]] && dest=$R/done/.$n.json.tmp
  node "$MJS" result --id "$n" --verb "$2" --run "$3" --ok "$4" --exit "$5" --output "$tmp/out" --runner-started "$6" \
    ${r[@]+"${r[@]}"} --now "$now" --log "$R/requests.log" > "$dest" || { echo "requests: no result for $n" >&2; bad=1; return 1; }
  [[ $dest == /dev/null ]] || mv -f -- "$dest" "$R/done/$n.json" || { echo "requests: could not write done/$n.json" >&2; bad=1; }
  tail -n 1 "$R/requests.log"
}

# <file name>: one request, judged and run
one() {
  local f=$1 p=$R/$1 k v verdict="" name=- id=- verb=- run=- window=0 reason="" text brief out rc started=0 refused="" args
  rm -f "$tmp/text" "$tmp/brief"; : > "$tmp/out"
  if [[ -L $p || ! -f $p ]]; then   # never read: mv moves the link, never its target (*default*: n8n writes plain files)
    [[ ${f%.json} =~ $ID_RULE ]] && name=${f%.json}
    move "$p" "$(free "$R/rejected" "$f")" && { nrej=$(( nrej + 1 )); result "$name" - - 0 - 0 "the request is not a regular file"; }
    return
  fi
  while read -r k v; do case $k in verdict) verdict=$v ;; name) name=$v ;; id) id=$v ;; verb) verb=$v ;; run) run=$v ;;
    window) window=$v ;; reason) reason=$v ;; esac; done < <(node "$MJS" validate "$p" --runs "$runs" --done "$R/done" --now "$now" --out "$tmp")
  [[ $name == - || $name =~ $ID_RULE ]] || name=-   # a name only ever becomes a path under done/ when it passes the id rule
  case $verdict in
    wait) nwait=$(( nwait + 1 )); waited=1 ;;
    rejected|duplicate) move "$p" "$(free "$R/rejected" "$f")" && { nrej=$(( nrej + 1 )); result "$name" "$verb" "$run" 0 - 0 "$reason"; } ;;
    ok)
      [[ $name != - ]] || { echo "requests: $f: no name" >&2; bad=1; return; }
      move "$p" "$R/done/$name.request.json" || return   # the claim: a pass that dies after it never runs the request again
      if [[ $verb == answer ]]; then
        text=$(cat -- "$tmp/text"; printf x); text=${text%x}   # $(…) would drop trailing newlines; NULs are refused
        out=$("$H" answer "$run" "$text" 2>&1); rc=$?
      else
        args=(queue add --continue "$run")
        [[ -e $tmp/brief ]] && { brief=$(cat -- "$tmp/brief"; printf x); args+=(--brief "${brief%x}"); }
        out=$("$H" "${args[@]}" 2>&1); rc=$?
        if (( rc == 0 )); then
          if [[ $window == 1 ]]; then refused=$(M=$MJS node -e 'import(process.env.M).then(m => console.log(m.BACKUP_REFUSAL))')   # the entry stays queued; the backup's window starts no runner
          else local so; so=$("$H" queue start 2>&1); rc=$?; out+=$'\n'$so
            [[ $so == *"queue runner started (tmux h-queue)"* ]] && started=1; fi
        fi
      fi
      printf '%s' "$out" > "$tmp/out"; ndone=$(( ndone + 1 ))
      result "$name" "$verb" "$run" "$(( rc == 0 ))" "$rc" "$started" "$refused" ;;
    *) echo "requests: $f: no verdict from lib/requests.mjs (left for the next call)" >&2; nwait=$(( nwait + 1 )); bad=1 ;;
  esac
}

# A pass over every pending *.json, oldest mtime first, then the name. On the fake clock (HARNESS_NOW, the suite) a
# call is one pass; on the real clock a pass that left a young file runs again a second later, at most 11 in all, so
# one call outlives the 10 s grace and the path unit isn't restarted in a loop (plan §2.4).
for (( pass = 1; pass <= 11; pass++ )); do
  now=${HARNESS_NOW:-$(date +%s)} waited=0 nwait=0
  while IFS= read -r -d '' e; do seen=1; one "${e#* }" < /dev/null; done < <(find "$R" -maxdepth 1 -name '*.json' \( -type f -o -type l \) -printf '%T@ %f\0' | LC_ALL=C sort -z -k1,1n -k2,2)
  [[ -z ${HARNESS_NOW:-} ]] && (( waited )) || break
  sleep 1   # sleep-ok: a young file's grace on the real clock
done
if (( seen )); then echo "requests: $ndone done, $nrej rejected, $nwait waiting"; else echo "requests: none pending ($R)"; fi
exit $(( bad ))
