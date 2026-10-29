# N2 · Merge conflicts resolved without Michael: a sorted merge for lists, a resolve session for the rest, the verify gate, then merge: plan

Spec: `docs/specs/2026-10-29-unattended-night.md` §N2 items 1–6 and its checks. This file is N2-01; N2-02 builds layer 1
(`merge-sorted.sh`, `.gitattributes`, the worktree config), N2-03 layer 2's happy path (`resolve.sh`, the prompt, the
stub's `both`, `merge_one`'s route, `rebase`'s call), N2-04 the bounds and fallbacks (`markers`, `give-up`, `stray`, a
refused session, `MAX_RESOLVES`, `sync_main`, the cards' `tried`), N2-05 what Michael sees (notes, summary, report, PR
body), N2-06 reviews. Every site is named by function and file as the code stands at `e9fb31e` (N1 merged). Nothing
here changes code: the suite is as the init left it (886 checks, green).

Facts checked for this plan, so the builders needn't re-derive them (git 2.43.0 on this box, tried 2026-10-29 in a
throwaway repo):

- **`git merge-tree --write-tree` runs a configured merge driver**, from the attributes of the checkout it runs in
  and the config it reads: two branches adding adjacent names to a file with `merge=sorted-union` and the driver set
  merge-tree clean (exit 0, the driver called). So layer 1 settles `merge_one`'s merge-tree as well as `git merge`,
  in a slot (the lane's `merge_one`) and in the record worktree (the coordinator's), both of which get the driver.
- **`git worktree add` copies the current worktree's `config.worktree` into the new one** (the driver line appeared in
  the second worktree without being set there). Harmless here (`slot_open` adds slots from the record worktree and sets
  the same value anyway), and the copy goes from the record worktree to slots, never back to Michael's checkout: the
  record worktree's `--worktree` value lives in `.git/worktrees/<id>/config.worktree`, which `git -C <project>` doesn't
  read. N2-02's check asserts that.
- Attributes are read from the checkout doing the merge (no `--attr-source`): a `.gitattributes` that only main has
  doesn't apply until the lane's tree has it. Fine for this repo (N2-02 commits it before any lane needs it); said in
  the decision as a limit.
- `extensions.worktreeConfig` is set only in `slot_open` today (`[[ $(git -C "$RWT" config extensions.worktreeConfig) == true ]] || …`).
- `session()` (`lib/record.sh`) reads `SESSION_TIMEOUT`, `MAX_TURNS` and `SESSION_BUDGET_USD` as globals: `resolve`
  sets them `local` to the `RESOLVE_*` values (bash's dynamic scope), so `session` needs no change.
- `dur_s` (`lib/scope.sh`, sourced by the lane) turns `30m` into 1800.
- `entries.mjs` `KINDS = ["coding", "verify", "init"]`: an entry of kind `resolve` is invalid until N2-03 adds it.
- `journal()`'s `case $kind` knows coding, verify and init; `resolve` gets `who="resolve $id"` like verify.
- `metrics.mjs append <log> <metrics> <run> <kind> <feature> <model> <passes> [<wall> <exit> <env> <role> <peak> <lane>]`
  takes any kind; `role` defaults to the kind.
- The stub project has no `README.md` (`tests/lib.sh` writes `CLAUDE.md` and `SPEC.md`): the checks land one on
  origin's main first, as `48-lanes-rebase.sh` lands `shared.txt`.
- `tests/checks/61-needs-git.sh`'s stub runs `mc` (sync_main's conflict in a lane) and `mr` (merge_one's) and
  `64-needs-review.sh`'s `mo` (merge_one sourced alone) test today's path. Under the new default `CONFLICTS=resolve`
  `mc` and `mr` would run a resolve session: N2-03 adds `echo 'CONFLICTS=michael' >> "$T/user-config.sh"` at the top
  of `61-needs-git.sh` (they keep testing today's path, which `michael` keeps). `mo` sources `lib/record.sh` without
  `lib/config.sh`, so `CONFLICTS` is unset there; the code tests `[[ ${CONFLICTS:-} == resolve ]]`, so an unset value
  is today's path and `mo` needs nothing.
- The stub with `STUB_MERGE_RESOLVE` unset answers a resolve prompt as `give-up` does, so any other stub run that meets
  a conflict ends as today plus one session line.
- Timings to size the new files: `48-lanes-rebase.sh` runs six two-lane stub runs in 90.6 s (9 checks),
  `61-needs-git.sh` 50.9 s, `59-needs-cards.sh` 2.4 s (the init's suite on this tree).

## Layer 1: merge-sorted.sh

**`lib/merge-sorted.sh`** (new, N2-02), usage header `# Usage: lib/merge-sorted.sh <O> <A> <B>   → a git merge driver
for one-item-per-line LC_ALL=C sorted files: A becomes the three-way union`.

- `set -uo pipefail`; `export LC_ALL=C`.
- `sort -c "$2" && sort -c "$3"` else exit 1 with A untouched (git then reports the conflict as usual and layer 2 takes
  it). `O` isn't checked (git's base may predate the file being sorted: its lines are only subtracted).
- removed = `comm -23 O A` ∪ `comm -23 O B` (each side's sorted copy; `sort -u` into temp files under `mktemp -d`,
  removed on EXIT). result = `sort -u A B | comm -23 - <(sort -u removed)`. Written to a temp file, then `cat tmp > A`
  (git reads `%A` back; keep its inode), exit 0.
- A line both sides added is one line (`sort -u`); a base line either side removed stays removed (the subtraction);
  a line one side removed and the other side re-added... is removed: the subtraction wins. Said in the decision.
- No trailing-newline special case: `sort` always ends with one; a file without one gains it (the fixture has one).

**Opt-in.** `.gitattributes` at the repo root, one line: `tests/fixtures/check-names.txt merge=sorted-union` (N2-02).

**Wiring.** One helper in `lib/record.sh`, beside `slot_open`:

```bash
# <worktree>: the sorted-union merge driver (lib/merge-sorted.sh) in that worktree's own config, so a project's
# `.gitattributes` `merge=sorted-union` works in the harness's checkouts and never in Michael's (decisions/2026-10-29-conflict-resolution)
merge_drivers() {
  [[ $(git -C "$1" config extensions.worktreeConfig) == true ]] || git -C "$1" config extensions.worktreeConfig true
  git -C "$1" config --worktree merge.sorted-union.name "sorted one-per-line list (harness)"
  git -C "$1" config --worktree merge.sorted-union.driver "$HARNESS_HOME/lib/merge-sorted.sh %O %A %B"
}
```

- Called by the driver (`lib/driver.sh`) right after `sync_record` and before the resumed start's `sync_main`
  (`if [[ -f $LIST ]] || (( resumed )); then`), every segment: `merge_drivers "$RWT"`. Every segment rather than once
  where `bin/harness cmd_start` creates the record worktree, because a continue may run a different `HARNESS_HOME`
  (the path in the value must be the running harness's), and a resumed start's own `sync_main` should have it.
- Called in `slot_open` in place of its `extensions.worktreeConfig` line (`merge_drivers "$SLOT"` after `git -C "$SLOT"
  config --worktree core.excludesFile …`, which needs the extension first: move that line below the call).
- A merge layer 1 settles is a clean merge to every caller; no caller changes.

## Layer 2: resolve.sh

**`lib/resolve.sh`** (new, N2-03, sourced by `lib/lane.sh` after `lib/review.sh`; usage header `# Usage: source
lib/resolve.sh   → resolve <who> <what>: a merge left in conflict, resolved by a session and committed, or aborted`).

### `resolve <who> <what>`

`<who>` is the milestone (`$LANE`); `<what>` what is merged in (`$MAIN_BRANCH`). Called with the merge in progress in
the slot (cwd), `MERGE_HEAD` set. Return codes:

| rc | meaning | the merge |
|---|---|---|
| 0 | resolved and committed (`git commit --no-edit`, the merge commit) | done |
| 1 | unresolved: a bound said no session, or the session or the driver's checks failed | `git merge --abort` |
| 2 | refused by a limit (`MET limit`, the session cap, the weekly gate, a memory wait cut short): deferred | `git merge --abort` |

It sets `RESOLVE_TRIED` (empty when no session ran, else `a resolve session (<model>, <n> min): <why it stopped>`)
and `RESOLVE_FILES` (the conflicted files, space-separated) for the caller's note and needs record, and `RESOLVE_MODEL_RAN`
/ `RESOLVE_MIN` for N2-05's note.

**Eligibility, `resolve_ok <m>`** (a function of its own, unit-checkable by sourcing `lib/resolve.sh`): prints the
reason and returns 1 when any holds, else 0. Checked first; a no → `git merge --abort`, return 1, `RESOLVE_TRIED=""`.

1. `[[ ${CONFLICTS:-} != resolve ]]` → `CONFLICTS=${CONFLICTS:-unset}` (callers test it too; this is the backstop).
2. `${HARNESS_MERGE_ONLY:-}` → `harness merge` (no session runs from a CLI command).
3. `[[ -z ${LANE:-} ]]` → `not in a lane` (the record branch's conflicts are Michael's).
4. the marker `$STATE/resolve-<m>-<sha>` for this main: `[[ -f $STATE/resolve-<m>-<mn> ]]`, `mn=$(git rev-parse MERGE_HEAD)` (the origin/main commit merged in, at both
   call sites) → `a resolve session already ran for main <sha7>`.
5. `$(cat "$STATE/resolves-<m>" || 0) >= MAX_RESOLVES` → `its <n> resolve session(s) used`; here the caller-visible note
   `note "<m>: its <n> resolve session(s) used; not merged (needs Michael)"` (N2-04).
6. `(( $(date +%s) + $(dur_s "$RESOLVE_TIMEOUT") > DEADLINE ))` → `less than RESOLVE_TIMEOUT before the deadline`
   (`DEADLINE` is the lane's `HARNESS_DEADLINE`; verify's `once` mode is past it, so it never resolves).

The re-base round (`MAX_REBASE_ROUNDS`) is the caller's (`rebase` knows `r`): see *Call sites*.

**Steps, in order** (cwd the slot; `fa` the conflicted files):

1. `files=$(git -c core.quotePath=false diff --name-only --diff-filter=U)` (one path per line: the shape of
   `tests/fixtures/git-conflict/diff-name-only-U.txt`); `mapfile -t fa`. Empty (the merge never started) → abort,
   return 1.
2. `resolve_ok` (above).
3. `note "<m>: <n> files conflict with <what> (<files, comma-separated>); a resolve session"` (N2-03's check greps
   `M2: 1 files conflict with main (README.md); a resolve session`).
4. Session cap and weekly gate, as the coding loop does: `n=$(rec_count "$STATE/sessions" 1)`; `(( n > MAX_SESSIONS ))`
   → `rec_count … -1`, abort, return 2. `weekly_over "$USAGE"` → abort, note `<m>: no resolve session: <why>`, return 2.
5. Memory gate: `mem_gate` (0 = enough memory, 1 = waited and now enough, a wait cut short is 1 too): after it,
   `[[ -f $STATE/lanes-end || $(control) == stop ]]` → `rec_count sessions -1`, abort, return 2. No `run_init` after a
   wait: the verify that follows runs it (`run_init fresh`).
6. **The snapshot**, before anything else touches the slot: `git ls-files -s -- . ":!$RUN_DIR" | awk '$3 == 0'` →
   `$SCRATCH/resolve-index` (mode, blob, stage 0, path: the paths git merged by itself); `git ls-files --others
   --exclude-standard -- . ":!$RUN_DIR"` → `$SCRATCH/resolve-untracked`; `pre=$(git rev-parse HEAD)`.
7. `materialize` (the slot's copy of the record, so the session has `$RUN_DIR/entry.json`'s home; no context pack).
8. The prompt: `HARNESS_MILESTONE=$m HARNESS_FEATURES=<ids> HARNESS_FEATURE_LINES=<"- `id` · description" per feature>
   HARNESS_MERGING=$what HARNESS_CONFLICT_FILES=<one per line> HARNESS_OURS=<subjects> HARNESS_THEIRS=<subjects>
   HARNESS_CLOCK=$(clock "resolve session for $m") prompt resolve`, where `mb=$(git merge-base HEAD MERGE_HEAD)`,
   `HARNESS_OURS=$(git log --format=%s -n 20 "$mb..HEAD" -- "${fa[@]}")` and `HARNESS_THEIRS` the same for
   `"$mb..MERGE_HEAD"` (`clock`'s line names `$SESSION_BUDGET_USD`, `$MAX_TURNS`, `$SESSION_TIMEOUT`: set the locals
   below first so the line is the resolve session's).
9. **The session**: `local SESSION_TIMEOUT=$RESOLVE_TIMEOUT MAX_TURNS=$RESOLVE_MAX_TURNS SESSION_BUDGET_USD=$RESOLVE_BUDGET_USD`;
   `model=$(F model "$RESOLVE_MODEL")`; `rlog="$LOGS/$(date +%H%M%S)-resolve-$m.jsonl"`; `log "resolve $m · $model"`;
   `echo "resolve session" > "$LDIR/now"`; `session resolve "$model" "$rlog" "resolve $m"`. `session` copies the prompt
   beside the transcript (`…-resolve-M2.prompt.md`, what N2-03's prompt check reads).
10. `journal resolve "$m" "$rlog" "$model" "$pre"` (before any restore and before the limit branch, as verify: a refused
    session is journaled too; the copy's `entry.json` is taken by `journal_` under the record lock), then
    `unmaterialize`.
11. **Refused** (`why=$(MET limit "$rlog" "$S_WALL" "$S_EXIT")`): `rec_count sessions -1`; `limits=$(rec_count
    "$STATE/limits" 1)`; `record MET append "$rlog" "$REC/metrics.jsonl" "$RUN_ID" resolve "$m" "$model" false
    "$S_WALL" "$S_EXIT" true resolve "$S_PEAK" "$LANE"`; abort. At `limits >= MAX_LIMIT_HITS` → `RESOLVE_TRIED="a
    resolve session (<model>): refused <n> times in a row (<reason>)"`, return 1 (today's path: the bound). Else
    `upto` as the verify's refusal computes it (`reset + 120`, else now + 900), `record limit_raise "$upto"`, `note "<m>:
    the resolve session was refused (<reason>); deferred until <HH:MM>"`, `rec_commit`, `sync_record`, return 2. No
    `resolve-<m>-<sha>` marker and no `resolves-<m>` count: the retry after the wait is the same session.
12. Went through: `echo 0 > "$STATE/limits"`; `rec_count "$STATE/resolves-$m" 1`; `: > "$STATE/resolve-$m-$mn"`.
    Its metrics row is written in step 14, once the verdict is known.
13. **The driver's checks**, in order; the first that fails sets `why` and goes to step 14's failure branch:
    1. the session committed or aborted the merge itself: `[[ $(git rev-parse HEAD) != "$pre" ]] || ! git rev-parse -q
       --verify MERGE_HEAD` → `why="it committed or aborted the merge itself"`; step 14's failure branch with
       `git reset -q --hard "$pre"` in place of `git merge --abort` (there may be no merge to abort).
    2. the session's final message: `MET final "$rlog"` has a line starting `UNRESOLVED:` → `why="UNRESOLVED: <rest>"`.
       (No `RESOLVED:` line at all is not a failure by itself: the next checks decide.)
    3. no unmerged path: `git diff --name-only --diff-filter=U` empty, else `why="<paths> still unmerged"`.
    4. no marker in a conflicted file: `grep -lE '^(<<<<<<<|=======|>>>>>>>)( |$)' -- "${fa[@]}"` (the worktree files
       that exist; a file the resolution deleted is skipped) empty, else `why="conflict markers left in <paths>"`.
    5. **outside the conflict, restored (not a failure)**: for each line `mode blob 0 path` of `resolve-index`: the
       path's current stage-0 entry (`git ls-files -s -- "$path"`) and worktree blob (`git hash-object -- "$path"`,
       missing = deleted) both equal `blob`, else `git update-index --cacheinfo "$mode,$blob,$path"` and `git
       cat-file blob "$blob" > "$path"` (mkdir -p its directory; `chmod +x` for 100755); each path in `git ls-files
       --others --exclude-standard -- . ":!$RUN_DIR"` and not in `resolve-untracked`: `rm -f`. Any → `note "<m>: the
       resolve session edited <paths, space-separated> outside the conflict; restored"`. A conflicted path is never in
       `resolve-index` (it was at stages 1–3), so the resolution itself is never undone.
14. Both branches first: `RESOLVE_MIN=$(( (S_WALL + 59) / 60 ))`, `RESOLVE_MODEL_RAN=$model`, `record MET append
    "$rlog" "$REC/metrics.jsonl" "$RUN_ID" resolve "$m" "$model" <true on success, else false> "$S_WALL" "$S_EXIT"
    false resolve "$S_PEAK" "$LANE"` (one row per session). Success: `git add -A -- "${fa[@]}"` (a no-op when the session added them; it keeps the worktree equal to what is
    committed), `git commit -q --no-edit`, `printf '%s\n' "${fa[@]}" >> "$STATE/resolved-$m"` (N2-05's PR body reads
    it), return 0. Failure: `git merge --abort`, `RESOLVE_TRIED="a resolve
    session ($model, $RESOLVE_MIN min): $why"`, `note "<m>: the resolve session did not resolve the merge ($why);
    merge aborted"`, return 1.

**`journal()`** (`lib/record.sh`): `resolve) who="resolve $id" ;;` beside `verify)`. **`entries.mjs`**: `KINDS` gains
`"resolve"`; a resolve entry is rendered into progress.md like a coding entry without evidence (whatever `render`
does with an unknown kind today: N2-03 checks the line appears and fixes it if not).

### prompts/resolve.md

First line `# Resolve session`; static text first, then `{{SECTIONS}}` (policy, run, rules), then `# This session`
(decisions/2026-10-21-static-first-prompts):

- You are resolving one merge in progress in this worktree: `{{MERGING}}` merged into the lane branch conflicted. The
  harness commits the merge after you; then a verify session re-checks the milestone on the merged tree, in full, before
  anything reaches main.
- The rules: keep the intent of both sides (read both sides' commits below; don't pick a side to make the conflict go
  away); edit only the conflicted files (the harness puts any other path back and says so); leave no conflict marker
  (`<<<<<<<`, `=======`, `>>>>>>>` at a line's start); `git add` each file; run only `{{CHECK}} <names>` for the parts of
  the suite that cover the files (the subset form, which never reruns), none when the project's suite takes no names,
  never the full suite (the verify round runs it; it takes 10 to 14 minutes here, more than this session has); never
  commit, never `git merge --abort`, never touch `MERGE_HEAD`.
- Write the run directory's `entry.json`: `feature` (the milestone id), `kind` `"resolve"`, `outcome` (`passes` when
  every file is resolved, else `not yet`), `summary` (what each side meant and how the resolution keeps both), `files`.
- The last lines of the final message: `RESOLVED: <file>: <one line on how>` per file, or `UNRESOLVED: <why>` (one
  line) when a file's two intents can't both be kept: then leave the files as they are.
- `# This session`: `Milestone: {{MILESTONE}}`, `Features: {{FEATURES}}`, `{{FEATURE_LINES}}`, `## Conflicted files`
  `{{CONFLICT_FILES}}`, `## This lane's commits (touching them)` `{{OURS}}`, `## {{MERGING}}'s commits (touching
  them)` `{{THEIRS}}`, `{{CLOCK}}`.

`prompt_render resolve` uses the coding `where` block (a resolve edits code). `lib/prompt.sh <state> resolve <feature>`
(the command form `harness eval probes` uses) renders it with the conflict values empty; N2-03 checks its first line
and that `{{` doesn't survive.

### Settings (`lib/config.sh`, N2-03)

One line beside `LANE_REBASE`/`MAX_REBASE_ROUNDS`:
`CONFLICTS=resolve RESOLVE_MODEL=opus RESOLVE_MAX_TURNS=60 RESOLVE_BUDGET_USD=5 RESOLVE_TIMEOUT=30m MAX_RESOLVES=3`,
commented `# a conflict with main in a lane: resolve = a resolve session, verified, merged; michael = needs Michael
(decisions/2026-10-29-conflict-resolution)`. Each commented in `templates/user/config.sh`. `RESOLVE_TIMEOUT` must pass
`dur_s` (config validation: an invalid value is reported as `CHECK_TIMEOUT` is, if `load_config` validates durations;
else `resolve_ok` treats a `dur_s` failure as 1800).

## Call sites

Each line quoted as it stands at `e9fb31e`.

### `sync_main` (`lib/record.sh`), a lane at the start of its verify (N2-04)

```bash
  git merge --abort 2>/dev/null; note "$MAIN_BRANCH conflicts with $b; carrying on without it (merges into $MAIN_BRANCH need Michael)"
```

Before this line (after `subjects=…`), a lane only:

```bash
  RESOLVE_TRIED=""
  if [[ -n ${LANE:-} && ${CONFLICTS:-} == resolve ]]; then
    resolve "$LANE" "$MAIN_BRANCH"; case $? in
      0) note "$LANE: main merged in by a resolve session (…); the verify goes on with main merged"; main_clear "$sub"; return 0 ;;
      2) return 2 ;;   # deferred: no record, no nomerge-<m> (verify below)
    esac
  fi
```

and `tried="$RESOLVE_TRIED"` added to its `needs_open main_conflict …` line. The record branch (`LANE` empty: the
driver's resumed start) keeps today's abort and record unchanged. N2-03 can leave `sync_main` alone (its checks go
through `rebase`); N2-04 adds it.

**The caller** (`verify`, `lib/lane.sh`): `sync_main || touch "$STATE/nomerge-$m"` becomes
`sync_main; (( $? == 1 )) && touch "$STATE/nomerge-$m"`. A deferred resolve (2) leaves `nomerge-<m>` off: the verify
goes on without main, holds, and `merge_own` → `merge_one` finds the conflict and returns 3 (below), so the lane's
`rebase` meets it again, where a refused session puts `rebase-<m>` back and the lane ends `its re-base waits` (exit 0)
for the coordinator to re-base it after the wait. With `nomerge-<m>` set instead (the spec's wording) a verified lane
ends `lane_exit 12 "$M needs Michael: main conflicts with its lane"` with no needs record: a stop, which the spec rules
out. This is the one place the plan departs from N2-04 step 3's words; said in the entry's `proposed_changes`.

### `rebase` (`lib/lane.sh`), main moved under a verified tag (N2-03, N2-04)

```bash
  if ! git merge -q --no-edit "origin/$MAIN_BRANCH" > /dev/null 2>&1; then
    files=$(git -c core.quotePath=false diff --name-only --diff-filter=U); git merge --abort 2> /dev/null
    rebase_fail "$m" "$c" "$m conflicts with $MAIN_BRANCH; not merged (needs Michael)" "conflicts with $MAIN_BRANCH" merge_conflict rebase files="$files" main="$mn"; return 1
  fi
```

becomes (the round `r` computed before the merge: its line below, `r=$(( $(cat "$STATE/rebase-rounds-$m" …) + 1 ))`,
moves up here, not copied; `resolved=""` and `rc` locals):

```bash
  r=$(( $(cat "$STATE/rebase-rounds-$m" 2> /dev/null || echo 0) + 1 ))
  if ! git merge -q --no-edit "origin/$MAIN_BRANCH" > /dev/null 2>&1; then
    files=$(git -c core.quotePath=false diff --name-only --diff-filter=U); rc=1 RESOLVE_TRIED=""
    if [[ ${CONFLICTS:-} == resolve ]] && (( r <= MAX_REBASE_ROUNDS )); then resolve "$m" "$MAIN_BRANCH"; rc=$?
    else git merge --abort 2> /dev/null; fi
    (( rc == 2 )) && { echo "$mn" > "$STATE/rebase-$m"; return 1; }   # refused: the re-base again after the wait
    (( rc == 0 )) || { rebase_fail "$m" "$c" "$m conflicts with $MAIN_BRANCH; not merged (needs Michael)" "conflicts with $MAIN_BRANCH" merge_conflict rebase files="$files" main="$mn" tried="$RESOLVE_TRIED"; return 1; }
    resolved=1
  fi
```

and the disjoint test `if [[ -z $both && $LANE_REBASE != verify ]]; then` gains the resolved flag (a resolved merge
counts as overlapping whatever `LANE_REBASE` says: `[[ -z $both && $LANE_REBASE != verify && -z $resolved ]]`), `how` reads `, resolved by a session (<files>)` instead of
`, disjoint` when `both` is empty and `resolved` is set, and the existing `(( r > MAX_REBASE_ROUNDS ))` line is still
the guard for the clean overlapping case. Its note (N2-05):
`note "$m: main merged in by a resolve session ($RESOLVE_FILES; $RESOLVE_MODEL_RAN, $RESOLVE_MIN min); one verify round follows"`,
then the existing `$m re-based on $how; one verify round (…)` note, `verify "$m" rebase`, re-tag and merge as today.
The round's verify sees the merge commit (`sync_lane` pushes it, the existing line).

### `merge_one`'s conflicting `merge-tree` (`lib/record.sh`, N2-03)

```bash
  if ! out=$(git -c core.quotePath=false merge-tree --write-tree --name-only "origin/$MAIN_BRANCH" "$c" 2>/dev/null); then
    # once per main: merge_milestones runs again after every verify and at the end; `harness merge` always says so
    [[ ! ${HARNESS_MERGE_ONLY:-} && $(cat "$STATE/conflict-$m" 2>/dev/null) == "$mn" ]] && return 1
```

A first line inside the branch, before the once-per-main line:

```bash
    if [[ ${CONFLICTS:-} == resolve && ! ${HARNESS_MERGE_ONLY:-} ]]; then   # the lane's rebase merges, resolves and verifies it
      [[ ( $(cat "$STATE/moved-$m" 2>/dev/null) == "$mn" && -f $STATE/rebase-$m ) || -f $STATE/needs-$m ]] && return 1
      echo "$mn" > "$STATE/moved-$m"; return 3
    fi
```

(the moved branch's guard, word for word but for the `HARNESS_MERGE_ONLY` half, which this branch excludes). No
record opens. `merge_milestones_` already turns 3 into `rebase-<m>` for the non-`--open` call; the lane's `merge_own`
then re-bases, and a closed lane's `rebase-<m>` goes through `rebase_due` and a `LANE_MERGE` lane. Under `--open` (a
dependency not merged) the 3 is dropped by `merge_milestones_`'s `merge_one "$m" --open && …` as it is for a clean
moved main today: the milestone is re-based once the dependency has merged and the call without `--open` runs. On the
coordinator (`harness merge`, `HARNESS_MERGE_ONLY`) the branch is today's: a `merge_conflict` record, no session.

### `slot_open`'s three `merge --abort` lines (`lib/record.sh`): they stay

```bash
      git -C "$SLOT" merge --abort 2> /dev/null
      note "$m: $b here and on origin diverged and conflict; needs Michael"; base_conflict "$m" "$fold" diverged
```
```bash
      git -C "$SLOT" merge --abort 2> /dev/null
      note "$m: its base conflicts ($dep vs $MAIN_BRANCH); needs Michael"; base_conflict "$m" "$tag" dependency
```
```bash
      git -C "$SLOT" merge --abort 2> /dev/null
      note "$m: its base conflicts (default vs $MAIN_BRANCH); needs Michael"; base_conflict "$m" "$dep" default
```

Unchanged: `slot_open` runs in the coordinator before the lane process exists, and a 30-minute session there would
hold up every other lane's reaping, merging and opening. N2-04 adds one comment above the first:
`# a base conflict stays Michael's: this runs in the coordinator, where a resolve session would block every lane (decisions/2026-10-29-conflict-resolution)`.

### Smaller sites

- `lane.sh`: `source "$HARNESS_HOME/lib/resolve.sh"` after `lib/review.sh`.
- `rebase_fail`'s extra `key=value` args already reach `needs_open`; `tried=` rides along.
- `bin/harness` `cmd_continue`'s fresh-attempts `rm -f … "$STATE"/moved-*` gains `"$STATE"/resolves-* "$STATE"/resolve-*-*`
  (Michael asks again: the bounds start over), N2-04.
- `harness merge` (`cmd_merge`) clears only `moved-*`, as today.

## The gate

What makes *what lands on main is byte for byte what was verified* hold after a resolution:

- `rebase`: a resolved merge never takes the disjoint branch (no suite-only re-tag): it takes the verify round, which
  `verify rebase` runs on the merge commit (`run_init fresh`: the suite in full, then the session re-checking every
  step). Hold → the tag moves to that commit (the existing re-tag) → `merge_one` compares `merge-tree`'s tree with the
  tag's tree (the existing invariant test) → merges that commit. Not hold → the tag is removed (the existing
  `the re-based tree did not hold` path).
- No round left (`r > MAX_REBASE_ROUNDS`) → no session (`rebase`'s test before `resolve`), today's `merge_conflict`.
- `sync_main` at verify: the merge commit is in the slot before `run_init fresh` and the verify session, so the verify
  is on the merged tree, as for any clean merge of main. The tag is made on it.
- `merge_one` itself never resolves anything: it routes to the re-base (3).
- `resolve` returns 0 only with `HEAD` its own merge commit on `pre` and `MERGE_HEAD`, no unmerged path, no marker,
  and every path outside the conflict as git merged it.

## Stubs and fixtures

`tests/stub-claude.sh` (comment lines in its header for each flag, as the others):

- **`STUB_CONFLICT=<file>`** (N2-03): A's and C's first coding sessions rewrite line 2 of `<file>` to `line two, from A`
  and `line two, from C` (`sed -i '2s/.*/line two, from <id>/'`), committed with their work. The check first lands
  `<file>` on origin's main as the three lines `# demo`, `line two`, `line three` (as `48-lanes-rebase.sh` lands
  `shared.txt`; `main0` re-read after it). Lanes M1 (A) and M2 (C) then both rewrite line 2 of `README.md`: a real
  `git merge` conflict, the fixture `README.conflicted.md`'s shape.
- **`STUB_SORTED=<file>`** (N2-02): A's first coding session adds the line `b A check` to `<file>` and C's `b C check`,
  each re-sorted (`printf '%s\n' "b A check" >> f; LC_ALL=C sort -o f f`), committed with their work. The check lands
  `<file>` (`a check`, `c check`) and `.gitattributes` (`<file> merge=sorted-union`) on main first: both lanes add a
  name between the same two lines, the fixture `names.conflicted.txt`'s shape without the driver.
- **`STUB_MAIN_TOUCH=resolve-<m>:<path>`** (N2-04): `main_touch "resolve-$m"` in the resolve branch on its first session
  (n == 1), so the first resolve session's turn moves main again (a conflicting `main's README.md` on main).
- **`STUB_RESOLVE_LIMIT=1`** (N2-04): the first resolve session prints `fixtures/usage-limit.jsonl` and exits 1 (the
  real refusal capture), before it touches a file.
- **The `# Resolve session` branch**: `m=$(after_session '/^Milestone: / { print $2; exit }'); n=$(count "resolve-$m")`;
  `echo "resolve $m $n" >> "$RS/sessions.log"`; `(( n == 1 )) && main_touch "resolve-$m"`; the limit flag; then the
  files from `git diff --name-only --diff-filter=U` (the fixture's shape) and, by **`STUB_MERGE_RESOLVE`**:

| value | the conflicted files | also | ends (final text) | entry outcome |
|---|---|---|---|---|
| `both` (N2-03) | each: the lines `^(<<<<<<<\|=======\|>>>>>>>)( \|$)` deleted, so both sides' lines stay (`line two, from A` then `line two, from C`); `git add` | — | `RESOLVED: <file>: kept both sides` per file | passes |
| `markers` (N2-04) | as `both`, then `<<<<<<< HEAD` put back as the first line of `README.md` (one marker left); `git add` | — | `RESOLVED: README.md: kept both sides` | passes |
| `stray` (N2-04) | as `both` | appends `stray` to `work-A.txt` (a path main merged in by itself, stage 0) and writes `stray.txt` (untracked) | as `both` | passes |
| `give-up` and unset (N2-04) | untouched | — | `UNRESOLVED: stub gives up` | not yet |

  Each writes `entry.json` (`{feature: $m, kind: "resolve", outcome, summary: "resolve \($m) (\($n))", files}`) and
  ends `ok 0.3 "<final text>"`. It never commits.
- `tests/fixtures/git-conflict/` (captured 2026-10-29) is what `resolve` and the stub parse: `diff-name-only-U.txt`
  (one path per line), `README.conflicted.md` and `names.conflicted.txt` (the marker lines, `<<<<<<< HEAD` …
  `>>>>>>> main`), `merge-stdout.txt` (not parsed: the code reads `diff --diff-filter=U`, never merge's stdout).
  `merge-sorted.sh`'s check runs on `names.conflicted.txt`'s pair: O = `a check`, `c check`; A adds `b lane check`; B
  adds `b main check` (built from the fixture: its HEAD side and its main side).

## Visible

- Notes (`harness-log.md`), all through `note`:
  - `<m>: <n> files conflict with <what> (<files>); a resolve session` (resolve, before the session);
  - `<m>: main merged in by a resolve session (<files>; <model>, <n> min); one verify round follows` (rebase) and
    `…; the verify goes on with main merged` (sync_main) (N2-05);
  - `<m>: the resolve session edited <paths> outside the conflict; restored`;
  - `<m>: the resolve session did not resolve the merge (<why>); merge aborted`, then today's note at that place;
  - `<m>: the resolve session was refused (<reason>); deferred until <HH:MM>`;
  - `<m>: its <n> resolve session(s) used; not merged (needs Michael)`.
- `metrics.jsonl`: one row per resolve session, `kind` and `role` `resolve` (`env: true` for a refused one).
- `entries.jsonl`/progress.md: the session's entry, `resolve <m>`.
- Needs cards (N2-04): `card()` in `lib/needs.mjs` returns `tried: t.tried ? nul(t.tried(F)) : null`; the
  `merge_conflict` and `main_conflict` templates get `tried: F => F.tried`; `renderCard` puts `{ label: "tried",
  value: c.tried }` right after `why`/`question` (so the notification body, `bodyOf` → `renderCard`, has it), and
  `markdown` a `**tried** …` paragraph after `**why**`. Absent (`null`) prints nothing: every other card is unchanged.
- `summary.json` (N2-05, `lib/summary.mjs` build): `conflicts: {resolved, escalated, sessions}`: `resolved` = the
  number of `main merged in by a resolve session` notes in harness-log.md, `escalated` = the number of distinct
  milestones with a `conflicts with <main>; not merged (needs Michael)` or `<main> conflicts with harness-lane/<run>/<m>;`
  note (the record branch's `… conflicts with harness/<run>` is not a milestone's and isn't counted), `sessions` =
  metrics rows of kind `resolve`. `reportRows`: after the `Flakes` row, `| Conflicts | <r> resolved by sessions
  (<m>: <files>; …), <e> to Michael |` (`<m>: <files>` from the resolution notes; `0 resolved, 0 to Michael` for none;
  no row when the summary has no `conflicts` key).
- PR body (N2-05, `pr_body` in `lib/record.sh`): when `$STATE/resolved-<m>` exists, a paragraph `Merged main in with a
  resolve session: <files, comma-separated, unique>` after the features list. A resolution that passed its gate opens
  no needs record and sends no `needs you` notification (nothing calls `needs_you` on that path).

## Checks

Each new file `source`s `tests/lib.sh` and runs `suite_setup`; two-lane runs reuse `48-lanes-rebase.sh`'s
`waitf`/`held`/`two_lanes`/`rewritten` pattern (copied into the file: check files share nothing but `tests/lib.sh`),
`echo 'MAX_LANES=2' >> "$T/user-config.sh"`, and set origin's main back (`update-ref`) between runs (the Gotcha).
Every name goes into `tests/fixtures/check-names.txt` (LC_ALL=C sorted). Planned wall time from `48-lanes-rebase.sh`'s
~15 s per two-lane run.

### tests/checks/75-merge-sorted.sh (N2-02; ≈ 30 s: one stub run, the rest throwaway repos)

- `merge-sorted: the fixture pair merges to a check, b lane check, b main check, c check with exit 0`
- `merge-sorted: a base line one side removed stays removed`
- `merge-sorted: a line both sides added is one line`
- `merge-sorted: a side not in LC_ALL=C order exits 1 and leaves A untouched`
- `merge-sorted: with the attribute and the worktree driver, two branches adding adjacent names merge with exit 0, no marker, the union`
- `merge-sorted: the harness sets the driver in the slot's worktree config and never in the project's checkout`
- `merge-sorted: two lanes adding names to a sorted list both merge, with no conflict note and no needs record`
  (`STUB_SORTED=names.txt`, `STUB_INDEPENDENT_M2=1` and the `two_lanes` timing; `.gitattributes` and `names.txt` on
  main first)

### tests/checks/76-resolve-session.sh (N2-03, N2-05 adds four; ≈ 60 s: two stub runs, one `harness merge`, units)

- `resolve: a re-base conflict gets a resolve session, noted with its file` (`M2: 1 files conflict with main (README.md); a resolve session`)
- `resolve: the resolved merge takes one verify round, then M2 merges (one resolve line, two verify lines)`
- `resolve: the tree on main is the tree verified as run/<run>/M2 (the invariant)`
- `resolve: no needs record and one metrics row of kind resolve`
- `resolve: the resolve prompt names README.md and a commit subject from each side`
- `resolve: prompts/resolve.md renders through lib/prompt.sh as a command, first line # Resolve session, no {{ left`
- `resolve: merge_one's conflict returns 3 with moved-<m> in a lane and opens merge_conflict under HARNESS_MERGE_ONLY`
  (a unit call, `64-needs-review.sh`'s `mo` shape, with `CONFLICTS=resolve`)
- `resolve: CONFLICTS=michael keeps today's merge_conflict record and runs no resolve session`
- `resolve: harness merge on the conflicting milestone keeps the needs path and runs no session` (on the `michael`
  run, with `CONFLICTS=michael` taken out of `$T/user-config.sh` first, so the default `resolve` is what
  `HARNESS_MERGE_ONLY` overrides)
- N2-05: `resolve: the note names the files, the model, the minutes and the verify round that follows`
- N2-05: `resolve: summary.json counts the conflict as resolved and report.md has its Conflicts row`
- N2-05: `resolve: the PR body says main was merged in with a resolve session, and the michael run's does not`
- N2-05: `resolve: a resolution that passed its gate sends no needs-you notification`

### tests/checks/77-resolve-fallbacks.sh (N2-04, N2-05 adds one; ≈ 150 s: six stub runs and units; split by topic into `77-resolve-fallbacks.sh` and `78-resolve-bounds.sh` if its timing line passes 300 s)

- `resolve fallbacks: a session that leaves a marker is aborted, the slot back at the verified commit, merge_conflict with tried, the lane closed`
- `resolve fallbacks: a session that gives up is aborted the same way and its card says why`
- `resolve fallbacks: a stray edit and a new file are put back with a note naming both, and M2 merges`
- `resolve fallbacks: a refused session is deferred: no needs record, rebase-M2 back, then it re-bases and merges after the wait`
  (`STUB_RESOLVE_LIMIT=1`, `STUB_MERGE_RESOLVE=both`; `HARNESS_LIMIT_SLEEP=0` is `tests/lib.sh`'s)
- `resolve fallbacks: past MAX_RESOLVES the next conflict takes today's path with the resolve session(s) used note`
  (`MAX_RESOLVES=1`, `MAX_REBASE_ROUNDS=2` so the round bound isn't what stops it, `STUB_MAIN_TOUCH=resolve-M2:README.md`)
- `resolve fallbacks: sync_main at verify resolves in the lane: the note before verify M2, one verify M2, merged with no re-base`
  (`held`; A and B released first, C once `M1 merged into main` is noted; no `STUB_VERIFY_WAIT`)
- `resolve fallbacks: resolve_ok says no for CONFLICTS=michael, harness merge, no lane, a marker for this main, MAX_RESOLVES used and the deadline`
  (unit: `source lib/resolve.sh` with stubbed `note`, `STATE` a temp dir)
- `resolve fallbacks: the record branch's sync_main keeps today's abort and main_conflict record`
  (unit, `61-needs-git.sh`'s throwaway-repo shape: `LANE` empty, `CONFLICTS=resolve`, `resolve` defined to touch a
  file, which stays absent)
- `resolve fallbacks: a slot_open base conflict keeps base_conflict and runs no resolve session`
  (`61-needs-git.sh`'s `u_base` shape with `CONFLICTS=resolve`; `resolve` defined to touch a file)
- N2-05: `resolve fallbacks: the give-up run's summary counts one escalated and its row says 1 to Michael`

### tests/checks/59-needs-cards.sh (N2-04, one more)

- `needs cards: merge_conflict and main_conflict show tried in the card, the notification body and needs.md`
  (facts with `tried=a resolve session (opus, 4 min): UNRESOLVED: stub gives up`; a card without it prints no `tried`)

### Existing files

- `61-needs-git.sh`: `echo 'CONFLICTS=michael' >> "$T/user-config.sh"` at its top (N2-03), so `mc` and `mr` keep
  testing today's path.
- `48-lanes-rebase.sh`: unchanged (no conflict in its runs).

## Docs

- `journal/decisions/2026-10-29-conflict-resolution.md` (new, N2-02 starts it with layer 1; N2-03 adds layer 2; N2-04
  and N2-05 edit in place with `Updated in place 2026-10-29:` lines; N2-06 completes it): finding · choice · rejected:
  Michael for every conflict; `git merge -X ours/theirs` (drops one side's intent silently); a union driver without the
  three-way removal (brings back a deleted name, and the conformance check goes red); resolving on main; a resolve
  session without the verify round; a resolve session in the coordinator for `slot_open` (named as the next step if
  base conflicts show up). The `sync_main` deferral's departure from the spec (above) is recorded there.
- `docs/architecture.md` (N2-06): §3 rows for `lib/resolve.sh`, `lib/merge-sorted.sh`, `prompts/resolve.md`; §4 the new
  state files (`resolve-<m>-<sha>`, `resolves-<m>`, `resolved-<m>`); §5 the conflict paths (sync_main in a lane,
  rebase, merge_one's 3, and the two that keep today's: the record branch and slot_open); §7 a `Resolved merge` guard
  row; §8 the merge driver in worktree config; §10 `CONFLICTS`, `RESOLVE_MODEL`, `RESOLVE_MAX_TURNS`,
  `RESOLVE_BUDGET_USD`, `RESOLVE_TIMEOUT`, `MAX_RESOLVES`; §12 lanes no longer stop on an overlap conflict.
- `README.md` (N2-06): the settings, `CONFLICTS=michael` for a project that wants to be asked, and under *What a
  project needs* the `.gitattributes` `merge=sorted-union` opt-in for a project's sorted lists.
- `templates/user/config.sh` (N2-03): the six settings, commented.
