# P1 Renderer pipeline state lifecycle preflight decision

日期：2026-05-04

状态：preflight decision

## Scope

本轮 docs-only 基于 draw call lifecycle manifest、encoder lifecycle manifest 和 backend / Metal reference pack，评估是否可以打开 pipeline state lifecycle runway。

本轮不修改 `.cj`，不创建 pipeline state，不创建或引用 `MTLRenderPipelineState`、`MTLRenderPipelineDescriptor`、shader function、shader library、encoder、buffer、texture、native handle 或 raw pointer；不实现 backend / Metal / AppKit、render execution、renderer state write 或 draw call；不运行 build / smoke。

## Read Inputs

- [2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [2026-05-04-p1-internal-renderer-draw-call-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-draw-call-lifecycle-manifest-stabilization-closure-review.md)
- [2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Preflight Decision

允许打开 pipeline state lifecycle runway，但下一步也只能是 internal value boundary，不是真实 pipeline state。

若下一轮实现，建议新建 internal-only owner：

- `runtime/cjgui/src/runtime_renderer_pipeline_state.cj`

Input truth 必须只消费：

- `CjguiInternalRendererNoDrawCallReadiness`
- `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`

Output truth 只能是：

- pipeline state lifecycle intent value facts。
- shader function policy value facts。
- pipeline descriptor policy value facts。
- pipeline compatibility guard value facts。
- no-pipeline-state readiness value facts。

下一轮不得把 draw call lifecycle endpoint、encoder lifecycle endpoint、render pass endpoint、packet ordering endpoint 或 reference pack 直接包装成 pipeline-state receipt / record / publication，也不得复用旧 handoff receipt 语义。

## Reference Evidence

Backend / Metal reference pack 的官方资料证据足以支撑一个 no-pipeline-state value boundary：

- Metal command structure evidence：`MTLDevice` 是 device-specific objects 的根，pipeline state 相关 object 只能属于 future backend owner，不得进入 core packet truth。
- Render command encoder evidence：render pipeline state / resources / fixed-function state 在 draw calls 前绑定，draw calls 通过 render command encoder 发出。
- Render pass lifecycle evidence：render pass descriptor / attachment / load-store / clear-color facts 已被 no-render-pass endpoint 封账；pipeline state boundary 只能消费它们的脱水 relation，不能创建 descriptor 或 attachment。
- Encoder lifecycle evidence：`CjguiInternalRendererNoEncoderReadiness` 已封账为 no-encoder endpoint；pipeline binding guard 仍只是 future precondition vocabulary，不是 encoder object or binding permission。
- Draw call lifecycle evidence：`CjguiInternalRendererNoDrawCallReadiness` 已封账为 no-draw-call endpoint；draw command shape / geometry source / sequencing facts 给 pipeline state preflight 提供 upstream value gate，但不是 draw call execution、buffer binding 或 texture binding permission。
- Secondary architecture context：Flutter / Impeller、Chromium / Skia 与 GPUI 只证明 shader / pipeline / backend resource work 应与 value-style command truth 分层；它们不是 implementation permission。

这些 evidence 只证明 pipeline state lifecycle 有独立 shader role / descriptor policy / compatibility / no-pipeline-state 语义空间，不批准 pipeline state creation、shader library loading、shader function resolution、pipeline compilation、cache mutation、encoder binding、buffer / texture binding、draw call execution、GPU submission、render execution 或 renderer state write。

## Allowed Dehydrated Facts

下一轮若进入 value boundary，只允许表达以下脱水 facts：

- material key relation。
- shader role placeholder。
- vertex layout placeholder。
- color attachment format relation。
- blend placeholder。
- depth / stencil placeholder。
- pipeline compatibility relation。
- failure / no-pipeline fallback。
- compile / cache policy as future vocabulary only。
- rollback expectation as value facts only。

这些 facts 不能携带 `MTLRenderPipelineState`、`MTLRenderPipelineDescriptor`、shader library、shader function、encoder、buffer、texture、command buffer、render pass descriptor、drawable、native handle、raw pointer、platform resource token、backend object、resource binding object、compile callback 或 cache object。

## Relationship Model

Pipeline state 与 material key / render pass / encoder / draw call 的关系只能这样表达：

- material key relation 是 upstream dehydrated grouping / material vocabulary，不是 GPU pipeline key 或 shader selection result。
- render pass relation 是 color attachment format / load-store / clear-color compatibility vocabulary，不是 render pass descriptor ownership。
- encoder relation 是 future pipeline binding precondition vocabulary，不是 render command encoder permission。
- draw call relation 是 draw command shape / geometry source compatibility vocabulary，不是 draw call execution or command sequencing implementation。
- shader role relation 是 future vertex / fragment role placeholder，不是 shader library lookup、function object ownership 或 compilation。
- pipeline descriptor relation 是 future descriptor policy vocabulary，不是 `MTLRenderPipelineDescriptor` creation。
- compatibility guard 是 future admission vocabulary，不是 pipeline state cache, compile, bind, or render permission。
- failure / rollback 是 fail-closed value outcome vocabulary，不是 completion callback、observer callback、telemetry、logging 或 event bus。

Pipeline compile / cache / failure rollback path 应以 policy / readiness value facts 表达：open path 只表示 facts 可继续评估；defer-only 保持 defer；blocked / inconsistent fail-closed blocked。它们不创建 shader library、不 resolve shader function、不 build descriptor、不 compile pipeline state、不 cache pipeline state、不 bind pipeline、不 draw、不 submit、不 write renderer state。

## Value Boundary vs Reference Hardening

不需要先做 pipeline state lifecycle reference hardening。

理由：

- Reference pack 已提供 command structure、render command encoder、render pass lifecycle 与 secondary architecture context，足以证明 shader role / descriptor policy / compatibility guard 语义空间。
- 当前缺口不是资料不足，而是需要下一轮 value boundary 继续保持 no-pipeline-state stop-line。
- 若下一轮实现，也只能表达 no-platform-object value facts，不能引入 real Metal type、shader library、pipeline descriptor 或 pipeline state cache。

## Candidate Comparison

### A. P1 internal Renderer pipeline state lifecycle value boundary bundle implementation

推荐。

Preflight evidence 足够证明 pipeline state lifecycle 有新增 shader role / descriptor policy / compatibility / no-pipeline-state 语义。下一轮若实现，也只能新增 internal value facts，不创建 pipeline state、不创建 pipeline descriptor、不加载 shader library、不 resolve shader function、不编译 pipeline、不缓存 pipeline、不绑定 pipeline、不调用 encoder、不绑定 buffer / texture、不执行 draw call、不接 backend。

### B. P1 internal Renderer pipeline state lifecycle reference hardening docs bundle implementation

暂缓。

Reference pack 已覆盖 Metal command structure、render command encoder / render pass lifecycle、resource ownership 和 secondary architecture context。当前主要缺口不是资料不足，而是下一轮 value boundary 必须继续保护 no-pipeline-state / no-platform-object / no-render stop-line。

### C. Render execution preflight

暂缓。

必须等 pipeline state owner truth 后再考虑。当前仍不得靠近 render execution、GPU submission 或 renderer state write。

### D. Shader / library lifecycle preflight

暂缓。

Shader / library lifecycle 可在 pipeline state owner truth 后拆。当前 pipeline state preflight 只允许 shader role placeholder / shader function policy vocabulary，不允许 shader library implementation。

### E. Backend-readiness preflight revisit

暂缓。

Backend-readiness 仍容易回到 thin wrapper。等 pipeline state / render execution lifecycle 拆清后再评估。

### F. Pipeline state / Metal implementation

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

Pipeline state boundary 不能是 `CjguiInternalRendererNoDrawCallReadiness` 的 receipt / record / publication thin wrapper。

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

允许选择 A 的原因不是继续包装 `CjguiInternalRendererNoDrawCallReadiness`，而是 pipeline state lifecycle 引入了新的不可替代语义：

- shader role placeholder。
- shader function policy。
- pipeline descriptor policy。
- vertex layout placeholder。
- color attachment format relation。
- blend / depth-stencil placeholders。
- material key compatibility relation。
- pipeline compatibility guard。
- failure / no-pipeline fallback。
- no-pipeline-state readiness。

本轮明确拒绝：

- pipeline-state receipt / record / publication。
- draw-call receipt / record / publication。
- backend-readiness wrapper。
- render-execution readiness wrapper。
- shader-library readiness wrapper。
- pipeline state implementation。
- pipeline descriptor implementation。
- shader library / function implementation。
- encoder binding implementation。

若下一轮进入 value boundary，仍必须禁止 `MTLRenderPipelineState`、`MTLRenderPipelineDescriptor`、shader library、shader function、encoder call、pipeline binding、buffer binding、texture binding、platform object implementation、backend implementation、draw call execution、render execution 或 renderer state write。

## Decision

Pipeline state lifecycle runway 可以打开，但下一步只允许 internal value boundary。

唯一 next opening：

`P1 internal Renderer pipeline state lifecycle value boundary bundle implementation`

下一轮默认 owner 可为 `runtime/cjgui/src/runtime_renderer_pipeline_state.cj`；只消费 `CjguiInternalRendererNoDrawCallReadiness`；只输出 pipeline state lifecycle intent / shader function policy / pipeline descriptor policy / pipeline compatibility guard / no-pipeline-state readiness value facts；不得创建 pipeline state、pipeline descriptor、shader library / function、encoder、buffer、texture、command buffer / render pass / drawable / platform object，不得实现 backend / Metal / AppKit、draw call execution、render execution 或 renderer state write。

## Downstream Value Boundary Closure

Renderer pipeline state lifecycle value boundary 已执行：

- [2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-value-boundary-closure-review.md)

实际新增 owner 是 `runtime/cjgui/src/runtime_renderer_pipeline_state.cj`。Canonical endpoint 是 `CjguiInternalRendererNoPipelineStateReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`；它只消费 `CjguiInternalRendererNoDrawCallReadiness`，只表达 pipeline state lifecycle intent / shader function policy / pipeline descriptor policy / pipeline compatibility guard / no-pipeline-state readiness value facts。

Same-shape Boundary Brake 继续生效：该 owner 不是 no-draw-call readiness 的 receipt / record / publication；下一步只能 docs-only 评估 endpoint closure / manifest stabilization，不得直接进入 shader library lifecycle implementation、pipeline state implementation、backend-readiness wrapper、render execution 或 renderer state write。

## Downstream Next-Boundary Decision

Renderer pipeline state lifecycle next-boundary decision 已完成：

- [2026-05-04-p1-renderer-pipeline-state-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoPipelineStateReadiness` 已足够作为当前 no-pipeline-state endpoint，并选择下一步 docs-only `P1 internal Renderer pipeline state lifecycle manifest stabilization bundle implementation`。Render execution preflight 与 shader / library lifecycle preflight 暂缓，直到 manifest 固定 owner / truth / canonical endpoint / stop-line。

## Downstream Manifest Stabilization

Renderer pipeline state lifecycle manifest stabilization 已完成：

- [2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_pipeline_state.cj` owner / truth / canonical endpoint / stop-line。Canonical endpoint 是 `CjguiInternalRendererNoPipelineStateReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`；current truth 是 pipeline state lifecycle intent / shader function policy / pipeline descriptor policy / pipeline compatibility guard / no-pipeline-state readiness value facts。下一步选择 docs-only `P1 internal Renderer render execution preflight decision`，不直接实现 render execution、shader library lifecycle、pipeline state implementation、backend-readiness wrapper 或 renderer state write。

## Validation

本轮 docs-only 验证结果：

- `git diff --check`: passed。
- Markdown absolute link missing target check: passed。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check: passed。
- Forbidden tracked diff check: passed；没有 tracked `.cj` runtime code diff，未触碰 `runtime_state.cj`、`cjpm.toml`、smoke、harness、native bridge、entry、`AGENTS` / `CLAUDE` / `CANGJIE_ISSUE_LEDGER`。工作区仍保留前序实现轮产生的 untracked renderer owner `.cj` files，本轮未修改它们。
- Public declaration scan: passed；仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`: risk `low`，affected processes `0`。

本轮按要求未运行 `cjpm build` / smoke。
