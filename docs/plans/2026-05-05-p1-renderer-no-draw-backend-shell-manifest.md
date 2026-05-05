# P1 Renderer no-draw backend shell manifest

日期：2026-05-05

状态：docs-only manifest stabilization

## Scope

本 manifest 固定 `runtime_renderer_no_draw_backend_shell.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-backend-shell lifecycle endpoint。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 backend shell object、backend object、platform object、native handle、raw pointer，不接 `MTLDevice` / `CAMetalLayer`，不接 Objective-C / Metal / AppKit / FFI，不创建 command queue、drawable、command buffer、render pass、encoder、pipeline state，不 commit / present / submit GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Canonical Owner

Owner file：

- [runtime_renderer_no_draw_backend_shell.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_no_draw_backend_shell.cj)

Runtime input：

- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`

Default draft：

- `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()` first obtains `CjguiInternalRendererNoMetalDeviceLayerReadiness` from `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`.
- It builds no-draw backend shell intent, backend shell lifecycle policy, no-draw execution gate, shell teardown policy and no-backend-shell readiness in owner-local value facts.
- It does not create or retain a backend shell object, backend object, platform object, native handle, raw pointer, `MTLDevice`, `CAMetalLayer`, command queue, drawable, command buffer, render pass, encoder or pipeline state.
- It does not call FFI / Objective-C / Metal / AppKit APIs, does not modify bridge / smoke / harness / native entry, does not commit / present / submit GPU work, does not render, does not write renderer state, and does not expand public API / C ABI.

## Current Truth

The current truth is exactly:

- no-draw backend shell intent value facts.
- backend shell lifecycle policy value facts.
- no-draw execution gate value facts.
- shell teardown policy value facts.
- no-backend-shell readiness value facts.

The canonical value chain is:

1. `CjguiInternalRendererNoMetalDeviceLayerReadiness`
2. `CjguiInternalRendererNoDrawBackendShellIntent`
3. `CjguiInternalRendererBackendShellLifecyclePolicy`
4. `CjguiInternalRendererNoDrawExecutionGate`
5. `CjguiInternalRendererShellTeardownPolicy`
6. `CjguiInternalRendererNoBackendShellReadiness`

## Value Semantics

`CjguiInternalRendererNoDrawBackendShellIntent` only records future no-draw backend shell intent facts. It is not a backend shell object, backend implementation permission, backend object permission or platform object permission.

`CjguiInternalRendererBackendShellLifecyclePolicy` only records future init / active / degraded / no-backend-object lifecycle facts. It does not create a backend shell object, does not create a backend object, and does not manage real backend lifecycle.

`CjguiInternalRendererNoDrawExecutionGate` only records no-draw / no-submit / no-render admission facts. It does not execute render, does not submit GPU work, does not commit command buffer, and does not present drawable.

`CjguiInternalRendererShellTeardownPolicy` only records future teardown ordering / failure rollback / idempotent cleanup facts. It does not execute real teardown, retain, release, destroy or foreign teardown calls.

`CjguiInternalRendererNoBackendShellReadiness` seals current no-backend-shell readiness facts. It is not backend shell permission, backend implementation permission, backend object permission, platform object permission, GPU submission permission, render permission, renderer state write permission, diagnostics permission, public API permission or C ABI permission.

## Relationship Facts

No-draw backend shell facts relate to upstream Metal device-layer facts only as dehydrated value facts:

- The upstream no-metal-device-layer endpoint remains the only runtime input.
- Device selection, layer binding and scale-color-space facts are evidence only; no device or layer is created.
- Backend platform object owner facts remain evidence only; no native resource ownership is materialized.
- Backend-readiness branch milestone remains evidence only; this manifest does not re-open backend-ready permission.
- Future command queue / drawable real lifecycle, command buffer commit, GPU submission and render execution require separate docs-only preflight before any implementation can be considered.
- Downstream real command queue lifecycle value boundary is now recorded in [2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-value-boundary-closure-review.md); it consumes this manifest's canonical no-backend-shell endpoint only as value facts.
- Downstream real command queue lifecycle next-boundary decision is now recorded in [2026-05-05-p1-renderer-real-command-queue-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-next-boundary-decision.md); it confirms the no-real-command-queue endpoint and chooses manifest stabilization before real drawable or GPU submission preflight.
- Downstream real command queue lifecycle manifest stabilization is now recorded in [2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md) and [2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-manifest-stabilization-closure-review.md); it closes the no-real-command-queue endpoint and points to docs-only real drawable lifecycle preflight.

## Explicit Non-Truth

The no-backend-shell endpoint is not:

- backend shell object permission.
- backend implementation permission.
- backend object permission.
- platform object permission.
- native handle / raw pointer permission.
- `MTLDevice` / `CAMetalLayer` permission.
- command queue / drawable permission.
- command buffer creation / commit permission.
- render pass / encoder / pipeline state permission.
- drawable present permission.
- GPU submission permission.
- render execution permission.
- renderer state write permission.
- diagnostics / event bus / observer / telemetry permission.
- public API / public C ABI permission.

## Evidence Chain

- [No-draw backend shell next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-no-draw-backend-shell-next-boundary-decision.md) confirmed `CjguiInternalRendererNoBackendShellReadiness` is sufficient as the current no-backend-shell endpoint.
- [No-draw backend shell value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-no-draw-backend-shell-value-boundary-closure-review.md) added the internal-only owner and verified the no-object / no-submit / no-render stop-line.
- [No-draw backend shell preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-no-draw-backend-shell-preflight-decision.md) proved enough shell lifecycle / no-draw / teardown evidence to open the value boundary.
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md) fixed the upstream no-metal-device-layer endpoint and denied real device / layer creation.
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md) fixed native resource ownership vocabulary without creating platform objects.
- [Backend-readiness branch milestone manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md) stabilized the no-backend-ready evidence chain and stop-line.
- [Real command queue lifecycle value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-value-boundary-closure-review.md) is downstream evidence only; it does not reopen backend shell permission, command queue materialization, GPU submission or render execution.
- [Real command queue lifecycle next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-next-boundary-decision.md) is downstream decision evidence only; it does not reopen backend shell permission, command queue materialization, GPU submission, render execution or renderer state write.

## Same-shape Boundary Brake

This round chooses manifest stabilization and closes the current no-backend-shell endpoint.

It explicitly rejects:

- no-draw backend shell receipt / record / publication.
- backend-shell-ready permission wrapper.
- backend implementation wrapper.
- backend-ready permission wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- platform-object wrapper.
- public API / C ABI wrapper.

`CjguiInternalRendererNoBackendShellReadiness` must not be wrapped into another tail endpoint unless a future docs-only preflight proves new owner / lifecycle / teardown / failure / verification semantics that are not already captured here.

## Stop-line

Future work approaching command queue / drawable real lifecycle, real backend shell, GPU submission or render execution must first pass docs-only preflight.

Until then:

- no backend shell object.
- no backend object.
- no platform object.
- no native handle.
- no raw pointer.
- no `MTLDevice`.
- no `CAMetalLayer`.
- no command queue.
- no drawable.
- no command buffer.
- no render pass.
- no encoder.
- no pipeline state.
- no FFI / Objective-C / Metal / AppKit API call.
- no bridge / smoke / harness / native entry modification.
- no command buffer commit.
- no drawable present.
- no GPU submission.
- no render execution.
- no renderer state write.
- no diagnostics / event bus / observer / telemetry.
- no public API / public C ABI expansion.

## Public Surface

The public declaration allowlist remains unchanged:

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

## Next Stage Candidate Comparison

### A. P1 internal Renderer command queue / drawable real lifecycle preflight decision

推荐为下一阶段 opening。

理由：no-draw backend shell endpoint 已封账，下一步可以 docs-only 评估 command queue / drawable real lifecycle owner、resource acquisition timing、no-submit gate、failure / no-draw fallback 与 platform confinement relation。该 preflight 不得创建 command queue、drawable、command buffer、platform object 或 GPU work。

### B. Real platform object implementation preflight

暂缓。

真实 platform object implementation 仍过早；no-backend-shell manifest 不授予 native handle、raw pointer、bridge ownership ABI 或 platform resource lifecycle implementation permission。

### C. Command buffer commit / GPU submission preflight

暂缓。

当前 no-draw execution gate 明确 no-submit / no-render，且 command queue / drawable real lifecycle 尚未完成 docs-only decision。

### D. No-draw backend shell hardening

仅在发现不足时选择。

当前 lifecycle / no-draw / teardown value facts 足够封账；没有 evidence 表明需要 hardening。

### E. Direct backend shell implementation

拒绝。

### F. Direct Metal / AppKit / Objective-C implementation

拒绝。

### G. GPU submission / render execution

拒绝。

### H. Renderer state write

拒绝。

### I. Public API / C ABI expansion

拒绝。

### J. Receipt / record / publication

拒绝。

### K. Consolidation

暂缓。

仅在明确 duplicate / low-value / self-wrapping evidence 出现时选择。当前需要的是 downstream command queue / drawable real lifecycle preflight，而不是 consolidation。

## Decision

This manifest stabilizes and closes the renderer no-draw backend shell no-backend-shell endpoint.

Unique next opening:

`P1 internal Renderer command queue / drawable real lifecycle preflight decision`

下一轮仍必须 docs-only。它只能评估 command queue / drawable real lifecycle owner、queue / drawable acquisition relation、failure / no-draw fallback、GPU submission gate 与 backend shell relation；不得创建 command queue、drawable、command buffer、render pass、encoder、pipeline state、backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`，不得调用 FFI / Objective-C / Metal / AppKit API，不得修改 bridge / smoke / harness，不得 commit / present / submit GPU work，不得执行 render，不得写 renderer state，不得扩 public API / C ABI。

## Downstream Command Queue / Drawable Real Lifecycle Preflight

Renderer command queue / drawable real lifecycle preflight 已完成：

- [2026-05-05-p1-renderer-command-queue-drawable-real-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-queue-drawable-real-lifecycle-preflight-decision.md)

该 preflight 允许打开 command queue / drawable real lifecycle runway，但要求拆成两个 owner / runway。下一步选择 docs-only `P1 internal Renderer real command queue lifecycle preflight decision`，因为 command queue ownership / creation / lifetime 是 drawable acquisition 与 command buffer creation 的更早硬前置。

Runtime input 仍建议只消费 `CjguiInternalRendererNoBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`；command queue lifecycle manifest、drawable acquisition lifecycle manifest 与 backend / Metal reference pack 只能作为 docs evidence。

Same-shape Boundary Brake 继续生效：不得把 no-backend-shell endpoint 包成 command queue / drawable receipt / record / publication、queue-ready permission wrapper、drawable-ready permission wrapper、GPU-submission wrapper 或 render-permission wrapper。

## Downstream Real Command Queue Lifecycle Preflight

Renderer real command queue lifecycle preflight 已完成：

- [2026-05-05-p1-renderer-real-command-queue-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-preflight-decision.md)

该 preflight 以 `CjguiInternalRendererNoBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()` 为唯一 runtime input candidate，允许下一步新增 real command queue lifecycle value facts owner，但不批准真实 `MTLCommandQueue` creation。

Historical downstream next opening from this checkpoint:

`P1 internal Renderer real command queue lifecycle value boundary bundle implementation`

## Downstream Command Submission Preflight

Renderer command buffer commit / GPU submission preflight 已完成：

- [2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md)

该 preflight 以 real drawable manifest 的 `CjguiInternalRendererNoRealDrawableReadiness` 为唯一 runtime input candidate，允许下一步新增 value-only command submission owner；本 no-draw backend shell manifest 只作为 docs evidence，继续不批准 backend shell object、command buffer creation、drawable present、GPU submission、render execution 或 renderer state write。

## Downstream Real Backend Shell Implementation Preflight

Renderer real backend shell implementation preflight 已完成：

- [2026-05-05-p1-renderer-real-backend-shell-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-backend-shell-implementation-preflight-decision.md)

该 preflight 允许靠近 real backend shell implementation runway，但要求下一步继续拆成 docs-only `P1 internal Renderer backend shell first implementation slice preflight decision`。本 no-draw backend shell manifest 的 `CjguiInternalRendererNoBackendShellReadiness` 仍只作为 shell lifecycle / no-draw execution gate / teardown value facts evidence，不是 backend shell object permission、backend implementation permission、GPU submission permission、renderer state write permission 或 public API permission。

Current downstream next opening:

`P1 internal Renderer backend shell skeleton no-resource value boundary bundle implementation`

## Downstream Backend Shell First Implementation Slice Preflight

Renderer backend shell first implementation slice preflight 已完成：

- [2026-05-05-p1-renderer-backend-shell-first-implementation-slice-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-first-implementation-slice-preflight-decision.md)

该 decision 选择 A `backend shell skeleton / no-resource implementation slice`，并把本 manifest 的 `CjguiInternalRendererNoBackendShellReadiness` 继续限制为 shell lifecycle / no-draw execution gate / teardown value facts evidence。它不是 backend shell object permission、backend implementation permission、native handle permission、platform object permission、GPU submission permission、renderer state write permission 或 public API permission。

下一步进入 `P1 internal Renderer backend shell skeleton no-resource value boundary bundle implementation`。该 next opening 只能使用 latest command submission tail `CjguiInternalRendererNoGpuSubmissionReadiness` 作为 runtime input candidate；本 no-draw backend shell endpoint 仍是 docs evidence，不得被包装成 backend-shell-ready permission wrapper、receipt / record / publication、backend implementation wrapper、GPU-submission wrapper 或 render-permission wrapper。
