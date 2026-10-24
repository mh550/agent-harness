status: run
<!-- Steer this run from the GitHub app: edit this file on branch harness/rane-one-mixxx-2026-10-24.
     Change the first line to "status: pause" or "status: stop"; write answers to questions under "## Answers".
     The harness pulls before every session; every session reads this file at startup. -->

## Question (M5-06, parked 2026-10-24)
M5-06 step 4 wants the pitch fader's bottom (value 0) on deck 2 (take 24) within ±0.5 % of the function. It can't be:
deck 2 at 0 ran 0.464×, 0.496× and 0.493× in the three sweeps (host-time tick counts agree, so it is the motor, not
the timer). It reaches 0.500× in sweeps 2 and 3, then sags (torque LOW). One value, three speeds: no function fits.
Pick one and write it under `## Answers`:
- **(a)** Change step 4 to: "deck 1's top/centre/bottom and deck 2's top/centre within ±0.5 %; deck 2's bottom pinned
  as a sag (0.8–7.3 % under 0.5×), reaching 0.5× ±0.5 % in a 250 ms window in sweeps 2 and 3". (Recommended; this is
  what the tests already do.)
- **(b)** Keep step 4. M5-06 then waits for round 2's torque-HIGH take of deck 2 at the fader's bottom
  (`HARDWARE-TESTS.md` Round 2) to show whether deck 2 holds 0.5× there.

## Answers
