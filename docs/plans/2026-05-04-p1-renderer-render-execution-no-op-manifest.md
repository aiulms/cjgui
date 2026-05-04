# P1 Renderer render execution no-op manifest

日期：2026-05-04

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_render_execution.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-render-execution endpoint。

它不是 render execution implementation manifest，也不是 backend-readiness manifest、renderer state write manifest、command buffer commit manifest、GPU submission manifest 或 Metal / AppKit implementation plan。它只记录 render execution intent、execution ordering policy、no-submit guard、completion observation policy 与 no-render-execution readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_execution.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoPipelineStateReadiness`
- `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoRenderExecutionReadiness`
- `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`

Current truth：

- render execution intent value facts。
- execution ordering policy value facts。
- no-submit guard value facts。
- completion observation policy value facts。
- no-render-execution readiness value facts。

## Current Pipeline

当前 render execution no-op value pipeline：

1. `CjguiInternalRendererNoPipelineStateReadiness`
2. `CjguiInternalRendererRenderExecutionIntent`
3. `CjguiInternalRendererExecutionOrderingPolicy`
4. `CjguiInternalRendererNoSubmitGuard`
5. `CjguiInternalRendererCompletionObservationPolicy`
6. `CjguiInternalRendererNoRenderExecutionReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不执行 render。
- 不提交 command buffer。
- 不提交 GPU work。
- 不 present drawable。
- 不调用 encoder。
- 不绑定 pipeline。
- 不绑定 buffer / texture。
- 不注册 callback。
- 不观察真实 GPU completion。
- 不写 renderer state。

## Value Semantics

`CjguiInternalRendererRenderExecutionIntent` 只表达 future render execution intent，不是 render implementation、backend readiness、renderer state write gate、GPU submission gate 或 render permission。

`CjguiInternalRendererExecutionOrderingPolicy` 只表达 command sequencing summary 与 execution phase facts；它不排序、不提交、不执行。

`CjguiInternalRendererNoSubmitGuard` 只表达 no-submit stop-line facts；它不 commit command buffer，不提交 GPU work，不 present drawable。

`CjguiInternalRendererCompletionObservationPolicy` 只表达 future completion / failure observation facts；它不注册 callback，不观察真实 GPU completion，不发布 diagnostics，不输出 telemetry，不写 log。

`CjguiInternalRendererNoRenderExecutionReadiness` 是当前 no-render-execution endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表任何 side effect permission。

## Relationship Facts

Render execution 与 command buffer commit / encoder end / draw call / pipeline state / frame pacing 的关系只能作为 dehydrated lifecycle facts 表达：

- execution phase。
- command sequencing summary。
- encoder end relation as policy vocabulary only。
- draw call relation as policy vocabulary only。
- pipeline state relation as policy vocabulary only。
- frame pacing relation as policy vocabulary only。
- completion / failure observation facts。
- rollback / no-draw fallback。
- no-submit stop-line。

这些 facts 不能携带 encoder、pipeline state、command buffer、drawable、render pass、GPU object、native handle、raw pointer、platform resource token、backend object、completion callback、present callback、command queue callback、observer callback、telemetry event、log sink、diagnostics output 或 renderer state write。

Completion / failure / rollback / no-draw 只作为 dehydrated value facts。它们不是 callback registration plan、completion handler plan、resource cleanup hook、backend callback、diagnostics publication、event bus、telemetry、logging、external artifact 或 renderer state mutation。

## Explicit Non-Truth

`CjguiInternalRendererNoRenderExecutionReadiness` 明确不是：

- render permission。
- render execution permission。
- GPU submission permission。
- command buffer commit permission。
- command buffer readiness。
- backend readiness。
- backend object readiness。
- renderer state write permission。
- renderer state write。
- encoder call permission。
- pipeline binding permission。
- buffer / texture binding permission。
- draw-call permission。
- drawable presentation permission。
- completion callback permission。
- observer callback / event bus permission。
- telemetry / logging / public diagnostics permission。
- Metal / AppKit implementation。
- `MTLRenderCommandEncoder` ownership。
- `MTLRenderPipelineState` ownership。
- command buffer ownership。
- drawable ownership。
- render pass ownership。
- GPU object ownership。
- native handle / raw pointer surface。
- backend-readiness wrapper。
- renderer-state-write readiness wrapper。
- command-buffer-commit readiness wrapper。
- GPU-submission wrapper。
- render-execution receipt / record / publication。
- public API / public C ABI。

当前没有 render execution、GPU submission、command buffer commit、encoder call、pipeline binding、drawable presentation、renderer state write、native handle 或 raw pointer。当前没有 backend implementation、Metal implementation、AppKit implementation 或 platform object implementation。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- render-execution receipt / record / publication。
- command-buffer-commit readiness wrapper。
- backend-readiness wrapper。
- renderer-state-write readiness wrapper。
- GPU-submission wrapper。
- render permission wrapper。
- completion callback wrapper。

`CjguiInternalRendererNoRenderExecutionReadiness` 已经是当前 no-render-execution endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 backend evidence。

若未来靠近 renderer state write / backend readiness / real render execution，必须先做 docs-only preflight，并引用 [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 的具体 evidence。不得直接执行 render、commit command buffer、submit GPU work、present drawable、调用 encoder、发 draw call、绑定 pipeline / buffer / texture、创建 platform object、接 backend / Metal / AppKit implementation 或写 renderer state。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no render execution。
- no command buffer commit。
- no GPU submission。
- no encoder call。
- no pipeline binding。
- no buffer / texture binding。
- no draw call execution。
- no drawable presentation。
- no command buffer creation。
- no render pass creation。
- no drawable acquisition。
- no platform object implementation。
- no backend / Metal / AppKit implementation。
- no renderer state write。
- no completion callback registration。
- no observer callback / event bus / telemetry / logging / public diagnostics。
- no native handle / raw pointer / platform resource token。
- no backend-readiness wrapper。
- no renderer-state-write readiness wrapper。
- no command-buffer-commit readiness wrapper。
- no render-execution receipt / record / publication。
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

### A. P1 internal Renderer backend-readiness revisit preflight decision

推荐为下一阶段 opening。

理由：

- Render pipeline no-op chain 已经到 no-render-execution endpoint。
- 当前可以 docs-only 重评 backend-readiness 的 owner / resource lifecycle / acceptance gate evidence。
- 该 preflight 不实现 backend，不创建 Metal / AppKit / platform object，不执行 render，不提交 command buffer，不写 renderer state。

### B. P1 internal Renderer renderer state write preflight decision

暂缓。

通常应等 backend-readiness revisit 后再开。当前 no-render-execution endpoint 不是 renderer state write permission。

### C. Render execution hardening

暂缓。

仅在发现 ordering / no-submit / completion observation / rollback-no-draw 表达不足时选择。当前 manifest 未发现硬化缺口。

### D. Local command buffer commit preflight

暂缓。

仍太靠近真实 GPU submission。Command buffer commit 继续属于 hard stop-line。

### E. Render execution / GPU submission / command buffer commit implementation

拒绝。

### F. Renderer state write implementation

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

本 manifest 固定 `runtime_renderer_render_execution.cj` owner / truth / canonical endpoint / stop-line，并封账 no-render-execution endpoint。

唯一 next opening：

`P1 internal Renderer backend-readiness revisit preflight decision`

下一轮必须 docs-only，重评 backend-readiness owner / resource lifecycle / acceptance gate evidence；不得实现 backend，不得执行 render，不得提交 command buffer，不得 GPU submission，不得创建或引用 `MTLRenderCommandEncoder`、`MTLRenderPipelineState`、command buffer、drawable、render pass、GPU object、native handle 或 raw pointer，不得写 renderer state。

## Downstream Backend-readiness Revisit Preflight

Renderer backend-readiness revisit preflight 已完成：

- [2026-05-04-p1-renderer-backend-readiness-revisit-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-revisit-preflight-decision.md)

该 preflight 复核本 manifest 固定的 `CjguiInternalRendererNoRenderExecutionReadiness`，判定 current lifecycle evidence 已覆盖 platform resource owner、command queue、drawable acquisition、command buffer、render pass、encoder、draw call、pipeline state 与 render execution no-op，但 backend object owner / lifecycle / acceptance gate truth 仍不足。

因此当前不批准 `runtime_renderer_backend_readiness.cj`、backend-readiness value boundary、backend-readiness receipt / record / publication、command-buffer-commit readiness wrapper、GPU-submission wrapper 或 renderer-state-write readiness wrapper。下一步转向 docs-only `P1 internal Renderer backend object owner preflight decision`。

## Downstream Backend Object Owner Preflight

Renderer backend object owner preflight 已完成：

- [2026-05-04-p1-renderer-backend-object-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-preflight-decision.md)

该 preflight 以 `CjguiInternalRendererNoRenderExecutionReadiness` 为唯一 future runtime input，判定下一步可以进入 backend object owner internal value boundary。该 downstream 只允许表达 backend object owner intent / backend lifecycle ownership policy / backend acceptance gate / platform confinement guard / no-backend-object readiness value facts；不批准 backend object creation、platform object creation、native handle、command buffer commit、GPU submission、render execution 或 renderer state write。

Renderer backend object owner value boundary 已完成：

- [2026-05-04-p1-internal-renderer-backend-object-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-object-owner-value-boundary-closure-review.md)

该 closure 新增 `runtime/cjgui/src/runtime_renderer_backend_object.cj`，只消费本 manifest 固定的 `CjguiInternalRendererNoRenderExecutionReadiness`，并把 current downstream endpoint 固定为 `CjguiInternalRendererNoBackendObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`。该 endpoint 不是 backend object permission、backend-readiness final gate、platform resource permission、command buffer commit permission、GPU submission permission、render execution permission 或 renderer state write permission。

Renderer backend object owner next-boundary decision 已完成：

- [2026-05-04-p1-renderer-backend-object-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-next-boundary-decision.md)

该 decision 确认 downstream no-backend-object endpoint 已足够，下一步先做 backend object owner manifest stabilization；不直接进入 backend-readiness wrapper、frame pacing readiness wrapper、renderer-state-write readiness wrapper、backend implementation、platform object implementation、command buffer commit、GPU submission 或 render execution。

Renderer backend object owner manifest stabilization 已完成：

- [2026-05-04-p1-renderer-backend-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-backend-object-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-object-owner-manifest-stabilization-closure-review.md)

该 manifest 封账 downstream no-backend-object endpoint，并把 next opening 转向 docs-only frame pacing owner preflight。`CjguiInternalRendererNoRenderExecutionReadiness` 与 `CjguiInternalRendererNoBackendObjectReadiness` 都不是 frame pacing permission、backend permission、command buffer commit permission、GPU submission permission、render execution permission 或 renderer state write permission。

Renderer frame pacing owner preflight 已完成：

- [2026-05-04-p1-renderer-frame-pacing-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-preflight-decision.md)

该 preflight 判定 frame pacing owner runway 可以打开，但下一步仍只能是 internal value boundary。Render execution no-op facts 只能作为 no-submit / no-render / completion-failure / no-draw fallback vocabulary，不授予 frame scheduler、display link、render loop、timer、GPU submission、command buffer commit、render execution 或 renderer state write permission。

## Downstream Renderer State Write Preflight

Renderer state write preflight 已完成：

- [2026-05-04-p1-renderer-state-write-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-preflight-decision.md)

该 preflight 引用本 manifest 的 `CjguiInternalRendererNoRenderExecutionReadiness` 作为 docs evidence，而不是 runtime input。Render execution no-op facts 只能证明 no-submit / completion observation / rollback-no-draw vocabulary；不得被解释成 frame completion recording、renderer state mutation、command buffer commit、GPU submission、backend readiness 或 public diagnostics。下一步若实现 no-write value boundary，只能消费 `CjguiInternalRendererNoFrameSchedulerReadiness`。

## Validation

Validation results will be recorded in [2026-05-04-p1-internal-renderer-render-execution-no-op-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-render-execution-no-op-manifest-stabilization-closure-review.md).
