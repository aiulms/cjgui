# P1 experimental public submit shell visibility manifest

## Purpose

This manifest fixes the first experimental queue submit shell visibility boundary after `runtime_queue_public_submit.cj` landed. It prevents accidental public surface expansion while the queue path is still value-style and not a real enqueue / storage / drain runtime.

## Owner

- Owner file: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_submit.cj`
- Input endpoint: `CjguiInternalQueuePublicNoStableCompatibility`
- Current endpoint: `CjguiInternalQueueExperimentalSubmitResult`

## Visibility Rules Used

- Top-level declarations default to `internal`.
- `public` top-level declarations are globally visible.
- A `public` declaration signature cannot expose internal types.
- A `public` function body may use internal declarations.
- Therefore the current shell may expose only a Bool projection and must not expose internal queue owner facts.

## Public Symbol Allowlist

Currently allowed:

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

Currently not allowed:

- Any second public symbol.
- Any structured public return value.
- Any public signature exposing internal queue owner types.
- Any public C ABI entry.
- Any symbol using enqueue terminology.
- Any public surface that performs real enqueue, queue storage write, drain, scheduler / event loop, platform callback, runtime cycle, or runtime global state write.

## Hardening Result

- `runtime_queue_public_submit.cj` now records the allowlist in the owner header.
- The allowed shell has a nearby Chinese maintenance comment stating that it is experimental, Bool-only, carries no stable compatibility promise, does not use real enqueue terminology, is not a C ABI entry, and does not produce a real side effect.
- No second public symbol was added.
- The Bool-only signature was preserved.
- No helper, Request+Report layer, five-piece sanity, storage write, drain, scheduler, event loop, runtime cycle, or `runtime_state.cj` change was introduced.

## Verification Expectations

- Declaration-level public scan must only find `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- Naming scan must not find new enqueue terminology in `runtime_queue_public_submit.cj`.
- C ABI / native scan must not find foreign / C ABI / raw pointer / native handle intake.
- `runtime_state.cj` remains untouched and stays at the current 10065-line critical warning until a separate owner split plan is approved.

## Next Decision

Next opening should be docs-only:

`P1 internal Queue experimental public submit shell hardening closure / next public submit result-boundary decision`

That decision should compare submit result hardening, submit result handoff, milestone stabilization, rollback / disable shell, second public symbol, public C ABI, real enqueue, drain / scheduler, and runtime-state integration. Default posture remains no second public symbol.
