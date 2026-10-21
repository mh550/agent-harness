# ~/.config/harness/config.sh — your settings for every project (bash, sourced). Layers, later wins: the harness
# defaults (lib/config.sh, every setting and its default) → this file → <project>/.harness/config.sh → the run's options.
# Start from this file: mkdir -p ~/.config/harness && cp templates/user/config.sh ~/.config/harness/config.sh

# Notifications: NTFY_URL (the harness posts itself: title, priority, click, actions) or NOTIFY_CMD. NTFY_URL wins.
# NTFY_URL=https://ntfy.sh/<your private topic>
# NTFY_TOKEN=<access token>          # optional; sent as "Authorization: Bearer …", never logged
# NOTIFY_CMD='curl -s -H "Title: $HARNESS_NOTIFY_TITLE" -d "$1" https://ntfy.sh/<topic>'   # $1 = "[<run>] <message>"

# "Answer with Claude" on a park's notification opens this: your Remote Control environment's URL from the Claude app.
# DESK_URL=<the URL>                 # no "," or ";" in it (they split ntfy's Actions header)

# The desk (P3, not built yet): a Remote Control session the harness starts when a run needs you.
# DESK=0                             # 1 = start one on a park, a blocked or waiting run end, verify or a merge needing you
# DESK_MODEL=opus
