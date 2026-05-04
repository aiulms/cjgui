# P1 Renderer drawable acquisition lifecycle preflight decision

日期：2026-05-03

状态：docs-only preflight decision

## Scope

本 preflight 基于 command queue lifecycle manifest、platform resource owner manifest 与 backend / Metal reference pack，评估是否可以打开 drawable acquisition lifecycle runway。

本轮不修改 `.cj`，不获取 drawable，不创建或引用 `CAMetalLayer`、`CAMetalDrawable`、`MTLDrawable`、command buffer、render pass、encoder、native handle 或 raw pointer，不实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Inputs Read

- [2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-command-queue-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-queue-lifecycle-manifest-stabilization-closure-review.md)
- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Current Upstream Truth

Current command queue lifecycle endpoint:

- `CjguiInternalRendererNoCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`

Current command queue truth:

- command queue lifecycle intent value facts.
- lifecycle ownership policy value facts.
- command queue creation guard value facts.
- command queue lifetime / shutdown / rollback policy value facts.
- no-command-queue readiness value facts.

This endpoint is not command queue permission, backend readiness, drawable acquisition permission, command buffer permission, render permission, or renderer state write.

## Reference Evidence

The backend / Metal reference pack provides enough evidence to separate drawable acquisition from command queue lifecycle:

- `CAMetalLayer` owns a limited drawable pool managed by Core Animation.
- `nextDrawable()` can wait for availability and can fail or return unavailable / `nil`-style conditions when the layer is invalid or timing constraints apply.
- A drawable is associated with its owning layer and exposes a texture as a future render target.
- Drawable acquisition should be late-bound and short-lived to avoid stalls.
- `CAMetalLayer` properties such as drawable size, pixel format, color space, presentation behavior, and display sync shape availability and timing.
- AppKit resize / backing scale / color facts can be dehydrated before crossing into core-adjacent value vocabulary.
- Frame pacing and display refresh influence acquisition timing, but they remain platform/backend-owner concerns.

These facts are sufficient for a value boundary that talks about availability / timing / presentation ownership / no-drawable readiness. They are not permission to obtain a drawable or create platform objects.

## Preflight Answers

是否允许打开 drawable acquisition lifecycle runway：

- 允许，但下一步也只能是 internal value boundary，不是真实 drawable acquisition。

下一步 owner：

- 建议新建 `runtime/cjgui/src/runtime_renderer_drawable_acquisition.cj` 或等价 internal-only owner。
- 该 owner 必须只表达 drawable acquisition lifecycle value facts，不得获取 drawable，不得持有 layer / drawable / native handle。

输入 truth：

- 只允许消费 `CjguiInternalRendererNoCommandQueueReadiness`。
- 不回退消费 `CjguiInternalRendererNoPlatformResourceReadiness`。
- 不回退消费 packet ordering endpoint。
- 不复用旧 `runtime_renderer_handoff.cj` 的 handoff receipt 语义。

输出 truth：

- drawable acquisition lifecycle intent value facts.
- drawable availability policy value facts.
- acquisition timing guard value facts.
- presentation ownership policy value facts.
- no-drawable readiness value facts.

Allowed dehydrated facts:

- drawable availability phase.
- acquisition timing.
- resize / scale / color relation.
- frame pacing relationship.
- presentation ownership.
- failure / unavailable / no-draw fallback.
- rollback / release expectation as value facts only.

Forbidden core objects:

- `CAMetalLayer`.
- `CAMetalDrawable`.
- `MTLDrawable`.
- native handle.
- raw pointer.
- drawable texture.
- command buffer.
- render pass.
- encoder.
- backend object.
- platform object.

Drawable acquisition relation to existing owners:

- Command queue lifecycle can provide only no-command-queue / ownership / lifetime guard context; it does not grant drawable acquisition.
- Platform resource owner remains the confinement policy source for device / layer / command queue / drawable / command buffer / render pass.
- Reference pack evidence says drawable acquisition must be late-bound and backend-local; therefore the next owner can only express availability / timing / presentation ownership facts.
- Resize / scale / color facts may be dehydrated into value vocabulary, but the layer, drawable, texture, view, display link, native handle, or raw pointer cannot cross into core packet truth.

No-draw / failure / rollback path:

- Drawable unavailable / invalid / timed-out / blocked conditions must be represented as no-drawable / no-draw value facts.
- Failure must stay fail-closed and must not synthesize a drawable, command buffer, render pass, or render permission.
- Rollback can only be described as a future backend-local policy fact; this preflight does not approve real resource release or lifetime management.

Reference hardening need:

- 当前 evidence 足够支持下一步 internal value boundary。
- 不需要先做 drawable acquisition reference hardening docs bundle。
- 但下一步 implementation 仍必须引用本 preflight，并保持 no-platform-object / no-render stop-line。

## Candidate Comparison

### A. P1 internal Renderer drawable acquisition lifecycle value boundary bundle implementation

推荐。

Reasoning:

- Evidence is sufficient for a distinct value boundary: availability / timing / presentation ownership / no-drawable readiness.
- The boundary would consume only `CjguiInternalRendererNoCommandQueueReadiness`.
- The output is not a drawable, not a layer, not a command buffer, and not render permission.

### B. P1 internal Renderer drawable acquisition reference hardening docs bundle implementation

暂缓。

Reference pack already contains the required official evidence for drawable pool, late acquisition, failure / unavailable path, resize / scale / color, frame pacing, and resource ownership.

### C. Command buffer lifecycle preflight

暂缓。

Command buffer lifecycle must wait until drawable acquisition lifecycle owner truth exists. It is closer to command submission, render pass and encoder lifecycle.

### D. Render pass lifecycle preflight

暂缓。

Render pass lifecycle depends on drawable and command buffer lifecycle clarity.

### E. Backend-readiness preflight revisit

暂缓。

Backend-readiness remains too broad and likely to become a wrapper until drawable / command buffer lifecycle facts are split.

### F. Drawable / Metal implementation

拒绝。

### G. Command buffer / render execution / renderer state write

拒绝。

### H. Metal / AppKit / platform resource / native handle implementation

拒绝。

### I. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### J. Public surface expansion

拒绝。

### K. Receipt / record / publication

拒绝。

### L. Consolidation

暂缓。

Only choose consolidation if future evidence shows duplicate / low-value helper / self-wrapping owner. No such evidence exists in this preflight.

## Same-shape Boundary Brake

Same-shape Boundary Brake is active.

This preflight does not approve wrapping `CjguiInternalRendererNoCommandQueueReadiness` as a drawable receipt / record / publication.

If the next boundary is implemented, it must prove new drawable-specific semantics:

- drawable availability.
- acquisition timing.
- presentation ownership.
- no-drawable readiness.
- failure / no-draw fallback.

It must not be a generic readiness wrapper, backend-readiness wrapper, command buffer readiness wrapper, or old handoff receipt.

## Decision

Decision: choose `P1 internal Renderer drawable acquisition lifecycle value boundary bundle implementation` as the next opening.

Preflight conclusion:

- Drawable acquisition lifecycle runway may open only as an internal value boundary.
- Suggested owner is `runtime/cjgui/src/runtime_renderer_drawable_acquisition.cj`.
- Input must be only `CjguiInternalRendererNoCommandQueueReadiness`.
- Output truth must be drawable acquisition lifecycle intent / drawable availability policy / acquisition timing guard / presentation ownership policy / no-drawable readiness value facts.
- No real drawable acquisition, platform object, command buffer, render pass, encoder, backend object, render execution, renderer state write, native handle, raw pointer, or public surface expansion is approved.

## Stop-line

Continue to prohibit:

- no `.cj` modifications in this preflight round.
- no drawable acquisition.
- no `CAMetalLayer` creation or reference.
- no `CAMetalDrawable` / `MTLDrawable` creation or reference.
- no drawable texture exposure.
- no command queue creation.
- no command buffer creation or submission.
- no render pass / encoder creation.
- no backend / Metal / AppKit implementation.
- no platform object / native handle / raw pointer.
- no render execution / draw call.
- no GPU batching / draw-call merge.
- no renderer state write.
- no dirty-region / diff / patch / incremental render.
- no Widget / Layout / Text / IME / Accessibility / ECS implementation.
- no public surface expansion.
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change.
- no `runtime_state.cj` touch.
- no `runtime/cjgui/cjpm.toml` change.
- no smoke / harness / native bridge / entry modifications.

## Next Opening

`P1 internal Renderer drawable acquisition lifecycle value boundary bundle implementation`

## Downstream Value Boundary

Renderer drawable acquisition lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-value-boundary-closure-review.md)

新增 owner 是 `runtime/cjgui/src/runtime_renderer_drawable_acquisition.cj`，只消费 `CjguiInternalRendererNoCommandQueueReadiness`，canonical endpoint 是 `CjguiInternalRendererNoDrawableReadiness` / `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()`。

该 boundary 只表达 drawable lifecycle intent / drawable availability policy / acquisition timing guard / presentation ownership policy / no-drawable readiness value facts。Same-shape Boundary Brake 继续生效：不得把 no-command-queue endpoint 包成 drawable receipt / record / publication，不得混入 command buffer lifecycle 或 render pass lifecycle。

下一步唯一 opening：`P1 internal Renderer drawable acquisition lifecycle closure / next drawable acquisition decision`。

## Downstream Next-Boundary Decision

Renderer drawable acquisition lifecycle next-boundary decision 已完成：

- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoDrawableReadiness` / `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()` 已足够作为当前 no-drawable lifecycle endpoint。下一步选择 docs-only `P1 internal Renderer drawable acquisition lifecycle manifest stabilization bundle implementation`，不进入 command buffer lifecycle 或 render pass lifecycle。

## Downstream Manifest

Renderer drawable acquisition lifecycle manifest 已完成：

- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_drawable_acquisition.cj` owner / truth / canonical endpoint / stop-line。下一步唯一 opening 是 docs-only `P1 internal Renderer command buffer lifecycle preflight decision`。
