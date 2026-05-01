# P1 public submit Bool result next-boundary decision

## Scope

- Opening: `P1 internal Queue experimental public submit shell hardening closure / next public submit result-boundary decision`
- Current public symbol allowlist: `cjguiExperimentalQueueSubmitShellReady(): Bool`
- Current owner: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_submit.cj`
- Current internal endpoint: `CjguiInternalQueueExperimentalSubmitResult`
- Decision date: 2026-05-01

This is a docs-only boundary decision. It does not write runtime code, does not change the Bool-only public shell signature, and does not add a second public symbol.

## Current Facts

- The experimental public submit shell hardening / visibility manifest is complete.
- The only declaration-level public symbol remains `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- The public shell exposes only `Bool`, not internal owner types.
- There is no `enqueue` naming in the public submit owner.
- There is no C ABI / foreign / raw pointer / native handle intake.
- There is no module-level `var`.
- The shell still has no stable public API compatibility promise.
- The shell is not real enqueue, does not write process-wide queue storage, does not drain, and does not connect scheduler / event loop / runtime cycle.
- `runtime_state.cj` remains a 10065-line critical-warning file and must not be touched by the next opening.

## Candidate Comparison

### A. Milestone / manifest stabilization

Risk is lowest, but the visibility manifest was just completed. Without new drift, choosing another stabilization round would mostly restate the same allowlist and slow the runway without improving result semantics.

Decision: not selected.

### B. Public submit result hardening boundary

This is the best next step. It keeps the public surface fixed while hardening what the existing Bool-only shell means. The next owner can consume `CjguiInternalQueueExperimentalSubmitResult` and express internal value facts for:

- Bool shell result contract.
- Diagnostic projection.
- No-stable-compatibility guarantee.
- No-enqueue guarantee.
- No-public-C-ABI guarantee.

This improves the safety of the first public symbol without adding another public symbol or changing the existing signature.

Decision: selected.

### C. Structured public result API

This would enlarge the public compatibility surface immediately after the first Bool-only shell. It should wait until the Bool result contract is hardened and a later decision explicitly approves structured return shape.

Decision: rejected.

### D. Second public symbol

The allowlist has just been hardened. Adding a second public symbol now would undercut the visibility manifest and make compatibility review harder.

Decision: rejected.

### E. Public C ABI boundary

C ABI remains out of scope. It would require stable handle, lifecycle, error ABI, native boundary, and compatibility decisions that do not exist yet.

Decision: rejected.

### F. Real enqueue implementation

The Bool shell result is not enqueue permission. Real enqueue remains blocked until public surface, storage mutation, rollback, and lifecycle decisions explicitly approve it.

Decision: rejected.

### G. Drain / scheduler / event loop

This remains too early and would approach runtime cycle behavior from a public shell that still only exposes Bool readiness.

Decision: rejected.

### H. Runtime state integration

This would approach global runtime state and the critical `runtime_state.cj` owner. It remains blocked.

Decision: rejected.

### I. Rollback / hide public shell

There is no current build, visibility, or compatibility failure that requires hiding or rolling back the shell. The safer response is hardening, not reversal.

Decision: not selected.

### J. Tail consolidation

No clear dead helper, duplicate projection, or same-owner self-wrapping was identified. Cleanup for its own sake is not justified.

Decision: not selected.

## Final Decision

Choose:

`P1 internal Queue public submit Bool result hardening boundary bundle implementation`

Next opening:

- New owner file: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_submit_result.cj`
- Input: only `CjguiInternalQueueExperimentalSubmitResult` or direct current experimental submit result facts.
- Output: internal Bool result contract / diagnostic projection / no-stable-compatibility / no-enqueue guarantee value facts.
- Do not add a second public symbol.
- Do not modify `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- Do not introduce structured public return.
- Do not use `enqueue` naming.
- Do not implement public C ABI.
- Do not real enqueue, write process-wide queue storage, drain, connect scheduler / event loop, or run runtime cycle.
- Do not touch `runtime_state.cj`.

## Next Opening Guardrails

The implementation may create an internal owner that explains the existing Bool shell result semantics, but it must not widen public visibility. The current public symbol allowlist remains:

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

Any second public symbol, richer public return, C ABI, real enqueue, or stable compatibility promise requires a separate decision.

## Validation

- `git diff --check`: required.
- README / GUI_TASK_TRACKER / docs/plans README must find this decision and the next opening.
- Markdown absolute-link missing target check: required.
- Forbidden file check: required; runtime code, `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke, harness, native bridge, entry files, `AGENTS.md`, `CLAUDE.md`, and `CANGJIE_ISSUE_LEDGER.md` must remain untouched.
- Public declaration scan is recommended; allowlist must remain only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- No build / smoke is required for this docs-only decision unless runtime code changes unexpectedly.
