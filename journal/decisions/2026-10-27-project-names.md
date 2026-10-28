# Project names: one resolver takes a path or a bare name

*(2026-10-28, run agent-harness-2026-10-28, feature U3-02; spec `docs/specs/2026-10-27-status-ux.md` §U3 (bug c),
plan `docs/plans/2026-10-28-U3-show-and-fixes.md` §1)*

- **Finding:** every command that takes a project (`start`, `init`, `queue add`, `gc`, `memlint`) ran `toplevel "$1"`,
  `git -C "$1" rev-parse --show-toplevel`: a path relative to the current directory or nothing. `harness gc
  agent-harness` from the home directory said `agent-harness is not a git repository`, though the harness had run that
  project all night and knew where it was. `status --project` went the other way: it compared the argument with the
  project names as given, so `--project .` or `--project ~/projects/x` listed nothing.
- **Choice:** `project_dir <arg>` in `bin/harness`, in this order: (1) a git repository here (a path, `.`, a
  subdirectory, or a name that is a directory under the current one): its top level, as before; (2) a bare name (no
  `/`): the `PROJECT_DIR` of that name's runs under the state root, newest `meta.env` first (it is rewritten at every
  start), the first that is still a repository; (3) `${HARNESS_PROJECTS:-~/projects}/<name>` when it is a repository;
  else `harness: no project '<arg>': not a git repository here, no run of a project named <arg>, no <projects>/<arg>
  (projects with runs: <a>, <b>, …)` (`none` when no project has a run), exit 1. A path (it has a `/`) that is no
  repository says `harness: no project '<arg>': not a git repository`: the runs and the projects directory are looked
  up by name, so naming them would mislead. The six callers use it; `queue add` stores the resolved absolute path, so
  the runner and `queue list` read the entry as before. `status --project <p>`: the resolved directory's basename; a
  bare name that doesn't resolve (its checkout gone) still filters by itself, so a project's old runs stay listable.
  `toplevel` is gone.
- *Default* (asked in the run's entry): the runs come before `$HARNESS_PROJECTS` (they know where the project actually
  is; a second checkout of the same name under `~/projects` is not taken while a run points elsewhere).
- **Visible:** the commands print what they did as before (`queued: …`, gc's lines, the run's `run <id> on …` in
  `run.log`); the resolver adds no note of its own: it writes nothing and a failure is its stderr line.
- **Rejected:** a project registry file (one more thing to keep in step with the checkouts); resolving by the basename
  of the current directory (a run's worktree and the project share it, so it would pick either); `$HARNESS_PROJECTS`
  first (a project checked out elsewhere, as this harness is in its worktrees, would resolve to a stale copy).
