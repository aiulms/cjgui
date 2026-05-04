# P1 Renderer backend-readiness revisit preflight decision

日期：2026-05-04

状态：docs-only preflight decision

## Scope

本轮 docs-only 在 render pipeline no-op chain 已到 `CjguiInternalRendererNoRenderExecutionReadiness` 后，重新评估 backend-readiness 是否具备足够 owner / resource lifecycle / acceptance gate evidence。

本轮不修改 `.cj`，不实现 backend / Metal / AppKit / CAMetalLayer / platform resource / command buffer / render execution / renderer state write，不运行 build / smoke。

## Read Inputs

- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [2026-05-04-p1-internal-renderer-render-execution-no-op-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-render-execution-no-op-manifest-stabilization-closure-review.md)
- [2026-05-03-p1-renderer-backend-readiness-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-readiness-preflight-decision.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
- [2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Revisit Decision

当前不允许打开 backend-readiness value boundary。

相比 2026-05-03 的 backend-readiness preflight，当前 evidence 已显著增强：render pipeline no-op chain 已经从 platform resource owner 一路走到 no-render-execution endpoint。但 backend-readiness value boundary 仍缺一个明确的 backend object owner / lifecycle / acceptance gate truth。如果现在新建 `runtime_renderer_backend_readiness.cj`，它很容易把 `CjguiInternalRendererNoRenderExecutionReadiness` 直接包装成 backend-readiness wrapper。

因此，本轮不批准：

- `runtime_renderer_backend_readiness.cj`
- backend-readiness value boundary implementation
- backend-readiness receipt / record / publication
- backend-readiness wrapper

如果未来重新打开 backend-readiness value boundary，候选 owner 可以是 `runtime/cjgui/src/runtime_renderer_backend_readiness.cj` 或等价 owner，但必须先由 backend object owner preflight 证明 backend owner / lifecycle / acceptance gate 语义足够。届时 input 应只消费 `CjguiInternalRendererNoRenderExecutionReadiness`，output truth 只能是 backend readiness intent / backend acceptance gate / platform lifecycle coverage / no-backend readiness value facts。

Backend readiness 仍明确不等于 backend implementation、platform resource permission、command buffer permission、GPU submission permission、render execution permission 或 renderer state write permission。

## Evidence Now Available

### Platform resource owner

[Platform resource owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md) 已固定 `CjguiInternalRendererNoPlatformResourceReadiness`。它表达 platform resource owner intent / resource confinement policy / drawable acquisition policy / command queue ownership policy / no-platform-resource readiness value facts，明确 future device / layer / command queue / drawable / command buffer / render pass / encoder 只能作为 policy targets，不进入 core packet。

### Command queue lifecycle

[Command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md) 已固定 `CjguiInternalRendererNoCommandQueueReadiness`。它表达 queue owner identity、lifetime phase、creation guard、shutdown / rollback policy、frame pacing relation 与 no-command-queue readiness facts，不创建 command queue。

### Drawable acquisition lifecycle

[Drawable acquisition lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md) 已固定 `CjguiInternalRendererNoDrawableReadiness`。它表达 drawable availability phase、acquisition timing、presentation ownership、resize / scale / color relation、failure / no-draw fallback，不获取 drawable。

### Command buffer lifecycle

[Command buffer lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md) 已固定 `CjguiInternalRendererNoCommandBufferReadiness`。它表达 creation phase、commit timing guard、single-use / post-commit invalidation、completion / failure phase、rollback / no-draw fallback，不创建或 commit command buffer。

### Render pass lifecycle

[Render pass lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md) 已固定 `CjguiInternalRendererNoRenderPassReadiness`。它表达 attachment role、load / store intent、clear-color facts、drawable-size relation、color-space relation、failure / no-draw fallback，不创建 descriptor / attachment / encoder。

### Encoder lifecycle

[Encoder lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md) 已固定 `CjguiInternalRendererNoEncoderReadiness`。它表达 encoding scope、pipeline binding guard、end-encoding boundary、failure / no-draw fallback，不 begin / end encoding，不绑定 pipeline 或 resources。

### Draw call lifecycle

[Draw call lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md) 已固定 `CjguiInternalRendererNoDrawCallReadiness`。它表达 primitive kind placeholder、geometry source policy、draw order relation、draw sequencing guard、failure / no-draw fallback，不发 draw command。

### Pipeline state lifecycle

[Pipeline state lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md) 已固定 `CjguiInternalRendererNoPipelineStateReadiness`。它表达 shader role placeholder、pipeline descriptor policy、material / render pass / encoder / draw call compatibility guard、failure / no-pipeline fallback，不创建 / 编译 / 缓存 / 绑定 pipeline state。

### Render execution no-op

[Render execution no-op manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md) 已固定 `CjguiInternalRendererNoRenderExecutionReadiness`。它表达 execution ordering policy、no-submit guard、completion observation policy、rollback / no-draw fallback，不执行 render、不 commit command buffer、不 submit GPU work、不写 renderer state。

### Backend / Metal reference pack

[Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 提供 Apple official evidence：Metal command structure、command buffer presentation / completion、render command encoder / render pass lifecycle、CAMetalLayer drawable lifecycle、MTKView / AppKit layer / backing scale、frame pacing 与 resource ownership sketch。

## Evidence Gaps

### Backend object lifecycle owner

仍缺明确 backend object owner truth：谁拥有 future backend object、backend object 的 lifetime phase / construction guard / shutdown guard / rollback guard 是什么、backend object 如何独占 platform resources，以及 backend acceptance gate 如何避免变成 `NoRenderExecutionReadiness` thin wrapper。

这是阻止 A 的主要缺口。

### Frame pacing owner

已有 frame pacing relation facts 与 Apple reference evidence，但仍缺明确 owner truth：frame pacing 应归 AppKit display link、MTKView draw loop、scheduler owner、backend owner，还是独立 pacing owner。该缺口不一定必须先于 backend object owner 解决，但 backend object owner preflight 必须说明它是否包含或暂缓 frame pacing。

### Renderer state write owner

Renderer state write 仍是 hard stop-line。当前没有 renderer state write permission，也没有 state write owner truth。该缺口不阻止先做 backend object owner preflight，但阻止任何 backend-readiness implementation 把 acceptance gate解释成 state write readiness。

### Platform bridge confinement

Platform resource owner manifest 已覆盖 resource confinement policy，但 backend object owner 仍需回答 platform bridge confinement 如何落到 future backend object boundary：backend object 是否独占 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer，如何避免 native handle / raw pointer 进入 core packet。

### Failure / rollback / no-draw path

各 lifecycle manifest 已有 failure / rollback / no-draw value facts，但 backend object owner 仍需定义这些 facts 如何汇总为 backend-local no-draw / no-backend readiness，而不是变成 callback、log、telemetry、event bus 或 renderer state mutation。

## Candidate Comparison

### A. P1 internal Renderer backend-readiness value boundary bundle implementation

暂缓，不选择。

Current lifecycle coverage 已足以证明 backend-readiness 有新增语义空间，但 backend object owner / acceptance gate evidence 仍不足。若现在直接实现，风险是把 `CjguiInternalRendererNoRenderExecutionReadiness` 包成 backend-readiness wrapper。

### B. P1 internal Renderer renderer state write preflight decision

暂缓。

State write 确实缺 owner truth，但当前更先缺 backend object owner。Renderer state write 通常应等 backend object / backend readiness 重新定界后再评估。

### C. P1 internal Renderer backend object owner preflight decision

选择。

该 preflight 可以 docs-only 回答：

- backend object owner 是谁。
- backend object 是否独占 future platform resources。
- backend object lifecycle / construction guard / shutdown guard / rollback guard 如何表达。
- backend acceptance gate 为什么不是 receipt / record / publication wrapper。
- frame pacing owner 是否被 backend object 包含、暂缓，或需要独立 preflight。
- no-draw / failure / rollback 如何保持 value facts。

### D. P1 internal Renderer frame pacing owner preflight decision

暂缓。

Frame pacing owner 仍是缺口，但通常应先看 backend object owner 是否承担 pacing relationship 或显式拆出 pacing owner。若 backend object preflight 无法收束该问题，再开 frame pacing owner preflight。

### E. Backend-readiness reference / manifest hardening docs bundle

暂缓。

Reference pack 和 lifecycle manifests 已足够清楚；当前问题不是文档链接不足，而是 backend object owner truth 尚未单独评估。

### F. Backend / Metal implementation

拒绝。

### G. Command buffer commit / GPU submission / render execution implementation

拒绝。

### H. Renderer state write implementation

拒绝。

### I. Metal / AppKit / platform resource / native handle implementation

拒绝。

### J. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### K. Public surface expansion

拒绝。

### L. Receipt / record / publication

拒绝。

### M. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

本轮判断 backend-readiness 确实有新增 acceptance gate / lifecycle coverage / no-backend readiness 语义空间，但 backend object owner evidence 仍不足，因此不批准 runtime boundary。

明确拒绝：

- 把 `CjguiInternalRendererNoRenderExecutionReadiness` 直接包成 backend-readiness wrapper。
- backend-readiness receipt / record / publication。
- command-buffer-commit readiness wrapper。
- GPU-submission wrapper。
- renderer-state-write readiness wrapper。
- backend implementation。

若未来选择 backend-readiness value boundary，下一轮仍必须禁止 backend implementation、platform object creation、command buffer commit、GPU submission 和 renderer state write。

## Decision

本轮不批准 `P1 internal Renderer backend-readiness value boundary bundle implementation`。

选择下一阶段：

`P1 internal Renderer backend object owner preflight decision`

下一轮仍必须 docs-only，基于 render execution no-op manifest 与 backend / Metal reference pack 评估 backend object owner / lifecycle / acceptance gate truth；不得实现 backend，不得创建 platform resource，不得执行 render，不得提交 command buffer，不得 GPU submission，不得写 renderer state。

## Downstream Backend Object Owner Preflight

Renderer backend object owner preflight 已完成：

- [2026-05-04-p1-renderer-backend-object-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-preflight-decision.md)

该 preflight 判定可以打开 backend object owner runway，但下一步仍只能是 internal value boundary，不是真实 backend object。若下一轮实现，建议 owner 是 `runtime/cjgui/src/runtime_renderer_backend_object.cj`，只消费 `CjguiInternalRendererNoRenderExecutionReadiness`，只输出 backend object owner intent / backend lifecycle ownership policy / backend acceptance gate / platform confinement guard / no-backend-object readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 no-render-execution endpoint 包成 backend object readiness wrapper、backend object receipt / record / publication、backend-readiness wrapper、command-buffer-commit readiness wrapper、GPU-submission wrapper 或 renderer-state-write readiness wrapper；不得创建 backend object、platform object、native handle、command buffer，不得 GPU submission、render execution 或 renderer state write。

## Validation

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过；范围限定 project docs / README / tracker / runtime README，避开 `reference_repos/` 外部镜像噪音。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过，均能找到本 preflight decision 与唯一 next opening。
- Forbidden check：通过；tracked diff 未包含 `.cj` runtime code、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- Public declaration scan：通过，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：risk `low`，changed_count `13`，changed_files `7`，affected_processes `[]`。
- 本轮 docs-only，未运行 `cjpm build`，未运行 smoke。
