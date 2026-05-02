# P1 public submit Bool result hardening next-milestone decision

## Scope

- Opening: `P1 internal Queue public submit Bool result hardening closure / next public submit result-boundary decision`
- Current owner: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_submit_result.cj`
- Current endpoint: `CjguiInternalQueuePublicSubmitNoQueueWriteGuarantee`
- Current public symbol allowlist: `cjguiExperimentalQueueSubmitShellReady(): Bool`
- Decision date: 2026-05-01

This is a docs-only boundary decision. It does not write runtime code, does not modify the Bool-only public shell signature, and does not add a second public symbol.

## Current Facts

- `P1 internal Queue public submit Bool result hardening boundary bundle implementation` is complete.
- `runtime_queue_public_submit_result.cj` now fixes the internal Bool shell result contract, diagnostic projection, no-stable-compatibility facts, and no-real-queue-write guarantee.
- The only allowed public symbol remains `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- The Bool-only signature is preserved.
- No structured public return exists.
- No second public symbol exists.
- There is no public C ABI, no raw pointer / native handle intake, and no real queue write.
- There is no queue drain, scheduler, event loop, or runtime cycle connection.
- `runtime_state.cj` remains a 10065-line critical-warning file and must not be touched by the next opening.

## Candidate Comparison

### A. Public submit shell milestone / manifest stabilization

This is the best next step. The first experimental public shell has now passed three gates: visibility allowlist, Bool-only shell hardening, and internal Bool result hardening. A milestone manifest can freeze the current public surface before any further public result expansion is considered.

Value:

- Records the single-symbol allowlist as milestone truth.
- Freezes Bool-only result contract and no-stable-compatibility facts.
- Records no-real-queue-write guarantee as the current public submit shell stop-line.
- Prevents accidental drift into a second public symbol or structured return.

Decision: selected.

### B. Second public symbol preflight

This remains premature. The first public symbol has only just been hardened, and the next safe move is to stabilize the milestone before discussing any wider visibility.

Decision: deferred.

### C. Structured public result preflight

This would widen the compatibility surface from Bool-only readiness into richer result shape. It should wait until the milestone manifest has explicitly frozen the existing Bool result contract.

Decision: deferred.

### D. Real public API implementation

This is rejected. The current shell remains experimental and does not carry stable public API compatibility.

Decision: rejected.

### E. Public C ABI

This remains out of scope. C ABI requires stable handle, lifecycle, and error ABI decisions that are not present.

Decision: rejected.

### F. Real enqueue / queue write

This is rejected. `CjguiInternalQueuePublicSubmitNoQueueWriteGuarantee` explicitly records that the public submit Bool result hardening is not a real queue write.

Decision: rejected.

### G. Drain / scheduler / event loop

This is rejected. The public submit shell is not a scheduler, drain, or runtime cycle boundary.

Decision: rejected.

### H. Runtime state integration

This is rejected. It would approach global runtime state and critical `runtime_state.cj`.

Decision: rejected.

### I. Tail consolidation

No clear dead helper, duplicate projection, or same-owner self-wrapping was identified. Consolidation is not justified.

Decision: not selected.

## Final Decision

Choose:

`P1 internal Queue experimental public submit shell milestone stabilization bundle implementation`

Next opening:

- Primary output: `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-experimental-public-submit-shell-milestone-manifest.md`
- Runtime code: default no runtime code.
- Source comments: only if needed for manifest alignment; do not change behavior or signatures.
- Public allowlist remains exactly `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- No second public symbol.
- No structured public return.
- No Bool-only signature change.
- No public C ABI.
- No real queue write.
- No drain / scheduler / event loop / runtime cycle.
- No `runtime_state.cj` touch.

## Next Opening Guardrails

The milestone stabilization should make the current public submit shell facts easy to audit:

- Visibility truth: one experimental public symbol only.
- Result truth: Bool-only readiness projection only.
- Compatibility truth: no stable public API promise.
- Storage truth: no queue write, no process-wide storage mutation, no global mutable queue.
- Runtime truth: no drain, scheduler, event loop, platform callback, or runtime cycle.

Any future second public symbol, structured result, C ABI, real queue write, or stable compatibility promise must start from a separate preflight / decision after this milestone.

## Validation

- `git diff --check`: required.
- README / GUI_TASK_TRACKER / docs/plans README must find this decision and the next opening.
- Markdown absolute-link missing target check: required.
- Forbidden file check: required; runtime code, `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke, harness, native bridge, entry files, `AGENTS.md`, `CLAUDE.md`, and `CANGJIE_ISSUE_LEDGER.md` must remain untouched.
- Public declaration scan is recommended; allowlist must remain only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- No build / smoke is required for this docs-only decision unless runtime code changes unexpectedly.
