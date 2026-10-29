# Needs Michael: agent-harness-2026-10-29-2

## ⚠ agent-harness-2026-10-29-2 and agent-harness-2026-10-29 change the same files

`agent-harness-2026-10-29-2/1` · since 2026-10-29T12:49:33.948Z

**blocked** agent-harness-2026-10-29; nothing else waits

**cost** the second to merge will conflict

**why** Two runs that change the same files conflict when the second merges (merge_one in lib/record.sh). agent-harness-2026-10-29-2 and agent-harness-2026-10-29 both change config.sh, CLAUDE.md, README.md, architecture.md and 9 more (harness start compared their branches and what their specs and briefs name). agent-harness-2026-10-29 merges second: its merge conflicts on these files unless agent-harness-2026-10-29-2 is merged first and it continues from there.

**where** [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/.harness/config.sh](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/.harness/config.sh) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/CLAUDE.md](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/CLAUDE.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/README.md](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/README.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/docs/architecture.md](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/docs/architecture.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/docs/specs/2026-10-28-reliability.md](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/docs/specs/2026-10-28-reliability.md) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/lib/config.sh](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/lib/config.sh) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/lib/lane.sh](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/lib/lane.sh) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/lib/record.sh](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/lib/record.sh) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/tests/checks/](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/tests/checks/) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/tests/checks/75-suite-tools.sh](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/tests/checks/75-suite-tools.sh) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/tests/fixtures/check-names.txt](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/tests/fixtures/check-names.txt) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/tests/run.sh](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/tests/run.sh) · [/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2/tests/stub-claude.sh](https://github.com/mh550/agent-harness/blob/harness/agent-harness-2026-10-29-2/tests/stub-claude.sh) · `/home/mh550/worktrees/agent-harness/agent-harness-2026-10-29-2`

- (a) let the first merge, then continue the second **(recommended: one conflict, resolved once)**
- (b) stop one

```sh
harness show agent-harness-2026-10-29
```
