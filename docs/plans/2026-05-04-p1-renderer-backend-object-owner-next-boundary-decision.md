# P1 Renderer backend object owner next-boundary decision

日期：2026-05-04

状态：docs-only next-boundary decision

## Scope

本轮 docs-only 评估 `CjguiInternalRendererNoBackendObjectReadiness` 是否已经足够作为当前 no-backend-object endpoint，并决定下一步是否先做 manifest stabilization，还是进入 frame pacing / renderer state write / backend-readiness 相关 preflight。

本轮不修改 `.cj`，不实现 backend / Metal / AppKit / platform object / command buffer commit / GPU submission / render execution / renderer state write，不运行 build / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

## Read Inputs

- [2026-05-04-p1-internal-renderer-backend-object-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-object-owner-value-boundary-closure-review.md)
- [2026-05-04-p1-renderer-backend-object-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Decision

`CjguiInternalRendererNoBackendObjectReadiness` is sufficient as the current no-backend-object endpoint.

Choose:

`P1 internal Renderer backend object owner manifest stabilization bundle implementation`

Rationale：

- The runtime owner exists and is isolated in `runtime/cjgui/src/runtime_renderer_backend_object.cj`.
- The canonical endpoint is `CjguiInternalRendererNoBackendObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`.
- The endpoint now carries distinct backend object owner intent / backend lifecycle ownership policy / backend acceptance gate / platform confinement guard / no-backend-object readiness value facts.
- The endpoint preserves the no-backend-object / no-platform-object / no-render stop-line and is not a backend object receipt / record / publication.
- Frame pacing, renderer state write and backend-readiness are still future preflight topics; they should not be opened before the backend object owner truth is manifest-stabilized.

## Current Endpoint Truth

Current owner:

- `runtime/cjgui/src/runtime_renderer_backend_object.cj`

Current upstream:

- `CjguiInternalRendererNoRenderExecutionReadiness`
- `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`

Current endpoint:

- `CjguiInternalRendererNoBackendObjectReadiness`
- `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`

Current truth:

- backend object owner intent value facts.
- backend lifecycle ownership policy value facts.
- backend acceptance gate value facts.
- platform confinement guard value facts.
- no-backend-object readiness value facts.

`CjguiInternalRendererNoBackendObjectReadiness` is not backend object permission, backend-readiness permission, platform resource permission, command buffer commit permission, GPU submission permission, render execution permission, renderer state write permission, frame pacing permission, public API, receipt, record or publication.

## Candidate Comparison

### A. P1 internal Renderer backend object owner manifest stabilization bundle implementation

推荐。

It should fix owner file, current truth, canonical endpoint, default draft and stop-line. This is the right next step because the endpoint is already semantically sufficient, but the owner / truth / canonical endpoint / stop-line have not yet been recorded as a manifest.

### B. Frame pacing owner preflight

暂缓。

Frame pacing remains an important future owner question from the backend / Metal reference pack, but it should wait until backend object owner manifest stabilization fixes what backend object owner does and does not own. The no-backend-object endpoint is not frame pacing permission.

### C. Renderer state write preflight

暂缓。

Renderer state write remains a hard stop-line. It should wait until backend object owner manifest stabilization has closed the no-backend-object endpoint, and even then it must be a docs-only preflight before any implementation.

### D. Backend-readiness value boundary revisit

暂缓。

Backend-readiness was previously blocked by missing backend object owner truth. The value boundary now supplies that truth, but it should be manifest-stabilized before reopening backend-readiness so the revisit cannot become a thin wrapper over `CjguiInternalRendererNoBackendObjectReadiness`.

### E. Backend object hardening

Only if a gap is found.

Current closure did not find lifecycle ownership / acceptance gate / platform confinement expression gaps. If manifest stabilization discovers ambiguity, choose hardening before any downstream boundary.

### F. Backend object receipt / record / publication

拒绝。

This would be a thin wrapper over the current endpoint.

### G. Backend-readiness wrapper

拒绝。

Backend-readiness must not be reopened as a wrapper. It requires a separate docs-only revisit after manifest stabilization.

### H. Backend / Metal implementation

拒绝。

### I. Platform object / native handle implementation

拒绝。

### J. Command buffer commit / GPU submission / render execution implementation

拒绝。

### K. Renderer state write implementation

拒绝。

### L. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### M. Public surface expansion

拒绝。

### N. Consolidation

Only if clear duplicate / low-value helper / self-wrapping evidence appears.

Current evidence does not show duplicate or low-value owner shape. The risk is downstream thin wrapping, not consolidation need.

## Same-shape Boundary Brake

Same-shape Boundary Brake is active.

`CjguiInternalRendererNoBackendObjectReadiness` is already the current no-backend-object endpoint. This decision does not approve:

- backend object receipt / record / publication.
- backend-readiness wrapper.
- renderer-state-write readiness wrapper.
- command-buffer-commit readiness wrapper.
- GPU-submission wrapper.
- frame pacing readiness wrapper.
- backend object implementation.
- platform object implementation.

Future frame pacing / renderer state write / backend-readiness work must start with docs-only preflight and cite concrete evidence from the backend object owner manifest and backend / Metal reference pack. It cannot directly implement backend, platform objects, command buffer commit, GPU submission, render execution or renderer state write.

## Unique Next Opening

`P1 internal Renderer backend object owner manifest stabilization bundle implementation`

Next round remains docs-first. It should add a manifest and closure that fix:

- owner file：`runtime/cjgui/src/runtime_renderer_backend_object.cj`
- canonical endpoint：`CjguiInternalRendererNoBackendObjectReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`
- current truth：backend object owner intent / backend lifecycle ownership policy / backend acceptance gate / platform confinement guard / no-backend-object readiness value facts
- stop-line：no backend object, no platform object, no native handle / raw pointer, no command buffer commit, no GPU submission, no render execution, no renderer state write

## Validation

Validation results are recorded in the task response for this docs-only round:

- `git diff --check`
- Markdown absolute link missing target check, project docs scope.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability.
- Forbidden path check.
- Public declaration scan.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`.

This round intentionally did not run `cjpm build` or smoke.
