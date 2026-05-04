# P1 Renderer command buffer lifecycle preflight decision

日期：2026-05-03

状态：docs-only preflight decision

## Scope

本 preflight 基于 drawable acquisition lifecycle manifest、command queue lifecycle manifest 与 backend / Metal reference pack，评估是否可以打开 command buffer lifecycle runway。

本轮不修改 `.cj`，不创建 command buffer，不创建或引用 `MTLCommandBuffer`、`MTLCommandQueue`、`CAMetalLayer`、drawable、render pass、encoder、native handle 或 raw pointer，不实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Inputs Read

- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-manifest-stabilization-closure-review.md)
- [2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Current Upstream Truth

Current drawable acquisition lifecycle endpoint:

- `CjguiInternalRendererNoDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()`

Current drawable truth:

- drawable lifecycle intent value facts.
- drawable availability policy value facts.
- acquisition timing guard value facts.
- presentation ownership policy value facts.
- no-drawable readiness value facts.

This endpoint is not drawable permission, backend readiness, command buffer permission, render permission, renderer state write, render pass permission, encoder permission, or platform object permission.

## Reference Evidence

The backend / Metal reference pack provides enough evidence to separate command buffer lifecycle from drawable lifecycle and command queue lifecycle:

- A command queue creates command buffers and orders their execution, but this does not grant queue creation or command buffer creation in core.
- A command buffer carries encoded commands, has explicit creation / encoding / commit / completion phases, and is not reusable after commit.
- Render, blit, or compute encoders append commands into a command buffer; therefore encoder lifecycle and render pass lifecycle must remain downstream.
- Presentation and completion handling are associated with command buffer lifecycle, but callbacks, observers, telemetry, and render execution remain forbidden.
- Drawable availability can influence render target readiness, but drawable objects remain late-bound backend-local resources and cannot enter core packet truth.
- Failure status, completion phase, and resource retention must be expressed as future backend-local value facts until a real backend owner is separately approved.
- Frame pacing can influence commit timing, but display callbacks, platform objects, command queues, and command buffers stay outside this preflight.

These facts are sufficient for a value boundary that talks about creation phase, encoding phase boundary, commit timing, single-use, completion / failure phase, rollback / no-draw fallback, and no-command-buffer readiness. They are not permission to create, encode, commit, submit, present, or retain a real command buffer.

## Preflight Answers

是否允许打开 command buffer lifecycle runway：

- 允许，但下一步也只能是 internal value boundary，不是真实 command buffer。

下一步 owner：

- 建议新建 `runtime/cjgui/src/runtime_renderer_command_buffer.cj` 或等价 internal-only owner。
- 该 owner 必须只表达 command buffer lifecycle value facts，不创建 command buffer，不持有 queue / drawable / render pass / encoder / native handle。

输入 truth：

- 只允许消费 `CjguiInternalRendererNoDrawableReadiness`。
- 不回退消费 `CjguiInternalRendererNoCommandQueueReadiness`。
- 不回退消费 platform resource owner endpoint 或 packet ordering endpoint。
- 不复用旧 `runtime_renderer_handoff.cj` 的 handoff receipt 语义。

输出 truth：

- command buffer lifecycle intent value facts.
- buffer creation policy value facts.
- commit timing guard value facts.
- single-use policy value facts.
- no-command-buffer readiness value facts.

Allowed dehydrated facts:

- creation phase.
- encoding phase boundary.
- commit timing.
- completion / failure phase.
- rollback / no-draw fallback.
- queue relationship as value facts only.
- drawable relationship as value facts only.
- render pass relationship as value facts only.
- frame pacing relationship as value facts only.

Forbidden core objects:

- `MTLCommandBuffer`.
- `MTLCommandQueue`.
- drawable.
- render pass.
- encoder.
- native handle.
- raw pointer.
- backend object.
- platform object.

Command buffer relation to existing owners:

- Command queue lifecycle remains the upstream owner for queue ownership / creation guard facts, but it does not grant command buffer creation.
- Drawable acquisition lifecycle remains the upstream owner for drawable availability / no-drawable facts, but it does not pass drawable objects into command buffer value truth.
- Render pass and encoder lifecycle must stay future downstream preflights; command buffer lifecycle may only name their phase boundary as dehydrated facts.
- Frame pacing may influence commit timing facts, but no display callback, event loop, scheduler, command submission, presentation, or completion handler is approved.

Commit-after-use / single-use / failure rollback path:

- Single-use must be represented as a policy fact: a future command buffer cannot be reused after commit, but this preflight creates no buffer and commits nothing.
- Commit timing guard can describe future before-commit / after-encoding boundaries, but it cannot submit work.
- Completion / failure phase can be represented as a value fact, not as a callback, observer, event bus message, telemetry record, or renderer state write.
- Rollback / no-draw fallback must fail closed and must not synthesize a command buffer, render pass, encoder, drawable, backend object, or render permission.

Reference hardening need:

- 当前 evidence 足够支持下一步 internal value boundary。
- 不需要先做 command buffer lifecycle reference hardening docs bundle。
- 但下一步 implementation 仍必须引用本 preflight，并保持 no-command-buffer / no-platform-object / no-render stop-line。

## Candidate Comparison

### A. P1 internal Renderer command buffer lifecycle value boundary bundle implementation

推荐。

Reasoning:

- Evidence is sufficient for a distinct value boundary: lifecycle intent / buffer creation policy / commit timing guard / single-use policy / no-command-buffer readiness.
- The boundary would consume only `CjguiInternalRendererNoDrawableReadiness`.
- The output is not a command buffer, not a queue, not a drawable, not a render pass / encoder, and not render permission.

### B. P1 internal Renderer command buffer lifecycle reference hardening docs bundle implementation

暂缓。

Reference pack already contains the required official evidence for command buffer lifecycle, commit timing, single-use semantics, completion / failure phases, presentation relation, and resource retention concerns.

### C. Render pass lifecycle preflight

暂缓。

Render pass lifecycle must wait until command buffer owner truth exists. It is closer to render pass descriptor, encoder lifecycle, and draw call setup.

### D. Encoder lifecycle preflight

暂缓。

Encoder lifecycle must wait until render pass lifecycle is separately evaluated.

### E. Backend-readiness preflight revisit

暂缓。

Backend-readiness remains too broad and likely to become a wrapper until command buffer / render pass / encoder lifecycle facts are split.

### F. Command buffer / Metal implementation

拒绝。

### G. Render execution / renderer state write

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

This preflight does not approve wrapping `CjguiInternalRendererNoDrawableReadiness` as a command buffer receipt / record / publication or generic backend-readiness wrapper.

If the next boundary is implemented, it must prove new command-buffer-specific semantics:

- buffer creation policy.
- encoding phase boundary.
- commit timing guard.
- single-use policy.
- completion / failure phase.
- rollback / no-draw fallback.
- no-command-buffer readiness.

It must not be a generic readiness wrapper, backend-readiness wrapper, render pass readiness wrapper, encoder readiness wrapper, or old handoff receipt.

## Decision

Decision: choose `P1 internal Renderer command buffer lifecycle value boundary bundle implementation` as the next opening.

Preflight conclusion:

- Command buffer lifecycle runway may open only as an internal value boundary.
- Suggested owner is `runtime/cjgui/src/runtime_renderer_command_buffer.cj`.
- Input must be only `CjguiInternalRendererNoDrawableReadiness`.
- Output truth must be command buffer lifecycle intent / buffer creation policy / commit timing guard / single-use policy / no-command-buffer readiness value facts.
- No real command buffer creation, queue creation, drawable acquisition, render pass / encoder creation, backend object, platform object, render execution, renderer state write, native handle, raw pointer, or public surface expansion is approved.

## Stop-line

Continue to prohibit:

- no `.cj` modifications in this preflight round.
- no command buffer creation.
- no command buffer submission or commit.
- no `MTLCommandBuffer` creation or reference.
- no `MTLCommandQueue` creation or reference.
- no `CAMetalLayer` creation or reference.
- no drawable acquisition or drawable object reference.
- no render pass / encoder creation.
- no backend / Metal / AppKit implementation.
- no platform object / native handle / raw pointer.
- no render execution / draw call.
- no GPU batching / draw-call merge.
- no renderer state write.
- no completion callback, observer callback, event bus, telemetry, logging, or public diagnostics.
- no dirty-region / diff / patch / incremental render.
- no Widget / Layout / Text / IME / Accessibility / ECS implementation.
- no public surface expansion.
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change.
- no `runtime_state.cj` touch.
- no `runtime/cjgui/cjpm.toml` change.
- no smoke / harness / native bridge / entry modifications.

## Next Opening

`P1 internal Renderer command buffer lifecycle value boundary bundle implementation`

下一轮允许新增 internal-only runtime owner file，但必须保持 no-command-buffer / no-platform-object / no-render boundary。不得创建或引用 `MTLCommandBuffer`、`MTLCommandQueue`、`CAMetalLayer`、drawable、render pass、encoder、native handle 或 raw pointer。

## Downstream Value Boundary Closure

Renderer command buffer lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-command-buffer-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-buffer-lifecycle-value-boundary-closure-review.md)

新增 owner 是 `runtime/cjgui/src/runtime_renderer_command_buffer.cj`，只消费 `CjguiInternalRendererNoDrawableReadiness`，canonical endpoint 是 `CjguiInternalRendererNoCommandBufferReadiness` / `cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()`。

该 boundary 只表达 command buffer lifecycle intent / creation policy / commit timing guard / single-use policy / no-command-buffer readiness value facts。Same-shape Boundary Brake 继续生效：不得把 no-drawable endpoint 包成 command buffer receipt / record / publication，不得混入 render pass lifecycle 或 encoder lifecycle。

下一步唯一 opening：`P1 internal Renderer command buffer lifecycle closure / next command buffer decision`。

## Downstream Next-Boundary Decision

Renderer command buffer lifecycle next-boundary decision 已完成：

- [2026-05-03-p1-renderer-command-buffer-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoCommandBufferReadiness` 已足够作为当前 no-command-buffer endpoint。下一步转向 docs-only `P1 internal Renderer command buffer lifecycle manifest stabilization bundle implementation`，不直接打开 render pass lifecycle preflight 或 encoder lifecycle preflight。

## Downstream Manifest Stabilization

Renderer command buffer lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 command buffer lifecycle owner / truth / canonical endpoint / stop-line。下一步转向 docs-only `P1 internal Renderer render pass lifecycle preflight decision`，仍不创建 render pass、encoder、command buffer、backend object、platform object、render execution 或 renderer state write。
