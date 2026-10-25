#!/usr/bin/env bash
# Usage: setup/apply-2026-10-24.sh [--dry-run]   (the permissions policy: docs/plans/2026-10-24-handoff.md, chunk 2)
# Re-run it after any change to templates/user/ (2026-10-25: secrets denies for .env.*local, voice-concierge, lk).
# Installs templates/user/{settings.permissions.json,CLAUDE.md,config.merge-policy.sh} and moves the n8n MCP servers
# from user scope to ~/projects/n8n-home's .mcp.json. --dry-run prints every change and writes nothing. Safe to re-run:
# a step already applied says "unchanged". Every file it changes is copied to ~/projects/backups/ first.
set -uo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TPL=$REPO/templates/user
DRY=0
case "${1:-}" in
  --dry-run) DRY=1 ;;
  "") ;;
  *) echo "usage: $0 [--dry-run]" >&2; exit 2 ;;
esac
SETTINGS=$HOME/.claude/settings.json
USER_MD=$HOME/.claude/CLAUDE.md
HCONF=${HARNESS_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/harness/config.sh}   # the path lib/config.sh reads
CLAUDE_JSON=$HOME/.claude.json
N8N_HOME=$HOME/projects/n8n-home
BACKUP=$HOME/projects/backups/apply-2026-10-24-$(date +%Y%m%d-%H%M%S)
for c in jq claude diff awk; do command -v "$c" >/dev/null || { echo "missing: $c" >&2; exit 1; }; done

say() { printf '\n== %s\n' "$*"; }
backup() {   # backup <file>: a copy under $BACKUP, private (~/.claude.json holds tokens)
  [[ -f $1 ]] || return 0
  (umask 077; mkdir -p "$BACKUP" && cp -p "$1" "$BACKUP/$(basename "$1")") || { echo "backup of $1 failed; stopping" >&2; exit 1; }
  echo "backed up $1 -> $BACKUP/"
}
install_text() {   # install_text <target> <new content>: show the diff; outside --dry-run back up and write
  local target=$1 new=$2 old=""
  [[ -f $target ]] && old=$(cat "$target")
  if [[ $old == "$new" ]]; then echo "unchanged: $target"; return 0; fi
  diff -u --label "$target (now)" --label "$target (new)" <([[ -f $target ]] && cat "$target") <(printf '%s\n' "$new")
  (( DRY )) && return 0
  backup "$target"
  mkdir -p "$(dirname "$target")" && printf '%s\n' "$new" > "$target" || { echo "writing $target failed" >&2; exit 1; }
  echo "installed: $target"
}

(( DRY )) && echo "DRY RUN: nothing is written, nothing is removed."

# 1. User settings: the template's permissions (and the n8n .mcp.json approval) over the live file's other keys,
#    so anything changed in ~/.claude/settings.json since the template was cut is kept.
say "1/4 $SETTINGS: permissions"
if [[ -f $SETTINGS ]]; then
  new=$(jq --slurpfile t "$TPL/settings.permissions.json" \
    '.permissions = $t[0].permissions | .enabledMcpjsonServers = $t[0].enabledMcpjsonServers' "$SETTINGS") \
    || { echo "$SETTINGS is not valid JSON; stopping" >&2; exit 1; }
else
  new=$(jq . "$TPL/settings.permissions.json")
fi
install_text "$SETTINGS" "$new"

# 2. ~/.claude/CLAUDE.md: the section from the template replaces the one with the same heading, or is appended.
say "2/4 $USER_MD: § Git, merges and permissions"
head_line=$(head -n1 "$TPL/CLAUDE.md")
if [[ -f $USER_MD ]]; then
  new=$(awk -v head="$head_line" -v tpl="$TPL/CLAUDE.md" '
    BEGIN { while ((getline l < tpl) > 0) sec = sec l "\n" }
    $0 == head { printf "%s", sec; skip = 1; done = 1; next }
    skip && /^##? / { skip = 0; print "" }
    skip { next }
    { print }
    END { if (!done) { if (NR) print ""; printf "%s", sec } }' "$USER_MD")
else
  new=$(cat "$TPL/CLAUDE.md")
fi
install_text "$USER_MD" "$new"

# 3. The harness's merge policy: append unless the last MERGE_POLICY= in the file already says the same.
say "3/4 $HCONF: merge policy"
want=$(grep -m1 '^MERGE_POLICY=' "$TPL/config.merge-policy.sh")
have=$( [[ -f $HCONF ]] && grep '^[[:space:]]*MERGE_POLICY=' "$HCONF" | tail -n1 | sed 's/^[[:space:]]*//; s/[[:space:]]*#.*//')
if [[ $have == "$want" ]]; then
  echo "unchanged: $HCONF ($want)"
else
  [[ -n $have ]] && echo "now: $have (the appended line wins: the file is sourced top to bottom)"
  if [[ -f $HCONF ]]; then new=$(printf '%s\n\n%s' "$(cat "$HCONF")" "$(cat "$TPL/config.merge-policy.sh")"); else new=$(cat "$TPL/config.merge-policy.sh"); fi
  install_text "$HCONF" "$new"
fi

# 4. n8n MCP servers: user scope -> project scope in n8n-home, so the live n8n tools load only there (where its
#    settings gate the writes). n8n keeps its URL and loses its static Authorization header: the server offers OAuth,
#    so Claude Code asks once (/mcp in n8n-home) and keeps the token outside the repo. n8n-docs moves as it is.
say "4/4 n8n MCP servers -> $N8N_HOME/.mcp.json (project scope)"
[[ -d $N8N_HOME ]] || { echo "no $N8N_HOME; skipping"; exit 0; }
moved=0
for name in n8n n8n-docs; do
  def=$( [[ -f $CLAUDE_JSON ]] && jq -c --arg n "$name" '.mcpServers[$n] // empty | del(.headers)' "$CLAUDE_JSON")
  in_project=$( [[ -f $N8N_HOME/.mcp.json ]] && jq -r --arg n "$name" '.mcpServers[$n] // empty | "yes"' "$N8N_HOME/.mcp.json")
  if [[ -z $def ]]; then
    [[ $in_project == yes ]] && echo "unchanged: $name is already in project scope" || echo "$name: not in user scope; nothing to move"
    continue
  fi
  echo "\$ claude mcp remove $name -s user"
  [[ $in_project == yes ]] && echo "(already in $N8N_HOME/.mcp.json: not re-added)" \
    || echo "\$ (cd $N8N_HOME && claude mcp add-json -s project $name '$def')"
  (( DRY )) && continue
  (( moved )) || backup "$CLAUDE_JSON"; moved=1
  claude mcp remove "$name" -s user || { echo "removing $name failed; stopping" >&2; exit 1; }
  if [[ $in_project != yes ]]; then
    (cd "$N8N_HOME" && claude mcp add-json -s project "$name" "$def") \
      || { echo "adding $name failed. To restore: claude mcp add-json -s user $name \"\$(jq -c '.mcpServers[\"$name\"]' $BACKUP/.claude.json)\"" >&2; exit 1; }
  fi
done

say "next"
echo "- In $N8N_HOME: run claude, then /mcp -> n8n -> Authenticate (once). The old static token still works in n8n until"
echo "  you revoke it there; the backup of ~/.claude.json holds it."
echo "- $N8N_HOME/.mcp.json is new and uncommitted: chunk 3's n8n-home worker commits it, so run worktrees get it too."
(( DRY )) && echo "- Dry run: run it again without --dry-run to apply."
exit 0
