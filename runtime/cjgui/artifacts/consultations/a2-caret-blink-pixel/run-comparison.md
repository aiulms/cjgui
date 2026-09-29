# A2 target-eligibility run comparison

Both probe runs used the same blink-only public TextInput scenario, queried accepted display byte 17 and required the same drawable pixel transitions; neither relaxed its pass criteria.

- 2026-09-29 11:47:34, PID 8081, probe source SHA-256 `e4c8d11aacb10d7c04a1ec4bdcc23aee714edb6216df74ac13794f00acb4fa50`, renderer source SHA-256 `a7673be5e21173e574cc578b79f1b22fc9d831f917f169fdcb336427010fe145`: test clock returned `started=0/0/0`; `hasCaretRect=0`; drawable reads were incomplete (`read=99`); accepted geometry was unchanged at `x=125.507812,y=6,w=1.5,h=18`; text work counters were unchanged. See `run-blink-only-ineligible.log`.
- 2026-09-29 12:02:00, PID 22030, same probe source SHA-256; renderer included only env-gated TESTING snapshot logging: focus/clock snapshots show all target gates true and overlay/view target identity equal; phase pixel and work assertions all passed. See `run-diagnostics.log`.

The first failure is an eligibility/readiness failure before a usable pixel sample, not an observed white caret. The second run does not reproduce it. No evidence isolates whether the earlier failure came from window activation, responder lifetime, or another timing/order effect; the comparison must not be presented as a confirmed fix to any one of those causes.
