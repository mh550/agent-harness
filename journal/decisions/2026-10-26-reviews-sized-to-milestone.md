# Reviews sized to the milestone: small milestones fold the review into their last build feature

*(2026-10-26, run agent-harness-2026-10-26-2, feature F2-04; spec `docs/specs/2026-10-21-retro-fixes.md` R2, plan
`docs/plans/2026-10-26-F2-initializer-verify.md` § R2)*

- **Finding:** the initializer's milestone pattern asked every milestone for a closing review + simplify feature,
  however small. Six retros (v2-2026-10-18, agent-harness-2026-10-19, rane-one-mixxx-2026-10-19,
  portfolio_site-2026-10-20, portfolio_site-2026-10-20-2, voice-concierge-2026-10-20) found review features costing
  up to 24 % of a run: a whole session (orientation, the suite, an Opus reviewer, the verify after it) spent on a
  milestone of one or two build features whose diff a subagent inside the last build session could have read.
- **Choice:**
  - `prompts/initializer.md` item 4 of the milestone pattern: a milestone with one or two build features folds its
    review into the last build feature's steps (`an Opus subagent reviews the diff; Critical/Important findings
    fixed`); a milestone of three or more keeps one closing review + simplify feature, one Opus round by default
    and a second only when the first found something Critical. The lint line in the prompt adds "a review the
    milestone's size doesn't call for".
  - Two more step-lint rules in `lint()` (`lib/features.mjs`, decisions/2026-10-26-step-lint), milestone-level
    (`step -`), kinds as `kindOf` gives them (explicit `kind`, else inferred), features without a milestone skipped:
    **`review-small`** on each review feature of a milestone with one or two build features (`<m> has <n> build
    feature(s): fold the review into <last build id>'s steps`); **`review-missing`** on the last feature of a
    milestone with three or more build features and no review (`<m> has <n> build features and no review
    feature`). A milestone of plan, docs and check features only gets neither. Reported, never applied, like the
    other rules: the initializer fixes them, the driver's `lint:` note counts what is left.
  - `summary.mjs` keeps its role list (`init plan build review check docs verify retro`), so `Spend by role` shows
    the review share falling, or not, in the ledger.
- **Rejected:**
  - No review at all for small milestones: verify re-checks the steps but nobody reads the diff for what the steps
    don't cover; an in-session subagent review is cheap and keeps that.
  - A reviewer per build feature: the cost the finding is about, multiplied.
  - The spec's own check ("a stub spec with a two-feature milestone yields no `review` feature"): the stub
    initializer writes a fixed list, so no stub run can show the initializer following the rule. The lint rules
    (pure checks) and a grep of the rendered initializer prompt stand in for it; whether real initializers follow
    it shows in the `lint:` note of real runs.
