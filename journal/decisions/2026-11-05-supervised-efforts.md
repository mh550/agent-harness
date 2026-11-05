# Supervised efforts for every project: one user-level skill, one dispatch list per effort, plain names throughout

*(2026-11-05, an interactive session with Michael. He asked for the test suite redesign's way of working (a planner
that writes a dispatch list, a supervisor that hands him one command at a time) on his other projects, and for codes
like "D6" to be expanded wherever a session writes to him, so he can review and steer without opening the source
files. Drawn from `docs/specs/2026-11-03-test-suite-redesign.md` § "How the planning session works",
`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`, `-supervisor.md` and `docs/plans/2026-11-04-f1-by-hand.md`.
Trialled read-only by one fresh session against the redesign's dispatch list. The skill's home, user level and not
this repo, is Michael's choice in the same session.)*

## Finding

The redesign runs from three hand-written files: a plan, a dispatch list (a Status table and one copy-and-paste block
per piece of work) and a supervisor prompt. It works: seven supervisor sessions, each checking what finished against
what was predicted and handing Michael the next command. Three things keep it from travelling:

- **The supervisor's rules are welded to one effort.** Its prompt mixes what holds for any effort (read the Status
  table first, start nothing, decide no verdict, one next command, land the table by PR) with this effort's phases and
  checks. A second effort would copy the file and the copies would drift.
- **The writing assumes the files are open.** Rows and messages say "D4", "H1-04", "§5.3", "Dx", "fx8". The Status
  table's result cells grew into paragraphs (the run-resilience row is some 600 words) holding the result, the
  history, Michael's decisions and the open questions at once.
- **What is Michael's to decide has no place of its own.** It sits inside result cells ("Michael's to call",
  "Michael to confirm", "Open for Michael").

## Choice

1. **One skill, `supervise`, at user level:** `~/.claude/skills/supervise/`, a directory of Michael's, not a file of
   this repo. Used from any project: `/supervise new <what the effort is>` plans an effort with Michael and writes its
   dispatch list; `/supervise <dispatch list>` is one supervisor session. `SKILL.md` holds what is common to every
   effort (the three kinds of session, the supervisor's bindings, its eight steps, the shape of its report);
   `planning.md` the planner's steps; `dispatch-template.md` the list's layout. Started from a terminal as
   `claude --model claude-fable-5-1 "/supervise <arguments>"`: a slash command as the opening prompt loads the skill
   with its arguments exactly as typing it does (tried on Claude Code 2.1.318 with a skill the model may not invoke by
   itself).
2. **One file per effort carries everything that is the effort's own:** the dispatch list,
   `docs/plans/<date>-<effort>-dispatch.md` in the effort's project. Beside Status and the blocks it gains **Decisions**
   (Michael's, numbered once and for good: open ones with options and a recommendation, decided ones with the answer
   and date), **Names** (every code and coined term, one line each), **Rules for this effort** (what binds beyond
   `CLAUDE.md`, the order, what to check hardest, what a missed check leads to, when it is done) and a **Log** (one
   entry per supervisor session). A Status result is one line with its evidence; the account goes in the Log.
3. **Plain names, one rule for every session of an effort:** the name first and the code after it as a handle ("the
   slim-suite phase (D6)"); what a reference says and then where it lives; a number with its unit, its comparison and
   whether that held; a run or a PR with what it was; the test "could Michael decide from this message alone". The
   planner puts the rule, as one sentence, into every piece's prompt and brief, so a hand session and a run's PR body
   follow it too.
4. **The supervisor's report has a fixed shape:** where it stands · what finished · in flight (a running piece is
   read, not judged) · yours to decide (under each decision's number in the list, with a recommendation) · next (one
   command, with what it does and how long it takes) · yours to do by hand. The trial session's notes gave it the
   in-flight part, the decisions' lasting numbers, and the rule for a list older than this layout.
5. **The project's own rules stay the project's.** The skill names no project. How a change lands, who merges, the
   live-system and hardware gates and the allowed `harness` commands come from `CLAUDE.md`; where it gives merges to
   Michael (portfolio_site), the supervisor opens its PR and lists the merge as his.
6. **The redesign keeps its own supervisor prompt and its list's layout** until it ends; the prompt gained the
   plain-names rule and the report's shape as one section (PR #101), nothing else.

## Rejected

- **The skill in this repo's `skills/`, installed by a symlink as `harness-answer` is** (built first, PR #102,
  closed unmerged). `skills/` is in the suite's cache key (three check files read `harness-answer`), so every edit to
  the skill would re-base a live run's verified milestone, and would reach the symlink only at the live checkout's
  next sync, when no run is alive. The skill is how Michael works on every project, not a part of the harness, and it
  will change often while other projects try it. What user level costs: `~/.claude` is not under git, so the skill
  has no history or backup until Michael gives it a repo of its own; and `README.md` and `docs/architecture.md` do not
  name it.
- **A `harness supervise` command, or the driver calling the supervisor.** That is the event-driven steward
  `findings-and-research/2026-11-04-orchestration-models.md` recommends (its step S2): a driver change with its own
  spec, checks and a run. This skill is the by-hand form of the same loop, and the list it defines (Status, `needs`,
  one block per piece) is what a steward would read, so nothing here has to be undone for it.
- **A plan, a dispatch list and a supervisor prompt per effort, copied from the redesign.** The common rules would
  fork with every copy, and the last fix to them would live in whichever effort made it.
- **Dropping the codes.** A short handle is what a command, a `needs` cell and a branch name use. They stay, never
  alone.
- **A glossary per project.** The terms that need explaining are an effort's (its pieces, phases, measures); the
  project's lasting vocabulary already has homes (`CLAUDE.md`, the architecture doc).
- **Migrating the redesign's list to the new layout mid-effort.** Its supervisor has no state but that table; a
  re-layout between two sessions risks more than the remaining pieces gain.
