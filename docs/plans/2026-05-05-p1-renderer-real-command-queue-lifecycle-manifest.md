# P1 Renderer real command queue lifecycle manifest

日期：2026-05-05

状态：docs-only manifest stabilization

## Scope

本 manifest 固定 `runtime_renderer_real_command_queue.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-real-command-queue endpoint。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 `MTLCommandQueue`，不创建 command buffer / drawable / render pass / encoder / pipeline state，不调用 Metal / AppKit / Objective-C / FFI，不 commit / present / submit GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Canonical Owner

Owner file：

- [runtime_renderer_real_command_queue.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_queue.cj)

Runtime input：

- `CjguiInternalRendererNoBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoRealCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()`

Default draft：

- `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()` first obtains `CjguiInternalRendererNoBackendShellReadiness` from `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`.
- It builds real command queue lifecycle intent, queue creation policy, queue ownership guard, queue teardown policy and no-real-command-queue readiness in owner-local value facts.
- It does not create `MTLCommandQueue`, does not call `newCommandQueue`, does not create `MTLDevice` / `CAMetalLayer`, drawable, command buffer, render pass, encoder or pipeline state.
- It does not call FFI / Objective-C / Metal / AppKit APIs, does not modify bridge / smoke / harness / native entry, does not commit / present / submit GPU work, does not render, does not write renderer state, and does not expand public API / C ABI.

## Current Truth

The current truth is exactly:

- real command queue lifecycle intent value facts.
- queue creation policy value facts.
- queue ownership guard value facts.
- queue teardown policy value facts.
- no-real-command-queue-readiness value facts.

The canonical value chain is:

1. `CjguiInternalRendererNoBackendShellReadiness`
2. `CjguiInternalRendererRealCommandQueueLifecycleIntent`
3. `CjguiInternalRendererRealCommandQueueCreationPolicy`
4. `CjguiInternalRendererRealCommandQueueOwnershipGuard`
5. `CjguiInternalRendererRealCommandQueueTeardownPolicy`
6. `CjguiInternalRendererNoRealCommandQueueReadiness`

## Value Semantics

`CjguiInternalRendererRealCommandQueueLifecycleIntent` only records future real command queue lifecycle intent facts. It is not a command queue object, backend implementation permission, GPU submission permission or command-buffer-ready permission.

`CjguiInternalRendererRealCommandQueueCreationPolicy` only records future queue creation prerequisite / fallback value facts. It does not create `MTLCommandQueue`, does not call `newCommandQueue`, does not call Metal / AppKit / Objective-C / FFI, and does not grant queue-ready permission.

`CjguiInternalRendererRealCommandQueueOwnershipGuard` only records backend-local confinement, no core resource leak and no resource borrow facts. It does not hold native handle, raw pointer, foreign resource token or backend resource.

`CjguiInternalRendererRealCommandQueueTeardownPolicy` only records future queue shutdown ordering, failure rollback and no-real-queue cleanup facts. It does not execute real release, destroy, foreign teardown, bridge cleanup or state mutation.

`CjguiInternalRendererNoRealCommandQueueReadiness` seals current no-real-command-queue readiness facts. It is not `MTLCommandQueue` permission, command buffer permission, drawable permission, GPU submission permission, backend implementation permission, render permission, renderer state write permission, diagnostics permission, public API permission or C ABI permission.

## Relationship Facts

Real command queue lifecycle facts relate to upstream no-draw backend shell facts only as dehydrated value facts:

- The upstream no-backend-shell endpoint remains the only runtime input.
- No-draw backend shell lifecycle / no-draw execution / teardown facts remain evidence and input value facts, not backend shell permission.
- Existing command queue lifecycle manifest remains evidence for lifecycle vocabulary, but the older no-command-queue endpoint is not a runtime input.
- Existing drawable acquisition lifecycle manifest remains downstream evidence only; drawable acquisition remains unapproved.
- Backend / Metal reference pack remains evidence only; it is not runtime truth and does not grant Metal API permission.
- Future real drawable lifecycle, command buffer commit / GPU submission and real backend shell implementation require separate docs-only preflight before any implementation can be considered.

Downstream real drawable lifecycle is now the only next opening after this manifest:

- `P1 internal Renderer real drawable lifecycle preflight decision`

Downstream real drawable lifecycle preflight is now recorded in:

- [2026-05-05-p1-renderer-real-drawable-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-preflight-decision.md)

The preflight keeps `CjguiInternalRendererNoRealCommandQueueReadiness` as the only runtime input candidate and chooses a value-only real drawable lifecycle boundary next. It does not approve drawable acquisition, `nextDrawable`, command buffer creation, present / commit / GPU submission, render execution or renderer state write.

Downstream real drawable lifecycle value boundary is now recorded in:

- [2026-05-05-p1-internal-renderer-real-drawable-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-lifecycle-value-boundary-closure-review.md)

That closure adds `runtime/cjgui/src/runtime_renderer_real_drawable.cj`, keeps `CjguiInternalRendererNoRealCommandQueueReadiness` as the only runtime input, and seals `CjguiInternalRendererNoRealDrawableReadiness` as a value-only no-real-drawable endpoint. It does not approve drawable acquisition, platform API calls, present / commit / GPU submission, render execution or renderer state write.

Downstream real drawable lifecycle next-boundary decision is now recorded in:

- [2026-05-05-p1-renderer-real-drawable-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-next-boundary-decision.md)

That decision confirms `CjguiInternalRendererNoRealDrawableReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()` is sufficient as the current no-real-drawable endpoint and chooses real drawable lifecycle manifest stabilization next. It does not approve drawable-ready permission, command buffer permission, GPU submission, backend implementation, render execution, renderer state write, public API or C ABI expansion.

Downstream real drawable lifecycle manifest stabilization is now recorded in:

- [2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)
- [2026-05-05-p1-internal-renderer-real-drawable-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-lifecycle-manifest-stabilization-closure-review.md)

That manifest fixes `runtime_renderer_real_drawable.cj` owner / truth / canonical endpoint / stop-line and closes `CjguiInternalRendererNoRealDrawableReadiness` as the current no-real-drawable endpoint. The next opening is docs-only command buffer commit / GPU submission preflight; it does not approve command buffer creation, drawable present, GPU submission, render execution or renderer state write.

Downstream command buffer commit / GPU submission preflight is now recorded in:

- [2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md)

That decision treats this manifest as docs evidence only, keeps `CjguiInternalRendererNoRealDrawableReadiness` as the sole runtime input candidate, and chooses a value-only command submission boundary next. It does not approve `MTLCommandQueue` creation, command buffer creation, drawable present, GPU submission, render execution or renderer state write.

## Explicit Non-Truth

The no-real-command-queue endpoint is not:

- `MTLCommandQueue` permission.
- command buffer permission.
- drawable permission.
- render pass / encoder / pipeline state permission.
- `MTLDevice` / `CAMetalLayer` permission.
- native handle / raw pointer permission.
- Metal / AppKit / Objective-C / FFI permission.
- command buffer commit permission.
- drawable present permission.
- GPU submission permission.
- render execution permission.
- backend implementation permission.
- renderer state write permission.
- diagnostics / event bus / observer / telemetry permission.
- public API / public C ABI permission.

## Evidence Chain

- [Real command queue lifecycle next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-next-boundary-decision.md) confirmed `CjguiInternalRendererNoRealCommandQueueReadiness` is sufficient as the current no-real-command-queue endpoint.
- [Real command queue lifecycle value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-value-boundary-closure-review.md) added the internal-only owner and verified the no-queue / no-API / no-submit / no-render stop-line.
- [Real command queue lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-preflight-decision.md) proved enough queue creation policy / ownership guard / teardown evidence to open the value boundary.
- [Command queue / drawable real lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-queue-drawable-real-lifecycle-preflight-decision.md) split command queue and drawable into separate runways and chose real command queue first.
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md) fixed the upstream no-backend-shell endpoint and denied backend shell / command queue / drawable / GPU submission permission.
- [Command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md) remains lifecycle vocabulary evidence only and does not become runtime input.

## Same-shape Boundary Brake

This round chooses manifest stabilization and closes the current no-real-command-queue endpoint.

It explicitly rejects:

- real command queue receipt / record / publication.
- queue-ready permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- command-buffer-ready wrapper.
- render-permission wrapper.
- public API / C ABI wrapper.

`CjguiInternalRendererNoRealCommandQueueReadiness` must not be wrapped into another tail endpoint unless a future docs-only preflight proves new owner / lifecycle / teardown / failure / verification semantics that are not already captured here.

Future work approaching real drawable lifecycle, command buffer commit / GPU submission or real backend shell implementation must first pass docs-only preflight.

## Stop-line

Until a later docs-only preflight explicitly opens a narrower runway:

- no `MTLCommandQueue`.
- no `newCommandQueue`.
- no command buffer.
- no drawable.
- no render pass.
- no encoder.
- no pipeline state.
- no `MTLDevice`.
- no `CAMetalLayer`.
- no backend shell object.
- no backend object.
- no platform object.
- no native handle.
- no raw pointer.
- no FFI / Objective-C / Metal / AppKit API call.
- no bridge / smoke / harness / native entry modification.
- no command buffer commit.
- no drawable present.
- no GPU submission.
- no render execution.
- no renderer state write.
- no diagnostics / event bus / observer / telemetry.
- no public API / public C ABI expansion.
- no module-level `var`.

## Public Surface

The public declaration allowlist remains unchanged:

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

## Next Stage Candidate Comparison

### A. P1 internal Renderer real drawable lifecycle preflight decision

推荐为下一阶段 opening。

Reasoning：real command queue lifecycle endpoint is now manifest-stabilized, so the next docs-only question can evaluate drawable availability, acquisition timing, borrowing / presentation ownership, resize / scale / color relation and no-real-drawable readiness without creating drawable or exposing texture.

### B. Command buffer commit / GPU submission preflight

暂缓。

It remains too close to real GPU work. Real drawable lifecycle and command buffer ownership must be clarified before commit / submit can be evaluated.

### C. Real backend shell implementation preflight

暂缓。

No-draw backend shell and real command queue lifecycle remain value facts only. Real backend shell implementation should wait until real drawable lifecycle and resource teardown paths are further clarified.

### D. Real command queue hardening

仅在发现不足时选择。

Current creation / ownership / teardown facts are enough to close the endpoint; choose hardening only if future review finds a concrete expression gap.

### E. Direct `MTLCommandQueue` implementation

拒绝。

### F. Command buffer / GPU submission / render execution

拒绝。

### G. Renderer state write

拒绝。

### H. Public API / C ABI expansion

拒绝。

### I. Receipt / record / publication

拒绝。

### J. Consolidation

暂缓。

Only choose consolidation if explicit duplicate / low-value / self-wrapping evidence appears. Current evidence points to downstream real drawable lifecycle preflight, not deletion or consolidation.

## Decision

This manifest stabilizes and closes the renderer real command queue no-real-command-queue endpoint.

Unique next opening:

`P1 internal Renderer real drawable lifecycle preflight decision`
