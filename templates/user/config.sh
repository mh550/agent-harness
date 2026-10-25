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

# Each claude session runs in its own systemd user scope (harness-<run>-s<n>); without user systemd, uncapped.
# SESSION_MEMORY_HIGH=5G             # throttled above this
# SESSION_MEMORY_MAX=6G              # killed at this (exit 137; the attempt counts)
# SESSION_SWAP_MAX=1G                # swap the scope may use (suites' scopes too)
