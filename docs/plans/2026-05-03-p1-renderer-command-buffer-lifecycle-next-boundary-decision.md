# P1 Renderer command buffer lifecycle next-boundary decision

日期：2026-05-03

状态：docs-only closure / next-boundary decision

## Scope

本 decision 评估 `CjguiInternalRendererNoCommandBufferReadiness` 是否已经足够作为当前 no-command-buffer lifecycle endpoint，并决定下一步是否先做 manifest stabilization，还是进入 render pass lifecycle preflight。

本轮不修改 `.cj`，不创建 command buffer，不创建或引用 `MTLCommandBuffer`、`MTLCommandQueue`、drawable、render pass、encoder、native handle 或 raw pointer，不实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Inputs Read

- [2026-05-03-p1-internal-renderer-command-buffer-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-buffer-lifecycle-value-boundary-closure-review.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-preflight-decision.md)
- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Current Endpoint Assessment

`CjguiInternalRendererNoCommandBufferReadiness` is sufficient as the current no-command-buffer lifecycle endpoint.

It already fixes the value boundary from `CjguiInternalRendererNoDrawableReadiness` into:

- command buffer lifecycle intent value facts。
- command buffer creation policy value facts。
- commit timing guard value facts。
- single-use policy value facts。
- completion / failure / rollback / no-draw fallback value facts。
- no-command-buffer readiness value facts。

This endpoint is not command buffer permission, command queue permission, drawable permission, render pass / encoder permission, backend readiness, render permission, renderer state write, Metal implementation, AppKit implementation, native handle exposure, raw pointer exposure, callback registration, telemetry, event bus, logging, or public diagnostics.

## Decision

Decision: choose `P1 internal Renderer command buffer lifecycle manifest stabilization bundle implementation`.

Reasoning:

- The value boundary has distinct command-buffer-specific truth: creation phase, encoding boundary, commit timing, single-use, post-commit invalidation, completion / failure, rollback / no-draw fallback, and no-command-buffer readiness.
- There is no evidence that creation / commit timing / single-use / failure rollback expression is insufficient.
- Render pass lifecycle should wait until the command buffer owner / truth / canonical endpoint / stop-line are fixed in a manifest.
- Opening render pass lifecycle immediately would increase Same-shape risk by turning command buffer readiness into a render pass readiness wrapper.

Next owner / endpoint to stabilize:

- owner file: `runtime/cjgui/src/runtime_renderer_command_buffer.cj`
- canonical endpoint: `CjguiInternalRendererNoCommandBufferReadiness`
- default draft: `cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()`
- current truth: command buffer lifecycle intent / creation policy / commit timing guard / single-use policy / no-command-buffer readiness value facts

## Candidate Comparison

### A. P1 internal Renderer command buffer lifecycle manifest stabilization bundle implementation

推荐。

This fixes command buffer lifecycle owner / truth / canonical endpoint / stop-line before any downstream render pass or encoder preflight. It preserves the current no-command-buffer endpoint and prevents downstream work from treating readiness as implementation permission.

### B. Render pass lifecycle preflight

暂缓。

Render pass lifecycle should wait until command buffer lifecycle manifest stabilization is complete. It is closer to render pass descriptor / attachment / encoder setup and therefore must not be opened from a loose no-command-buffer endpoint.

### C. Encoder lifecycle preflight

暂缓。

Encoder lifecycle must wait for a separate render pass lifecycle preflight and cannot be opened directly from command buffer readiness.

### D. Command buffer lifecycle hardening

暂缓。

Only choose hardening if future evidence shows insufficient creation / commit timing / single-use / completion-failure / rollback expression. Current closure does not show that gap.

### E. Command buffer receipt / record / publication

拒绝。

Thin wrapper risk is high, and `CjguiInternalRendererNoCommandBufferReadiness` already carries the current endpoint truth.

### F. Backend-readiness wrapper

拒绝。

Backend-readiness remains too broad and would likely become a wrapper without platform lifecycle evidence beyond command buffer value facts.

### G. Command buffer / Metal implementation

拒绝。

### H. Render execution / renderer state write

拒绝。

### I. Metal / AppKit / platform resource / native handle implementation

拒绝。

### J. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### K. Public surface expansion

拒绝。

### L. Consolidation

暂缓。

Only choose consolidation if future evidence shows duplicate / low-value helper / self-wrapping owner. No such evidence exists in this decision.

## Same-shape Boundary Brake

Same-shape Boundary Brake is active.

`CjguiInternalRendererNoCommandBufferReadiness` is already the current no-command-buffer endpoint. Do not add command buffer receipt / record / publication, backend-readiness wrapper, render pass readiness wrapper, or encoder readiness wrapper.

If future work approaches render pass / encoder / platform lifecycle, it must begin with docs-only preflight and must provide concrete owner / lifecycle / resource / stop-line evidence. It cannot directly implement render pass, encoder, command buffer, backend object, platform object, render execution, or renderer state write.

## Stop-line

Continue to prohibit:

- no `.cj` modifications in this decision round。
- no command buffer creation。
- no command buffer commit / submission。
- no `MTLCommandBuffer` creation or reference。
- no `MTLCommandQueue` creation or reference。
- no drawable acquisition or drawable object reference。
- no render pass / encoder creation。
- no backend / Metal / AppKit implementation。
- no platform object / native handle / raw pointer。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no renderer state write。
- no completion callback, observer callback, event bus, telemetry, logging, or public diagnostics。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public surface expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Next Opening

`P1 internal Renderer command buffer lifecycle manifest stabilization bundle implementation`

下一轮必须 docs-only，固定 `runtime_renderer_command_buffer.cj` owner / truth / canonical endpoint / stop-line，并封账 no-command-buffer lifecycle endpoint；不得创建 command buffer、render pass、encoder、backend object、platform object、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Downstream Manifest Stabilization

Renderer command buffer lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_command_buffer.cj` owner / truth / canonical endpoint / stop-line，并封账 no-command-buffer lifecycle endpoint。下一步唯一 opening 是 docs-only `P1 internal Renderer render pass lifecycle preflight decision`，不直接创建 render pass、encoder、command buffer、backend object、platform object、render execution 或 renderer state write。
