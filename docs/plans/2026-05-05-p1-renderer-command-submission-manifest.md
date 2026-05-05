# P1 Renderer command submission manifest

日期：2026-05-05

状态：docs-only manifest stabilization

## Scope

本 manifest 固定 `runtime_renderer_command_submission.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-gpu-submission endpoint。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不调用 `commit`、`present` 或 `nextDrawable`，不创建 command buffer、drawable、render pass、encoder 或 pipeline state，不调用 Metal / AppKit / Objective-C / FFI，不提交 GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Canonical Owner

Owner file：

- [runtime_renderer_command_submission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_submission.cj)

Runtime input：

- `CjguiInternalRendererNoRealDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoGpuSubmissionReadiness`
- `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`

Default draft：

- `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()` first obtains `CjguiInternalRendererNoRealDrawableReadiness` from `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()`.
- It builds command submission intent, command buffer commit policy, drawable presentation gate, GPU submission failure policy and no-gpu-submission readiness in owner-local value facts.
- It does not create command buffer, does not call `commit`, does not acquire or present drawable, does not call `nextDrawable`, and does not submit GPU work.
- It does not create render pass, encoder or pipeline state.
- It does not call Metal / AppKit / Objective-C / FFI, does not modify bridge / smoke / harness / native entry, does not execute render, does not write renderer state, and does not expand public API / C ABI.

## Current Truth

The current truth is exactly:

- command submission intent value facts.
- command buffer commit policy value facts.
- drawable presentation gate value facts.
- GPU submission failure policy value facts.
- no-gpu-submission readiness value facts.

The canonical value chain is:

1. `CjguiInternalRendererNoRealDrawableReadiness`
2. `CjguiInternalRendererCommandSubmissionIntent`
3. `CjguiInternalRendererCommandBufferCommitPolicy`
4. `CjguiInternalRendererDrawablePresentationGate`
5. `CjguiInternalRendererGpuSubmissionFailurePolicy`
6. `CjguiInternalRendererNoGpuSubmissionReadiness`

## Value Semantics

`CjguiInternalRendererCommandSubmissionIntent` only records future command submission lifecycle intent facts. It is not command submission implementation, command buffer permission, drawable present permission or render permission.

`CjguiInternalRendererCommandBufferCommitPolicy` only records future command buffer commit ordering / single-use / no-commit policy facts. It does not create command buffer, does not call `commit` and does not grant command-buffer-ready permission.

`CjguiInternalRendererDrawablePresentationGate` only records future drawable presentation ordering / no-present gate facts. It does not acquire drawable, does not call `nextDrawable`, does not present drawable and does not grant drawable-present-ready permission.

`CjguiInternalRendererGpuSubmissionFailurePolicy` only records future completion / failure / rollback / no-draw relation facts. It does not observe real GPU completion, does not register callback, does not emit telemetry and does not publish diagnostics.

`CjguiInternalRendererNoGpuSubmissionReadiness` seals current no-gpu-submission readiness facts. It is not command buffer permission, drawable present permission, GPU submission permission, render permission, backend implementation permission, renderer state write permission, diagnostics permission, public API permission or C ABI permission.

## Relationship Facts

Command submission facts relate to upstream no-real-drawable facts only as dehydrated value facts:

- The upstream no-real-drawable endpoint remains the only runtime input.
- Real drawable lifecycle facts remain input value facts, not drawable permission, command buffer permission, present permission or GPU submission permission.
- Real command queue lifecycle and no-draw backend shell manifests remain docs evidence only; they are not runtime inputs for this owner.
- Command buffer lifecycle, render execution no-op, renderer state write no-write and backend / Metal reference pack remain vocabulary evidence only; they do not grant object creation, commit, present, submission, completion callback or state-write permission.
- Future real backend shell implementation, render completion / frame completion tracking and real command buffer commit / drawable present / GPU submission require separate docs-only preflight before any implementation can be considered.

Downstream real backend shell implementation preflight is now the only next opening after this manifest:

- `P1 internal Renderer real backend shell implementation preflight decision`

Downstream real backend shell implementation preflight is now recorded in:

- [2026-05-05-p1-renderer-real-backend-shell-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-backend-shell-implementation-preflight-decision.md)

That decision treats this manifest's `CjguiInternalRendererNoGpuSubmissionReadiness` as value-only no-gpu-submission evidence, not backend implementation permission. It chooses docs-only backend shell first implementation slice preflight next and does not approve command buffer creation, `commit`, `present`, `nextDrawable`, GPU submission, render execution, backend implementation, renderer state write or public API expansion.

## Explicit Non-Truth

The no-gpu-submission endpoint is not:

- command buffer permission.
- command buffer creation permission.
- command buffer commit permission.
- drawable permission.
- drawable acquisition permission.
- drawable present permission.
- `nextDrawable` permission.
- GPU submission permission.
- render pass / encoder / pipeline state permission.
- render execution permission.
- backend shell implementation permission.
- backend implementation permission.
- renderer state write permission.
- frame completion tracking permission.
- completion callback permission.
- diagnostics / event bus / observer / telemetry permission.
- public API / public C ABI permission.

Current truth has no command buffer object, no drawable object, no pass / encoder / pipeline object, no foreign API call, no resource token, no pointer-like resource, no work submit, no present, no render work, no renderer state mutation and no bridge / smoke / harness / native entry change.

## Evidence Chain

- [Command submission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-next-boundary-decision.md) confirmed `CjguiInternalRendererNoGpuSubmissionReadiness` / `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()` is sufficient as the current no-gpu-submission endpoint.
- [Command submission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-command-submission-value-boundary-closure-review.md) added the internal-only owner and verified the no-commit / no-present / no-nextDrawable / no-submit / no-render / no-state-write stop-line.
- [Command buffer commit / GPU submission preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md) proved enough commit policy / presentation gate / failure policy evidence to open the value boundary.
- [Real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md) fixed the upstream no-real-drawable endpoint and denied drawable acquisition, present, command buffer, GPU submission and render permission.
- [Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md) remains command queue lifecycle evidence only and does not become runtime input.
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md) remains backend shell lifecycle evidence only and does not become backend implementation permission.

## Same-shape Boundary Brake

This round chooses manifest stabilization and closes the current no-gpu-submission endpoint.

It explicitly rejects:

- command submission receipt / record / publication.
- GPU-submission permission wrapper.
- command-buffer-ready wrapper.
- drawable-present-ready wrapper.
- render-permission wrapper.
- backend implementation wrapper.
- renderer-state-write wrapper.
- public API / C ABI wrapper.

`CjguiInternalRendererNoGpuSubmissionReadiness` must not be wrapped into another tail endpoint unless a future docs-only preflight proves new owner / lifecycle / teardown / failure / verification semantics that are not already captured here.

Future work approaching real backend shell implementation, render completion / frame completion tracking, real command buffer commit, real drawable present or real GPU submission must first pass docs-only preflight.

## Stop-line

Until a later docs-only preflight explicitly opens a narrower runway:

- no `.cj` modification for this manifest.
- no command buffer.
- no drawable acquisition.
- no `nextDrawable`.
- no drawable present.
- no `present`.
- no `commit`.
- no render pass.
- no encoder.
- no pipeline state.
- no Metal / AppKit / Objective-C / FFI call.
- no bridge / smoke / harness / native entry modification.
- no GPU submission.
- no render execution.
- no renderer state write.
- no completion callback.
- no diagnostics / event bus / observer / telemetry.
- no public API / public C ABI expansion.
- no native handle.
- no raw pointer.
- no module-level `var`.

## Public Surface

The public declaration allowlist remains unchanged:

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

## Next Stage Candidate Comparison

### A. P1 internal Renderer real backend shell implementation preflight decision

推荐为下一阶段 opening。

Reasoning：command submission is now manifest-stabilized as a no-gpu-submission endpoint. The next docs-only question can evaluate whether a real backend shell implementation preflight has enough owner / teardown / failure / no-draw / smoke strategy evidence without creating backend shell object, command buffer, drawable or GPU work.

### B. Render completion / frame completion tracking preflight

暂缓。

Completion tracking remains close to callback, telemetry, observer and renderer state visibility. It should wait until real backend shell implementation risk is evaluated as docs-only evidence.

### C. Command submission hardening

暂缓，仅在发现不足时选择。

Current commit policy / presentation gate / failure policy expression is enough to close the endpoint; choose hardening only if a future review finds a concrete expression gap.

### D. Direct command buffer commit implementation

拒绝。

### E. Direct drawable present implementation

拒绝。

### F. GPU submission / render execution implementation

拒绝。

### G. Renderer state write

拒绝。

### H. Public API / C ABI expansion

拒绝。

### I. Receipt / record / publication

拒绝。

### J. Consolidation

仅在发现明确 duplicate / low-value / self-wrapping evidence 时选择。

## Decision

`runtime/cjgui/src/runtime_renderer_command_submission.cj` is now the fixed command submission owner for the current no-gpu-submission endpoint.

`CjguiInternalRendererNoGpuSubmissionReadiness` / `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()` is the canonical tail for command submission value facts. It is not permission to create command buffer, present drawable, submit GPU work, render, implement backend, write renderer state or expose public API.

唯一 next opening：

`P1 internal Renderer real backend shell implementation preflight decision`

## Downstream Backend Shell Skeleton No-resource Value Boundary

Renderer backend shell skeleton no-resource value boundary 已完成：

- [2026-05-05-p1-internal-renderer-backend-shell-skeleton-no-resource-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-backend-shell-skeleton-no-resource-value-boundary-closure-review.md)

It consumes this manifest's `CjguiInternalRendererNoGpuSubmissionReadiness` only as value facts. The downstream canonical endpoint is `CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`.

The downstream owner adds skeleton lifecycle envelope / no-resource guard / failure rollback / teardown confinement semantics. It does not create backend shell object, backend object, platform object, native handle, raw pointer, Metal / AppKit / Objective-C / FFI resource, command buffer, drawable, render pass, encoder or pipeline state, and it does not submit GPU work, execute render, write renderer state or expand public API / C ABI.

## Downstream Backend Shell Skeleton Next-boundary Decision

Renderer backend shell skeleton next-boundary decision 已完成：

- [2026-05-05-p1-renderer-backend-shell-skeleton-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-next-boundary-decision.md)

It confirms `CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()` is sufficient as the current no-resource-backend-shell endpoint. This command submission manifest remains upstream value evidence only; it still does not grant command buffer commit, drawable present, GPU submission, render, backend implementation, renderer state write, public API or C ABI permission.

Unique downstream next opening from that decision:

`P1 internal Renderer backend shell skeleton manifest stabilization bundle implementation`

## Downstream Backend Shell Skeleton Manifest Stabilization

Renderer backend shell skeleton manifest stabilization 已完成：

- [2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md)
- [2026-05-05-p1-internal-renderer-backend-shell-skeleton-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-backend-shell-skeleton-manifest-stabilization-closure-review.md)

It fixes `runtime_renderer_backend_shell_skeleton.cj` as the downstream no-resource-backend-shell owner. This command submission manifest remains upstream no-gpu-submission value evidence only; it still does not grant native handle, platform object, Metal / AppKit bridge, command buffer commit, drawable present, GPU submission, render, backend implementation, renderer state write, public API or C ABI permission.

Unique downstream next opening from that manifest:

`P1 internal Renderer native resource bridge preflight decision`
