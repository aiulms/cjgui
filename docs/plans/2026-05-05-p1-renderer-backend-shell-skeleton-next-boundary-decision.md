# P1 Renderer backend shell skeleton next-boundary decision

日期：2026-05-05

状态：docs-only next-boundary decision

## Scope

本轮评估 `CjguiInternalRendererNoResourceBackendShellReadiness` 是否已经足够作为当前 no-resource-backend-shell endpoint，并决定下一步是否先做 manifest stabilization。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer；不调用 `commit`、`present`、`nextDrawable`、Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [Backend shell skeleton owner source](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_shell_skeleton.cj)
- [Backend shell skeleton no-resource value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-backend-shell-skeleton-no-resource-value-boundary-closure-review.md)
- [Backend shell first implementation slice preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-first-implementation-slice-preflight-decision.md)
- [Command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)

## Decision

`CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()` is sufficient as the current no-resource-backend-shell endpoint.

选择 A：`P1 internal Renderer backend shell skeleton manifest stabilization bundle implementation`。

The next round must remain docs-only manifest stabilization. It may fix the owner / truth / canonical endpoint / stop-line for `runtime/cjgui/src/runtime_renderer_backend_shell_skeleton.cj`; it must not implement a backend shell object, backend object, platform object, native handle, raw pointer, Metal / AppKit bridge, GPU submission, render execution, renderer state write, public API or C ABI.

唯一 next opening：

`P1 internal Renderer backend shell skeleton manifest stabilization bundle implementation`

## Endpoint Truth

The current endpoint represents only these value facts:

- backend shell skeleton intent.
- backend shell lifecycle envelope.
- backend shell no-resource guard.
- backend shell failure rollback policy.
- backend shell teardown confinement policy.
- no-resource-backend-shell readiness.

It is not:

- backend shell implementation permission.
- backend shell object permission.
- backend object permission.
- native handle permission.
- raw pointer permission.
- platform object permission.
- Metal / AppKit bridge permission.
- `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue` permission.
- drawable / command buffer permission.
- GPU submission permission.
- render permission.
- renderer state write permission.
- public API or C ABI permission.

## Evidence

The source owner provides a real endpoint, not a thin wrapper:

- `CjguiInternalRendererBackendShellSkeletonIntent` records future skeleton lifecycle, no-resource, failure rollback and anti-wrapper facts.
- `CjguiInternalRendererBackendShellLifecycleEnvelope` records future create / active / degraded phase facts, no-object lifecycle facts and no-draw fallback facts.
- `CjguiInternalRendererBackendShellNoResourceGuard` confirms no backend shell instance, no backend object, no platform object, no foreign resource token, no pointer-like resource and no bridge call.
- `CjguiInternalRendererBackendShellFailureRollbackPolicy` records failure reason, rollback no-draw and degraded fallback facts while avoiding completion observation, callback registration and telemetry output.
- `CjguiInternalRendererBackendShellTeardownConfinementPolicy` records teardown ordering, idempotent teardown and confinement facts while avoiding foreign teardown calls, resource release side effects, bridge / smoke / harness / entry changes, renderer state mutation and external API surface.
- `CjguiInternalRendererNoResourceBackendShellReadiness` seals the no-resource-backend-shell facts and rejects backend-shell-ready permission wrapper, native resource wrapper, platform object wrapper, device-layer wrapper, work-submit wrapper, render-permission wrapper, tail wrapper and receipt / record / publication shapes.

The closure verified that open path produces only value facts, defer-only remains deferred, and blocked / inconsistent paths fail closed. Its GitNexus impact scan returned `UNKNOWN / not found` for the recent upstream symbols and used source / build / smoke / scans / detect_changes as fallback; no HIGH / CRITICAL impact was reported.

Command submission remains upstream value evidence only: `CjguiInternalRendererNoGpuSubmissionReadiness` is the single runtime input consumed by the default draft, and it does not grant command buffer commit, drawable present, GPU submission, render, backend implementation, renderer state write, public API or C ABI permission.

No-draw backend shell remains broader lifecycle evidence only. It is not a runtime input for the skeleton owner and does not become backend shell object permission.

## Candidate Comparison

### A. P1 internal Renderer backend shell skeleton manifest stabilization bundle implementation

推荐。

The endpoint is sufficiently expressive to freeze the owner / truth / canonical endpoint / stop-line. Manifest stabilization is the right next step because it closes the no-resource-backend-shell endpoint without adding runtime behavior.

### B. Native resource bridge preflight

暂缓。

Native bridge / handle ownership is still too close to resource creation, FFI teardown, ABI shape and smoke / bridge modification. It should wait until the skeleton manifest is sealed.

### C. Platform object implementation preflight

暂缓。

Platform object creation / retain / release / teardown / failure must not reopen before the no-resource skeleton endpoint is manifest-stabilized.

### D. Metal device-layer implementation preflight

暂缓。

Device / layer creation remains downstream of no-resource skeleton, platform object and bridge confinement decisions. No `MTLDevice` or `CAMetalLayer` runway is opened here.

### E. Render completion / frame completion tracking preflight

暂缓。

Completion tracking remains close to callbacks, observers, telemetry and renderer state visibility. It should not precede backend shell skeleton manifest stabilization.

### F. Backend shell lifecycle hardening

暂缓，仅在发现不足时选择。

Current evidence covers lifecycle envelope, no-resource guard, failure rollback and teardown confinement. No hardening gap was found in this decision.

### G. Direct backend shell implementation

拒绝。

No backend shell object, backend object or backend implementation is approved.

### H. Direct native handle / raw pointer implementation

拒绝。

No native handle, raw pointer, foreign resource token or pointer-like storage is approved.

### I. Direct Metal / AppKit / Objective-C / FFI implementation

拒绝。

No Metal, AppKit, Objective-C, FFI or bridge call is approved.

### J. GPU submission / render execution

拒绝。

No command buffer commit, drawable present, GPU submission, render execution, render pass, encoder, pipeline state or draw call is approved.

### K. Renderer state write

拒绝。

No renderer state mutation and no `runtime_state.cj` write are approved.

### L. Public API / C ABI expansion

拒绝。

The public declaration allowlist remains unchanged.

### M. Receipt / record / publication

拒绝。

Do not add backend shell skeleton receipt / record / publication, backend-shell-ready permission wrapper, resource wrapper, GPU wrapper or render-permission wrapper.

### N. Consolidation

暂缓。

No duplicate / low-value / self-wrapping evidence was found. The next useful action is manifest stabilization, not deletion.

## Same-shape Boundary Brake

`CjguiInternalRendererNoResourceBackendShellReadiness` must not be wrapped into another tail endpoint.

This decision explicitly rejects:

- backend-shell-ready permission wrapper.
- native-handle wrapper.
- platform-object wrapper.
- Metal-device wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- receipt / record / publication.

The current endpoint already carries the new skeleton lifecycle envelope / no-resource guard / failure rollback / teardown confinement / no-resource-backend-shell semantics. Future work must not repackage it as a permission-shaped endpoint.

## Validation Plan

This docs-only decision should be verified with:

- `git diff --check`
- new decision no-index whitespace check.
- Markdown absolute link missing target check scoped to project docs and excluding `reference_repos/`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability.
- forbidden check: no tracked `.cj` diff, no protected path diff / status, `runtime_state.cj` line count remains `10065`.
- public declaration scan still finds only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`.

Build and smoke must not be run in this docs-only round.

## Downstream Backend Shell Skeleton Manifest Stabilization

Backend shell skeleton manifest stabilization 已完成：

- [2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md)
- [2026-05-05-p1-internal-renderer-backend-shell-skeleton-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-backend-shell-skeleton-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_backend_shell_skeleton.cj` owner / truth / canonical endpoint / stop-line，并封账 `CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`。

Downstream next opening：

`P1 internal Renderer native resource bridge preflight decision`
