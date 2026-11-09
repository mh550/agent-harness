#!/usr/bin/env bash
# Usage: source lib/record.sh; run_paths   (by lib/driver.sh, the coordinator, and lib/lane.sh, one per open milestone)
# The run record and everything both processes share (lanes P1-03, P1-04). The record (.harness/runs/<run>/) lives only
# on harness/<run>, in the record worktree RWT; code lives on lane branches harness-lane/<run>/<m>, worked in slot
# worktrees. Every write to the record goes through `record` (one flock on $STATE/record.lock, so two writers never lose
# each other's lines); sessions, inits and suites never run under it. A session sees the record as a copy materialized
# into its slot, excluded from git there, and taken back after it.
# Plan: docs/plans/2026-10-26-P1-lanes-serial.md §2, §5, §6. Needs WT (the record worktree, the cwd) RUN_ID STATE
# PROJECT_DIR HARNESS_HOME, and config.sh, prompt.sh, scope.sh and notify.sh sourced.
INBOX_MJS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/inbox.mjs   # INBOX.md's one parser (U2-02)

# The spec's helper: the lock is held while "$@" runs and released when fd 9 closes. HARNESS_RECORD_DELAY=<s> (tests
# only, unset everywhere else) holds it that long first, so a check can make two writers meet.
_record() { flock 9; [[ -n ${HARNESS_RECORD_DELAY:-} ]] && sleep "$HARNESS_RECORD_DELAY"; "$@"; } 9> "$STATE/record.lock"
# A wrapped function may call another (note inside a commit): the inner call runs under the lock it already holds,
# never a second flock on a new descriptor, which would wait on itself.
record() { (( ${REC_HELD:-0} )) && { "$@"; return; }; REC_HELD=1; _record "$@"; local rc=$?; REC_HELD=0; return $rc; }

# <m>: its lane process is alive ($STATE/lanes/<m>/pid, written by the coordinator: the lane's own $$)
lane_alive() { local p; p=$(cat "$STATE/lanes/$1/pid" 2> /dev/null) && [[ -n $p ]] && kill -0 "$p" 2> /dev/null; }
commit_all() { git add -A && ! git diff --cached --quiet && git commit -q -m "$1"; return 0; }
# the run record only: a suite or an init run in the record worktree may leave files there that are no record's
rec_commit_() { ( cd "$RWT" && git add -A -- "$RUN_DIR" && ! git diff --cached --quiet -- "$RUN_DIR" && git commit -q -m "$1" -- "$RUN_DIR" ); return 0; }
rec_commit() { record rec_commit_ "$1"; }   # <message>: a commit of the record

# <file> [<delta>] → the run counter in <file> (sessions: coding sessions started, limits: refused in a row) plus delta,
# printed from inside the lock: two lanes never get one number
rec_count_() { local n; n=$(cat "$1" 2> /dev/null || echo 0); n=$(( n + ${2:-0} )); echo "$n" > "$1"; echo "$n"; }
rec_count() { record rec_count_ "$1" "${2:-0}"; }


# The run's paths and configuration, read in the record worktree (cwd). A lane then moves to its slot (lane_paths).
run_paths() {
  prompt_vars   # PROJECT_NAME BRANCH RUN_DIR SCRATCH CHECK PORT
  # the record worktree and branch, the record itself (absolute), the slots' parent; a lane's slot and branch come later
  RWT=$WT RBRANCH=$BRANCH REC=$WT/$RUN_DIR WT_ROOT_DIR=${WT%/*} SLOT="" LBRANCH="" LANE="" LANEU="" LDIR=""
  CLAUDE=${HARNESS_CLAUDE:-claude} GH=${HARNESS_GH:-gh}
  LIST=$REC/feature_list.json SLIST=$REC/feature_list.json
  LOGS=$STATE/logs ATT=$STATE/attempts.json PARKED=$STATE/parked.json LS=$STATE
  STATE_ROOT=$(cd "$STATE/../.." && pwd); LIMIT_FILE=$STATE_ROOT/LIMIT_UNTIL USAGE=$STATE_ROOT/USAGE_7D USAGE5=$STATE_ROOT/USAGE_5H
  LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger} SVC_UNIT=$(scope_unit "$RUN_ID" svc)
  mkdir -p "$LOGS" "$REC" "$SCRATCH"
  load_config
  helper_begin   # after the config (HARNESS_HELPER=0 there counts), before the first $( ask ), which can't start one
  f_models   # F model's memo for this process: one node start answers every alias
}
# ask <script> <args…>: what `node lib/<script> <args…>` prints and exits, from this shell's resident helper when it can
# answer, else by that spawn, so a helper absent, busy, off or broken costs a node start and never an answer or a hang
# (decisions/2026-11-03-resident-helper). HARNESS_HELPER=0 turns it off.
HELPER_SHELL=$BASHPID HELPER_LIVE="" HELPER_ERR="" HELPER_ENV_RAW="" HELPER_ENV="{}"
ask() {
  if helper_ask "$@"; then printf %s "$ASK_OUT"; return "$ASK_RC"; fi
  local ask_s=$1; shift
  node "$HARNESS_HOME/lib/$ask_s" "$@"
}
# → ASK_OUT, ASK_RC; 1: the caller spawns. A TTY on stdout is the view's question (main in the helper sees none). The
# lock is held from before the request to after the reply: a job of this shell asking at that moment spawns, so two
# requests never meet on the pipe; flock -n never waits.
helper_ask() {
  [[ ${HARNESS_HELPER:-} != 0 && -d ${HARNESS_SCRATCH:-/nonexistent} && ! -t 1 ]] || return 1
  helper_ready || return 1
  local ha_lk ha_rc=1
  { exec {ha_lk}> "$HARNESS_SCRATCH/helper-$HELPER_SHELL.lock"; } 2> /dev/null || return 1
  if flock -n "$ha_lk"; then helper_request "$@"; ha_rc=$?; helper_stderr "$ha_rc"; fi
  exec {ha_lk}>&-
  return "$ha_rc"
}
# 0: this shell holds the pipes of a helper. Bash keeps them only in $( ) and < <( ) (5.2's manual, and checked by file
# 91): a ( ), a pipeline's side or a job has the numbers and no pipes, and spawns. Only the shell that sourced this file
# starts one or replaces one: a coproc started in a subshell would die with it. A helper that went between two calls
# costs this call a spawn; the next one starts its successor.
helper_ready() {
  [[ -n ${HELPER[1]:-} && -p /proc/self/fd/${HELPER[1]:-} ]] && return 0
  [[ $BASHPID == "$HELPER_SHELL" ]] || return 1
  [[ -z $HELPER_LIVE ]] || { helper_failed "the helper went away"; return 1; }
  helper_start
}
# The helper's stderr is a file, so a request's (a git it runs included) can go where that call sends its own (helper_stderr).
# It keeps no other descriptor: one started under `record` would hold the record lock (fd 9) for its whole life.
# `set +x` first: the trace's descriptor (HARNESS_XTRACE, lib/xtrace.sh) closes with the rest, and bash would print the
# loop's remaining lines on stderr instead.
helper_start() {
  HELPER_ERR=$HARNESS_SCRATCH/helper-$HELPER_SHELL.err
  coproc HELPER { set +x; local f; for f in /proc/self/fd/*; do f=${f##*/}; (( f > 2 )) && eval "exec $f>&-"; done; exec node "$HARNESS_HOME/lib/helper.mjs" 2>> "$HELPER_ERR"; }
  HELPER_LIVE=$HELPER_PID
}
# The driver's and a lane's: their helper from the start, where $( ) can use it
helper_begin() { [[ ${HARNESS_HELPER:-} != 0 && -d ${HARNESS_SCRATCH:-/nonexistent} && $BASHPID == "$HELPER_SHELL" && -z $HELPER_LIVE ]] && helper_start; return 0; }
helper_stop() { [[ -n ${HELPER_PID:-} ]] && kill "$HELPER_PID" 2> /dev/null; return 0; }   # an EXIT trap's: stdin's EOF would end it anyway
# <the exchange's status>: what the request wrote to stderr, to this call's stderr, as a spawn's would be: before ask
# prints the answer, which a spawn's main writes at its end (2>&1 keeps the order). Declined: dropped, the spawn says it again.
helper_stderr() {
  [[ -s ${HELPER_ERR:-} ]] || return 0
  (( $1 )) || cat "$HELPER_ERR" >&2
  : > "$HELPER_ERR"
}
# <s>: HELPER_J is it as a JSON string. Bytes over 127 go as they are: node decodes them as it decodes an argv.
helper_j() {
  HELPER_J=$1
  if [[ $HELPER_J == *[\\\"[:cntrl:]]* ]]; then
    local hj_i hj_h hj_c
    HELPER_J=${HELPER_J//\\/"\\\\"}; HELPER_J=${HELPER_J//\"/"\\\""}
    for (( hj_i = 1; hj_i < 32; hj_i++ )); do
      printf -v hj_h %02x "$hj_i"; printf -v hj_c "\\x$hj_h"
      [[ $HELPER_J == *"$hj_c"* ]] && HELPER_J=${HELPER_J//"$hj_c"/"\\u00$hj_h"}
    done
  fi
  HELPER_J=\"$HELPER_J\"
}
# HELPER_ENV: this call's exported environment as a JSON object, so a spawn and the helper see one, X=1 ask … included.
# Encoding is the slow part: the last one is kept while its names and values are the same. `_` differs per command. The
# names go through a file (no fork; only names, under the lock); 1: none could be read, and an empty env would be wrong.
helper_env() {
  local he_n he_raw="" he_j="" he_f=$HARNESS_SCRATCH/helper-$HELPER_SHELL.names; local -a he_names=()
  { compgen -e > "$he_f" && mapfile -t he_names < "$he_f"; } 2> /dev/null
  (( ${#he_names[@]} )) || return 1
  for he_n in "${he_names[@]}"; do [[ $he_n == _ ]] || he_raw+=$he_n=${!he_n-}$'\x1e'; done
  [[ $he_raw == "$HELPER_ENV_RAW" ]] && return 0
  for he_n in "${he_names[@]}"; do [[ $he_n == _ ]] || { helper_j "${!he_n-}"; he_j+=,\"$he_n\":$HELPER_J; }; done
  HELPER_ENV_RAW=$he_raw HELPER_ENV={${he_j#,}}
}
helper_request() {
  local hr_id=$SRANDOM hr_args="" hr_a hr_req   # random, not a counter: a $( )'s count dies with it, and a killed asker leaves its reply in the pipe
  helper_env || return 1
  helper_j "$1"; hr_req='{"id":'$hr_id',"script":'$HELPER_J; shift
  for hr_a; do helper_j "$hr_a"; hr_args+=,$HELPER_J; done
  helper_j "$PWD"; hr_req+=',"args":['${hr_args#,}'],"cwd":'$HELPER_J',"env":'$HELPER_ENV'}'
  helper_exchange "$hr_id" "$hr_req"
}
# <id> <request>: bytes from here on (read -N, the length). A request that fits the pipe's buffer can't block on a
# helper that stopped reading, the one write here with no timeout; a write to a dead one is an error, not this shell's
# SIGPIPE (no file here traps PIPE, and `trap -` restores what it was). A failed read or a reply that doesn't parse ends
# the helper: what's left in its pipe can't be trusted. rc 64 declines, with the helper still good.
helper_exchange() {
  local LC_ALL=C hx_t=${HARNESS_HELPER_TIMEOUT:-120} hx_w=${HELPER[1]:-} hx_r=${HELPER[0]:-} hx_h hx_rc hx_n hx_e
  (( ${#2} < 60000 )) || return 1
  trap '' PIPE
  { printf '%s\n' "$2" >&"$hx_w"; } 2> /dev/null; hx_e=$?
  trap - PIPE
  (( hx_e == 0 )) || { helper_failed "the helper went away"; return 1; }
  { IFS= read -r -t "$hx_t" -u "$hx_r" hx_h; } 2> /dev/null; hx_e=$?
  (( hx_e > 128 )) && { helper_failed "no reply in $hx_t s"; return 1; }
  (( hx_e == 0 )) || { helper_failed "the helper went away"; return 1; }
  [[ $hx_h =~ ^([0-9]+)\ ([0-9]{1,3})\ ([0-9]+)$ ]] && (( 10#${BASH_REMATCH[2]} <= 255 )) || { helper_failed "bad header: ${hx_h:0:60}"; return 1; }
  hx_rc=${BASH_REMATCH[2]} hx_n=${BASH_REMATCH[3]}
  [[ ${BASH_REMATCH[1]} == "$1" ]] || { helper_failed "wrong id: ${BASH_REMATCH[1]} for $1"; return 1; }
  ASK_OUT=""
  if [[ $hx_n != 0 ]]; then
    { IFS= read -r -N "$hx_n" -t "$hx_t" -u "$hx_r" ASK_OUT; } 2> /dev/null; hx_e=$?
    (( hx_e > 128 )) && { helper_failed "no reply in $hx_t s (the answer's $hx_n bytes)"; return 1; }
    [[ ${#ASK_OUT} == "$hx_n" ]] || { helper_failed "short answer: ${#ASK_OUT} of $hx_n bytes"; return 1; }
  fi
  ASK_RC=$(( 10#$hx_rc ))
  (( ASK_RC != 64 ))
}
# <why>: this helper is done: it goes, and one run.log line says so however many shells see it die. The tally is a file
# (a $( ) that met the failure can't tell its parent), one line per helper; a helper's fourth failure is `helper off`.
helper_failed() {
  local hf_k=${HELPER_PID:-} hf_p=${HELPER_PID:-$HELPER_LIVE} hf_f=$HARNESS_SCRATCH/helper-$HELPER_SHELL.restarts hf_n=0 hf_l hf_seen="" hf_word=restarted
  # only a pid bash still holds: HELPER_LIVE's may be another process's by now. A plain kill in a subshell, so its parent,
  # who reaps, prints no "Killed" (node has no TERM handler: it dies even in a loop); the owner can wait, and -9 is sure
  if [[ -n $hf_k ]]; then
    if [[ $BASHPID == "$HELPER_SHELL" ]]; then { kill -9 "$hf_k" && wait "$hf_k"; } 2> /dev/null; else kill "$hf_k" 2> /dev/null; fi
  fi
  [[ -s ${HELPER_ERR:-} ]] && { cat "$HELPER_ERR" >&2; : > "$HELPER_ERR"; }   # its last words: no answer will say them
  [[ -f $hf_f ]] && while read -r hf_l _; do (( hf_n += 1 )); [[ $hf_l == "$hf_p" ]] && hf_seen=1; done < "$hf_f"
  if [[ -z $hf_seen ]]; then
    (( hf_n >= 3 )) && hf_word=off
    (( hf_n += 1 ))
    { echo "$hf_p $1" >> "$hf_f"; printf '%(%F %T)T helper %s: %s\n' -1 "$hf_word" "$1" >> "${STATE:-/nonexistent}/run.log"; } 2> /dev/null
  fi
  [[ $BASHPID == "$HELPER_SHELL" ]] || return 0
  HELPER_LIVE=""
  (( hf_n > 3 )) && HARNESS_HELPER=0
  return 0
}
# F's memo (decisions/2026-10-31-fewer-node-starts): a pure subcommand's answer (stdout byte for byte and the exit code)
# is kept in this process, keyed on the subcommand, the sha1 of each file it reads and its other arguments: never an
# mtime, a path or the clock, and never on disk. A subshell reads its parent's entries, but one it stores dies with it:
# Fv answers into a variable in the current shell. Writers, F lanes (it reads the state dir) and an unpark that
# unparked (it rewrote parked.json) call node every time.
declare -gA F_MEMO=() F_MRC=()
F_MODELS=0 F_MEMO_PID=$BASHPID   # the shell that keeps entries: a subshell's miss runs node straight (it couldn't keep one)
F() {
  f_memo "$@" || { ask features.mjs "$@"; return; }
  printf %s "$F_OUT"; return "$F_RC"
}
Fv() {   # <var> <sub> <args…>: F's answer into <var> (trailing newlines cut, as $( ) does), stored in this shell
  local f_var_=$1; shift
  if f_memo "$@"; then F_OUT=${F_OUT%"${F_OUT##*[!$'\n']}"}; else F_OUT=$(ask features.mjs "$@"); F_RC=$?; fi
  printf -v "$f_var_" %s "$F_OUT"; return "$F_RC"
}
f_sha() { local _h; _h=$(sha1sum 2> /dev/null < "$2") || _h=-; printf -v "$1" %s "${_h%% *}"; }   # <var> <file>; "-": none
# <sub> <args…> → F_KEY; 1: not memoized. The argument positions that are files the subcommand reads go in as their
# content's sha1 (next and blocked read attempts.json and parked.json too, parked the list, evidence progress.md)
f_key() {
  local files i=0 a h
  case ${1:-} in
    model) files=" " ;;
    summary|milestones|snapshot|undeclared|lint|passes|milestone-done|ids|deps|kind|milestone|unpark|unparks) files=" 1 " ;;
    next|blocked|poll) files=" 1 2 4 " ;;
    parked) files=" 1 2 " ;;
    evidence) files=" 1 3 " ;;
    *) return 1 ;;
  esac
  F_KEY=$1; shift
  for a; do (( ++i )); if [[ $files == *" $i "* ]]; then f_sha h "$a"; F_KEY+=$'\x1f'"#$h"; else F_KEY+=$'\x1f'$a; fi; done
}
# <sub> <args…> → F_OUT and F_RC, from the memo or one node start; 1: not memoized, or a miss in a subshell (the
# caller runs node). An answer is kept when its exit code is one (0, or 1 where 1 is the answer; a throw exits 70) and
# its files still hash as before the start
f_memo() {
  local k s=${1:-}
  if [[ $s == model && ${2:-} == claude-* ]]; then F_OUT=$2$'\n' F_RC=0; return 0; fi   # modelId: such an id as is
  f_key "$@" || return 1; k=$F_KEY
  [[ $s == model && -z ${F_MEMO[$k]+x} ]] && (( ! F_MODELS )) && f_models
  if [[ ${F_MEMO[$k]+x} ]]; then F_OUT=${F_MEMO[$k]} F_RC=${F_MRC[$k]}; return 0; fi
  [[ $BASHPID == "$F_MEMO_PID" ]] || return 1
  F_OUT=$(ask features.mjs "$@"; r=$?; printf x; exit "$r"); F_RC=$?; F_OUT=${F_OUT%x}
  case $F_RC:$s in
    0:unpark) [[ -z $F_OUT ]] || return 0 ;;
    0:*|1:passes|1:milestone-done|1:evidence|1:lint) ;;
    *) return 0 ;;
  esac
  f_key "$@" && [[ $F_KEY == "$k" ]] && F_MEMO[$k]=$F_OUT F_MRC[$k]=$F_RC && [[ $s == poll ]] && f_poll_seed "$k" "$#"
  return 0
}
# <poll's key> <its argument count, poll included>: poll's labelled lines (F_OUT) as the memo entries of the five subcommands it
# answers, under the keys f_key gives them: next and blocked take poll's arguments, summary the list's hash, parked
# parked.json's and the list's, milestone-done (with a lane) the list's and the lane
f_poll_seed() {
  local -a kp; local l lab rest k
  local -A out=([summary]="" [parked]="" [blocked]="" [next]="")
  (( $2 >= 5 )) || return 0   # parked.json's hash is the fourth argument: a shorter poll seeds nothing
  IFS=$'\x1f' read -ra kp <<< "${1}"$'\x1f'
  while IFS= read -r l; do
    [[ $l == *$'\t'* ]] || continue; lab=${l%%$'\t'*} rest=${l#*$'\t'}
    case $lab in
      summary|parked|blocked|next) out[$lab]+=$rest$'\n' ;;
      milestone-done) (( $2 > 5 )) && k=milestone-done$'\x1f'${kp[1]}$'\x1f'${kp[5]} && F_MEMO[$k]="" F_MRC[$k]=$rest ;;
    esac
  done <<< "$F_OUT"
  for lab in next blocked; do k=$lab${1#poll}; F_MEMO[$k]=${out[$lab]} F_MRC[$k]=0; done
  k=summary$'\x1f'${kp[1]}; F_MEMO[$k]=${out[summary]} F_MRC[$k]=0
  k=parked$'\x1f'${kp[4]}$'\x1f'${kp[1]}; F_MEMO[$k]=${out[parked]} F_MRC[$k]=0
}
# F model's memo, every alias from one node start (features.mjs models), once per shell: run_paths fills it, so every
# later $(F model …) of the driver or a lane is a hit
f_models() {
  local a id out; F_MODELS=1
  out=$(ask features.mjs models) || return 0
  while IFS=$'\t' read -r a id; do [[ -n $a ]] && F_MEMO[model$'\x1f'$a]=$id$'\n' F_MRC[model$'\x1f'$a]=0; done <<< "$out"
}
# The coordinator's F lanes (lanes_v): memoized as F is, on the list's, attempts.json's and parked.json's hashes, the max,
# the state dir and a fingerprint of all laneState reads there, for "default" and each milestone: verified-<m>,
# needs-<m>, a non-empty lanes/<m>/review-escalate, lanes/<m>/pid and whether /proc has that process (node's kill 0, to
# which EPERM is alive); then meta.env's lines. Any change to them is a new key. A pid file that isn't one number is no
# key (node reads it with Number()): node every time then.
lanes_key() {   # <var> <list> <attempts> <max> <parked.json> <state dir>; 1: no key
  local lk_=$1 m ms hl ha hp fp=""; local -a mm pl me; shift
  [[ -d /proc/self ]] || return 1
  Fv ms milestones "$1" || return 1; mapfile -t mm <<< "$ms"
  for m in default "${mm[@]}"; do
    [[ -n $m ]] || continue
    pl=(); [[ -f $5/lanes/$m/pid ]] && mapfile -t pl < "$5/lanes/$m/pid"
    (( ${#pl[@]} <= 1 )) && [[ ${pl[0]:-0} =~ ^(0|[1-9][0-9]*)$ ]] || return 1
    fp+=$'\x1e'$m:${pl[0]:-}:; [[ ${pl[0]:-0} != 0 && -e /proc/${pl[0]} ]] && fp+=a
    [[ -e $5/verified-$m ]] && fp+=v; [[ -e $5/needs-$m ]] && fp+=n; [[ -s $5/lanes/$m/review-escalate ]] && fp+=e
  done
  [[ -f $5/meta.env ]] && mapfile -t me < "$5/meta.env"
  f_sha hl "$1"; f_sha ha "$2"; f_sha hp "$4"
  printf -v "$lk_" '%s' "lanes"$'\x1f'"#$hl"$'\x1f'"#$ha"$'\x1f'"$3"$'\x1f'"#$hp"$'\x1f'"$5"$'\x1f'"${me[*]}$fp"
}
lanes_v() {   # <var> <list> <attempts> <max> <parked.json> <state dir>: F lanes' lines (trailing newline cut), from the memo
  local lv_=$1 k="" k2="" lo lr; shift
  if lanes_key k "$@" && [[ ${F_MEMO[$k]+x} ]]; then printf -v "$lv_" %s "${F_MEMO[$k]}"; return 0; fi
  lo=$(ask features.mjs lanes "$@"); lr=$?   # its own variable: lanes_key's Fv sets F_OUT
  (( lr == 0 )) && [[ -n $k && $BASHPID == "$F_MEMO_PID" ]] && lanes_key k2 "$@" && [[ $k2 == "$k" ]] && F_MEMO[$k]=$lo F_MRC[$k]=0
  printf -v "$lv_" %s "$lo"; return "$lr"
}
MET() { ask metrics.mjs "$@"; }
SUM() { ask summary.mjs "$@"; }
# The configuration comes from the worktree, so it is loaded again after a resumed run merges main (which may have
# changed .harness/config.sh, e.g. a new POLICY).
load_config() {
  harness_config "$WT" "$STATE"
  prompt_env   # the exports every session and template sees (lib/prompt.sh)
}

log() { echo "$(date '+%F %T') $*" | tee -a "$STATE/run.log"; }
note_() { echo "- $(date '+%F %H:%M') · $*" >> "$REC/harness-log.md"; }
note() { log "$*"; record note_ "$*"; }   # phone-readable, committed with the record
# <why>: the project's teardown, then the services scope, then one note (decisions/2026-10-25-teardown-hook). Only after
# an init started something (SVC_UP): finish's call and the EXIT trap's after it give one note, and a segment that never
# ran an init is silent. SVC_UP clears after the stop, so a TERM during a teardown still stops the scope; the hook runs
# in the background (SVC_TD) so the trap, which bash runs at once, waits for it instead of starting a second. A TERM
# during an init (SVC_INIT) stops the init first, or it would start what the hook just stopped (L2-06 review).
# SVC_UNIT is the run's harness-<run>-svc, a lane's harness-<run>-<m>-svc; a lane's services leave LDIR/svc-up behind
# while they run, so the coordinator stops them at finish when the lane closed with them up (lane_services_down).
services_down() {
  (( ${SVC_UP:-0} )) || return 0
  local rc=0 unit=$SVC_UNIT cmd=${TEARDOWN_CMD:-} dir=${SVC_DIR:-$PWD}
  [[ -n $cmd || ! -x $dir/.harness/teardown.sh ]] || cmd=.harness/teardown.sh   # looked up now: a hook added mid-run counts
  (( ${SVC_INIT:-0} )) && scope_stop "$unit"
  if [[ -n ${SVC_TD:-} ]]; then wait "$SVC_TD"; rc=$?
  elif [[ -n $cmd ]]; then
    ( cd "$dir" || exit 1; HARNESS_PORT=$PORT HARNESS_SCRATCH=$SCRATCH HARNESS_TEARDOWN_WHY=$1 exec timeout -k 10s 2m bash -c "$cmd" ) < /dev/null >> "$SCRATCH/teardown.out" 2>&1 &   # in the tree the init ran in (a lane's slot)
    SVC_TD=$!; wait "$SVC_TD"; rc=$?
  fi
  scope_stop "$unit"; SVC_UP=0 SVC_TD=""; [[ -n $LDIR ]] && rm -f "$LDIR/svc-up"
  if (( rc )); then note "services stopped ($1; teardown exit $rc, see $SCRATCH/teardown.out, at finish $STATE/teardown.out)"
  else note "services stopped ($1)"; fi
}
# check.sh's first question, the tree's key, asked here: it is a child process with no helper, and that's a node start per
# call in it. Only from the tree's top, where check.sh takes it; empty (a subdirectory, a failure): check.sh asks itself.
# check.sh's first two questions asked here, so this shell's helper answers them: the tree's key, then (a full or --fast
# call on a key) what its markers and the map say (decisions/2026-11-03-purity). No answer: check.sh asks.
check_run() {
  local tk="" before="" f=0 l=()
  [[ -e .git ]] && tk=$(ask treekey.mjs --partial --names 2> /dev/null)
  if [[ -n $tk && ( $# == 0 || $1 == --fast ) ]]; then
    [[ ${1:-} == --fast && -n ${HARNESS_CHECK_FAST_CMD:-} ]] && f=1
    mapfile -t l <<< "$tk"
    before=$(ask checkdecide.mjs before "${HARNESS_CHECK_CACHE:-${HARNESS_SCRATCH:-}}" "$f" "${l[@]}" 2> /dev/null)
  fi
  HARNESS_CHECK_BEFORE=$before HARNESS_CHECK_TK=$tk "$CHECK" "$@"
}
green() { check_run > /dev/null 2>&1; }
green_fast() { check_run --fast > /dev/null 2>&1; }   # the gate `passes` stands on (decisions/2026-11-03-fast-gate)
# <fix feature id>: the gate a fix feature's `passes` stands on (decisions/2026-11-04-fix-rounds): the red's files through
# the suite's subset form (the record's fix_files; none: the whole suite), then the fast tier. The first red stops it and
# sets FIX_RED to what was red, as the un-pass note says it (`check <files>`, `suite`, `fast tier`).
green_fix() {
  local files; read -ra files <<< "$(jq -r --arg id "$1" '.features[] | select(.id == $id) | .fix_files // [] | join(" ")' "$LIST")"
  FIX_RED=""
  if (( ${#files[@]} )); then "$CHECK" "${files[@]}" > /dev/null 2>&1 || { FIX_RED="check ${files[*]}"; return 1; }
  else green || { FIX_RED=suite; return 1; }; fi
  green_fast || { FIX_RED="fast tier"; return 1; }
}
# The flakes check.sh's reruns turned green (green/flakes.jsonl, every lane's and session's) get one note each, once:
# $STATE/flakes-noted is the byte offset noted up to. Whole lines only (a lane may be mid-append); a row that isn't a
# JSON object is passed over. Under its own lock, so two lanes never note a row twice (decisions/2026-10-29-rerun-guard).
flakes_note() { [[ -s $STATE/green/flakes.jsonl ]] || return 0; _flakes_note 9> "$STATE/flakes-noted.lock"; }
_flakes_note() {
  flock 9
  local f=$STATE/green/flakes.jsonl off size chunk msg
  off=$(cat "$STATE/flakes-noted" 2> /dev/null); [[ $off =~ ^[0-9]+$ ]] || off=0
  size=$(stat -c %s "$f") || return 0; (( size < off )) && off=0   # a file started again
  (( size > off )) || return 0
  chunk=$(tail -c "+$(( off + 1 ))" "$f"; echo .); chunk=${chunk%.}
  [[ $chunk == *$'\n'* ]] || return 0
  chunk=${chunk%$'\n'*}$'\n'
  while IFS= read -r msg; do [[ -n $msg ]] && note "$msg"; done <<< "$(jq -Rr 'try (fromjson | objects | "flaky: \(if (.names | length) > 0
    then .names | join(" ") elif .tier == "fast" then "the fast tier" else "whole suite" end) (red, then green on a rerun; load \((.load // "") | split(" ")[0] // "?"))") catch empty' <<< "${chunk%$'\n'}")"
  echo $(( off + $(printf %s "$chunk" | wc -c) )) > "$STATE/flakes-noted"
}

# Revert what a session changed since <base> outside what it may change: "record" (the run record), "nothing" (a
# lane's .harness/runs/ is lane_guard's) or, inverted, "memory": the project's memory from the repo root (CLAUDE.md,
# .harness/project.md, and the twins Claude Code loads the same way, .claude/CLAUDE.md and all of .claude/rules/:
# decisions/2026-11-08-memory-rules-pr) and nothing else. Its commits stay in history; a new commit puts the files back.
# Prints what it reverted.
restrict() {   # base record|nothing|memory who
  local base=$1 spec=(. ':!.harness/runs') st path
  [[ $2 == nothing ]] && spec=(.)
  [[ $2 == memory ]] && spec=(CLAUDE.md .harness/project.md .claude/CLAUDE.md .claude/rules)   # from the root: docs/CLAUDE.md and .claude/settings.json are code
  commit_all "WIP: uncommitted at session end (harness)"
  # -z: a path git would quote (a rules file named café.md) comes verbatim, the path the revert needs
  while IFS= read -r -d '' st && IFS= read -r -d '' path; do
    [[ -n $path ]] || continue
    if [[ $st == A ]]; then git rm -q --cached -- "$path" && rm -f -- "$path"; else git checkout -q "$base" -- "$path"; fi
    echo "$path"
  done < <(git diff -z --name-status --no-renames "$base" HEAD -- "${spec[@]}")
  commit_all "HARNESS: reverted edits a $3 session may not make"
}

# The curator's bases (decisions/2026-11-07-memory-tiers, decisions/2026-11-08-memory-rules-pr): for the facts
# (harness-memory/<run>: MEM_BASE, MEM_URL, MEM_NOPR) and then the rules (harness-rules/<run>: RULES_BASE, RULES_URL,
# RULES_NOPR), each by memory_tip from origin's main. The facts' texts go to $SCRATCH/memory-base/ for the session to read
# (so its anchors are matched against the text the apply sees), the rules' to $SCRATCH/memory-rules-base/ for the apply,
# and for a rules tip main lacks, its merge-base with main and main to memory-rules-mb/ and memory-main/ (the drift).
# A facts base that fails is 1 and one note (no curator); a rules base that fails sets RULES_STOP and RULES_NOTE (noted by
# curator() after the session), and the facts half goes on
memory_base() {
  local d=$SCRATCH/memory-base f main mb=""
  MEM_URL="" MEM_NOPR="" RULES_BASE="" RULES_URL="" RULES_NOPR="" RULES_STOP="" RULES_NOTE=""
  origin_t git -C "$RWT" fetch -q origin "$MAIN_BRANCH" 2> /dev/null
  main=$(git -C "$RWT" rev-parse -q --verify "origin/$MAIN_BRANCH^{commit}") || { note "curator: none (no origin/$MAIN_BRANCH to curate against)"; return 1; }
  memory_tip facts "$main" || { note "$TIP_NOTE"; return 1; }
  MEM_BASE=$TIP_BASE MEM_URL=$TIP_URL MEM_NOPR=$TIP_NOPR
  # the rules half's note waits for curator() to give it after the session's restrict, which reverts harness-log.md
  if memory_tip rules "$main"; then RULES_BASE=$TIP_BASE RULES_URL=$TIP_URL RULES_NOPR=$TIP_NOPR; else RULES_STOP=1 RULES_NOTE=$TIP_NOTE; fi
  # a rules tip main lacks: its merge-base with main and main itself, so the apply counts what main gained outside
  # Gotchas since (the merge takes it too: the union cap's drift)
  [[ -n $RULES_BASE && $RULES_BASE != "$main" ]] && mb=$(git -C "$RWT" merge-base "$RULES_BASE" "$main" 2> /dev/null)
  for d in "$SCRATCH/memory-base:$MEM_BASE" "$SCRATCH/memory-rules-base:$RULES_BASE" "$SCRATCH/memory-rules-mb:$mb" "$SCRATCH/memory-main:${mb:+$main}"; do
    rm -rf "${d%%:*}"; [[ -n ${d#*:} ]] || continue
    mkdir -p "${d%%:*}/.harness" "${d%%:*}/.claude"
    for f in CLAUDE.md .harness/project.md .claude/CLAUDE.md; do git -C "$RWT" show "${d#*:}:$f" > "${d%%:*}/$f" 2> /dev/null || rm -f "${d%%:*}/$f"; done
  done
}
# facts|rules → the words of that tier's branch, PR and commit: B (branch), LBL (its notes' label), TITLE, WORD (the
# commit subject's), NONE (the no-change reason)
memory_tier() {
  if [[ $1 == rules ]]; then B=harness-rules/$RUN_ID LBL="memory rules PR" TITLE="memory rules: $RUN_ID" WORD=rules NONE="no tier-2 change"
  else B=harness-memory/$RUN_ID LBL="memory PR" TITLE="memory: $RUN_ID" WORD=facts NONE="no tier-1 change"; fi
}
# <facts|rules> <main> → TIP_BASE, the tier's branch tip when origin has it with its open PR (TIP_URL ← its URL: a
# continue's curator restates nothing already there) or with no PR at all (TIP_NOPR: a push whose pr create failed; the
# PR opens on it), <main> when main has taken that tip or there is none. A tip main lacks whose PR is closed (or not the
# run's) is Michael's, and GitHub or origin not answering is no answer: 1 and TIP_NOTE (the caller notes it), never a
# branch over it
memory_tip() {
  local tip pv st="" x B LBL TITLE WORD NONE err=$STATE/memory-base.err
  memory_tier "$1"; TIP_BASE=$2 TIP_URL="" TIP_NOPR="" TIP_NOTE=""
  tip=$(origin_t git -C "$RWT" ls-remote -q origin "refs/heads/$B" 2>> "$STATE/run.log") || { TIP_NOTE="$LBL: none (origin did not answer for $B; see run.log)"; return 1; }
  tip=${tip%%$'\t'*}
  [[ -n $tip ]] || return 0
  if pv=$(origin_t $GH pr view "$B" --json url,state,title 2> "$err"); then   # the head's open PR, else its newest
    [[ $(jq -r .title <<< "$pv" 2> /dev/null) == "$TITLE" ]] && st=$(jq -r .state <<< "$pv")
  elif grep -q '^no pull requests found' "$err"; then st=NONE
  else cat "$err" >> "$STATE/run.log"; TIP_NOTE="$LBL: none (GitHub did not answer for $B; see run.log)"; return 1; fi
  origin_t git -C "$RWT" fetch -q origin "refs/heads/$B" 2>> "$STATE/run.log"
  git -C "$RWT" cat-file -e "$tip^{commit}" 2> /dev/null || { TIP_NOTE="$LBL: none (could not fetch $B; see run.log)"; return 1; }
  if git -C "$RWT" merge-base --is-ancestor "$tip" "$2"; then :   # taken by main: cut from main, a fast-forward of it
  elif [[ $st == OPEN || $st == NONE ]]; then
    x=$(memory_foreign "$2" "$tip" "$WORD")   # a commit a session pushed there is never a base, nor carried to Michael
    [[ -n $x ]] && { TIP_NOTE="$LBL: none ($B has a commit the driver would not write, $x; delete the branch to curate again)"; return 1; }
    TIP_BASE=$tip; if [[ $st == OPEN ]]; then TIP_URL=$(jq -r .url <<< "$pv"); else TIP_NOPR=1; fi
  else TIP_NOTE="$LBL: none ($B is on origin and main lacks it, its PR ${st:-titled otherwise}; delete the branch to curate again)"; return 1; fi
}

# <base> <tip> <facts|rules> → the first commit of base..tip memory_pr would not have written: a merge, another subject
# than `memory: <run>: <n> <facts|rules>`, or a path besides curator.mjs's FILES (`<sha12> "<subject>" (<paths>)`); else nothing
memory_foreign() {
  local c s f
  while read -r c; do
    s=$(git -C "$RWT" log -1 --format=%s "$c"); f=$(git -C "$RWT" diff-tree --no-commit-id --name-only -r "$c" | grep -vxE 'CLAUDE\.md|\.harness/project\.md|\.claude/CLAUDE\.md' | paste -sd' ')
    if [[ -n $f || ! ${s#"memory: $RUN_ID: "} =~ ^[0-9]+\ $3$ || $(git -C "$RWT" rev-list --parents -n 1 "$c" | wc -w) != 2 ]]; then
      echo "${c:0:12} \"${s:0:80}\"${f:+ ($f)}"; return 0; fi
  done < <(git -C "$RWT" rev-list --reverse "$1..$2")
}

# <ops> <applied> <rules> <dropped> <proposed> <pr url|""> <rules pr url|""> [<invalid why>] → $STATE/memory.json, for
# the summary (M3, N1-01), with the `##` sections each tier's ops touched (from memory-result.json, when this segment has one)
memory_json() {
  local r=$SCRATCH/memory-result.json sec='{"facts":[],"rules":[]}'
  [[ -s $r ]] && sec=$(jq -c 'def seen: reduce .[] as $x ([]; if index([$x]) then . else . + [$x] end);
    {facts: ([.applied[]?.section | sub("\\s+$"; "")] | seen), rules: ([.rules[]?.section | sub("\\s+$"; "")] | seen)}' "$r" 2> /dev/null || echo '{"facts":[],"rules":[]}')
  jq -nc --argjson o "$1" --argjson a "$2" --argjson rl "$3" --argjson d "$4" --argjson p "$5" --arg u "$6" --arg ru "$7" --arg w "${8:-}" --argjson s "$sec" \
    '{ops: $o, applied: $a, dropped: $d, proposed: $p, pr: (if $u == "" then null else $u end), rules: $rl, rules_pr: (if $ru == "" then null else $ru end), sections: $s}
     + (if $w == "" then {} else {invalid: $w} end)' > "$STATE/memory.json"
}

# The curator's memory-ops.json (rescued to $SCRATCH) → applied by curator.mjs in a detached scratch worktree at
# MEM_BASE, then two passes of one path (decisions/2026-11-08-memory-rules-pr): the facts (tier 1, written there) on
# harness-memory/<run> as `memory: <run>`, then the rules (tier 2, the result's ruleTexts written into the worktree made
# again at RULES_BASE) on harness-rules/<run> as `memory rules: <run>`, each one commit, pushed (never forced) and its PR
# opened or its body refreshed; a failure in one is its own note and never stops the other. Tier 3 and every dropped op
# are in both bodies, each body naming the other PR; the union is memory.md in the run record. MEMORY_POLICY=auto
# merges the facts PR alone, at the head pushed and after both bodies are written, and only with this segment's body on
# it: a reused PR whose refresh failed stays open, the next segment the retry (never --delete-branch, as
# record_pr); the rules PR is Michael's under every policy: memory_merge never sees its URL (invariant 3). The record
# branch's tree is never touched, so record_pr's guard holds. Each outcome one note; memory.json the counts
memory_pr() {
  local why n w=$SCRATCH/memory r=$SCRATCH/memory-result.json url="" rurl="" fhead="" fbody=0 o a rl d p rd x f files=() rfiles=() rb=()
  rm -f "$r"; [[ -n $RULES_STOP ]] || rb=("$SCRATCH/memory-rules-base")
  [[ -z $RULES_STOP && -d $SCRATCH/memory-rules-mb ]] && rb+=("$SCRATCH/memory-rules-mb" "$SCRATCH/memory-main")
  why=$(node "$HARNESS_HOME/lib/curator.mjs" validate "$SCRATCH/memory-ops.json" 2> /dev/null) || {
    why=$(head -1 <<< "${why:-the validator gave no answer}" | cut -c1-200)
    note "curator: memory-ops.json invalid: $why"; memory_json 0 0 0 0 0 "$MEM_URL" "$RULES_URL" "$why"; return 0; }
  n=$(jq length "$SCRATCH/memory-ops.json" 2> /dev/null)
  [[ $n == 0 ]] && { note "curator: no operations"; memory_json 0 0 0 0 0 "$MEM_URL" "$RULES_URL"; return 0; }
  memory_wt_gone
  git -C "$RWT" worktree add -q --detach "$w" "$MEM_BASE" 2>> "$STATE/run.log" \
    || { note "memory: apply failed (no worktree at ${MEM_BASE:0:12}; see run.log)"; memory_json "$n" 0 0 0 0 "$MEM_URL" "$RULES_URL"; memory_wt_gone; return 0; }
  node "$HARNESS_HOME/lib/curator.mjs" apply "$SCRATCH/memory-ops.json" "$w" "$RUN_ID" "$REC/entries.jsonl" "${rb[@]}" > "$r" 2>> "$STATE/run.log"
  # a stopped rules half commits nothing: its tier-2 ops are dropped (named in both bodies), the proposals renumbered
  [[ -n $RULES_STOP && -s $r ]] && jq -c '.dropped += [.rules[]? | {op: del(.n), reason: "the rules half stopped; its note says why"}]
    | .rules = [] | .ruleFiles = [] | .ruleTexts = {} | .proposed |= (to_entries | map(.value + {n: (.key + 1)}))' "$r" > "$r.t" 2> /dev/null && mv "$r.t" "$r"
  # an apply that threw prints nothing: no commit and no PR (tests/checks/no-answer.sh's rule)
  IFS=$'\t' read -r o a rl d p rd < <(jq -r '[.ops, (.applied | length), (.rules | length), (.dropped | length), (.proposed | length), .rederived] | @tsv' "$r" 2> /dev/null)
  if [[ ! $o =~ ^[0-9]+$ ]]; then note "memory: apply failed (see run.log)"; rm -f "$r"; memory_json "$n" 0 0 0 0 "$MEM_URL" "$RULES_URL"; memory_wt_gone; return 0; fi
  note "memory: $o ops · $a facts · $rl rules · $d dropped · $p proposals"
  # a cap breach is a dropped op as any other (N1-03); an anchored add that evicted names the line it cut
  while IFS= read -r x; do note "${x:0:200}"; done < <(jq -r '(.dropped[] | "memory: dropped \(.op.op) \(.op.section) (\(.reason))"),
    (.applied[], .rules[] | select(.evicted != null) | "memory: evicted \"\(.evicted[0:80])\" for \(.op) \(.section)")' "$r")
  (( rd > 0 )) && note "memory: tier re-derived for $rd ops"
  # the facts: tier 1 as apply wrote it into the worktree; its body names the rules PR this run already has
  mapfile -t files < <(jq -r '.files[]?' "$r")
  memory_body "$r" facts "$RULES_URL"
  memory_pass facts "$a" "${files[@]}"; fbody=$?; url=$PASS_URL fhead=$PASS_HEAD
  # the rules: the worktree made again at their own base, tier 2's texts written into it
  if [[ -z $RULES_STOP ]]; then
    memory_wt_gone
    mapfile -t rfiles < <(jq -r '.ruleFiles[]?' "$r")
    if ! git -C "$RWT" worktree add -q --detach "$w" "$RULES_BASE" 2>> "$STATE/run.log"; then note "memory rules PR: none (no worktree at ${RULES_BASE:0:12}; see run.log)"
    else
      for f in "${rfiles[@]}"; do jq -j --arg f "$f" '.ruleTexts[$f]' "$r" > "$w/$f"; done
      memory_body "$r" rules "${url:-$MEM_URL}"
      memory_pass rules "$rl" "${rfiles[@]}"; rurl=$PASS_URL
    fi
  fi
  # a rules PR opened after the facts body was written: the facts body names it now
  if [[ $rurl == http* && $rurl != "$RULES_URL" && ${url:-$MEM_URL} == http* ]]; then
    memory_body "$r" facts "$rurl"
    if origin_t $GH pr edit "${url:-$MEM_URL}" --body-file "$SCRATCH/memory-body-facts.md" > /dev/null 2>> "$STATE/run.log"; then note "memory PR: its body names the rules PR · ${url:-$MEM_URL}"
    else note "memory PR: its body could not name the rules PR (see run.log) · ${url:-$MEM_URL}"; fi
  fi
  # the facts PR alone, and only with this segment's body on it (N2-02): no retry of a failed edit here
  if [[ $MEMORY_POLICY == auto && -n $fhead && $url == http* ]]; then
    if (( fbody == 0 )); then memory_merge "$url" "$fhead"
    else note "memory PR: its body was not updated (see run.log); not merged (MEMORY_POLICY=auto), left open · $url"; fi
  fi
  memory_record "$r"
  memory_wt_gone
  memory_json "$o" "$a" "$rl" "$d" "$p" "${url:-$MEM_URL}" "${rurl:-$RULES_URL}"
}
# <facts|rules> <count> <files…> → that tier's change committed in $SCRATCH/memory (`memory: <run>: <n> <tier>`), pushed
# to its branch (never forced: a reused head moves forward) and its PR opened or its body refreshed; with no change, a
# PR this run already has gets this segment's body and a pushed branch without one gets its PR. PASS_URL ← the PR's
# URL, PASS_HEAD ← the commit pushed (auto merges the facts PR only at it); 1 when that commit's PR kept an older body
memory_pass() {
  local t=$1 k=$2 prior nopr B LBL TITLE WORD NONE; shift 2
  memory_tier "$t"; PASS_URL="" PASS_HEAD=""
  if [[ $t == rules ]]; then prior=$RULES_URL nopr=$RULES_NOPR; else prior=$MEM_URL nopr=$MEM_NOPR; fi
  if (( k == 0 || $# == 0 )); then
    if [[ $prior == http* && $MERGE_POLICY != off ]]; then memory_edit "$prior" " ($NONE)" "$t"   # its proposals still reach Michael
    elif [[ -n $nopr && $MERGE_POLICY != off ]]; then memory_open "$t"   # an earlier segment's commit, still without its PR
    elif [[ $t == rules ]]; then note "$LBL: none ($NONE)"
    else note "$LBL: none ($NONE); the body is in memory.md"; fi
  elif [[ $MERGE_POLICY == off ]]; then note "$LBL: none (MERGE_POLICY=off); the body is in memory.md"
  elif ! git -C "$SCRATCH/memory" add -- "$@" 2>> "$STATE/run.log" || ! git -C "$SCRATCH/memory" commit -q -m "memory: $RUN_ID: $k $WORD" -- "$@" 2>> "$STATE/run.log"; then
    note "$LBL: could not commit the tier-$([[ $t == rules ]] && echo 2 || echo 1) change (see run.log)"
  elif ! origin_t git -C "$SCRATCH/memory" push -q origin "HEAD:refs/heads/$B" 2>> "$STATE/run.log"; then
    note "$LBL: could not push $B (see run.log)"
  else
    PASS_HEAD=$(git -C "$SCRATCH/memory" rev-parse HEAD)
    # auto's facts PR: memory_pr's merge decision says it in one note, so the edit stays quiet on a failure
    if [[ $prior == http* ]]; then PASS_URL=$prior; memory_edit "$prior" "" "$t" "$([[ $t == facts && $MEMORY_POLICY == auto ]] && echo quiet)" || return 1
    else memory_open "$t" merge; fi
  fi
  return 0
}
# <result.json> <facts|rules> <other PR url|""> → $SCRATCH/memory-body-<tier>.md, that PR's body: on a reused PR this
# segment's body over the earlier ones (memory.md: the PR's first commit is explained there), while that fits GitHub's
# limit; a body that fails is one line saying so
memory_body() {
  local m=$SCRATCH/memory-body-$2.md prior=$MEM_URL
  [[ $2 == rules ]] && prior=$RULES_URL
  node "$HARNESS_HOME/lib/curator.mjs" body "$1" "$RUN_ID" "$2" "$3" > "$m" 2>> "$STATE/run.log" \
    || { note "memory: the $([[ $2 == rules ]] && echo "rules ")PR body failed (see run.log)"; echo "Project memory curated by run \`$RUN_ID\`: the body failed; memory-result.json in the run record has the ops." > "$m"; }
  memory_earlier "$m" "$prior"
}
# <body file> <the PR's url|""> → the earlier segments' memory.md appended, on a reused PR, while that fits
memory_earlier() {
  if [[ $2 == http* && -s $REC/memory.md ]] && (( $(stat -c %s "$1") + $(stat -c %s "$REC/memory.md") < 60000 )); then
    printf '\n---\n\n_An earlier segment of this run:_\n\n' >> "$1"; cat "$REC/memory.md" >> "$1"
  fi
}
# <result.json> → the run record's memory.md: the union of both bodies (decisions/2026-11-08-memory-rules-pr), over the
# earlier segments' when either PR is reused
memory_record() {
  local m=$SCRATCH/memory-union.md u=$MEM_URL
  node "$HARNESS_HOME/lib/curator.mjs" body "$1" "$RUN_ID" union > "$m" 2>> "$STATE/run.log" \
    || echo "Project memory curated by run \`$RUN_ID\`: the body failed; memory-result.json in the run record has the ops." > "$m"
  [[ $u == http* ]] || u=$RULES_URL
  memory_earlier "$m" "$u"
  cp "$m" "$REC/memory.md"
}
memory_open() {   # <facts|rules> [merge]: that tier's PR opened and noted, unless the merge's note follows; its URL in PASS_URL, else ""
  local u B LBL TITLE WORD NONE
  memory_tier "$1"; PASS_URL=""
  u=$(origin_t $GH pr create --base "$MAIN_BRANCH" --head "$B" --title "$TITLE" --body-file "$SCRATCH/memory-body-$1.md" 2>> "$STATE/run.log" | tail -1)
  if [[ $u != http* ]]; then note "$LBL: could not open it (see run.log)"; return 0; fi
  PASS_URL=$u
  if [[ $1 == rules ]]; then note "memory rules PR opened; left for Michael · $u"   # under every MEMORY_POLICY (invariant 3)
  elif [[ $MEMORY_POLICY != auto ]]; then note "memory PR opened; left for Michael (MEMORY_POLICY=pr) · $u"
  elif [[ ${2:-} != merge ]]; then note "memory PR opened; left open (MEMORY_POLICY=auto: no new tier-1 commit to merge) · $u"; fi
}
memory_merge() {   # <url> <head> (MEMORY_POLICY=auto, the facts PR alone): merged only at the commit pushed, else left open, as record_pr
  if origin_t $GH pr merge "$1" --merge --match-head-commit "$2" > /dev/null 2>> "$STATE/run.log"; then note "memory PR merged into $MAIN_BRANCH · $1"
  else note "memory PR: the merge was refused; left open · $1"; fi
}
memory_edit() {   # <url> <why suffix> <facts|rules> [quiet]: that open PR's body refreshed, noted; PASS_URL ← <url>; gh's status (quiet: a failure's note is the caller's)
  local B LBL TITLE WORD NONE
  memory_tier "$3"; PASS_URL=$1
  if origin_t $GH pr edit "$1" --body-file "$SCRATCH/memory-body-$3.md" > /dev/null 2>> "$STATE/run.log"; then note "$LBL updated$2 · $1"
  else [[ -n ${4:-} ]] || note "$LBL: its body was not updated (see run.log) · $1"; return 1; fi
}
# the scratch worktree goes after every path: a stale registration would trip gc (prune is the fallback)
memory_wt_gone() { git -C "$RWT" worktree remove --force "$SCRATCH/memory" 2> /dev/null; rm -rf "$SCRATCH/memory"; git -C "$RWT" worktree prune 2> /dev/null; return 0; }

# Bring main's new commits into the branch checked out here (a lane at its verify, so what is verified is what merges;
# the record branch at a resumed start, for its configuration). In a lane under CONFLICTS=resolve a conflict goes to a
# resolve session first (lib/resolve.sh): resolved, 0 (the verify runs on the merged tree); refused by a limit, 2 (no
# record: the caller defers). 1 = conflict (left as it was): a main_conflict record
# for the lane (record on the record branch) naming the conflicted files and the PRs that brought them, notified once
# per origin/main commit (main-conflict-<subject> holds it); a later clean merge, or main already in, resolves it.
sync_main() {
  local b sub=${LANE:-record} mn old files fa=() subjects ref; b=$(git branch --show-current)
  fetch_main_ 2>/dev/null || return 0
  git merge-base --is-ancestor "origin/$MAIN_BRANCH" HEAD && { main_clear "$sub"; return 0; }
  merge_main "${LANE:-}" "${LANE:+resolve}"; case $? in   # the record branch's conflicts stay Michael's
    0) [[ -n $MERGE_RESOLVED ]] && resolved_note "$LANE" "the verify goes on with $MAIN_BRANCH merged"
       note "merged $MAIN_BRANCH into $b"; main_clear "$sub"; return 0 ;;
    2) return 2 ;;
  esac
  files=$MERGE_FILES; [[ -n $files ]] && mapfile -t fa <<< "$files"
  # no conflicted file: the merge never started (a dirty tree, no identity): said, as before, and nothing recorded
  (( ${#fa[@]} )) || { note "$MAIN_BRANCH did not merge into $b (see run.log); carrying on without it"; return 1; }
  # --first-parent: main's own merges; path-limited, git's default simplification hides a merge that took a file whole
  subjects=$(git log --first-parent --merges --format=%s "$(git merge-base HEAD "origin/$MAIN_BRANCH")..origin/$MAIN_BRANCH" -- "${fa[@]}")
  note "$MAIN_BRANCH conflicts with $b; carrying on without it (merges into $MAIN_BRANCH need Michael)"
  mn=$(git rev-parse "origin/$MAIN_BRANCH"); old=$(cat "$STATE/main-conflict-$sub" 2> /dev/null)
  echo "$mn" > "$STATE/main-conflict-$sub"   # before the open: a sweep meanwhile must not resolve it
  ref=$(needs_open main_conflict "$sub" files="$files" subjects="$subjects" main="$mn" head="$(git rev-parse HEAD)" ${RESOLVE_TRIED:+tried="$RESOLVE_TRIED"})
  [[ $old == "$mn" ]] && return 1   # once per main commit: a verify after it says nothing new
  rec_commit "HARNESS: $MAIN_BRANCH conflicts with $b"; sync_record
  needs_you "$sub" "$MAIN_BRANCH conflicts with $b" needs.md "$ref"
  return 1
}
# <m> <resolve|""> → origin's main merged into the branch checked out here, the one conflict path of sync_main and
# rebase: 0 = merged (MERGE_RESOLVED set when a resolve session settled a conflict: lib/resolve.sh, a lane only, under
# CONFLICTS=resolve when the caller passes resolve) · 1 = not merged, the merge aborted (MERGE_FILES the conflicted files,
# empty when it never started; RESOLVE_TRIED what a session tried) · 2 = a resolve session refused by a limit (aborted)
merge_main() {
  local rc; MERGE_FILES="" MERGE_RESOLVED="" RESOLVE_TRIED=""
  git merge -q --no-edit "origin/$MAIN_BRANCH" > /dev/null 2>&1 && return 0
  MERGE_FILES=$(git -c core.quotePath=false diff --name-only --diff-filter=U)
  if [[ -n $MERGE_FILES && $2 == resolve && ${CONFLICTS:-} == resolve ]]; then
    resolve "$1" "$MAIN_BRANCH"; rc=$?; (( rc )) || MERGE_RESOLVED=1; return $rc   # resolve aborts the merge on anything but 0
  fi
  git merge --abort 2> /dev/null; return 1
}
main_clear() { [[ -f $STATE/main-conflict-$1 ]] || return 0; rm -f "$STATE/main-conflict-$1"; needs_sweep; }   # <subject>
# git merge-tree --write-tree --name-only's output → its conflicted paths (the lines between the tree and the blank line)
conflict_files() { sed -n '2,/^$/{/./p}'; }

# Answers typed locally (`harness answer`, the supervisor) are moved into INBOX.md so sessions see them.
take_answers_() {
  [[ -s $STATE/inbox.md ]] || return 0
  { echo; echo "### $(date '+%F %H:%M') (local)"; cat "$STATE/inbox.md"; } >> "$REC/INBOX.md"
  : > "$STATE/inbox.md"
  rec_commit "HARNESS: answers from Michael"
}
take_answers() { record take_answers_; }

# A milestone Michael must act on (verify, a conflict): its needs record's title, body (the card), click (needs.md) and
# priority; without a record (a failed open) high, one tap from the run-record file that explains it.
needs_you() {   # <milestone> <why> <file in the run record> <the record's ref>
  needs_notify "${4:-}" "$1 needs Michael: $2" title="[$RUN_ID] $1 needs you" priority=high click="$(gh_url "$RUN_DIR/$3")" kind=needs_michael
  desk "$1 needs Michael: $2"
}

# DESK=1: a Remote Control session briefs Michael (lib/desk.sh). It never changes the run: a failure is a note.
# Its note is committed at once: left over, the retro's revert would drop it, or a session's "WIP" commit take it.
# 9>&-: no lock fd may reach a tmux server it starts.
desk() {
  [[ $DESK == 1 ]] || return 0
  "$HARNESS_HOME/bin/harness" desk "$RUN_ID" --why "$1" > /dev/null 2>&1 8>&- 9>&- || note "desk: could not start (exit $?): $1"
  [[ -n $(git -C "$RWT" status --porcelain -- "$RUN_DIR") ]] && { rec_commit "HARNESS: desk"; sync_record; }
  return 0
}

# The park's notification: the question the session wrote in INBOX.md and how to answer, with the INBOX one tap away.
# A park's notification is its needs record's (lib/needs.sh): the title, the body (PARKED: <why>, the question, the
# card's blocked, where and do, the answer line), the click (needs.md), priority high and the actions park_actions gave
# it at its open. Without a record (a failed open) the question and the answer line still go out.
park_actions() { ask notify.mjs actions "Edit INBOX" "$(gh_url "$RUN_DIR/INBOX.md" edit)" "Answer with Claude" "$DESK_URL" Progress "$(gh_url "$RUN_DIR/progress.md")"; }
notify_park() {   # <id> <why> <the parked record's ref>
  local id=$1 why=$2 q
  q=$(cat "$LS/question" 2> /dev/null)   # what take_question found in the session's copy (gone by now)
  needs_notify "${3:-}" "needs Michael: $id · $why" kind=park feature="$id" title="[$RUN_ID] $id needs you" priority=high tags=question actions="$(park_actions)" click="$(gh_url "$RUN_DIR/INBOX.md")" \
    body="PARKED: $why"$'\n\n'"${q:+$q$'\n\n'}Answer: harness answer $RUN_ID \"…\""
}

# What unparks a feature: Michael's answers changing (INBOX.md from "## Answers" on, local answers included). The
# heading is the one outside the steering comment: a `## Answers".` a session left inside it is not his answers.
# Memoized as F is, on INBOX.md's content (decisions/2026-10-31-fewer-node-starts).
answers_hash() { local v; answers_v v; echo "$v"; }
answers_v() {   # <var>: answers_hash's value, kept in the memo when this is the shell that keeps entries
  local av_h av_k av_o av_v; f_sha av_h "$REC/INBOX.md"; av_k=answers$'\x1f'$av_h
  if [[ -z ${F_MEMO[$av_k]+x} ]]; then
    # into a variable first: a pipeline's side has no helper. The x keeps its trailing newlines, which the hash covers
    av_o=$(ask inbox.mjs answers "$REC/INBOX.md" 2> /dev/null; printf x)
    av_v=$(printf %s "${av_o%x}" | sha1sum | cut -c1-12)
    [[ $BASHPID == "$F_MEMO_PID" ]] || { printf -v "$1" %s "$av_v"; return 0; }   # a subshell couldn't keep it
    f_sha av_h "$REC/INBOX.md"; [[ answers$'\x1f'$av_h == "$av_k" ]] || { printf -v "$1" %s "$av_v"; return 0; }
    F_MEMO[$av_k]=$av_v
  fi
  printf -v "$1" %s "${F_MEMO[$av_k]}"
}
# Before `$(record F unpark "$PARKED" "$(answers_hash)")`, in the shell that keeps the memo (both run in a subshell
# there): answers_hash's entry, and, when the pure `unparks` finds nothing to un-park, unpark's (empty: it would change
# nothing). With something to un-park nothing is filled, so that unpark runs node, un-parks and prints as before.
unpark_warm() {
  local ah u; answers_v ah
  Fv u unparks "$PARKED" "$ah" || return 0
  # unparks' own stored answer, empty (the key's parked.json hash is the content it read): unpark's key is the same but its name
  [[ $F_KEY == unparks$'\x1f'* && ${F_MEMO[$F_KEY]+x} && -z ${F_MEMO[$F_KEY]} ]] && F_MEMO[unpark${F_KEY#unparks}]="" F_MRC[unpark${F_KEY#unparks}]=0
  return 0
}

control() {   # → run | pause | stop. The common case answers here, with no node start on a helper-off poll (node-memo): no STOP or
  # PAUSE file and `status: run` as the first status line; any other asks lib/inbox.mjs
  [[ ! -f $STATE/STOP && ! -f $STATE/PAUSE && $(grep -m1 "^status:" "$REC/INBOX.md" 2> /dev/null) == "status: run" ]] && { echo run; return 0; }
  ask inbox.mjs control "$REC/INBOX.md" "$STATE"; }
stop_why() { local w; w=$(ask inbox.mjs stop-why "$REC/INBOX.md" "$STATE"); echo "${w:-stopped by Michael}"; }   # → "stopped by Michael[: <why>]": STOP's line (harness stop --why), else the text after control()'s `status: stop`; no answer, the plain words

# <epoch>: the box-wide usage-limit window raised to it, never lowered (any lane, any run may have set a later one)
limit_raise() { (( $1 > $(cat "$LIMIT_FILE" 2> /dev/null || echo 0) )) && echo "$1" > "$LIMIT_FILE"; return 0; }
# One usage limit covers every run on the box: wait until the window that refused a session (any run's) is over.
# Each lane waits for a window once (its marker in its lane dir: a shared one would let one lane's wait cover another
# that then starts sessions inside the window); the coordinator waits only while no lane is open, so a window it or any
# lane already waited for is done for it, and one it waited for before opening is done for the lane.
limit_wait() {
  local upto now w; upto=$(cat "$LIMIT_FILE" 2>/dev/null || echo 0); now=$(date +%s)
  (( upto > now )) && [[ ! -f $STATE/waited-$upto && ! -f $LS/waited-$upto ]] || return 0
  [[ $LS == "$STATE" ]] && compgen -G "$STATE/lanes/*/waited-$upto" > /dev/null && return 0
  w=$(( upto - now )); (( DEADLINE && w > DEADLINE - now )) && w=$(( DEADLINE - now )); (( w > 0 )) || return 0
  touch "$LS/waited-$upto"
  if (( w > SVC_IDLE_STOP_MIN * 60 )); then   # a short wait keeps them (decisions/2026-10-25-services-stop-points)
    services_down "usage-limit wait"; [[ $LS == "$STATE" ]] && lanes_services_down "usage-limit wait"   # the coordinator: closed lanes' too
  fi
  note "usage-limit window (shared by all runs): waiting until $(date -d "@$upto" '+%H:%M') ($(( w / 60 )) min)"
  rec_commit "HARNESS: waiting for the usage limit"; sync_record
  w=${HARNESS_LIMIT_SLEEP:-$w}; slept_until "$w"
}
# <s>: sleep that long in slices of at most 60 s; 1 early when the run is ending (another lane's end: lanes-end) or
# Michael stopped it, so finish's wait for the lanes never waits out a five-hour window
slept_until() {
  local w=$1 s
  while (( w > 0 )); do
    [[ -f $STATE/lanes-end || $(control) == stop ]] && return 1
    s=$(( w < 60 ? w : 60 )); sleep "$s"; w=$(( w - s ))
  done
  return 0
}

past_deadline() { (( DEADLINE && $(date +%s) >= DEADLINE )); }   # 0 is no end time, never "now"

prompt() {   # template name → $LS/prompt.md (lib/prompt.sh, which `harness eval probes` renders the same way)
  prompt_render "$1" > "$LS/prompt.md"
  cp "$LS/prompt.md" "$STATE/prompt-$1.md"   # the last prompt of each kind (any lane's), for debugging
}

# <attempt N of M | verify round N of M> → the clock line of a coding or verify prompt ({{CLOCK}}): sessions can't tell
# time, budget or attempt otherwise. The run is this driver's segment (T0 to DEADLINE). decisions/2026-10-21-clock-and-bounded-init-output
clock() {
  local now el tot span=" (no end time)"; now=$(date +%s); el=$(( (now - T0) / 60 ))
  if (( DEADLINE )); then
    tot=$(( (DEADLINE - T0) / 60 ))
    span=" of $( (( tot % 60 )) && printf '%dh%02dm' $(( tot / 60 )) $(( tot % 60 )) || echo "$(( tot / 60 ))h"), ends $(date -d "@$DEADLINE" +%H:%M)"
  fi
  printf 'Clock: %s · run %dh%02dm%s · this session: $%s budget, %s turns, %s timeout · %s\n' "$(date '+%F %H:%M')" \
    $(( el / 60 )) $(( el % 60 )) "$span" "$SESSION_BUDGET_USD" "$MAX_TURNS" "$SESSION_TIMEOUT" "$1"
}

# kind model log who → runs claude headless on $LS/prompt.md in its own capped scope (decisions/2026-10-25-scoped-sessions);
# sets S_EXIT, S_WALL, S_PEAK (MB, empty when uncapped) and S_NOTES (what the scope showed; noted here, except for the
# read-only retro and curator, whose callers note them after restrict, which would revert them). The caller's S_RESUME (a session id:
# --resume, and its entry.json kept), S_TURNS, S_TIMEOUT and S_BUDGET override the defaults (entry_resume's); an S_DENY
# array is the session's deny rules, --disallowedTools last on the line (the curator's: decisions/2026-11-08-memory-session-and-answers)
session() {
  local settings=() mcp=(--strict-mcp-config) t0 seq unit left x resume=() deny=()
  t0=$(date +%s) S_NOTES=()
  [[ -n ${S_RESUME:-} ]] && resume=(--resume "$S_RESUME")
  [[ -v S_DENY ]] && (( ${#S_DENY[@]} )) && deny=(--disallowedTools "${S_DENY[@]}")
  # an entry.json no ingest took (the driver died after its session) would pass for this session's own
  [[ -z ${S_RESUME:-} && -e $RUN_DIR/entry.json ]] && { mv -f "$RUN_DIR/entry.json" "$STATE/entry-stale-$(date +%s).json"; note "an earlier session's entry.json moved aside before this $1 session"; }
  cp "$LS/prompt.md" "${3%.jsonl}.prompt.md"   # each session's prompt beside its transcript, so two can be diffed (decisions/2026-10-21-static-first-prompts)
  [[ $1 == coding || $1 == verify ]] && cp "$RUN_DIR/context.md" "${3%.jsonl}.context.md" 2> /dev/null   # and the pack it read first
  [[ -f $AGENT_SETTINGS ]] && settings=(--settings "$WT/$AGENT_SETTINGS")
  # only the project's committed MCP servers, never the user's or another project's (decisions/2026-10-25-strict-mcp-and-deepequal-rule)
  [[ -f $WT/.mcp.json ]] && mcp+=(--mcp-config "$WT/.mcp.json")
  # s<n> is per run, never per segment: a crashed segment's scope may still hold its name; a lane's is harness-<run>-<m>-s<n>
  seq=$(rec_count "$STATE/scope-seq" 1); unit=$(scope_unit "$RUN_ID" "${LANEU:+$LANEU-}s$seq")
  # timeout inside the scope: outside it would signal the wrapper and leave claude running; -k: claude ignoring TERM
  S_UNIT=$unit   # the EXIT trap stops it when the driver dies mid-session
  scope_run "$unit" "$SESSION_MEMORY_HIGH" "$SESSION_MEMORY_MAX" timeout -k 30s "${S_TIMEOUT:-$SESSION_TIMEOUT}" \
    "$CLAUDE" -p "$(cat "$LS/prompt.md")" --model "$2" --permission-mode auto "${settings[@]}" "${mcp[@]}" \
    --max-turns "${S_TURNS:-$MAX_TURNS}" --max-budget-usd "${S_BUDGET:-$SESSION_BUDGET_USD}" --output-format stream-json --verbose "${resume[@]}" "${deny[@]}" > "$3" 2>&1
  S_EXIT=$? S_WALL=$(( $(date +%s) - t0 ))
  # read what the wrapper recorded, then stop the scope: whatever the session left running goes with it
  S_PEAK=$(scope_peak "$unit") left=$(scope_left "$unit"); scope_stop "$unit"; S_UNIT=""
  (( left > 0 )) && S_NOTES+=("$1 session left $left process(es) running; stopped with its scope")
  [[ -n ${SCOPE_BARE:-} ]] && S_NOTES+=("$1 session ran uncapped: $SCOPE_BARE")   # its error is in the transcript
  # the peak alone could be page cache: a cap kill is the kernel's 137 with the peak at the cap
  (( S_EXIT == 137 )) && scope_capped "$unit" "$SESSION_MEMORY_MAX" && S_NOTES+=("${4:-$1}: the session hit its memory cap ($SESSION_MEMORY_MAX)")
  [[ $1 == retro || $1 == curator ]] || for x in "${S_NOTES[@]}"; do note "$x"; done
  # the box-wide 7-day and 5-hour windows (admit reads the second); a temporary file per process: two lanes' sessions
  # may end in the same second
  MET usage "$3" > "$USAGE.$$.tmp" 2> /dev/null && mv "$USAGE.$$.tmp" "$USAGE" || rm -f "$USAGE.$$.tmp"
  MET usage "$3" five_hour > "$USAGE5.$$.tmp" 2> /dev/null && mv "$USAGE5.$$.tmp" "$USAGE5" || rm -f "$USAGE5.$$.tmp"
  log "  $1 exit $S_EXIT · $(git log --oneline -1)"
}

# <kind> <id> <transcript> <model> <who> → once, a coding, verify or init session whose entry the ingest would make
# minimal (missing, or invalid beyond the caps the ingest trims) and that no limit refused: resumed by its session id to
# write entry.json and nothing else, in its own scope, before the ingest and outside the record lock. Its other edits
# go (the run's list and INBOX put back, the tree's changes dropped, its commits reverted); its cost is an entry-resume
# metrics row, never a session. Sets ENTRY_RESUMED (journal_'s note). docs/plans/2026-10-29-R2-entries.md §The resume
entry_resume() {
  local errs sid budget base f out
  ENTRY_RESUMED=""
  [[ $1 == coding || $1 == verify || $1 == init ]] || return 0
  errs=$(ask entries.mjs validate "$RUN_DIR/entry.json" "$2" "$1" 2>&1)
  (( $? == 1 )) || return 0   # valid, only a cap over (2: the ingest trims it), or unreadable (70: the ingest's failure takes it)
  MET limit "$3" "$S_WALL" "$S_EXIT" > /dev/null && return 0   # refused: the limit would refuse the resume too
  sid=$(MET session-id "$3" 2> /dev/null) || { note "$5: no session id in its transcript; not resumed"; return 0; }
  [[ $errs == missing ]] && errs="It is missing." || errs="The entry check printed:"$'\n\n'$(sed 's/^/    /' <<< "$errs")
  HARNESS_FEATURE=$2 HARNESS_ENTRY_KIND=$1 HARNESS_ENTRY_ERRORS=$errs prompt entry-resume
  for f in feature_list.json INBOX.md; do   # absent (an initializer's list): a marker, so one the resume writes goes
    rm -f "$SCRATCH/resume-absent-$f"; cp -p "$RUN_DIR/$f" "$SCRATCH/resume-before-$f" 2> /dev/null || : > "$SCRATCH/resume-absent-$f"; done
  budget=$(awk -v a="$(MET cost "$3" 2> /dev/null)" -v b="$ENTRY_RESUME_BUDGET_USD" 'BEGIN { print a + b }')
  base=$(git rev-parse HEAD)
  local S_EXIT S_WALL S_PEAK S_NOTES S_UNIT   # the resume's: the caller reads the session's own after this
  S_RESUME=$sid S_TURNS=$ENTRY_RESUME_TURNS S_TIMEOUT=$ENTRY_RESUME_TIMEOUT S_BUDGET=$budget \
    session entry-resume "$4" "${3%.jsonl}.resume.jsonl" "$5"
  ENTRY_RESUMED=1
  # the driver reads the list's claim and the INBOX's questions after this: the resume may write entry.json only
  for f in feature_list.json INBOX.md; do
    if [[ -e $SCRATCH/resume-absent-$f ]]; then rm -f "$SCRATCH/resume-absent-$f"
      [[ -e $RUN_DIR/$f ]] && { rm -f "$RUN_DIR/$f"; note "$5: the resume wrote $f; removed"; }; continue; fi
    cmp -s "$SCRATCH/resume-before-$f" "$RUN_DIR/$f" || { cp -p "$SCRATCH/resume-before-$f" "$RUN_DIR/$f"; note "$5: the resume changed $f; restored"; }
    rm -f "$SCRATCH/resume-before-$f"
  done
  # the tree was clean before it (the WIP commit, restrict): its uncommitted edits go uncommitted, then its commits
  git checkout -q -- . ':!.harness/runs' 2> /dev/null; git clean -fdq -- . ':!.harness/runs' 2> /dev/null
  if [[ $(git rev-parse HEAD) != "$base" ]]; then
    out=$(restrict "$base" record entry-resume | paste -sd' ')
    [[ -n $out ]] && { note "$5: reverted edits the resume may not make: $out"; sync_lane; }
  fi
  record MET append-resume "$3" "${3%.jsonl}.resume.jsonl" "$REC/metrics.jsonl" "$RUN_ID" "$2" "$4" "$1" "$S_WALL" "$S_EXIT" "$S_PEAK" "${LANE:-}"
  return 0
}

# <kind> <feature> <transcript> <model> <start commit> → the session's entry.json into entries.jsonl: the driver is its
# only writer (decisions/2026-10-22-journal-single-writer). Missing or invalid: a note and a minimal entry from git and
# the final message, whose outcome is what the list says now (the session's claim, before the driver's checks; a
# refused session's claim is reverted, so not yet). A session's own edits to the journal are undone first.
# Then progress.md and progress-archive.md are rendered from the journal (decisions/2026-10-22-rendered-progress).
journal() {
  local kind=$1 id=$2 who=$2 outcome="not yet" name f; name=$(basename "$3" .jsonl)
  git -c core.quotePath=false diff --name-only --no-renames "$5" HEAD -- . ":!$RUN_DIR" > "$SCRATCH/entry-files"
  MET final "$3" > "$SCRATCH/entry-final" 2> /dev/null
  case $kind in   # the claim is the session's own list: the slot's copy in a lane (the flip comes after the checks)
    coding) if MET limit "$3" "$S_WALL" "$S_EXIT" > /dev/null; then :   # refused: the driver reverts its claim below
            elif F passes "$RUN_DIR/feature_list.json" "$id"; then outcome=passes
            elif sed -n 's/^[[:space:]*`>-]*PARKED:[[:space:]]*//p' "$SCRATCH/entry-final" | grep -q .; then outcome=parked; fi ;;
    verify) who="verify $id" ;;   # a verify without its entry has no evidence rows, so it never holds: not yet
    resolve) who="resolve $id" ;;   # its verdict is the driver's checks (lib/resolve.sh), never its entry's outcome
    init)   F summary "$LIST" > /dev/null 2>&1 && outcome=passes ;;
  esac
  entry_resume "$kind" "$id" "$3" "$4" "$who"   # before the loop below, which also undoes a resume's journal edits
  if [[ $PWD == "$RWT" ]]; then   # the initializer: committed by the WIP/restrict commit, so a diff from the start sees it
    for f in entries.jsonl progress-archive.md; do
      git diff --quiet "$5" -- "$RUN_DIR/$f" 2> /dev/null && continue
      if git cat-file -e "$5:$RUN_DIR/$f" 2> /dev/null; then git show "$5:$RUN_DIR/$f" > "$RUN_DIR/$f"; else rm -f "$RUN_DIR/$f"; fi
      note "$who: $f edited by the session; restored (the driver is its only writer)"
    done
  else   # a lane: the copy is discarded, so a session's edit to it never reaches the record; said all the same
    for f in entries.jsonl progress-archive.md; do
      [[ ! -e $RUN_DIR/$f && ! -e $REC/$f ]] || cmp -s "$RUN_DIR/$f" "$REC/$f" && continue
      note "$who: $f edited by the session; restored (the driver is its only writer)"
    done
  fi
  record journal_ "$who" "$kind" "$id" "$name" "$4" "$outcome" "$PWD"
  return 0
}
journal_() {   # who kind id name model outcome worktree: the ingest and the render, in the record
  local out rc n f
  if [[ $PWD != "$RWT" ]]; then   # a lane: the take-back of the copy's entry, under the lock with the ingest
    rm -f "$REC/entry.json"; [[ -e $RUN_DIR/entry.json ]] && mv -f "$RUN_DIR/entry.json" "$REC/entry.json"
  fi
  out=$(ask entries.mjs ingest "$REC" "$2" "$3" "$4" "$5" "$6" "$SCRATCH/entry-files" "$SCRATCH/entry-final" "$7"); rc=$?
  # a question without a Files: line got the session's files (decisions/2026-10-27-question-locations)
  n=$(sed -n 's/^filled //p' <<< "$out"); out=$(grep -v '^filled ' <<< "$out")
  [[ -n $n ]] && note "$1: $n question(s) had no Files: line; filled from the session's diff"
  # a summary or header over its cap, the entry's only fault: cut and kept, not minimal (docs/plans/2026-10-29-R2-entries.md)
  while read -r f n; do [[ -n $n ]] && note "$1: entry.json $f $n characters; cut to $([[ $f == header ]] && echo 2000 || echo 400) and kept"
  done < <(sed -n 's/^trimmed //p' <<< "$out"); out=$(grep -v '^trimmed ' <<< "$out")
  if (( rc == 3 )); then note "$1: entry.json ${ENTRY_RESUMED:+still }$out${ENTRY_RESUMED:+ after one resume}; recorded a minimal entry"
  elif (( rc == 0 && ${ENTRY_RESUMED:-0} )); then note "$1: entry.json written on a resume"; fi
  (( rc == 0 || rc == 3 )) || { note "$1: the journal append failed (exit $rc): $out"   # aside, so the next session's ingest can't take it
    mv -f "$REC/entry.json" "$STATE/entry-failed-$4.json" 2> /dev/null; }
  # each question the entry asks waits in harness needs until answered (docs/plans/2026-10-29-R4-questions.md §3)
  (( rc == 0 )) && questions_ "$1" "$2" "$3"
  out=$(ask entries.mjs render "$REC" 2>&1) || note "$1: rendering progress.md failed: $out"
  return 0
}

# who kind id: one question item per question of the entry just appended (its last line, under the lock), the text as
# entries.jsonl stores it (filled): the sweep matches a later resolved against it. An entry that resolves sweeps at once
questions_() {
  local l q n=0 last f=(); l=$(grep -c '' "$REC/entries.jsonl"); last=$(tail -n 1 "$REC/entries.jsonl")
  [[ $2 == coding ]] && f=(feature="$3")
  while IFS= read -r -d '' q; do
    needs_open question "$q" asker="$3" line="$l" "${f[@]}" > /dev/null; n=$(( n + 1 ))
  done < <(jq -j '.questions[]? | strings | select(test("\\S")) | . + "\u0000"' <<< "$last")
  (( n )) && note "$1: $n question(s) for Michael recorded (harness needs)"
  [[ $(jq '.resolved // [] | length' <<< "$last") == 0 ]] || needs_sweep
  return 0
}

# <m> → how many verify entries the milestone has in entries.jsonl (the rendered progress.md shows only the 15 newest in
# full). A run with a list always has the file by its first verify: the start-up or the initializer's append creates it
vcount() {
  jq -cR --arg m "$1" 'fromjson? | objects | select(.kind == "verify" and .feature == $m)' "$REC/entries.jsonl" 2> /dev/null | wc -l
}

# <feature or milestone> [<cap>] → <run>/context.md, the bounded pack of the journal the next coding or verify session
# reads first (lib/entries.mjs pack, at most <cap>, default CONTEXT_PACK_BYTES; verify passes CONTEXT_PACK_BYTES_VERIFY:
# decisions/2026-10-22-context-pack, decisions/2026-10-26-pack-current-rules). Its Gotchas and Current rules are the
# cwd's (a lane's slot: the code the session sees). Committed with the run record on the record branch; materialize
# copies it into the slot.
context_() {
  if ask entries.mjs pack "$REC" "$1" "${2:-$CONTEXT_PACK_BYTES}" "$PWD" > "$SCRATCH/context.md" 2> "$SCRATCH/context.err"; then
    mv -f "$SCRATCH/context.md" "$REC/context.md"
    note "context.md for $1: $(wc -c < "$REC/context.md") bytes$(sed -n 's/^_\([0-9]*\) items left out at .*/, \1 items left out/p' "$REC/context.md")"
  else   # never a stale pack: the session is sent to the full record instead
    printf '# Context pack for `%s`\n\nThe harness could not build it this time; read entries.jsonl / progress-archive.md.\n' "$1" > "$REC/context.md"
    note "context.md for $1: the pack failed ($(head -c 200 "$SCRATCH/context.err" | tr '\n' ' ')); it points at the full record"
  fi
  # committed now, alone: anything else uncommitted in the record stays for its own commit (E4 review F4)
  git -C "$RWT" add -- "$RUN_DIR/context.md" && { git -C "$RWT" diff --cached --quiet -- "$RUN_DIR/context.md" || git -C "$RWT" commit -q -m "HARNESS: context pack for $1" -- "$RUN_DIR/context.md"; }
}

# The project's init, then the suite (cached per code tree); both go into the next prompt. The init runs in
# harness-<run>-svc (decisions/2026-10-25-services-scope): what it backgrounds (a dev server) stays there, capped at
# SVC_MEMORY_MAX. timeout bounds the init, not the servers it left once it returned (a timeout takes its process group
# too); stdin is /dev/null, so no tool waits on the tmux pane. The last init's scope is stopped first: systemd refuses
# a unit name still loaded (tests/fixtures/systemd-run-unit-exists.txt), and its services would live on beside the new.
# fast: the suite's fast tier (check.sh --fast, a coding session's init); bare and fresh: the full suite.
run_init() {   # [fresh: clear the suite cache's markers for the tree as the init left it, so the suite runs in full | fast]
  local unit=$SVC_UNIT
  scope_stop "$unit"
  SVC_UP=1 SVC_INIT=1 SVC_DIR=$PWD; [[ -n $LDIR ]] && echo "$unit" > "$LDIR/svc-up"   # before the start: a TERM during the init must still stop what it began (services_down, L2-03)
  HARNESS_PORT=$PORT HARNESS_SCRATCH=$SCRATCH scope_run "$unit" "" "$SVC_MEMORY_MAX" timeout -k 10s "$INIT_TIMEOUT" bash -c "$INIT_CMD" < /dev/null > "$SCRATCH/init.out" 2>&1
  local rc=$?; SVC_INIT=0; echo "(init exit $rc)" >> "$SCRATCH/init.out"
  [[ -n ${SCOPE_BARE:-} ]] && note "init ran uncapped: $SCOPE_BARE"   # systemd refused the unit; its line is in init.out
  (( rc == 0 )) || log "  init exit $rc (the session is told to fix it first)"
  # the tree's key as check.sh takes it, before the suite runs (what a suite leaves untracked would change it after)
  # and its reduced key (CHECK_KEY_MAP's paths left out): fresh drops its part- sidecar, or a tree differing from that
  # sidecar's green tree in mapped paths alone would run a partial (decisions/2026-10-30-partial-key)
  local key red; { read -r key; read -r red; } < <(ask treekey.mjs --partial 2> /dev/null)   # a dropped entry: check.sh says it
  # a red found around a failed init may be the init's (a network blip, a failed install), not the tree's: an init after
  # a failed one runs the suite, and a red under a failed init isn't kept (init-failed: this lane's, or the driver's)
  local flag=${LDIR:-$STATE}/init-failed prev=0; [[ -f $flag ]] && prev=1
  if (( rc )); then touch "$flag"; else rm -f "$flag"; fi
  [[ ${1:-} == fresh ]] && rm -f "$STATE/green/"{green,red,fast}-"$key" "$STATE/green/part-$red"   # a cached red or fast-green would answer too
  (( rc || prev )) && rm -f "$STATE/green/red-$key"
  local crc=0 tier=(); [[ ${1:-} == fast ]] && tier=(--fast)
  check_run "${tier[@]}" >> "$SCRATCH/init.out" 2>&1 || { crc=$?; log "  suite red before the session (the session is told to fix it first)"; }
  (( rc )) && [[ -f $STATE/green/red-$key ]] && rm -f "$STATE/green/red-$key" && note "suite red under a failed init: not cached (the next init runs it)"
  # a red suite pins neither the count nor its source: the next green one does. Of a green tree, its marker first (after
  # a rerun the first run's total), then its own output, check-<key>.out: check.out may be an older tree's, a red one's
  # when this green was cached. Full markers only: a fast-green tree (fast-<key>) leaves tests-start for a full green
  local n="" out=$SCRATCH/check-$key.out
  if (( crc == 0 )) && [[ ! -f $STATE/tests-start ]]; then
    n=$(green_count "$key")
    [[ -n $n ]] && echo "${n%% *}" > "$STATE/tests-start"
  fi
  # once per run, from the first green suite whose output is here (a green cached in an earlier segment has none): where
  # the count came from, so a scraped count is told from the contract and a missing one explains the report's `?`
  # (testcount-nomatch: older runs)
  local src
  if (( crc == 0 )) && [[ -f $out && ! -f $STATE/testcount-source && ! -f $STATE/testcount-nomatch ]]; then
    src=$(ask testcount.mjs "$out" --source); src=${src##* · }
    case $src in
      contract) note "test count: HARNESS_TESTS contract" ;;
      none|"") src=none; note "test count: no match in the suite's output (tests start/end stay unknown)" ;;
      *) note "test count: parsed ($src)" ;;
    esac
    echo "$src" > "$STATE/testcount-source"
  fi
}

# <key> → a green tree's count: its marker's line 1 (line 2 is the wall), else (an older, empty marker) its output's,
# check-<key>.out; nothing for a tree with no green marker. check.sh's cached line reads the marker the same way.
# green-<key> alone, never fast-<key>: every count in the record is the whole suite's.
green_count() {
  local n="" f=$STATE/green/green-$1
  [[ -f $f ]] || return 0
  read -r n < "$f"; [[ -n $n ]] || n=$(ask testcount.mjs "$SCRATCH/check-$1.out" 2> /dev/null)
  echo "$n"
}

# tests-end: a green tree's count, its marker's (a continued segment's scratch has no output of a tree cached green),
# else (an older, empty marker) its output's; a red tree has none, whatever its output counted. Written after every
# session too (by its lane, of its slot's tree), so status and report show it between sessions; tests-start, the run's
# baseline, is never rewritten (decisions/2026-10-26-test-count-contract). Without a count only `final` (finish) clears
# it: mid-run, the last stays. The cwd's tree, with this process's SCRATCH.
tests_end() {   # [final]
  local key n; key=$(ask treekey.mjs); n=$(green_count "$key")
  if [[ -n $n ]]; then echo "${n%% *}" > "$STATE/tests-end"; elif [[ ${1:-} == final ]]; then rm -f "$STATE/tests-end"; fi
}

pr_body() {   # milestone → the evidence a reviewer (or the record) needs; the archive has every entry in full
  local p=$REC/progress-archive.md; [[ -f $p ]] || p=$REC/progress.md
  echo "Milestone **$1** of harness run \`$RUN_ID\` (lane \`harness-lane/$RUN_ID/$1\`), verified by an independent session."
  echo; echo "**Features:**"; for id in $(F ids "$LIST" "$1"); do echo "- \`$id\` · $(jq -r --arg id "$id" '.features[]|select(.id==$id)|.description' "$LIST" 2>/dev/null)"; done
  # a lane's resolve session merged main in (lib/resolve.sh wrote its files): said, never asked about
  [[ -s $STATE/resolved-$1 ]] && { echo; echo "Merged $MAIN_BRANCH in with a resolve session: $(awk '!s[$0]++ { printf "%s%s", n++ ? ", " : "", $0 }' "$STATE/resolved-$1")"; }
  echo; echo "**Run so far:** $(F summary "$LIST") · $(MET summary "$REC/metrics.jsonl")"
  echo; echo "**Verify entry:**"; echo
  # `verify M1` followed by anything but a letter, digit, _ or - (M1 never matches M10; a legacy `verify M1: …` does)
  awk -v m="verify $1" 'index($0, "### ") == 1 { if (on) exit; i = index($0, m); if (i && substr($0, i + length(m), 1) !~ /[[:alnum:]_-]/) on = 1 } on' "$p" | head -60
  echo; echo "Run record: \`$RUN_DIR/\` on branch \`$RBRANCH\` (progress.md, harness-log.md, feature_list.json, metrics.jsonl)."
}

# <m> <commit> <tree> <main> → 0 when they differ only in paths the suite's cache key ignores (.harness/runs and
# CHECK_KEY_IGNORE: lib/treekey.mjs's own pathspecs, so the key and this test are one definition), noted once per main:
# main moved only there, so the verified result stands
ignored_only() {
  local spec; mapfile -t spec < <(HARNESS_CHECK_KEY_IGNORE=${CHECK_KEY_IGNORE:-} ask treekey.mjs --pathspec)
  # no pathspecs (node failed, or an older treekey.mjs printed its key): a re-base
  [[ ${spec[0]:-} == . ]] && git diff --quiet "$2" "$3" -- "${spec[@]}" || return 1
  [[ $(cat "$STATE/ignored-$1" 2> /dev/null) == "$4" ]] && return 0   # once per main: merge_milestones runs again after every verify
  echo "$4" > "$STATE/ignored-$1"
  note "$1: $MAIN_BRANCH changed only in ignored paths ($(git diff --name-only "$2" "$3" | head -3 | paste -sd' ')); its verify stands"
  return 0
}

# <commit> → a commit on it whose .harness/runs/ is origin/<main>'s, built in a scratch index (no checkout). Dated as
# <commit>, so merge_one's next try for the same tag makes the same commit.
runs_as_main() {
  local idx=$STATE/runs-index.$$ t d
  rm -f "$idx"
  GIT_INDEX_FILE=$idx git read-tree "$1" && GIT_INDEX_FILE=$idx git reset -q "origin/$MAIN_BRANCH" -- .harness/runs/ > /dev/null 2>&1
  t=$(GIT_INDEX_FILE=$idx git write-tree 2>> "$STATE/run.log"); rm -f "$idx"; [[ -n $t ]] || return 1
  d=$(git log -1 --format=%cI "$1")
  GIT_AUTHOR_DATE=$d GIT_COMMITTER_DATE=$d git commit-tree "$t" -p "$1" -m "HARNESS: .harness/runs/ as $MAIN_BRANCH has it (a lane never carries the record)" 2>> "$STATE/run.log"
}

# <m> <what> <command…>: one origin step of a merge, retried with bounded backoff (ORIGIN_WAITS; HARNESS_ORIGIN_WAITS in
# tests), its stderr appended to run.log. Each failed try is a run.log line; a success after one a note; the last failure
# returns the command's exit with ORIGIN_TRIES and ORIGIN_SECS set for the caller's words. A GitHub refusal (a GraphQL:
# line, gh's own or wrapped as `pull request create failed: GraphQL: …`; gh's `is not mergeable: `, a required check or
# review; a remote rejection some hook or rule `declined`) is a decision, not an outage: one try, ORIGIN_REFUSED=1.
# ORIGIN_WAITS="" is one try. Each try runs under origin_t, a step function in this shell (it may set a variable:
# pr_open_'s PR_URL).
origin_try() {
  local m=$1 what=$2 k=1 n rc w waits err=$STATE/origin-try.$BASHPID t0=$SECONDS; shift 2
  read -ra waits <<< "${HARNESS_ORIGIN_WAITS:-${ORIGIN_WAITS-5 15 30 60 120}}"; n=$(( ${#waits[@]} + 1 ))
  ORIGIN_REFUSED=0
  while :; do
    origin_t "$@" 2> "$err"; rc=$?; cat "$err" >> "$STATE/run.log"
    ORIGIN_TRIES=$k ORIGIN_SECS=$(( SECONDS - t0 ))
    if (( rc == 0 )); then
      rm -f "$err"; (( k > 1 )) && note "$m: $what succeeded on try $k (origin unreachable for $ORIGIN_SECS s)"; return 0
    fi
    grep -qE '(^|: )GraphQL: |\[remote rejected\].*declined|is not mergeable: ' "$err" && ORIGIN_REFUSED=1
    if (( k >= n || ORIGIN_REFUSED )); then rm -f "$err"; return "$rc"; fi
    w=${waits[k-1]}; log "$m: $what failed (try $k of $n; next in $w s)"; sleep "$w"; k=$(( k + 1 ))
  done
}
# <command…> with one try's bound: an origin that takes the connection and never answers would hold the merge or record
# lock for good (git has no such limit of its own). 124: cut, a failure like any other. A function runs in this shell,
# unbounded here: it puts origin_t round its own commands.
origin_t() {
  declare -F "$1" > /dev/null && { "$@"; return; }
  timeout -k 5 "${HARNESS_ORIGIN_TRY_TIMEOUT:-${ORIGIN_TRY_TIMEOUT:-120}}" "$@"
}
fetch_main_() { origin_t git fetch -q origin "$MAIN_BRANCH" 8>&-; }
# <m> [--force]: its tag to origin through origin_try. tag-local-<m> holds it until origin has it (set first: a lane
# killed in the retries leaves the marker), so merge_one's next try carries it before the branch
tag_push() {
  local m=$1 t=run/$RUN_ID/$1; shift
  touch "$STATE/tag-local-$m"
  origin_try "$m" "push of tag $t" git push -q "$@" origin "refs/tags/$t" 8>&- || return 1
  rm -f "$STATE/tag-local-$m"
}
# <m>: what a note adds while its tag is local only (nothing once origin has it): "harness-log.md never claims a tag the origin didn't take"
tag_local_words() {
  [[ -f $STATE/tag-local-$1 ]] && printf '; tag run/%s/%s is local only (push failed %s times over %s s; see run.log)' "$RUN_ID" "$1" "${ORIGIN_TRIES:-?}" "${ORIGIN_SECS:-?}"
  return 0
}
# <tag>: origin's copy here, if it has one (an answer of none is no failure: only an outage is retried)
tag_fetch_() { local r; r=$(origin_t git ls-remote origin "refs/tags/$1" 8>&-) || return 1; [[ -z $r ]] || origin_t git fetch -q origin tag "$1" 8>&-; }
# The tag's commit, or nothing (the once-per markers and the cards' head)
tag_commit() { git rev-parse -q --verify "refs/tags/run/$RUN_ID/$1^{commit}" 2> /dev/null; }
# <m> <what> [<PR url>]: a merge past origin_try's retries (what=unknown: a merge with no reason to give, the fail-closed
# case): needs-<m> and the lane's exit words, then once per <what> while merge-failed-<m> holds it (`harness merge`
# always says so) a note, the merge_failed card and its notification. Always 1.
merge_failed() {
  local m=$1 what=$2 pr=${3:-} ref tries=${ORIGIN_TRIES:-0} secs=${ORIGIN_SECS:-0} tl=""
  local words="its merge (origin unreachable at $what)"; [[ $what == unknown ]] && tries=0 secs=0 words="its merge"
  touch "$STATE/needs-$m"
  [[ -n ${LDIR:-} ]] && printf '%s' "$words" > "$LDIR/need"
  [[ ! ${HARNESS_MERGE_ONLY:-} && $(cat "$STATE/merge-failed-$m" 2> /dev/null) == "$what" ]] && return 1
  echo "$what" > "$STATE/merge-failed-$m"; [[ -f $STATE/tag-local-$m ]] && tl=1
  if [[ $what == unknown ]]; then note "$m: its merge stopped with no reason recorded (see run.log); merged later: harness merge $RUN_ID"
  else note "$m: merge failed at $what after $tries tries over $secs s; merged later: harness merge $RUN_ID"; fi
  ref=$(needs_open merge_failed "$m" milestone="$m" what="$what" tries="$tries" secs="$secs" tag_local="$tl" head="$(tag_commit "$m")" \
    branch="harness-lane/$RUN_ID/$m" pr="$pr" log="$STATE/run.log")
  rec_commit "HARNESS: $m merge failed"; sync_record
  [[ ${HARNESS_MERGE_ONLY:-} ]] && local DESK=0   # Michael is at the terminal
  needs_you "$m" "merge failed at $what" needs.md "$ref"
  return 1
}
# <m> <what> [<PR url>]: GitHub said no: once per tag commit (merge_milestones runs again after every verify and at the
# end; `harness merge` always says so) a note, the merge_refused card and its notification. Always 1.
merge_refused_() {
  local m=$1 what=$2 url=${3:-} c ref; c=$(tag_commit "$m")
  [[ ! ${HARNESS_MERGE_ONLY:-} && $(cat "$STATE/refused-$m" 2> /dev/null) == "$c" ]] && return 1
  echo "$c" > "$STATE/refused-$m"; merge_settled "$m"   # the refusal's card speaks for it now
  if [[ -n $url ]]; then note "$m: the merge was refused; PR left open for Michael · $url"
  else note "$m: the merge was refused at $what; no PR is open (see run.log)"; fi
  ref=$(needs_open merge_refused "$m" milestone="$m" pr="$url" click="$url" what="$what" head="$c"); rec_commit "HARNESS: $m merge refused"; sync_record
  needs_notify "$ref" "$m needs Michael: merge refused${url:+ · $url}" title="[$RUN_ID] $m needs you" priority=high click="$url" kind=needs_michael
  [[ ${HARNESS_MERGE_ONLY:-} ]] || desk "$m: merge refused"   # `harness merge`: Michael is at the terminal
  return 1
}
# <m> <what> [<PR url>]: an origin step gave up: refused or an outage. Always 1.
merge_stop() { if (( ${ORIGIN_REFUSED:-0} )); then merge_refused_ "$@"; else merge_failed "$@"; fi; }
# <m> <what> <command…>: one origin step of merge_one; 1 = merge_stop has said why
merge_step() { local m=$1 what=$2; shift 2; origin_try "$m" "$what" "$@" && return 0; merge_stop "$m" "$what"; }
# <m>: nothing holds its merge up for an outage any more (it landed, it waits on Michael or a dependency for another
# reason, or another card speaks): the marker goes, and with it the needs-<m> merge_failed set. Not on a step's success:
# a fetch that works now and a main that moved would leave a verified milestone with no card at all.
merge_settled() { [[ -f $STATE/merge-failed-$1 ]] && rm -f "$STATE/merge-failed-$1" "$STATE/needs-$1"; return 0; }
# <m> <the note's words>: it is on main
merged_() { touch "$STATE/merged-$1"; merge_settled "$1"; note "$1 merged into $MAIN_BRANCH$2"; }
# <head> <m>: the head's open PR, else a new one, its URL in PR_URL (origin_try's "opening its PR": a pr view that can't
# reach GitHub reads as no PR, and the pr create after it fails too)
pr_open_() {
  PR_URL=$(origin_t $GH pr view "$1" --json url,state -q 'select(.state=="OPEN") | .url' 2> /dev/null) || PR_URL=""
  [[ $PR_URL == http* ]] || PR_URL=$(origin_t $GH pr create --base "$MAIN_BRANCH" --head "$1" --title "$RUN_ID: $2 (verified)" --body-file "$LS/pr-body.md" | tail -1)
  [[ $PR_URL == http* ]]
}

# Merge one verified milestone (its tag, the lane tip) into main through a PR. The invariant: the tree that lands on
# main is the tree that was verified, outside the paths the suite's cache key ignores (ignored_only). 0 = merged,
# proposed, or (--open) its PR open and waiting · 1 = needs Michael (conflict, refusal, an outage past the retries: each
# with its card, once; a re-base already pending says nothing new) · 3 = main moved since the verify
# (moved-<m> holds that main): its lane re-bases it (lib/lane.sh rebase), once per main, never after it needs Michael;
# `harness merge` clears moved-* and so tries once more.
# --open (a dependency not merged yet) skips that test: main moves again when the dependency lands, and the rule runs then.
merge_one() {
  local m=$1 tag=run/$RUN_ID/$1 c head url tree mn out ref t
  head=harness-merge/$RUN_ID-$m
  c=$(git rev-list -n1 "$tag") || return 1
  # retried: an outage, or another lane's fetch holding refs/remotes/origin/<main>'s lock
  merge_step "$m" "fetch of $MAIN_BRANCH" fetch_main_ || return 1
  # a tag the verify's push left local goes before the branch: forced, the local one is the verified one. A refusal (a
  # rule on run/* tags) holds no merge up: the tag was never what lands
  if [[ -f $STATE/tag-local-$m ]]; then
    if tag_push "$m" --force; then note "$m: tag $tag reached origin"
    elif (( ! ORIGIN_REFUSED )); then merge_failed "$m" "push of tag $tag"; return 1; fi
  fi
  if git merge-base --is-ancestor "$c" "origin/$MAIN_BRANCH"; then merged_ "$m" " (already there)"; return 0; fi
  mn=$(git rev-parse "origin/$MAIN_BRANCH")
  # `harness merge` after Michael merged main into the lane branch by hand (the merge_conflict card's (a)): that merge
  # is the milestone's tip, re-tagged, when it holds the verified commit and its merge_conflict record is open
  if [[ ${HARNESS_MERGE_ONLY:-} ]] && grep -qs "\"key\": \"merge_conflict:$m\"" "$STATE"/needs/*.json \
    && origin_t git fetch -q origin "harness-lane/$RUN_ID/$m" 8>&- 2> /dev/null && t=$(git rev-parse FETCH_HEAD) \
    && [[ $t != "$c" ]] && git merge-base --is-ancestor "$c" "$t"; then
    git tag -f -a "$tag" -m "harness run $RUN_ID: $m verified (v3); main merged in by hand, harness merge" "$t" > /dev/null \
      && { tag_push "$m" --force; c=$t; note "$m: main merged into its branch by hand; re-tagged $tag at ${t:0:7}$(tag_local_words "$m")"; }
  fi
  if ! out=$(git -c core.quotePath=false merge-tree --write-tree --name-only "origin/$MAIN_BRANCH" "$c" 2>/dev/null); then
    # the lane's rebase merges, resolves and verifies it (lib/resolve.sh); at the run's end (finish wrote ended) no lane
    # can, so Michael hears of it now
    if [[ ${CONFLICTS:-} == resolve && ! ${HARNESS_MERGE_ONLY:-} && ! -f $STATE/ended ]]; then
      [[ ( $(cat "$STATE/moved-$m" 2>/dev/null) == "$mn" && -f $STATE/rebase-$m ) || -f $STATE/needs-$m ]] && return 1
      # its lane's sync_main already tried this main (main_conflict open): a re-base would only say it again
      [[ $(cat "$STATE/main-conflict-$m" 2> /dev/null) == "$mn" ]] && return 1
      echo "$mn" > "$STATE/moved-$m"; return 3
    fi
    # once per main: merge_milestones runs again after every verify and at the end; `harness merge` always says so
    [[ ! ${HARNESS_MERGE_ONLY:-} && $(cat "$STATE/conflict-$m" 2>/dev/null) == "$mn" ]] && return 1
    echo "$mn" > "$STATE/conflict-$m"; merge_settled "$m"   # the conflict's card speaks for it now
    note "$m conflicts with $MAIN_BRANCH; not merged (needs Michael)"
    # the lane's branch and slot (on the coordinator LBRANCH is empty and HARNESS_WT the record worktree)
    ref=$(needs_open merge_conflict "$m" milestone="$m" files="$(conflict_files <<< "$out")" main="$mn" head="$c" \
      branch="harness-lane/$RUN_ID/$m" worktree="$(cat "$STATE/lanes/$m/slot" 2> /dev/null)")
    rec_commit "HARNESS: $m conflicts with $MAIN_BRANCH"; sync_record
    # its lane's sync_main already said this main conflicts (main_conflict): one notification for it
    [[ $(cat "$STATE/main-conflict-$m" 2> /dev/null) == "$mn" ]] || needs_you "$m" "conflicts with $MAIN_BRANCH" harness-log.md "$ref"
    return 1
  fi
  tree=${out%%$'\n'*}; rm -f "$STATE/conflict-$m"   # merges cleanly now: its merge_conflict record resolves at the next sweep
  if [[ ${2:-} != --open && $tree != "$(git rev-parse "$c^{tree}")" ]] && ! ignored_only "$m" "$c" "$tree" "$mn"; then   # main has content the lane wasn't verified with
    # once per main while its re-base is pending (rebase-<m>); a re-base cut short (its lane killed) took that marker
    # with it, and the milestone would wait silently for the next main (P2 review 4)
    [[ ( $(cat "$STATE/moved-$m" 2>/dev/null) == "$mn" && -f $STATE/rebase-$m ) || ( -f $STATE/needs-$m && ! ${HARNESS_MERGE_ONLY:-} ) ]] && return 1
    echo "$mn" > "$STATE/moved-$m"; return 3
  fi
  # lane_guard's fail-safe: a lane never carries .harness/runs/ to main (decisions/2026-10-30-lane-guard-base)
  if [[ -n $(git diff --name-only "origin/$MAIN_BRANCH...$c" -- .harness/runs/ 2> /dev/null) ]]; then
    out=$(git diff --name-only "origin/$MAIN_BRANCH...$c" -- .harness/runs/ | head -3 | paste -sd' ')
    c=$(runs_as_main "$c") || { note "$m: its .harness/runs/ changes could not be undone; not merged (see run.log)"; merge_failed "$m" unknown; return 1; }
    note "$m: the lane carried .harness/runs/ changes ($out); merged with $MAIN_BRANCH's"
  fi
  merge_step "$m" "push of $head" git push -q -f origin "$c:refs/heads/$head" 8>&- || return 1
  pr_body "$m" > "$LS/pr-body.md"; [[ $LS == "$STATE" ]] || cp "$LS/pr-body.md" "$STATE/pr-body.md"   # the last body, whichever lane (checks read it)
  PR_URL=""; merge_step "$m" "opening its PR" pr_open_ "$head" "$m" 8>&- || return 1
  url=$PR_URL
  [[ ${2:-} == --open ]] && { merge_settled "$m"; return 0; }   # a dependency hasn't merged: the PR waits for it, whatever the policy
  if [[ $MERGE_POLICY != auto && ! ${HARNESS_MERGE_ONLY:-} ]]; then touch "$STATE/proposed-$m"; merge_settled "$m"; note "$m proposed for merging · $url"; notify "$m verified · review: $url" title="[$RUN_ID] $m ready to merge" click="$url" kind=verified; return 0; fi   # harness merge lands it whatever the policy
  # a merge whose answer was lost looks like a failure, and every later try too (already merged): main decides
  if origin_try "$m" "merging its PR" "$GH" pr merge "$url" --merge --match-head-commit "$c" > /dev/null 8>&- \
    || { fetch_main_ 2> /dev/null && git merge-base --is-ancestor "$c" "origin/$MAIN_BRANCH"; }; then
    origin_t git push -q origin --delete "$head" 8>&- 2>/dev/null
    merged_ "$m" " · $url"; notify "$m merged · $url" click="$url" kind=merged
    lane_branch_gone "$m"; return 0
  fi
  merge_stop "$m" "merging its PR" "$url"
}

# [<m>] → merge every verified, unmerged milestone (or just <m>) in list order. A tag is a lane tip, so it carries no
# other milestone's unverified work: each merges on its own once every milestone it depends on (F deps) has merged;
# until then its PR is opened and waits (noted once, under pr too). v2 tags (verified under weaker rules) and proposed
# milestones (pr) merge only through `harness merge`, in the same order. Nothing under MERGE_POLICY=off.
# Under the merge lock (state/merge.lock, fd 8): a lane's verify and the coordinator's reap never merge one milestone
# twice; the second finds merged-<m>. Lock order is merge, then record (merge_one notes and commits); nothing under the
# record lock merges. Network commands close fd 8, as sync_record_'s close 9.
# Main moved under a tag: state/rebase-<m> (that main) for its lane's rebase, outside this lock. A milestone whose lane
# is alive is that lane's to merge (outside it: a reap during its re-base would find the old tag and ask for another).
merge_milestones() {
  [[ $MERGE_POLICY == off || ! -f $LIST ]] && return 0
  { flock 8; merge_milestones_ "$@"; } 8> "$STATE/merge.lock"
  return 0
}
merge_milestones_() {
  local m d wait rc ms ds; Fv ms milestones "$LIST"
  for m in $ms; do
    [[ -n ${1:-} && $m != "$1" ]] && continue
    [[ -f $STATE/merged-$m ]] && continue
    [[ $(cat "$STATE/lanes/$m/pid" 2> /dev/null) != "$$" ]] && lane_alive "$m" && continue
    if [[ -f $STATE/proposed-$m && ! ${HARNESS_MERGE_ONLY:-} ]]; then   # Michael's to merge, or `harness merge`'s
      # merged by Michael meanwhile (its PR on GitHub): merged here too, so what waits on it moves on
      git rev-parse -q --verify "refs/tags/run/$RUN_ID/$m" > /dev/null && origin_try "$m" "fetch of $MAIN_BRANCH" fetch_main_ \
        && git merge-base --is-ancestor "run/$RUN_ID/$m" "origin/$MAIN_BRANCH" && { merged_ "$m" " (by its PR)"; lane_branch_gone "$m"; }
      continue
    fi
    if ! git rev-parse -q --verify "refs/tags/run/$RUN_ID/$m" > /dev/null; then
      # `harness merge`, a verified milestone whose tag isn't here: origin's; gone there too, nothing is left to merge
      [[ ${HARNESS_MERGE_ONLY:-} && -f $STATE/verified-$m ]] || continue
      merge_step "$m" "fetch of tag run/$RUN_ID/$m" tag_fetch_ "run/$RUN_ID/$m" || continue
      [[ -n $(tag_commit "$m") ]] || { note "$m: tag run/$RUN_ID/$m is gone; not merged"; continue; }
    fi
    if [[ ! ${HARNESS_MERGE_ONLY:-} ]] && ! git tag -l --format='%(contents:subject)' "run/$RUN_ID/$m" | grep -q '(v3'; then
      [[ -f $STATE/legacy-noted ]] || { touch "$STATE/legacy-noted"; note "$m was verified by harness v2; it merges only with: harness merge $RUN_ID"; }
      continue
    fi
    wait=""; Fv ds deps "$LIST" "$m"; for d in $ds; do [[ -f $STATE/merged-$d ]] || wait+="${wait:+, }$d"; done
    if [[ -n $wait ]]; then
      merge_one "$m" --open; rc=$?   # 3: it conflicts with main; the re-base once the dependency has merged
      (( rc == 0 || rc == 3 )) && [[ ! -f $STATE/waits-$m && ! -f $STATE/proposed-$m ]] && { touch "$STATE/waits-$m"
        (( rc == 0 )) && note "$m verified; its PR waits for $wait to merge" || note "$m verified; it conflicts with $MAIN_BRANCH and is re-based once $wait has merged"; }
      continue
    fi
    merge_one "$m"; (( $? == 3 )) && cp "$STATE/moved-$m" "$STATE/rebase-$m"
  done
  return 0
}

# <m>: a merged milestone's lane branch goes, on the origin at once and here once no live lane has it checked out (a
# lane merging its own milestone leaves its local branch to the coordinator's reap); a closed lane's slot is detached
# from it first. Only what its merged tag or main holds (a fix Michael pushed onto it after the merge stays), only from
# this run's slots (a checkout of Michael's with it checked out keeps it), the origin's under a lease on the tip seen.
# Noted once, when something went. branch -D writes .git/config, which git locks without waiting: once more after a
# second (another run of the project may be writing it)
lane_branch_gone() {
  local m=$1 b=harness-lane/$RUN_ID/$1 w r tip gone=0 od=0 left=""
  tip=$(git rev-parse -q --verify "refs/tags/run/$RUN_ID/$m^{commit}") || tip=""
  held_() { { [[ -n $tip ]] && git merge-base --is-ancestor "$1" "$tip" 2> /dev/null; } || git merge-base --is-ancestor "$1" "origin/$MAIN_BRANCH" 2> /dev/null; }
  r=$(origin_t git ls-remote origin "refs/heads/$b" 8>&- 9>&- 2> /dev/null | cut -f1)
  if [[ -n $r ]]; then
    if held_ "$r" && origin_t git push -q --force-with-lease="refs/heads/$b:$r" origin ":refs/heads/$b" 8>&- 9>&- 2>> "$STATE/run.log"; then gone=1 od=1
    else log "lane $m: $b kept on origin (commits its merge doesn't hold, or the push failed)"; fi
  fi
  if git rev-parse -q --verify "refs/heads/$b" > /dev/null; then
    w=$(git worktree list --porcelain | awk -v b="branch refs/heads/$b" '/^worktree / { w = substr($0, 10) } $0 == b { print w; exit }')
    if [[ -n $w ]] && lane_alive "$m"; then return 0
    elif ! held_ "refs/heads/$b"; then log "lane $m: $b kept here (commits its merge doesn't hold)"
    elif [[ -n $w && $w != "$WT_ROOT_DIR/lanes/$RUN_ID/slot-"* ]]; then log "lane $m: $b kept here (checked out in $w)"
    elif [[ -n $w ]] && ! git -C "$w" checkout -q --detach 2>> "$STATE/run.log"; then log "lane $m: $b kept here (its slot $w would not detach)"
    elif git branch -q -D "$b" 2> /dev/null || { sleep 1; git branch -q -D "$b" 2>> "$STATE/run.log"; }; then gone=1
    else log "lane $m: could not delete $b here (see run.log)"; fi
  fi
  (( gone )) || return 0
  git rev-parse -q --verify "refs/heads/$b" > /dev/null && left=" here"
  [[ -n $r ]] && (( ! od )) && left+="${left:+ and} on origin"
  note "lane $m: branch $b deleted (merged)${left:+; kept$left (see run.log)}"
  return 0
}

# Pull Michael's phone edits (INBOX.md) into the record, push its commits. Never rewrites history. 9>&-: a network
# command never holds the lock past this call (an ssh ControlPersist master would keep fd 9).
sync_record_() {
  if origin_t git -C "$RWT" fetch -q origin "$RBRANCH" 8>&- 9>&- 2> /dev/null; then
    git -C "$RWT" merge -q --ff-only "origin/$RBRANCH" 2> /dev/null \
      || git -C "$RWT" merge -q --no-edit "origin/$RBRANCH" > /dev/null 2>&1 \
      || { git -C "$RWT" merge --abort 2> /dev/null; log "remote edits on $RBRANCH conflict with local work; kept local"; }
  fi
  PUSH_NOTE=""
  if origin_t git -C "$RWT" push -q -u origin "$RBRANCH" 8>&- 9>&- 2>> "$STATE/run.log"; then
    push_streak "$STATE/push-failing" ok "record branch" "$RBRANCH"
  else
    log "push of $RBRANCH failed"; push_streak "$STATE/push-failing" failed "record branch" "$RBRANCH"
  fi
}
# <marker> ok|failed <who> <branch>: a push streak, one note at its start and one at its end, in PUSH_NOTE for the caller
# to say outside the lock; the marker holds "<epoch of its start> <failures>"
push_streak() {
  local f=$1 at=0 n=0; [[ -f $f ]] && read -r at n < "$f"
  if [[ $2 == ok ]]; then
    [[ -f $f ]] && { rm -f "$f"; PUSH_NOTE="$3: push of $4 succeeded after $n failures over $(( ( $(date +%s) - at ) / 60 )) min"; }
  elif [[ -f $f ]]; then echo "$at $(( n + 1 ))" > "$f"
  else echo "$(date +%s) 1" > "$f"; PUSH_NOTE="$3: push of $4 failed; retrying at every sync (see run.log)"; fi
  return 0
}
# Its streak note is committed at once (a note left over would keep gc from the worktree); one that says the streak
# ended goes to origin too, so harness-log.md there shows it.
sync_record() {
  record sync_record_; local n=${PUSH_NOTE:-}; PUSH_NOTE=""
  [[ -n $n ]] || return 0
  note "$n"; rec_commit "HARNESS: $n"
  [[ $n == *succeeded* ]] && sync_record
  return 0
}
# no -u, as slot_open's --no-track: a lane never writes .git/config, which git locks without waiting (a coordinator
# opening another slot meanwhile would fail); nothing reads a lane branch's upstream. Its streak's notes go with the
# record's next commit; its commits reach origin at its next sync.
sync_lane() {
  [[ -n ${LBRANCH:-} ]] || return 0
  local m=${LBRANCH##*/}; PUSH_NOTE=""
  if origin_t git -C "$SLOT" push -q origin "$LBRANCH" 2>> "$STATE/run.log"; then
    push_streak "$STATE/lane-push-failing-$m" ok "lane $m" "$LBRANCH"
  else
    log "push of $LBRANCH failed"; push_streak "$STATE/lane-push-failing-$m" failed "lane $m" "$LBRANCH"
  fi
  [[ -z $PUSH_NOTE ]] || note "$PUSH_NOTE"
  PUSH_NOTE=""
}

# <worktree>: the sorted-union merge driver (lib/merge-sorted.sh) in that worktree's own config, so a project's
# `.gitattributes` `merge=sorted-union` works in the harness's checkouts and never in Michael's (decisions/2026-10-29-conflict-resolution)
merge_drivers() {
  [[ $(git -C "$1" config extensions.worktreeConfig) == true ]] || git -C "$1" config extensions.worktreeConfig true
  git -C "$1" config --worktree merge.sorted-union.name "sorted one-per-line list (harness)"
  git -C "$1" config --worktree merge.sorted-union.driver "$HARNESS_HOME/lib/merge-sorted.sh %O %A %B"
}

# <m> [<k>] → slot k (0) on harness-lane/<run>/<m>, cwd there; HARNESS_WT and HARNESS_BRANCH name it for sessions.
# The coordinator opens it, then starts the lane process in it (lib/lane.sh). A lane resumes its branch (the newer of
# the box's and the origin's, both merged if they diverged), else starts from BASE_REF (harness start --base) or
# origin/main, then merges the tag of every dependency main doesn't have yet. 1 = its base
# conflicts or the slot can't be checked out (needs-<m>, noted: the loop would only pick it again), cwd back in the
# record worktree.
slot_open() {
  local m=$1 k=${2:-0} b=harness-lane/$RUN_ID/$1 base fold dep tag first=0 sha
  SLOT=$WT_ROOT_DIR/lanes/$RUN_ID/slot-$k
  LBRANCH="" LANE=""   # from here the slot leaves the last lane's branch: only a full open names a lane again
  if [[ -d $SLOT ]]; then   # a segment killed mid-session left its work here: committed before the base is chosen, so it stays
    local cur; cur=$(git -C "$SLOT" branch --show-current)
    # a lane killed mid-merge (its resolve session) left MERGE_HEAD: undone, never committed as WIP with its markers
    git -C "$SLOT" rev-parse -q --verify MERGE_HEAD > /dev/null && { git -C "$SLOT" reset -q --hard HEAD; note "$m: its slot-$k had a merge left in progress; undone"; }
    ( cd "$SLOT" && commit_all "WIP: uncommitted in the slot when it was reused (harness)" )
    [[ $cur == harness-lane/* ]] && origin_t git -C "$SLOT" push -q origin "$cur" 2> /dev/null
  fi
  origin_t git -C "$RWT" fetch -q origin 2> /dev/null
  base=${BASE_REF:-origin/$MAIN_BRANCH} fold=""
  # a lane resumes its branch (harness continue, a segment that ended mid-milestone): the origin's, which may be ahead
  # (Michael pushed a fix by hand); the box's when it has commits the origin lacks (a failed push); both when they diverged
  if git -C "$RWT" rev-parse -q --verify "refs/remotes/origin/$b" > /dev/null; then
    base=origin/$b
    if git -C "$RWT" rev-parse -q --verify "refs/heads/$b" > /dev/null && ! git -C "$RWT" merge-base --is-ancestor "refs/heads/$b" "refs/remotes/origin/$b"; then
      base=$b; git -C "$RWT" merge-base --is-ancestor "refs/remotes/origin/$b" "refs/heads/$b" || fold=origin/$b
    fi
  elif git -C "$RWT" rev-parse -q --verify "refs/heads/$b" > /dev/null; then base=$b; fi
  # a re-base (LANE_MERGE=1): the verified commit, whatever the branch holds; nothing merged into it here
  [[ ${LANE_MERGE:-0} == 1 ]] && base=run/$RUN_ID/$m fold=""
  if [[ ! -d $SLOT ]]; then
    mkdir -p "${SLOT%/*}"; first=1
    git -C "$RWT" worktree add -q -f --no-track "$SLOT" -B "$b" "$base" 2>> "$STATE/run.log" || { slot_fail "$m" "worktree add of $SLOT"; return 1; }
  else
    git -C "$SLOT" checkout -q -f --no-track -B "$b" "$base" 2>> "$STATE/run.log" || { slot_fail "$m" "checkout of $b"; return 1; }
  fi
  if [[ -n $fold ]]; then
    if ! git -C "$SLOT" merge -q --no-edit "$fold" > /dev/null 2>&1; then
      # a base conflict stays Michael's: this runs in the coordinator, where a resolve session would block every lane (decisions/2026-10-29-conflict-resolution)
      git -C "$SLOT" merge --abort 2> /dev/null
      note "$m: $b here and on origin diverged and conflict; needs Michael"; base_conflict "$m" "$fold" diverged
      cd "$RWT" || return 1; return 1
    fi
    note "$m: $b here and on origin had diverged; merged origin's into it"
  fi
  for dep in $( [[ ${LANE_MERGE:-0} == 1 ]] || F deps "$LIST" "$m"); do
    tag=run/$RUN_ID/$dep
    git -C "$SLOT" rev-parse -q --verify "refs/tags/$tag" > /dev/null || continue
    git -C "$SLOT" merge-base --is-ancestor "$tag" "origin/$MAIN_BRANCH" 2> /dev/null && continue
    git -C "$SLOT" merge-base --is-ancestor "$tag" HEAD && continue
    if ! git -C "$SLOT" merge -q --no-edit "$tag" > /dev/null 2>&1; then
      git -C "$SLOT" merge --abort 2> /dev/null
      note "$m: its base conflicts ($dep vs $MAIN_BRANCH); needs Michael"; base_conflict "$m" "$tag" dependency
      cd "$RWT" || return 1; return 1
    fi
  done
  # the default lane (features in no milestone) is never verified or tagged (D7), so once its features pass a later
  # lane starts on its branch, as before lanes the next milestone carried that code (review of P1)
  dep=harness-lane/$RUN_ID/default
  git -C "$SLOT" rev-parse -q --verify "refs/remotes/origin/$dep" > /dev/null && dep=origin/$dep
  if [[ $m != default && ${LANE_MERGE:-0} != 1 ]] && F milestone-done "$LIST" default && git -C "$SLOT" rev-parse -q --verify "$dep^{commit}" > /dev/null \
    && ! git -C "$SLOT" merge-base --is-ancestor "$dep" HEAD; then
    if ! git -C "$SLOT" merge -q --no-edit "$dep" > /dev/null 2>&1; then
      git -C "$SLOT" merge --abort 2> /dev/null
      note "$m: its base conflicts (default vs $MAIN_BRANCH); needs Michael"; base_conflict "$m" "$dep" default
      cd "$RWT" || return 1; return 1
    fi
  fi
  # the copy of the record is invisible to the slot's git (a per-worktree excludes file, never .git/info/exclude,
  # which the record worktree shares), plus the user's own global excludes the worktree value would shadow
  mkdir -p "$STATE/lanes/$m"
  { echo ".harness/runs/"; cat "$(git config --global --path core.excludesFile 2> /dev/null || echo "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore")" 2> /dev/null; } > "$STATE/lanes/$m/exclude"
  merge_drivers "$SLOT"
  git -C "$SLOT" config --worktree core.excludesFile "$STATE/lanes/$m/exclude"
  echo "$SLOT" > "$STATE/lanes/$m/slot"   # lib/prompt.sh as a command renders a lane's prompt from it
  LBRANCH=$b LANE=$m; lane_cd
  sha=$(git rev-parse --short HEAD)
  note "lane $m opened (slot $k, port ${LANE_PORT:-$PORT}, from $sha$( (( first )) || echo ", slot reused"))"
}
slot_fail() { note "$1: its slot failed ($2; see run.log); needs Michael"; base_conflict "$1" "" slot; cd "$RWT" || :; }
# <m> <what conflicted (a ref git merge takes)> <variant>: needs-<m> and its base_conflict record, the slot its worktree
base_conflict() {
  touch "$STATE/needs-$1"
  needs_open base_conflict "$1" milestone="$1" with="$2" variant="$3" worktree="$SLOT" branch="harness-lane/$RUN_ID/$1" > /dev/null
}
lane_cd() { cd "$SLOT" || return 1; export HARNESS_WT=$SLOT HARNESS_BRANCH=$LBRANCH; SLIST=$SLOT/$RUN_DIR/feature_list.json; }
rec_cd() { cd "$RWT" || return 1; export HARNESS_WT=$RWT HARNESS_BRANCH=$RBRANCH; SLIST=$LIST; }

# The record copied into the slot for the next session; the snapshot and the INBOX it is judged against are the copy's,
# so a phone edit merged into the record meanwhile is never the session's. A record tracked at the slot's base (a run
# whose record reached main before lanes) is marked skip-worktree, so the session's `git add -A` stages none of it.
materialize_() {
  rm -rf "${SLOT:?}/$RUN_DIR"; mkdir -p "$SLOT/$RUN_DIR"; cp -a "$REC/." "$SLOT/$RUN_DIR/"
  git -C "$SLOT" ls-files -z -- "$RUN_DIR" | (cd "$SLOT" && xargs -0 -r git update-index --skip-worktree)
  F snapshot "$SLIST" > "$LS/before.json"
  cp "$SLOT/$RUN_DIR/INBOX.md" "$LS/inbox-before.md" 2> /dev/null || : > "$LS/inbox-before.md"
}
materialize() { record materialize_; }
# The pack and the slot's copy under one lock: between two, another lane's context_ could overwrite $REC/context.md and
# this lane's session would read that feature's pack first (P2 review 3)
pack_and_copy_() { context_ "$@"; materialize_; }
pack_and_copy() { record pack_and_copy_ "$@"; }
# The copy goes; the slot is clean again (the next checkout -B and gc rely on it).
unmaterialize() {
  [[ -n ${SLOT:-} && -d $SLOT/$RUN_DIR ]] || return 0
  local tracked; tracked=$(git -C "$SLOT" ls-files -- "$RUN_DIR")
  rm -rf "${SLOT:?}/$RUN_DIR"
  [[ -n $tracked ]] && { git -C "$SLOT" ls-files -z -- "$RUN_DIR" | (cd "$SLOT" && xargs -0 -r git update-index --no-skip-worktree); git -C "$SLOT" checkout -q HEAD -- "$RUN_DIR"; }
  return 0
}

# The lines a session added above "## Answers" in its copy go into the record's INBOX.md above that line (at the end
# they would sit under the answers and change answers_hash, unparking at once); saved for the park's notification.
take_question_() {
  local q; q=$(ask inbox.mjs question "$LS/inbox-before.md" "$SLOT/$RUN_DIR/INBOX.md" 2> /dev/null)
  printf '%s' "$q" > "$LS/question"
  [[ -n $q ]] || return 0
  printf '%s' "$q" | node "$INBOX_MJS" insert "$REC/INBOX.md"
}
take_question() { record take_question_; }

# A question written inside the steering comment is hidden on GitHub, and a `## Answers` it splits off there was read
# as the heading (n8n-home 2026-10-27): the comment goes back as it was, the question above "## Answers"
# (decisions/2026-10-27-question-locations). On the copy the session wrote: the slot's for a lane, the record's for the
# initializer.
inbox_repair() {   # <who> <INBOX before the session> <the INBOX it left>
  [[ -f $3 ]] || return 0
  ask inbox.mjs repair "$2" "$3" 2>> "$STATE/run.log"
  (( $? == 3 )) && note "INBOX.md: $1's question was inside the steering comment (hidden on GitHub); moved below it"
  return 0
}

# <start commit> <who>: a lane commit that touched .harness/runs/ (a session that `git add -f`'d the copy) is reverted
# by a new commit; the record never takes anything from it. The base is the lane's merge-base with main, never the
# session's start: a session that merged main itself brought main's records in, and those are main's
# (decisions/2026-10-30-lane-guard-base). Only the index goes back: the copy on disk is what F repair and the claim read.
lane_guard() {
  local mb; mb=$(git merge-base HEAD "origin/$MAIN_BRANCH" 2> /dev/null) || mb=$1
  main_merged "$1" && note "$2: the session merged $MAIN_BRANCH into its branch itself (the driver does that, at verify)"
  [[ -n $(git diff --name-only "$mb" HEAD -- .harness/runs/ 2> /dev/null) ]] || return 0
  git reset -q "$mb" -- .harness/runs/ > /dev/null 2>&1
  git commit -q -m "HARNESS: reverted edits a $2 session may not make"
  # other runs' records on disk as committed again; the copy, tracked now if the session merged its run's earlier
  # record in, kept but out of every later `git add -A` (as materialize_ marks it)
  git checkout -q -- .harness/runs/ ":!$RUN_DIR" 2> /dev/null
  git ls-files -z -- "$RUN_DIR" | xargs -0 -r git update-index --skip-worktree
  note "$2: a lane commit touched the run record; reverted"
  sync_lane
}
# A coding session's edit to the project's memory goes back, one note per file: the curator is its one writer
# (decisions/2026-11-07-memory-one-writer). Base: the merge-base with main, as lane_guard's, so the CLAUDE.md lines a
# session's own merge of main brought in stay main's; <start commit> when there is none. The caller pushes.
memory_guard() {   # start who
  local mb f; mb=$(git merge-base HEAD "origin/$MAIN_BRANCH" 2> /dev/null) || mb=$1
  while IFS= read -r f; do
    [[ -n $f ]] && note "$2: reverted its $f edit (project memory is the curator's; say it in the entry)"
  done < <(restrict "$mb" memory "$2")
  return 0
}
# <start commit>: a merge since it whose second parent is main's history (a session's own `git merge origin/main`)
main_merged() {
  local c p1 p2
  while read -r c p1 p2 _; do
    [[ -n $p2 ]] && git merge-base --is-ancestor "$p2" "origin/$MAIN_BRANCH" 2> /dev/null && return 0
  done < <(git rev-list --merges --parents "$1..HEAD" 2> /dev/null)
  return 1
}

# Every slot goes at the end of a segment (its lane's branch is pushed: a continuation reopens it); merged lanes'
# branches go, locally and on the origin; unverified ones stay.
slot_close() {
  local s
  rec_cd
  for s in "$WT_ROOT_DIR/lanes/$RUN_ID"/slot-*; do
    [[ -d $s ]] || continue
    git -C "$RWT" worktree remove --force "$s" 2>> "$STATE/run.log" || log "slot: could not remove $s"
  done
  git -C "$RWT" worktree prune
  rmdir "$WT_ROOT_DIR/lanes/$RUN_ID" "$WT_ROOT_DIR/lanes" 2> /dev/null
  LBRANCH="" LANE=""
  local f m b
  for f in "$STATE"/merged-*; do   # most went when they merged (lane_branch_gone); what a failed push or a crash left
    [[ -f $f ]] || continue; m=${f##*/merged-} b=harness-lane/$RUN_ID/$m
    git rev-parse -q --verify "refs/heads/$b" > /dev/null || git rev-parse -q --verify "refs/remotes/origin/$b" > /dev/null || continue
    lane_branch_gone "$m"
  done
  # a lane opened and never pushed (the run ended before its first session) that carries nothing main lacks is litter
  for b in $(git -C "$RWT" for-each-ref --format='%(refname:short)' "refs/heads/harness-lane/$RUN_ID"); do
    git -C "$RWT" rev-parse -q --verify "refs/remotes/origin/$b" > /dev/null && continue
    git -C "$RWT" merge-base --is-ancestor "$b" "origin/$MAIN_BRANCH" 2> /dev/null && git -C "$RWT" branch -q -D "$b"
  done
  return 0
}
