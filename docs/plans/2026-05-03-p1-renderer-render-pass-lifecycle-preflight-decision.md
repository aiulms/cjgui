# P1 Renderer render pass lifecycle preflight decision

日期：2026-05-03

状态：preflight decision

## Scope

本轮 docs-only 基于 command buffer lifecycle manifest、drawable acquisition lifecycle manifest 和 backend / Metal reference pack，评估是否可以打开 render pass lifecycle runway。

本轮不修改 `.cj`，不创建 render pass，不创建或引用 `MTLRenderPassDescriptor`、`MTLRenderCommandEncoder`、`MTLCommandBuffer`、drawable、texture、attachment object、native handle 或 raw pointer；不实现 backend / Metal / AppKit、render execution 或 renderer state write；不运行 build / smoke。

## Read Inputs

- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md)
- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Preflight Decision

允许打开 render pass lifecycle runway，但下一步也只能是 internal value boundary，不是真实 render pass。

若下一轮实现，建议新建 internal-only owner：

- `runtime/cjgui/src/runtime_renderer_render_pass.cj`

Input truth 必须只消费：

- `CjguiInternalRendererNoCommandBufferReadiness`
- `cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()`

Output truth 只能是：

- render pass lifecycle intent value facts。
- attachment policy value facts。
- load-store policy value facts。
- clear-color policy value facts。
- no-render-pass readiness value facts。

下一轮不得把 command buffer lifecycle endpoint、drawable endpoint 或 reference pack 直接包装成 render pass receipt / record / publication，也不得复用旧 handoff receipt 语义。

## Reference Evidence

Backend / Metal reference pack 的官方资料证据足以支撑一个 no-render-pass value boundary：

- Metal render command encoder / render pass lifecycle evidence：`MTLRenderPassDescriptor` 描述 render pass attachments / destinations；`MTLRenderCommandEncoder` 由 command buffer 与 render pass descriptor 创建；attachments 携带 load / store actions 与 target textures；draw calls 通过 render command encoder 发出。
- Command buffer lifecycle evidence：command buffer 承载 encoded commands，commit 后不可复用；render pass / encoder 必须保持 backend-local，不能反向污染 core packet 或 command buffer readiness。
- Drawable lifecycle evidence：drawable texture 只是 future render pass output 的临时 backend-local target；drawable acquisition 需要 late-bound / short-lived，并且 failure / unavailable / no-draw path 必须可表达。
- AppKit / layer / Retina evidence：drawable size、backing scale、color space、resize 与 frame pacing 只能脱水为 lifecycle facts，不能让 `NSView`、layer、`CAMetalLayer` 或 drawable object 进入 core。

这些 evidence 只证明 render pass lifecycle 有独立 attachment / load-store / clear-color / no-render-pass 语义空间，不批准 render pass descriptor、attachment object、encoder、draw call、render execution 或 renderer state write。

## Allowed Dehydrated Facts

下一轮若进入 value boundary，只允许表达以下脱水 facts：

- attachment role。
- load / store intent。
- clear color facts。
- drawable-size relation。
- color-space relation。
- resize relation。
- command-buffer relation as value facts only。
- failure / no-draw fallback。
- rollback expectation as value facts only。

这些 facts 不能携带 `MTLRenderPassDescriptor`、`MTLRenderCommandEncoder`、drawable、texture、attachment object、native handle、raw pointer、platform resource token、backend object 或 callback。

## Relationship Model

Render pass 与 command buffer / drawable / color space / resize 的关系只能这样表达：

- command buffer readiness 是 upstream value gate，不是 command buffer permission。
- drawable relation 是 target availability / size / color-space relation，不是 drawable acquisition 或 texture exposure。
- attachment role / load-store / clear-color 是 future render pass policy facts，不是 descriptor creation。
- no-draw / failure / rollback 是 fail-closed value outcome vocabulary，不是 render failure callback、observer callback、telemetry、logging 或 event bus。

Load/store / clear / no-draw / failure rollback path 应以 policy / readiness value facts 表达：open path 只表示 facts 可继续评估；defer-only 保持 defer；blocked / inconsistent fail-closed blocked。它们不创建 descriptor、不开始 encoder、不 encode、不 draw、不 present、不 write renderer state。

## Candidate Comparison

### A. P1 internal Renderer render pass lifecycle value boundary bundle implementation

推荐。

Preflight evidence 足够证明 render pass lifecycle 有新增 attachment / load-store / clear-color / no-render-pass 语义。下一轮若实现，也只能新增 internal value facts，不创建 render pass descriptor、encoder、attachment object、drawable texture、backend object 或 platform resource。

### B. P1 internal Renderer render pass lifecycle reference hardening docs bundle implementation

暂缓。

Reference pack 已覆盖 render command encoder / render pass lifecycle、drawable lifecycle、command buffer lifecycle、AppKit resize / scale / color 与 resource ownership evidence。当前主要缺口不是资料不足，而是需要下一轮 value boundary 继续保持 no-render-pass stop-line。

### C. Encoder lifecycle preflight

暂缓。

Encoder lifecycle 必须等 render pass owner truth 后再评估，避免把 render pass readiness 直接薄包装成 encoder readiness。

### D. Draw call lifecycle preflight

暂缓。

Draw call lifecycle 必须等 encoder lifecycle 后再评估，当前仍不得靠近 draw calls、pipeline state 或 resource binding implementation。

### E. Backend-readiness preflight revisit

暂缓。

Backend-readiness 仍容易回到 thin wrapper。等 render pass / encoder lifecycle 拆清后再评估。

### F. Render pass / Metal implementation

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

Render pass boundary 不能是 `CjguiInternalRendererNoCommandBufferReadiness` 的 receipt / record / publication thin wrapper。

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

允许选择 A 的原因不是继续包装 `CjguiInternalRendererNoCommandBufferReadiness`，而是 render pass lifecycle 引入了新的不可替代语义：

- attachment policy。
- load-store policy。
- clear-color policy。
- drawable-size / color-space relation。
- no-render-pass readiness。
- no-draw / failure rollback value facts。

本轮明确拒绝：

- render pass receipt / record / publication。
- command buffer receipt / record / publication。
- backend-readiness wrapper。
- encoder readiness wrapper。
- render permission wrapper。

若下一轮进入 value boundary，仍必须禁止 `MTLRenderPassDescriptor`、`MTLRenderCommandEncoder`、drawable、texture、attachment object、native handle、raw pointer、backend object、platform object、render execution、draw call 或 renderer state write。

## Decision

Render pass lifecycle runway 可以打开，但下一步只允许 internal value boundary。

唯一 next opening：

`P1 internal Renderer render pass lifecycle value boundary bundle implementation`

下一轮默认 owner 可为 `runtime/cjgui/src/runtime_renderer_render_pass.cj`；只消费 `CjguiInternalRendererNoCommandBufferReadiness`；只输出 render pass lifecycle intent / attachment policy / load-store policy / clear-color policy / no-render-pass readiness value facts；不得创建 render pass descriptor、encoder、attachment、drawable、command buffer、backend object、platform object、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Downstream Render Pass Lifecycle Value Boundary

Renderer render pass lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-render-pass-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-render-pass-lifecycle-value-boundary-closure-review.md)

该 boundary 新增 `runtime/cjgui/src/runtime_renderer_render_pass.cj`，只消费 `CjguiInternalRendererNoCommandBufferReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRenderPassReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()`。

Same-shape Boundary Brake 继续生效：本 owner 新增 render pass attachment / load-store / clear-color / no-render-pass readiness 语义，不是 no-command-buffer endpoint 的 receipt / record / publication thin wrapper。下一步只能进入 docs-only `P1 internal Renderer render pass lifecycle closure / next render pass decision`，不得直接创建 descriptor、encoder、attachment、drawable、command buffer、backend object、platform object、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Downstream Render Pass Lifecycle Next-Boundary Decision

Renderer render pass lifecycle next-boundary decision 已完成：

- [2026-05-03-p1-renderer-render-pass-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRenderPassReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()` 已足够作为当前 no-render-pass endpoint。下一步选择 docs-only `P1 internal Renderer render pass lifecycle manifest stabilization bundle implementation`，先固定 `runtime_renderer_render_pass.cj` owner / truth / canonical endpoint / stop-line，再评估未来 encoder lifecycle preflight。

## Downstream Render Pass Lifecycle Manifest

Renderer render pass lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-render-pass-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-render-pass-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime/cjgui/src/runtime_renderer_render_pass.cj` owner / truth / canonical endpoint / stop-line，并封账 `CjguiInternalRendererNoRenderPassReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()`。下一步唯一 opening 是 docs-only `P1 internal Renderer encoder lifecycle preflight decision`，不得直接创建 encoder、descriptor、command buffer、drawable、backend object、platform object、native handle 或 raw pointer。
