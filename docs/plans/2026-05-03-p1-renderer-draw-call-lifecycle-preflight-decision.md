# P1 Renderer draw call lifecycle preflight decision

日期：2026-05-03

状态：preflight decision

## Scope

本轮 docs-only 基于 encoder lifecycle manifest、render pass lifecycle manifest 和 backend / Metal reference pack，评估是否可以打开 draw call lifecycle runway。

本轮不修改 `.cj`，不执行 draw call，不创建或引用 `MTLRenderCommandEncoder`、pipeline state、vertex buffer、index buffer、texture、command buffer、render pass、native handle 或 raw pointer；不实现 backend / Metal / AppKit、render execution 或 renderer state write；不运行 build / smoke。

## Read Inputs

- [2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-encoder-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-encoder-lifecycle-manifest-stabilization-closure-review.md)
- [2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Preflight Decision

允许打开 draw call lifecycle runway，但下一步也只能是 internal value boundary，不是真实 draw call。

若下一轮实现，建议新建 internal-only owner：

- `runtime/cjgui/src/runtime_renderer_draw_call.cj`

Input truth 必须只消费：

- `CjguiInternalRendererNoEncoderReadiness`
- `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`

Output truth 只能是：

- draw call lifecycle intent value facts。
- draw command shape policy value facts。
- geometry source policy value facts。
- draw sequencing guard value facts。
- no-draw-call readiness value facts。

下一轮不得把 encoder lifecycle endpoint、render pass endpoint、packet ordering endpoint 或 reference pack 直接包装成 draw-call receipt / record / publication，也不得复用旧 handoff receipt 语义。

## Reference Evidence

Backend / Metal reference pack 的官方资料证据足以支撑一个 no-draw-call value boundary：

- Metal command structure evidence：command encoder 将 render / compute / blit commands 追加进 command buffer；command buffer commit 后不可复用，draw commands 必须服从 command buffer / encoder lifecycle。
- Render command encoder evidence：render pipeline state / resources / fixed-function state 在 draw calls 前绑定，draw calls 通过 render command encoder 发出。
- Render pass lifecycle evidence：render pass descriptor / attachment / load-store / clear-color facts 已在 no-render-pass endpoint 封账，不能被 draw call endpoint 重新解释为 render pass permission。
- Encoder lifecycle evidence：`CjguiInternalRendererNoEncoderReadiness` 已封账为 no-encoder endpoint；它给 draw call preflight 提供 upstream value gate，但不是 encoder object or draw permission。
- Packet / material grouping evidence：`CjguiInternalRendererPacketOrderingHardeningResult` 与 material grouping hints 仍只是 ordering / hint value facts，不是 draw-call merge、GPU batching、pipeline state 或 vertex/index buffer evidence。

这些 evidence 只证明 draw call lifecycle 有独立 draw command shape / geometry source / sequencing / no-draw-call 语义空间，不批准 draw call execution、encoder call、pipeline state binding、buffer binding、texture binding、GPU submission、render execution 或 renderer state write。

## Allowed Dehydrated Facts

下一轮若进入 value boundary，只允许表达以下脱水 facts：

- primitive kind placeholder。
- vertex source policy。
- index source policy。
- instance count placeholder。
- draw order relation。
- material grouping relation as hints only。
- render command packet relation as value facts only。
- draw sequencing guard。
- failure / no-draw fallback。
- rollback expectation as value facts only。

这些 facts 不能携带 `MTLRenderCommandEncoder`、pipeline state object、vertex buffer、index buffer、texture、command buffer、render pass descriptor、drawable、native handle、raw pointer、platform resource token、backend object、resource binding object 或 callback。

## Relationship Model

Draw call 与 encoder / pipeline binding / material grouping / render command packet 的关系只能这样表达：

- encoder relation 是 upstream no-encoder value gate，不是 render command encoder permission。
- pipeline binding relation 是 future binding precondition vocabulary，不是 pipeline state creation or binding。
- geometry source relation 是 future source policy vocabulary，不是 vertex / index buffer ownership。
- material grouping relation 是 hint-preservation vocabulary，不是 draw-call merge or GPU batching。
- render command packet relation 是 dehydrated command shape vocabulary，不是 backend packet, command buffer, or execution plan。
- draw sequencing guard 是 future sequence policy vocabulary，不是 draw call permission。
- failure / rollback 是 fail-closed value outcome vocabulary，不是 render failure callback、observer callback、telemetry、logging 或 event bus。

Draw sequencing、no-draw 和 failure rollback path 应以 policy / readiness value facts 表达：open path 只表示 facts 可继续评估；defer-only 保持 defer；blocked / inconsistent fail-closed blocked。它们不创建 encoder、不 bind pipeline state、不 bind resources、不 bind buffers、不 encode、不 draw、不 present、不 write renderer state。

## Pipeline State Ordering Question

不需要先做 pipeline state lifecycle preflight。

理由：

- Draw call lifecycle 当前要打开的是 draw command shape / geometry source / sequencing / no-draw-call value vocabulary。
- Pipeline state lifecycle 更靠近 shader state、pipeline object creation、resource layout、backend-local binding implementation。
- 当前 evidence 足以先定义 no-draw-call boundary，并明确 pipeline binding 只作为 guard / precondition facts。

Pipeline state lifecycle preflight 应暂缓到 draw call lifecycle endpoint 封账后再评估，避免把 no-encoder endpoint 直接包成 pipeline-state readiness wrapper。

## Candidate Comparison

### A. P1 internal Renderer draw call lifecycle value boundary bundle implementation

推荐。

Preflight evidence 足够证明 draw call lifecycle 有新增 draw command shape / geometry source / sequencing / no-draw-call 语义。下一轮若实现，也只能新增 internal value facts，不执行 draw call、不调用 encoder、不绑定 pipeline state、不绑定 vertex / index buffer、不绑定 texture、不创建 command buffer、backend object 或 platform resource。

### B. P1 internal Renderer draw call lifecycle reference hardening docs bundle implementation

暂缓。

Reference pack 已覆盖 Metal command structure、render command encoder / render pass lifecycle、command buffer lifecycle 与 resource ownership evidence。当前主要缺口不是资料不足，而是需要下一轮 value boundary 继续保持 no-draw-call stop-line。

### C. Pipeline state lifecycle preflight

暂缓。

当前 draw call evidence 足够，不需要先拆 pipeline state owner truth。Pipeline state lifecycle 应等 draw call lifecycle endpoint 后再评估。

### D. Render execution preflight

暂缓。

必须等 draw call / pipeline lifecycle 后再考虑。当前仍不得靠近 render execution、GPU submission 或 renderer state write。

### E. Backend-readiness preflight revisit

暂缓。

Backend-readiness 仍容易回到 thin wrapper。等 draw call / pipeline state lifecycle 拆清后再评估。

### F. Draw call / Metal implementation

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

Draw call boundary 不能是 `CjguiInternalRendererNoEncoderReadiness` 的 receipt / record / publication thin wrapper。

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

允许选择 A 的原因不是继续包装 `CjguiInternalRendererNoEncoderReadiness`，而是 draw call lifecycle 引入了新的不可替代语义：

- draw command shape。
- primitive kind placeholder。
- vertex / index source policy。
- instance count placeholder。
- draw order relation。
- material grouping relation as hints only。
- draw sequencing guard。
- no-draw-call readiness。
- failure / no-draw fallback value facts。

本轮明确拒绝：

- draw-call receipt / record / publication。
- encoder receipt / record / publication。
- backend-readiness wrapper。
- pipeline-state readiness wrapper。
- render permission wrapper。

若下一轮进入 value boundary，仍必须禁止 draw call execution、encoder call、pipeline state binding、buffer binding、texture binding、platform object implementation、backend implementation、render execution 或 renderer state write。

## Decision

Draw call lifecycle runway 可以打开，但下一步只允许 internal value boundary。

唯一 next opening：

`P1 internal Renderer draw call lifecycle value boundary bundle implementation`

下一轮默认 owner 可为 `runtime/cjgui/src/runtime_renderer_draw_call.cj`；只消费 `CjguiInternalRendererNoEncoderReadiness`；只输出 draw call lifecycle intent / draw command shape policy / geometry source policy / draw sequencing guard / no-draw-call readiness value facts；不得执行 draw call、调用 encoder、绑定 pipeline state、绑定 vertex / index buffer、绑定 texture、创建 command buffer / render pass / drawable / platform object，不得实现 backend / Metal / AppKit、render execution 或 renderer state write。

## Downstream Draw Call Lifecycle Value Boundary

Renderer draw call lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-draw-call-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-draw-call-lifecycle-value-boundary-closure-review.md)

新增 owner 是 `runtime/cjgui/src/runtime_renderer_draw_call.cj`，只消费 `CjguiInternalRendererNoEncoderReadiness`，canonical endpoint 是 `CjguiInternalRendererNoDrawCallReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`。该 owner 只表达 draw call lifecycle intent / draw command shape policy / geometry source policy / draw sequencing guard / no-draw-call readiness value facts，不执行 draw call、不调用 encoder、不绑定 pipeline state / buffer / texture、不提交 GPU work、不接 backend / Metal / AppKit implementation。

唯一 next opening：

`P1 internal Renderer draw call lifecycle closure / next draw call decision`

## Downstream Draw Call Lifecycle Next Decision

Renderer draw call lifecycle next-boundary decision 已完成：

- [2026-05-04-p1-renderer-draw-call-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-next-boundary-decision.md)

该 decision 判定 `CjguiInternalRendererNoDrawCallReadiness` 已足够作为当前 no-draw-call endpoint。下一步选择 `P1 internal Renderer draw call lifecycle manifest stabilization bundle implementation`，而不是 draw-call receipt / record / publication、backend-readiness wrapper、pipeline state lifecycle preflight 或 render execution preflight。

## Downstream Draw Call Lifecycle Manifest

Renderer draw call lifecycle manifest stabilization 已完成：

- [2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [2026-05-04-p1-internal-renderer-draw-call-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-draw-call-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_draw_call.cj` owner / truth / canonical endpoint / stop-line。Canonical endpoint 仍是 `CjguiInternalRendererNoDrawCallReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`；它不是 draw-call permission、pipeline binding permission、backend readiness、render execution permission 或 renderer state write。

唯一 next opening：

`P1 internal Renderer pipeline state lifecycle preflight decision`

## Validation

本轮 docs-only 验证结果：

- `git diff --check`: passed。
- Markdown absolute link missing target check: passed。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check: passed。
- Forbidden tracked diff check: passed；没有 tracked `.cj` runtime code diff，未触碰 `runtime_state.cj`、`cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`。工作区仍保留前序实现轮产生的 untracked renderer owner `.cj` files，本轮未修改它们。
- Public declaration scan: passed；仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`: risk `low`，affected processes `0`。

本轮按要求未运行 `cjpm build` / smoke。
