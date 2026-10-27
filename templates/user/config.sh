# ~/.config/harness/config.sh — your settings for every project (bash, sourced). Layers, later wins: the harness
# defaults (lib/config.sh, every setting and its default) → this file → <project>/.harness/config.sh → the run's options.
# Start from this file: mkdir -p ~/.config/harness && cp templates/user/config.sh ~/.config/harness/config.sh

# Notifications: NTFY_URL (the harness posts itself: title, priority, click, actions) or NOTIFY_CMD. NTFY_URL wins.
# NTFY_URL=https://ntfy.sh/<your private topic>
# NTFY_TOKEN=<access token>          # optional; sent as "Authorization: Bearer …", never logged
# NOTIFY_CMD='curl -s -H "Title: $HARNESS_NOTIFY_TITLE" -d "$1" https://ntfy.sh/<topic>'   # $1 = "[<run>] <message>"

# "Answer with Claude" on a park's notification opens this: your Remote Control environment's URL from the Claude app.
# DESK_URL=<the URL>                 # no "," or ";" in it (they split ntfy's Actions header)

# The desk: a Remote Control claude the harness starts in tmux (h-desk) when a run needs you; its notification opens it.
# DESK=0                             # 1 = start one on a park, a blocked or waiting run end, verify or a merge needing
#                                    #     you, and a debrief with Needs Michael. Try `harness desk <run> --why test` first.
# DESK_MODEL=opus                    # the desk session's model: fable, opus, sonnet, haiku or a claude-… id

# A milestone's review feature is sized by its diff (git diff --shortstat origin/<main>...HEAD, the run directory left out).
# REVIEW_OPUS_LINES=400              # changed lines (insertions + deletions): under it the review runs on sonnet, at or over on opus
# REVIEW_ESCALATE_MODEL=opus         # a sonnet review that reports a Critical or Important finding gets one round on this (no attempt)

# MAX_PARALLEL_RUNS=1                # runs alive at once (1 = one after another); the queue runner re-reads it each poll,
#                                    #     and lowering it stops no running run (an entry waits until fewer are alive)

# context.md, the bounded pack of the run's journal a session reads first (failed verify rows lead a verify's pack).
# CONTEXT_PACK_BYTES=8192            # a coding session's pack; whole bytes, at least 1024
# CONTEXT_PACK_BYTES_VERIFY=16384    # a verify session's pack (raising the first doesn't raise this one: set both)

# Each claude session runs in its own systemd user scope (harness-<run>-s<n>); without user systemd, uncapped.
# SESSION_MEMORY_HIGH=5G             # throttled above this
# SESSION_MEMORY_MAX=6G              # killed at this (exit 137; the attempt counts)
# SESSION_SWAP_MAX=1G                # swap the scope may use (check.sh's scopes always get 1G)
# Each check.sh run (full or subset, the driver's or a session's) runs in its own scope, harness-<run>-check-<pid>.
# CHECK_MEMORY_MAX=3G                # killed at this: "check: RED (killed at its 3G memory cap, …)"
# CHECK_TIMEOUT=15m                  # then TERM, KILL 30 s later: "check: RED (timed out after 15m, …)"
# The project's init runs in the run's services scope, harness-<run>-svc: what it backgrounds (a dev server) stays there.
# INIT_TIMEOUT=10m                   # the init itself, then TERM, KILL 10 s later; servers it left when it returned keep running
# SVC_MEMORY_MAX=3G                  # the services scope is killed at this (no MemoryHigh: a runaway server dies, not crawls)
# SVC_IDLE_STOP_MIN=10               # a usage-limit wait longer than this (minutes) stops the services first; the next init starts them
# TMUX_KEEP_HOURS=24                 # whole hours a tmux-started run's session (h-<run>) stays after its driver exits; 0 = closes at once
# DEPS_DIRS="node_modules .next .next-check .venv"   # `harness gc <project> --deps` deletes these (paths in the worktree) in ended runs' worktrees
# KEEP_SCRATCH=0                     # 1 = a finished run keeps /tmp/harness/<project>/<run> (debugging); 0 = finish deletes it
# TEARDOWN_CMD=.harness/teardown.sh # per project (its .harness/config.sh), not here: run before the services scope stops; the default when executable
# Before each init, coding and verify session, the driver checks MemAvailable; under the minimum it waits, then starts anyway.
# MEM_MIN_AVAILABLE_GB=5             # whole GB; under it: note, stop the run's services, poll every 5 minutes
# MEM_WAIT_MAX=30m                   # then the session starts anyway, with a note (its cap protects the box)
