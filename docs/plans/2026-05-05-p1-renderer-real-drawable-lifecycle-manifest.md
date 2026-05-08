# P1 Renderer real drawable lifecycle manifest

日期：2026-05-05

状态：docs-only manifest stabilization

## Scope

本 manifest 固定 `runtime_renderer_real_drawable.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-real-drawable endpoint。

本轮 docs-only：不修改 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不获取 drawable，不调用 `nextDrawable`，不创建 `CAMetalDrawable` / `MTLDrawable`，不创建 command buffer / render pass / encoder / pipeline state，不调用 Metal / AppKit / Objective-C / FFI，不 present / commit / submit GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Canonical Owner

Owner file：

- [runtime_renderer_real_drawable.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_drawable.cj)

Runtime input：

- `CjguiInternalRendererNoRealCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoRealDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()`

Default draft：

- `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()` first obtains `CjguiInternalRendererNoRealCommandQueueReadiness` from `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()`.
- It builds real drawable lifecycle intent, drawable availability policy, drawable acquisition guard, presentation ownership policy and no-real-drawable readiness in owner-local value facts.
- It does not query a real drawable pool, does not call `nextDrawable`, does not acquire or hold `CAMetalDrawable` / `MTLDrawable`, and does not expose drawable texture.
- It does not create command buffer, render pass, encoder or pipeline state.
- It does not call Metal / AppKit / Objective-C / FFI, does not modify bridge / smoke / harness / native entry, does not present / commit / submit GPU work, does not render, does not write renderer state, and does not expand public API / C ABI.

## Current Truth

The current truth is exactly:

- real drawable lifecycle intent value facts.
- drawable availability policy value facts.
- drawable acquisition guard value facts.
- presentation ownership policy value facts.
- no-real-drawable-readiness value facts.

The canonical value chain is:

1. `CjguiInternalRendererNoRealCommandQueueReadiness`
2. `CjguiInternalRendererRealDrawableLifecycleIntent`
3. `CjguiInternalRendererRealDrawableAvailabilityPolicy`
4. `CjguiInternalRendererRealDrawableAcquisitionGuard`
5. `CjguiInternalRendererRealDrawablePresentationOwnershipPolicy`
6. `CjguiInternalRendererNoRealDrawableReadiness`

## Value Semantics

`CjguiInternalRendererRealDrawableLifecycleIntent` only records future real drawable lifecycle intent facts. It is not drawable acquisition implementation, drawable-ready permission, backend implementation permission or GPU submission permission.

`CjguiInternalRendererRealDrawableAvailabilityPolicy` only records future drawable availability / unavailable / fallback / resize-scale-color relation value facts. It does not query a real drawable pool, does not borrow a drawable and does not grant drawable-ready permission.

`CjguiInternalRendererRealDrawableAcquisitionGuard` only records future late-bound acquisition guard / unavailable timeout fallback / no borrowed resource facts. It does not call `nextDrawable`, does not acquire drawable, does not block on a foreign call and does not carry a resource token.

`CjguiInternalRendererRealDrawablePresentationOwnershipPolicy` only records future presentation ownership / release expectation / no-present facts. It does not present drawable, does not submit work, does not create pass / encoder objects and does not write renderer state.

`CjguiInternalRendererNoRealDrawableReadiness` seals current no-real-drawable readiness facts. It is not drawable permission, command buffer permission, GPU submission permission, backend implementation permission, render permission, renderer state write permission, diagnostics permission, public API permission or C ABI permission.

## Relationship Facts

Real drawable lifecycle facts relate to upstream no-real-command-queue facts only as dehydrated value facts:

- The upstream no-real-command-queue endpoint remains the only runtime input.
- Real command queue lifecycle facts remain input value facts, not command queue permission or drawable permission.
- The older drawable acquisition lifecycle manifest remains vocabulary evidence only; it is not runtime input for this owner.
- Drawable availability, late acquisition, unavailable fallback, resize / scale / color relation, presentation ownership, no-present and no-draw fallback remain value facts only.
- Future command buffer commit / GPU submission, real backend shell implementation and real drawable acquisition require separate docs-only preflight before any implementation can be considered.

Downstream command buffer commit / GPU submission preflight is now the only next opening after this manifest:

- `P1 internal Renderer command buffer commit / GPU submission preflight decision`

Downstream command buffer commit / GPU submission preflight is now recorded in:

- [2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-buffer-commit-gpu-submission-preflight-decision.md)

That decision keeps `CjguiInternalRendererNoRealDrawableReadiness` as the only runtime input candidate and chooses a value-only command submission boundary next. It does not approve command buffer creation, `commit`, `present`, `nextDrawable`, GPU submission, render execution or renderer state write.

Downstream command submission value boundary is now recorded in:

- [2026-05-05-p1-internal-renderer-command-submission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-command-submission-value-boundary-closure-review.md)

That closure keeps this manifest's `CjguiInternalRendererNoRealDrawableReadiness` as the only runtime input, seals `CjguiInternalRendererNoGpuSubmissionReadiness` / `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`, and stays value-only: no command buffer creation, no `commit`, no `present`, no `nextDrawable`, no GPU submission, no render execution and no renderer state write.

Downstream command submission next-boundary decision is now recorded in:

- [2026-05-05-p1-renderer-command-submission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-next-boundary-decision.md)

That decision confirms the downstream no-gpu-submission endpoint is sufficient and moves the next opening to docs-only command submission manifest stabilization. It does not approve command buffer permission, drawable present permission, GPU submission, render execution, backend implementation, renderer state write or public API expansion.

Downstream command submission manifest stabilization is now recorded in:

- [2026-05-05-p1-renderer-command-submission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [2026-05-05-p1-internal-renderer-command-submission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-command-submission-manifest-stabilization-closure-review.md)

That manifest fixes the downstream `CjguiInternalRendererNoGpuSubmissionReadiness` endpoint and keeps this manifest's `CjguiInternalRendererNoRealDrawableReadiness` as the only runtime input. It does not approve command buffer creation, `commit`, `present`, `nextDrawable`, GPU submission, render execution, backend implementation, renderer state write or public API expansion.

下游 real drawable implementation preflight 已记录在：

- [2026-05-05-p1-renderer-real-drawable-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-implementation-preflight-decision.md)

下游 value boundary closure 已记录在：

- [2026-05-05-p1-internal-renderer-real-drawable-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-implementation-admission-value-boundary-closure-review.md)

下游 next-boundary decision 已记录在：

- [2026-05-06-p1-renderer-real-drawable-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-next-boundary-decision.md)

下游 manifest stabilization 已记录在：

- [2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-real-drawable-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-real-drawable-implementation-admission-manifest-stabilization-closure-review.md)

该 implementation admission 只把本 manifest 作为 drawable vocabulary evidence。`CjguiInternalRendererNoRealDrawableReadiness` 仍不是 runtime input，不是 drawable-ready permission，不是 `nextDrawable` permission，不是 present permission，不是 command-buffer permission，不是 GPU-submission permission，不是 render permission，不是 renderer-state-write permission，也不是 public API permission。新增 owner 的唯一 runtime input 是 `CjguiInternalRendererNoRealCommandQueueImplementationReadiness`；当前 downstream next opening 已转为 docs-only real command buffer implementation preflight。

## Explicit Non-Truth

The no-real-drawable endpoint is not:

- drawable permission.
- drawable acquisition permission.
- drawable texture exposure.
- `nextDrawable` permission.
- `CAMetalDrawable` / `MTLDrawable` ownership.
- command buffer permission.
- render pass / encoder / pipeline state permission.
- GPU submission permission.
- command buffer commit permission.
- drawable present permission.
- backend implementation permission.
- render permission.
- renderer state write permission.
- native handle / raw pointer permission.
- Metal / AppKit / Objective-C / FFI permission.
- diagnostics / event bus / observer / telemetry permission.
- public API / public C ABI permission.

Current truth has no drawable acquisition, no drawable object, no drawable texture, no submission object, no pass / encoder object, no foreign API call, no resource token, no pointer-like resource, no work submit, no render work, no renderer state mutation and no bridge / smoke / harness / native entry change.

## Evidence Chain

- [Real drawable lifecycle next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-next-boundary-decision.md) confirmed `CjguiInternalRendererNoRealDrawableReadiness` is sufficient as the current no-real-drawable endpoint.
- [Real drawable lifecycle value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-lifecycle-value-boundary-closure-review.md) added the internal-only owner and verified the no-drawable-acquisition / no-platform-API / no-submit / no-render stop-line.
- [Real drawable lifecycle preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-preflight-decision.md) proved enough availability / acquisition guard / presentation ownership evidence to open the value boundary.
- [Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md) fixed the upstream no-real-command-queue endpoint and denied drawable permission, command buffer permission, GPU submission permission and render permission.
- [Drawable acquisition lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md) remains lifecycle vocabulary evidence only and does not become runtime input.

## Same-shape Boundary Brake

This round chooses manifest stabilization and closes the current no-real-drawable endpoint.

It explicitly rejects:

- real drawable receipt / record / publication.
- drawable-ready permission wrapper.
- backend implementation wrapper.
- GPU-submission wrapper.
- command-buffer-ready wrapper.
- render-permission wrapper.
- public API / C ABI wrapper.

`CjguiInternalRendererNoRealDrawableReadiness` must not be wrapped into another tail endpoint unless a future docs-only preflight proves new owner / lifecycle / teardown / failure / verification semantics that are not already captured here.

Future work approaching command buffer commit / GPU submission, real backend shell implementation or real drawable acquisition must first pass docs-only preflight.

## Stop-line

Until a later docs-only preflight explicitly opens a narrower runway:

- no drawable acquisition.
- no `nextDrawable`.
- no `CAMetalDrawable`.
- no `MTLDrawable`.
- no drawable texture exposure.
- no command buffer.
- no render pass.
- no encoder.
- no pipeline state.
- no Metal / AppKit / Objective-C / FFI call.
- no bridge / smoke / harness / native entry modification.
- no drawable present.
- no command buffer commit.
- no GPU submission.
- no render execution.
- no renderer state write.
- no diagnostics / event bus / observer / telemetry.
- no public API / public C ABI expansion.
- no native handle.
- no raw pointer.
- no module-level `var`.

## Public Surface

The public declaration allowlist remains unchanged:

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

## Next Stage Candidate Comparison

### A. P1 internal Renderer command buffer commit / GPU submission preflight decision

推荐为下一阶段 opening。

Reasoning：real drawable lifecycle endpoint is now manifest-stabilized, so the next docs-only question can evaluate commit / submission gating, command buffer relation, drawable present relation, no-submit fallback and verification strategy without creating command buffer, presenting drawable or submitting GPU work.

### B. Real backend shell implementation preflight

暂缓。

Real backend shell implementation should wait until command buffer commit / GPU submission risk is examined as docs-only evidence.

### C. Real drawable hardening

仅在发现不足时选择。

Current availability / acquisition guard / presentation ownership facts are enough to close the endpoint; choose hardening only if future review finds a concrete expression gap.

### D. Direct drawable acquisition implementation

拒绝。

### E. Direct command buffer / render pass / encoder implementation

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

暂缓。

Only choose consolidation if explicit duplicate / low-value / self-wrapping evidence appears. Current evidence points to downstream command buffer commit / GPU submission preflight, not deletion or consolidation.

## Decision

This manifest stabilizes and closes the renderer real drawable no-real-drawable endpoint.

Unique next opening:

`P1 internal Renderer command buffer commit / GPU submission preflight decision`

## 下游真实 drawable 第一刀 shell

新的 real drawable first implementation runway 已从 real command queue first-slice shell 重新评估，并完成 docs-only preflight 与 runtime-local shell：

- [real drawable first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-preflight-decision.md)
- [real drawable first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-drawable-first-implementation-slice-closure-review.md)
- [real drawable first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-manifest.md)

该 downstream shell 只把本 manifest 作为 drawable lifecycle vocabulary evidence。旧 `CjguiInternalRendererNoRealDrawableReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()` 仍归本 lifecycle owner，不成为 downstream runtime input，也不是 drawable-ready、`nextDrawable`、present、command buffer、GPU submission、renderer state write、backend ready truth 或 public API permission。

新的 downstream endpoint 是 `CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()`。它只消费 `CjguiInternalRendererNoRealCommandQueueShellReadiness`，不获取 drawable，不调用 `nextDrawable` / `present`，不创建 command buffer，不提交 GPU work，不写 renderer state，不修改 native bridge / Objective-C / Metal / AppKit / FFI，不扩 C ABI / public API。

新的下游后续入口：

`P1 internal Renderer real drawable branch closure / next real drawable decision`
