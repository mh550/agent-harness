---

# This run

Run: `{{RUN_ID}}` of {{PROJECT}}
Worktree: `{{WT}}` on branch `{{BRANCH}}` (milestones merge into `{{MAIN_BRANCH}}`)
Run directory: `{{RUN_DIR}}` (progress.md, INBOX.md, feature_list.json, brief.md, entries.jsonl, progress-archive.md, context.md)
Port: {{PORT}} · scratch directory: `{{SCRATCH}}`
Other lanes of this run work in other slots (their own worktree, branch and port): stay in yours.
{{!CHECK_FAST_CMD}}Suite: `{{CHECK}}` (runs `{{CHECK_CMD}}`, cached per code tree; its last full run is under *This session*) · init: `{{INIT_CMD}}` · smoke: `{{SMOKE_CMD}}`
{{?CHECK_FAST_CMD}}Suite: `{{CHECK}}` (full: runs `{{CHECK_CMD}}`; fast tier: `{{CHECK}} --fast` runs `{{CHECK_FAST_CMD}}`; cached per code tree; its last full run, and in a coding session its last fast run, are under *This session*) · init: `{{INIT_CMD}}` · smoke: `{{SMOKE_CMD}}`
Spec: {{SPEC_FILES}}
