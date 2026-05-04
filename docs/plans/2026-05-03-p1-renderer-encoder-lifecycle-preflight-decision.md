# P1 Renderer encoder lifecycle preflight decision

日期：2026-05-03

状态：preflight decision

## Scope

本轮 docs-only 基于 render pass lifecycle manifest、command buffer lifecycle manifest 和 backend / Metal reference pack，评估是否可以打开 encoder lifecycle runway。

本轮不修改 `.cj`，不创建 encoder，不创建或引用 `MTLRenderCommandEncoder`、`MTLRenderPassDescriptor`、command buffer、drawable、texture、attachment object、native handle 或 raw pointer；不实现 backend / Metal / AppKit、render execution 或 renderer state write；不运行 build / smoke。

## Read Inputs

- [2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-render-pass-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-render-pass-lifecycle-manifest-stabilization-closure-review.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Preflight Decision

允许打开 encoder lifecycle runway，但下一步也只能是 internal value boundary，不是真实 encoder。

若下一轮实现，建议新建 internal-only owner：

- `runtime/cjgui/src/runtime_renderer_encoder.cj`

Input truth 必须只消费：

- `CjguiInternalRendererNoRenderPassReadiness`
- `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()`

Output truth 只能是：

- encoder lifecycle intent value facts。
- encoding scope policy value facts。
- pipeline binding guard value facts。
- end-encoding policy value facts。
- no-encoder readiness value facts。

下一轮不得把 render pass lifecycle endpoint、command buffer endpoint 或 reference pack 直接包装成 encoder receipt / record / publication，也不得复用旧 handoff receipt 语义。

## Reference Evidence

Backend / Metal reference pack 的官方资料证据足以支撑一个 no-encoder value boundary：

- Metal command structure evidence：command encoder 将 render / compute / blit commands 追加进 command buffer；command buffer commit 后不可复用，encoder scope 必须服从 command buffer lifecycle。
- Render command encoder evidence：`MTLRenderCommandEncoder` 由 command buffer 与 render pass descriptor 创建；render pipeline state / resources / fixed-function state 在 draw calls 前绑定；draw calls 通过 render command encoder 发出。
- Render pass lifecycle evidence：`MTLRenderPassDescriptor` 描述 attachments / destinations，render pass attachment / load-store / clear-color facts 已被 no-render-pass endpoint 封账。
- Resource ownership evidence：encoder 是 future backend-local short-lived object，不能进入 core packet、renderer packet truth、render pass readiness 或 command buffer readiness。

这些 evidence 只证明 encoder lifecycle 有独立 encoding scope / pipeline binding guard / end-encoding / no-encoder 语义空间，不批准 encoder creation、pipeline state binding、resource binding、draw calls、render execution 或 renderer state write。

## Allowed Dehydrated Facts

下一轮若进入 value boundary，只允许表达以下脱水 facts：

- encoding scope。
- pipeline binding intent。
- viewport / scissor placeholder。
- command sequencing guard。
- end-encoding boundary。
- failure / no-draw fallback。
- rollback expectation as value facts only。

这些 facts 不能携带 `MTLRenderCommandEncoder`、`MTLRenderPassDescriptor`、command buffer、drawable、texture、attachment object、native handle、raw pointer、platform resource token、backend object、pipeline state object、resource binding object 或 callback。

## Relationship Model

Encoder 与 render pass / command buffer / draw call / pipeline state 的关系只能这样表达：

- render pass readiness 是 upstream value gate，不是 render pass descriptor permission。
- command buffer relation 是 encoding target relation as value facts only，不是 command buffer ownership or commit permission。
- pipeline binding guard 是 future binding precondition vocabulary，不是 pipeline state creation or binding。
- draw command sequencing guard 是 future sequence policy vocabulary，不是 draw call permission。
- end-encoding boundary 是 future lifecycle boundary vocabulary，不是 encoder end call。
- failure / rollback 是 fail-closed value outcome vocabulary，不是 render failure callback、observer callback、telemetry、logging 或 event bus。

Begin/end encoding、pipeline binding、draw command sequencing 与 failure rollback path 应以 policy / readiness value facts 表达：open path 只表示 facts 可继续评估；defer-only 保持 defer；blocked / inconsistent fail-closed blocked。它们不创建 encoder、不 bind pipeline state、不 bind resources、不 encode、不 draw、不 present、不 write renderer state。

## Candidate Comparison

### A. P1 internal Renderer encoder lifecycle value boundary bundle implementation

推荐。

Preflight evidence 足够证明 encoder lifecycle 有新增 encoding scope / pipeline binding guard / end-encoding / no-encoder 语义。下一轮若实现，也只能新增 internal value facts，不创建 encoder、pipeline state、resource binding、draw call、command buffer、backend object 或 platform resource。

### B. P1 internal Renderer encoder lifecycle reference hardening docs bundle implementation

暂缓。

Reference pack 已覆盖 Metal command structure、render command encoder / render pass lifecycle、command buffer lifecycle 与 resource ownership evidence。当前主要缺口不是资料不足，而是需要下一轮 value boundary 继续保持 no-encoder stop-line。

### C. Draw call lifecycle preflight

暂缓。

Draw call lifecycle 必须等 encoder owner truth 后再评估，避免把 no-render-pass endpoint 或 encoder preflight 直接薄包装成 draw call readiness。

### D. Pipeline state lifecycle preflight

暂缓。

Pipeline state lifecycle 必须等 encoder / draw call preflight 后再评估。当前仍不得靠近 pipeline object creation、shader state、resource binding implementation 或 GPU submission。

### E. Backend-readiness preflight revisit

暂缓。

Backend-readiness 仍容易回到 thin wrapper。等 encoder / draw call lifecycle 拆清后再评估。

### F. Encoder / Metal implementation

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

Encoder boundary 不能是 `CjguiInternalRendererNoRenderPassReadiness` 的 receipt / record / publication thin wrapper。

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

允许选择 A 的原因不是继续包装 `CjguiInternalRendererNoRenderPassReadiness`，而是 encoder lifecycle 引入了新的不可替代语义：

- encoding scope。
- pipeline binding guard。
- viewport / scissor placeholder。
- command sequencing guard。
- end-encoding boundary。
- no-encoder readiness。
- failure / no-draw fallback value facts。

本轮明确拒绝：

- encoder receipt / record / publication。
- render pass receipt / record / publication。
- backend-readiness wrapper。
- draw call readiness wrapper。
- render permission wrapper。

若下一轮进入 value boundary，仍必须禁止 `MTLRenderCommandEncoder`、`MTLRenderPassDescriptor`、command buffer、drawable、texture、attachment object、pipeline state object、native handle、raw pointer、backend object、platform object、render execution、draw call 或 renderer state write。

## Decision

Encoder lifecycle runway 可以打开，但下一步只允许 internal value boundary。

唯一 next opening：

`P1 internal Renderer encoder lifecycle value boundary bundle implementation`

下一轮默认 owner 可为 `runtime/cjgui/src/runtime_renderer_encoder.cj`；只消费 `CjguiInternalRendererNoRenderPassReadiness`；只输出 encoder lifecycle intent / encoding scope policy / pipeline binding guard / end-encoding policy / no-encoder readiness value facts；不得创建 encoder、render pass descriptor、command buffer、drawable、texture、attachment object、pipeline state、backend object、platform object、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Downstream Encoder Lifecycle Value Boundary

Renderer encoder lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-encoder-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-encoder-lifecycle-value-boundary-closure-review.md)

该 implementation 新增 `runtime/cjgui/src/runtime_renderer_encoder.cj`，只消费 `CjguiInternalRendererNoRenderPassReadiness`，输出 encoder lifecycle intent / encoding scope policy / pipeline binding guard / end-encoding policy / no-encoder readiness value facts。Canonical endpoint 是 `CjguiInternalRendererNoEncoderReadiness` / `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`。

Same-shape Boundary Brake 继续生效：这不是 encoder receipt / record / publication、backend-readiness wrapper、draw call readiness wrapper 或 pipeline state lifecycle wrapper；下一步只能 docs-only 进入 encoder lifecycle closure / next encoder decision。

## Downstream Encoder Lifecycle Next-boundary Decision

Renderer encoder lifecycle next-boundary decision 已完成：

- [2026-05-03-p1-renderer-encoder-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-next-boundary-decision.md)

该 decision 判定 `CjguiInternalRendererNoEncoderReadiness` 已足够作为当前 no-encoder lifecycle endpoint。下一步选择 docs-only encoder lifecycle manifest stabilization，固定 `runtime_renderer_encoder.cj` owner / truth / canonical endpoint / stop-line，而不是直接进入 draw call lifecycle preflight、pipeline state lifecycle preflight、backend-readiness wrapper 或真实 encoder / Metal implementation。

## Downstream Encoder Lifecycle Manifest

Renderer encoder lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-encoder-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-encoder-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_encoder.cj` owner / truth / canonical endpoint / stop-line。Canonical endpoint 是 `CjguiInternalRendererNoEncoderReadiness` / `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`；current truth 只能是 encoder lifecycle intent / encoding scope policy / pipeline binding guard / end-encoding policy / no-encoder readiness value facts。下一步只允许 docs-only 进入 draw call lifecycle preflight，不允许直接实现 draw call、pipeline state、backend readiness wrapper、render execution 或 renderer state write。
