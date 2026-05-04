# P1 Renderer drawable acquisition lifecycle next-boundary decision

日期：2026-05-03

状态：docs-only decision

## Scope

本轮评估 `CjguiInternalRendererNoDrawableReadiness` 是否已经足够作为当前 no-drawable lifecycle endpoint，并决定下一阶段是否先做 manifest stabilization。

本轮不修改 `.cj`，不获取 drawable，不创建或引用 `CAMetalLayer`、`CAMetalDrawable`、`MTLDrawable`、command buffer、render pass、native handle 或 raw pointer，不实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Inputs Read

- [2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-value-boundary-closure-review.md)
- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-preflight-decision.md)
- [2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Current Endpoint Assessment

Current owner:

- `runtime/cjgui/src/runtime_renderer_drawable_acquisition.cj`

Current upstream endpoint:

- `CjguiInternalRendererNoCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`

Current no-drawable endpoint:

- `CjguiInternalRendererNoDrawableReadiness`
- `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()`

Current truth:

- drawable lifecycle intent value facts。
- drawable availability policy value facts。
- acquisition timing guard value facts。
- presentation ownership policy value facts。
- no-drawable readiness value facts。

Decision assessment：`CjguiInternalRendererNoDrawableReadiness` 已经足够作为当前 no-drawable lifecycle endpoint。

Reasoning:

- Closure 已证明 open path / defer-only / blocked / inconsistent paths 都保持 fail-closed。
- Endpoint 已覆盖 availability / timing / presentation ownership / no-drawable readiness，不需要继续新增 readiness wrapper。
- It does not grant drawable acquisition, platform object permission, backend readiness, command buffer permission, render pass permission, render permission, or renderer state write.
- Reference pack evidence supports the value vocabulary, but does not support real drawable acquisition implementation.

## Candidate Comparison

### A. P1 internal Renderer drawable acquisition lifecycle manifest stabilization bundle implementation

推荐。

理由：

- `CjguiInternalRendererNoDrawableReadiness` 已经足够作为当前 no-drawable lifecycle endpoint。
- 下一步应固定 owner / truth / canonical endpoint / stop-line，防止继续在 tail 追加同构 wrapper。
- Manifest 可以明确 command buffer lifecycle preflight 必须等 no-drawable endpoint 封账后再评估。

### B. Command buffer lifecycle preflight

暂缓。

Command buffer lifecycle 太靠近 command submission、render pass / encoder 与 render execution。应等 drawable acquisition lifecycle manifest stabilization 完成后再 docs-only 评估。

### C. Render pass lifecycle preflight

暂缓。

Render pass lifecycle 必须等 drawable lifecycle 与 command buffer lifecycle 之后再拆；否则容易把 no-drawable endpoint 误读成 render pass permission。

### D. Drawable lifecycle hardening

暂缓。

仅在发现 availability / timing / presentation ownership 表达不足时选择。当前 closure 未发现表达缺口。

### E. Drawable receipt / record / publication

拒绝。

这类 thin wrapper 风险高，会把 `CjguiInternalRendererNoDrawableReadiness` 换名包装成尾部记录，而不是新增 owner truth。

### F. Backend-readiness wrapper

拒绝。

当前 evidence 不足以从 no-drawable endpoint 直接推出 backend readiness；该方向易变成 thin wrapper。

### G. Drawable / Metal implementation

拒绝。

### H. Command buffer / render execution / renderer state write

拒绝。

### I. Metal / AppKit / platform resource / native handle implementation

拒绝。

### J. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### K. Public surface expansion

拒绝。

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 decision 生效。

`CjguiInternalRendererNoDrawableReadiness` 已经是当前 no-drawable endpoint。它不需要再被包装成 drawable receipt / record / publication、backend-readiness wrapper 或 command buffer readiness wrapper。

若未来靠近 command buffer / render pass / platform lifecycle，必须先做 docs-only preflight，不能直接实现。Preflight 必须提供具体 owner / lifecycle / resource confinement / no-render evidence，并继续禁止 drawable acquisition、command buffer creation、render pass creation、encoder creation、backend implementation、native handle / raw pointer surface 与 renderer state write。

## Decision

选择：

`P1 internal Renderer drawable acquisition lifecycle manifest stabilization bundle implementation`

Decision conclusion:

- `CjguiInternalRendererNoDrawableReadiness` / `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()` 已经足够作为当前 no-drawable lifecycle endpoint。
- 下一步先固定 `runtime_renderer_drawable_acquisition.cj` owner / truth / canonical endpoint / stop-line。
- 不批准 command buffer lifecycle preflight、render pass lifecycle preflight、backend-readiness wrapper、drawable receipt / record / publication 或真实 drawable / Metal implementation。

## Stop-line

继续禁止：

- no `.cj` modifications in this decision round。
- no drawable acquisition。
- no `CAMetalLayer` / `CAMetalDrawable` / `MTLDrawable` creation or reference。
- no command buffer / render pass / encoder。
- no backend / Metal / AppKit implementation。
- no platform object / native handle / raw pointer。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no renderer state write。
- no dirty-region / Widget / Layout / Text / IME / Accessibility。
- no public surface expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Next Opening

唯一 next opening：

`P1 internal Renderer drawable acquisition lifecycle manifest stabilization bundle implementation`

下一轮仍不得获取 drawable，不得创建 `CAMetalLayer` / `CAMetalDrawable` / `MTLDrawable`、command buffer、render pass、encoder、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Downstream Manifest

Renderer drawable acquisition lifecycle manifest 已完成：

- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 no-drawable lifecycle endpoint。下一步唯一 opening 是 docs-only `P1 internal Renderer command buffer lifecycle preflight decision`。
