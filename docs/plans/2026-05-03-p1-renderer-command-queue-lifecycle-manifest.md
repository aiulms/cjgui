# P1 Renderer command queue lifecycle manifest

日期：2026-05-03

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_command_queue.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-command-queue lifecycle endpoint。

它不是 command queue implementation manifest，也不是 backend-readiness manifest。它只记录 command queue lifecycle intent、lifecycle ownership policy、creation guard、lifetime policy 与 no-command-queue readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoPlatformResourceReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`

Current truth：

- command queue lifecycle intent value facts。
- lifecycle ownership policy value facts。
- command queue creation guard value facts。
- command queue lifetime / shutdown / rollback policy value facts。
- no-command-queue readiness value facts。

## Current Pipeline

当前 command queue lifecycle value pipeline：

1. `CjguiInternalRendererNoPlatformResourceReadiness`
2. `CjguiInternalRendererCommandQueueLifecycleIntent`
3. `CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy`
4. `CjguiInternalRendererCommandQueueCreationGuard`
5. `CjguiInternalRendererCommandQueueLifetimePolicy`
6. `CjguiInternalRendererNoCommandQueueReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不创建 command queue。
- 不创建 platform resource。
- 不获取 drawable。
- 不创建 command buffer / render pass / encoder。
- 不执行 render。
- 不写 renderer state。

## Ownership Policy Naming

`CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy` 与 platform resource owner 中的 `CjguiInternalRendererCommandQueueOwnershipPolicy` 不冲突。

分工如下：

- `CjguiInternalRendererCommandQueueOwnershipPolicy` 属于 `runtime_renderer_platform_resource.cj`，描述 platform resource owner pipeline 中的 future command queue ownership policy。
- `CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy` 属于 `runtime_renderer_command_queue.cj`，描述 command queue lifecycle owner pipeline 中的 lifecycle owner facts、queue owner identity、queue 与 future backend/platform owner 的关系。

这种命名避免重复定义，也避免把 no-platform-resource endpoint 直接包成 command queue permission。

## Allowed Value Facts

当前允许表达的 facts 仅限：

- queue owner identity fact。
- future backend / platform owner confinement fact。
- creation guard fact。
- lifetime phase fact。
- shutdown policy fact。
- rollback policy fact。
- frame pacing relationship fact。
- no-draw / blocked / unavailable value facts。

这些 facts 只能是脱水 value facts，不携带 platform object、native handle、raw pointer、drawable、command buffer、render pass、encoder、callback、display link object 或 backend-local resource token。

## Explicit Non-Truth

`CjguiInternalRendererNoCommandQueueReadiness` 明确不是：

- command queue permission。
- command queue creation。
- backend readiness。
- backend object readiness。
- platform object readiness。
- drawable acquisition permission。
- command buffer permission。
- render pass / encoder permission。
- render permission。
- renderer state write。
- Metal / AppKit implementation。
- `MTLCommandQueue` / `MTLDevice` / `CAMetalLayer` ownership。
- native handle / raw pointer surface。
- drawable lifecycle owner。
- command buffer lifecycle owner。
- render execution gate。
- draw call。
- GPU batching。
- public API / public C ABI。

当前没有 `MTLCommandQueue`、`MTLDevice`、`CAMetalLayer`、drawable、command buffer、render pass、encoder、native handle 或 raw pointer。当前没有 backend implementation、render execution 或 renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- command queue receipt / record / publication。
- backend-readiness wrapper。
- command buffer readiness wrapper。
- drawable acquisition readiness wrapper。
- command queue permission wrapper。

`CjguiInternalRendererNoCommandQueueReadiness` 已经是当前 no-command-queue lifecycle endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 platform evidence。

若未来靠近 drawable acquisition / command buffer / platform lifecycle，必须先做 docs-only preflight，并引用 [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 的具体 evidence。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no command queue creation。
- no backend / Metal / AppKit implementation。
- no platform resource implementation。
- no `MTLCommandQueue` / `MTLDevice` / `CAMetalLayer` creation。
- no drawable acquisition。
- no command buffer creation or submission。
- no render pass / render encoder creation。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no renderer state write。
- no native handle / raw pointer / platform object。
- no backend-readiness wrapper。
- no command buffer readiness wrapper。
- no drawable acquisition readiness wrapper。
- no receipt / record / publication。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public surface expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Public Surface

public symbol allowlist 未变：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol、不修改 Bool-only signature、不新增 structured public return、不开放 public C ABI。

## Next Stage Candidate Comparison

### A. P1 internal Renderer drawable acquisition lifecycle preflight decision

推荐为下一阶段 opening。

理由：

- command queue lifecycle endpoint 已封账后，下一步若继续靠近 platform lifecycle，应先 docs-only 评估 drawable acquisition owner / lifecycle / readiness runway。
- Drawable acquisition 必须仍保持 no-drawable-acquisition / no-platform-object / no-render 边界。
- 该 preflight 不获取 drawable，不创建 `CAMetalLayer`，不创建 command buffer，不接 backend implementation。

### B. P1 internal Renderer command buffer lifecycle preflight decision

暂缓。

Command buffer lifecycle 通常应等 drawable lifecycle preflight 后再开。它太靠近 command submission、render pass / encoder 与 render execution。

### C. Command queue lifecycle hardening

暂缓。

只有发现 lifecycle ownership / creation guard / lifetime policy 表达不足时才选。当前 manifest 未发现硬化缺口。

### D. Backend-readiness preflight revisit

暂缓。

Backend-readiness 仍太容易变成 wrapper。等 command queue / drawable lifecycle 进一步拆清后再评估。

### E. Command queue / Metal implementation

拒绝。

### F. Command buffer / render execution / renderer state write

拒绝。

### G. Metal / AppKit / platform resource / native handle implementation

拒绝。

### H. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### I. Public surface expansion

拒绝。

### J. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Decision

本 manifest 固定 `runtime_renderer_command_queue.cj` owner / truth / canonical endpoint / stop-line，并封账 no-command-queue lifecycle endpoint。

唯一 next opening：

`P1 internal Renderer drawable acquisition lifecycle preflight decision`

下一轮必须 docs-only，不得获取 drawable，不得创建 `CAMetalLayer` / command queue / command buffer / render pass / encoder，不得 render，不得写 renderer state。

## Downstream Drawable Acquisition Preflight

Renderer drawable acquisition lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-preflight-decision.md)

该 preflight 判定可以打开 drawable acquisition lifecycle runway，但下一步仍只能是 internal value boundary，不是真实 drawable acquisition。若下一轮实现，建议 owner 是 `runtime/cjgui/src/runtime_renderer_drawable_acquisition.cj`，只消费 `CjguiInternalRendererNoCommandQueueReadiness`，只输出 drawable acquisition lifecycle intent / drawable availability policy / acquisition timing guard / presentation ownership policy / no-drawable readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 no-command-queue endpoint 包成 drawable receipt / record / publication、backend-readiness wrapper 或 command buffer readiness wrapper；不得获取 drawable，不得创建 `CAMetalLayer`、`CAMetalDrawable` / `MTLDrawable`、command buffer、render pass、encoder、native handle 或 raw pointer。

## Downstream Drawable Acquisition Value Boundary

Renderer drawable acquisition lifecycle value boundary 已完成：

- [2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-value-boundary-closure-review.md)

该 boundary 新增 `runtime/cjgui/src/runtime_renderer_drawable_acquisition.cj`，只消费 `CjguiInternalRendererNoCommandQueueReadiness`，canonical endpoint 是 `CjguiInternalRendererNoDrawableReadiness` / `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()`。

它不获取 drawable，不创建 `CAMetalLayer` / `CAMetalDrawable` / `MTLDrawable`、command buffer、render pass、encoder、native handle 或 raw pointer，不实现 backend / Metal / AppKit、render execution 或 renderer state write。下一步唯一 opening 是 docs-only `P1 internal Renderer drawable acquisition lifecycle closure / next drawable acquisition decision`。

## Downstream Drawable Acquisition Next-Boundary Decision

Renderer drawable acquisition lifecycle next-boundary decision 已完成：

- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoDrawableReadiness` 已是当前 no-drawable endpoint，并选择先做 drawable acquisition lifecycle manifest stabilization。Command buffer lifecycle / render pass lifecycle 继续暂缓，必须等 manifest 后再 docs-only 评估。

## Downstream Drawable Acquisition Manifest

Renderer drawable acquisition lifecycle manifest 已完成：

- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-drawable-acquisition-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 封账 no-drawable lifecycle endpoint，并把下一步限制为 docs-only command buffer lifecycle preflight；不批准 command buffer implementation、render pass lifecycle implementation 或 backend / Metal implementation。

## Downstream Command Buffer Lifecycle Preflight

Renderer command buffer lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-command-buffer-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-preflight-decision.md)

该 preflight 建立在 command queue lifecycle 与 drawable acquisition lifecycle 已封账的基础上，判定可以打开 command buffer lifecycle value boundary。Command queue manifest 仍只提供 no-command-queue / lifecycle ownership / creation guard / lifetime facts；下一 owner 必须只消费 `CjguiInternalRendererNoDrawableReadiness`，不得回退消费本 endpoint 形成 thin wrapper。

不批准 `MTLCommandBuffer`、`MTLCommandQueue`、drawable、render pass、encoder、native handle、raw pointer、backend implementation、render execution 或 renderer state write。
