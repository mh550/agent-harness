status: run
<!-- Steer this run from the GitHub app: edit this file on branch harness/rane-one-mixxx-2026-10-19.
     Change the first line to "status: pause" or "status: stop"; write answers to questions under "## Answers".
     The harness pulls before every session; every session reads this file at startup. -->

## Question (2026-10-19 18:05, M1-04): amend step 3? It cannot hold as written
M1-04 step 3 wants the Mixxx version line in `dev-profile/mixxx.log`. Mixxx 2.5.6 can't write it there while it
runs with `--controller-debug`, and step 1 (and CLAUDE.md) require that flag. Checked against the `2.5.6` tag:
`VersionStore::logBuildDetails` logs "Mixxx 2.5.6 … is starting" with `qDebug` in the default category, and
`controllerDebugCategoryFilter` (`src/util/logging.cpp`) turns Debug off for every category except `js` and
`controller.*`. No env var or `--log-level` gets around that. The only other version line, "Configuration file is
at the current version", is printed before `Logging::initialize`, so it goes to stdout only. All 8 dev logs so
far: 0 version lines. The launcher already handles this (D10): it treats Mixxx as started when a **new** `mixxx.log`
exists and this launch's `dev-profile/mixxx-dev.stdout` has `Configuration file is at the current version "2.5.6"`.
I won't write a line into Mixxx's log myself, because that would be faking it.
**Please pick one** (my recommendation is a):
- **a)** Amend step 3: "… produces a new `dev-profile/mixxx.log` within 60 s, and `dev-profile/mixxx-dev.stdout`
  contains `Configuration file is at the current version "2.5.6"` …" (the rest of the step unchanged).
- **b)** Drop `--controller-debug` from the dev launch. That changes CLAUDE.md, and it hides the mapping's debug output.

## Answers

### 2026-10-20 08:14 (local)
M1-04: option (a). I amended step 3 in feature_list.json (new mixxx.log within 60 s + this launch's mixxx-dev.stdout has the 'Configuration file is at the current version "2.5.6"' line). Keep --controller-debug. M1-05: step 5 amended too: shutdown() is proven by a hot reload (re-run tools/install-mapping), not by stop.

### 2026-10-21 14:56 (local)
Michael, 2026-10-21 ~13:40, answers to progress.md 'Questions for Michael'.
Q1: Yes, note 0 on channel 1 was the Play button. My hand was on the record during the 3 s hold. I did not press Play to turn the motor on or off. If note 0 still lines up with motor start/stop in the capture, record what you conclude as a D-default and carry on; don't stop for it.
Q2: 33⅓. I re-measured today and the decks spin at 33⅓.
Q3: D13 stands; D9's night-time port rule is superseded. D9 in docs/decisions.md gets an in-place update on main (current rule only, one superseded-by line). Drop Q3 from progress.md; don't re-ask it.
Q4: I'll run HARDWARE-TESTS.md later today.
Note: around 13:00-13:40 I was turning deck 2 by hand to check its speed. Any live MIDI from the One in that window was me, not a test: discard it.
