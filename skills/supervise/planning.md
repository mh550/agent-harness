# Planning an effort (the planner session)

Michael is here for this session. You write no code. You deliver the effort's dispatch list (and the plan or specs its
pieces need), landed on main, and the command that starts the supervisor. The list's shape:
`dispatch-template.md` beside this file. *Plain names* in `SKILL.md` binds everything you write.

## Do this

1. **Understand before you plan.** Read `CLAUDE.md`, the user's and the project's (how a change lands, the live-system
   and hardware gates), then the docs and code the effort touches. Then ask Michael, in one batch and early, only what
   reading cannot tell you: what will be true when this is done and how we would know; what is out of scope; the order
   he prefers; where he wants to be asked and where a session should proceed on a default.
2. **Split the effort into pieces.** A piece ends in something on main that can be checked (a merged PR, a findings
   file, a measured number) and fits one run or one sitting. If the effort claims to improve a number, the first piece
   measures that number as it is today. Each piece is one of four kinds:
   - **a harness run:** a spec to build. `harness queue add ~/projects/<project> --spec <spec> --brief "<brief>"`.
     The harness refuses a spec that is not on `origin/main`, so the specs land with the list.
   - **a `claude` session:** exploration, a spec to write, a measurement, a review, a diagnosis.
     `claude --model <model> "$(cat <<'EOF' … EOF)"`, its prompt complete in the block.
   - **a hand session:** Michael at the terminal while a session builds, where a run's overhead is not worth it or the
     project gates what a run may do. The same command shape as a `claude` session.
   - **Michael:** a step only he can do (a hardware test, a production merge or deploy, an account). It still gets a
     row, its commands, and what he pastes back.
3. **Write each block for a session that starts cold.** It knows nothing of this conversation. Every block says, in
   plain words, what the piece is and why, what it produces, what the supervisor checks (commands and expected values,
   and which of them Michael must run), and about how long it takes. A session's prompt carries, in this order:
   - who it is and the effort in a sentence;
   - what binds it: `CLAUDE.md`, and the effort's rules that apply to it;
   - what to read first, by path, with what each file holds;
   - what to do, and where a default stands and where to stop and ask;
   - how it lands its work (the project's way);
   - this sentence, as is: *Michael reads your messages and your PR with no source file open: call everything by what
     it is with its code after it ("the slim-suite phase (D6)"), say what a reference says and then where it lives,
     and give each number with its unit and what it is compared with.*
   - its closing report: what is on main, the numbers, what is Michael's to decide, and the supervisor's start command
     as the next step.

   A harness run's brief names the milestones and their order, says to proceed on the spec's defaults and mark them,
   and asks for the same plain writing in the PR body and the decision file.
4. **Write down what is expected,** per piece. The supervisor compares results with what the list says and nothing
   else: a number with a threshold, a file with its sections, a test count. Mark a guess as a guess.
5. **Fill the rest of the list:** the goal in plain words; Names (every code and coined term you used); Decisions
   (what Michael already decided, with the date, and what is still open); the effort's rules (only what `CLAUDE.md`
   does not say: what binds beyond it, the order, what to check hardest, what happens when a check misses, when the
   effort is done).
6. **Read it as Michael would,** with nothing else open: every row and block must make sense alone. Then as a cold
   session would: every path exists, every command is complete, every `needs` names a piece of the list.
7. **Land it** the way the project lands any change, and tell Michael: the effort in three lines, the pieces in order
   by name, what he must decide before the first piece, and the command that starts the supervisor.

## An effort that ran this way

`docs/plans/2026-11-03-test-suite-redesign-dispatch.md` in agent-harness, with its plan and its phase specs beside it:
the effort this procedure was drawn from. It predates the Names, Decisions and Log sections; read it for how a block
and a prediction are written, not for its layout.
