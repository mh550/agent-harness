# Usage: source lib/scope.sh; scope_run <unit> <mem-high> <mem-max> <cmd…> · scope_stop <unit> · scope_peak <unit> ·
#   scope_left <unit> · scope_capped <unit> <mem-max> · scope_unit <run> <role> · scope_bytes <size> · dur_s <duration> · scope_available ·
#   mem_available_gb [<meminfo>] · mem_gate (notes through the caller's note)
# Capped transient systemd user scopes (docs/plans/2026-10-25-L1-capped-sessions.md §1-§2): bare when the user bus is
# missing. systemd-run and systemctl are ${HARNESS_SYSTEMD_RUN:-systemd-run} and ${HARNESS_SYSTEMCTL:-systemctl}, read
# at call time (the suite points them at its stubs).

# Inside the scope, around the command: an emptied scope is gone at once (--collect), so the wrapper reads the peak
# and the task count while it still holds the scope. $1 unit, $2 dir, $3 systemctl, then the command. No .started
# marker means the command never ran (exit 254 when the dir isn't writable), so scope_run may run it bare: never twice.
SCOPE_WRAP='touch "$2/$1.started" 2> /dev/null || exit 254; "${@:4}"; rc=$?; "$3" --user show -p MemoryPeak,ControlGroup,TasksCurrent "$1.scope" 2> /dev/null > "$2/$1.show"; exit $rc'

scope_dir() { echo "${HARNESS_SCRATCH:-${TMPDIR:-/tmp}}/scopes"; }

# The probe, once per process: SCOPE_OK caches 1/0 (unset it to probe again). Call it outside $(…) to keep the answer.
scope_available() {
  [[ -n ${SCOPE_OK:-} ]] || { "${HARNESS_SYSTEMD_RUN:-systemd-run}" --user --scope --quiet true > /dev/null 2>&1 && SCOPE_OK=1 || SCOPE_OK=0; }
  [[ $SCOPE_OK == 1 ]]
}

# harness-<run>-<role>, the run id reduced to [A-Za-z0-9_-]: "." is legal in a unit name but would blur harness-<run>-* globs
scope_unit() { local r=${1//[^A-Za-z0-9_-]/-}; echo "harness-$r${2:+-$2}"; }

# 6G → bytes, 1024-based as systemd reads K/M/G/T; a bare number is bytes
scope_bytes() { local n=${1%[KMGTkmgt]}; case ${1##*[0-9]} in [Kk]) echo $(( n << 10 )) ;; [Mm]) echo $(( n << 20 )) ;; [Gg]) echo $(( n << 30 )) ;; [Tt]) echo $(( n << 40 )) ;; *) echo "$n" ;; esac; }

# 15m → 900: the whole-number durations timeout(1) takes (s m h d; bare = seconds); nothing and exit 1 for any other
dur_s() { [[ $1 =~ ^([0-9]+)([smhd]?)$ ]] || return 1; local n=${BASH_REMATCH[1]}; case ${BASH_REMATCH[2]} in m) echo $(( n * 60 )) ;; h) echo $(( n * 3600 )) ;; d) echo $(( n * 86400 )) ;; *) echo "$n" ;; esac; }

# The command's exit code. An empty <mem-high> leaves MemoryHigh out (it throttles near the cap instead of killing).
# SCOPE_BARE says why a call with the probe passed still ran bare (empty when scoped), for the caller's note.
# OOMPolicy=continue: a cap kill takes only its victim, so the wrapper lives to record the peak and pass the 137 on.
# --description: otherwise systemd describes the unit by its whole command line (a session's prompt) in the journal.
scope_run() {
  local unit=$1 high=$2 max=$3 dir rc; shift 3; SCOPE_BARE=""
  scope_available || { "$@"; return; }
  dir=$(scope_dir); mkdir -p "$dir"; rm -f "$dir/$unit.started" "$dir/$unit.show"
  local props=(-p "MemoryMax=$max" -p "MemorySwapMax=${SESSION_SWAP_MAX:-1G}" -p OOMPolicy=continue)
  [[ -n $high ]] && props=(-p "MemoryHigh=$high" "${props[@]}")
  "${HARNESS_SYSTEMD_RUN:-systemd-run}" --user --scope --collect --quiet --unit="$unit" --description="$unit" "${props[@]}" \
    bash -c "$SCOPE_WRAP" _ "$unit" "$dir" "${HARNESS_SYSTEMCTL:-systemctl}" "$@"
  rc=$?
  [[ -f $dir/$unit.started ]] && return $rc
  if (( rc == 254 )); then SCOPE_BARE="$dir is not writable"
  else SCOPE_BARE="systemd-run failed (exit $rc)"; fi   # the bus went away, or systemd refused the unit
  echo "scope_run: $SCOPE_BARE; running bare" >&2
  "$@"
}

# Stops what the scope still holds; a unit already gone (exit 5, "not loaded") counts as done.
scope_stop() {
  scope_available || return 0
  "${HARNESS_SYSTEMCTL:-systemctl}" --user stop "$1.scope" 2> /dev/null; local rc=$?
  (( rc == 5 )) && return 0; return $rc
}

# <unit> <key>: the value from the wrapper's .show, else from a live show; by key, since systemd picks the order
scope_prop() {
  local f; f=$(scope_dir)/$1.show
  if [[ -f $f ]]; then sed -n "s/^$2=//p" "$f"
  else "${HARNESS_SYSTEMCTL:-systemctl}" --user show -p "$2" "$1.scope" 2> /dev/null | sed -n "s/^$2=//p"; fi
}

# MemoryPeak in whole MB, rounded; nothing and exit 1 when uncapped, gone or [not set]
scope_peak() {
  scope_available || return 1
  local b; b=$(scope_prop "$1" MemoryPeak); [[ $b =~ ^[0-9]+$ ]] || return 1
  echo $(( (b + 524288) / 1048576 ))
}

# Tasks the command left running: TasksCurrent less the wrapper's bash and its systemctl (0 when unknown)
scope_left() {
  local n; scope_available && n=$(scope_prop "$1" TasksCurrent)
  [[ ${n:-} =~ ^[0-9]+$ ]] && (( n > 2 )) && echo $(( n - 2 )) || echo 0
}

# exit 0 when the peak reached <mem-max>: the kernel's OOM kill at the cap
scope_capped() {
  scope_available || return 1
  local b m; b=$(scope_prop "$1" MemoryPeak) m=$(scope_bytes "$2"); [[ $b =~ ^[0-9]+$ && $m =~ ^[0-9]+$ ]] && (( b >= m ))
}

# MemAvailable of <meminfo> (default ${HARNESS_MEMINFO:-/proc/meminfo}) in whole GB, floored; exit 1 without the line
mem_available_gb() {
  local kb; kb=$(awk '$1 == "MemAvailable:" { print $2; exit }' "${1:-${HARNESS_MEMINFO:-/proc/meminfo}}" 2> /dev/null)
  [[ $kb =~ ^[0-9]+$ ]] || return 1; echo $(( kb / 1048576 ))
}

# Before a session (decisions/2026-10-25-memory-gate): under MEM_MIN_AVAILABLE_GB, note it, stop the run's services
# (services_down, when the caller has one), poll every ${HARNESS_MEM_POLL:-300} s up to MEM_WAIT_MAX, then start
# anyway: the session's cap protects the box, and a run that never starts helps nobody. Unreadable → no gate.
# Exit 0 when it passed at once, 1 after a wait: the caller re-checks what the wait made stale (deadline, stop, clock).
mem_gate() {
  local gb waited=0 max poll=${HARNESS_MEM_POLL:-300} s; (( poll > 0 )) || poll=1   # 0 would never advance the wait
  gb=$(mem_available_gb) && (( gb < MEM_MIN_AVAILABLE_GB )) || return 0
  note "memory: $gb GB available, under MEM_MIN_AVAILABLE_GB=$MEM_MIN_AVAILABLE_GB; waiting up to $MEM_WAIT_MAX"
  declare -F services_down > /dev/null && services_down "memory wait"
  max=$(dur_s "$MEM_WAIT_MAX") || max=1800
  while :; do   # first right after services_down: what it freed may be enough
    gb=$(mem_available_gb) || return 0
    (( gb >= MEM_MIN_AVAILABLE_GB )) && { note "memory: $gb GB available after $waited s; starting the session"; return 1; }
    (( waited < max )) || break
    s=$(( poll < max - waited ? poll : max - waited )); sleep "$s"; waited=$(( waited + s ))
  done
  note "memory still at $gb GB after $MEM_WAIT_MAX; starting the session anyway (its cap protects the box)"; return 1
}
