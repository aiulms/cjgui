# P1 Renderer pipeline state lifecycle next-boundary decision

日期：2026-05-04

状态：next-boundary decision

## Scope

本轮 docs-only 评估 `CjguiInternalRendererNoPipelineStateReadiness` 是否已经足够作为当前 no-pipeline-state lifecycle endpoint，并决定下一步是否先做 manifest stabilization，还是进入 render execution preflight。

本轮不修改 `.cj`，不创建 pipeline state，不创建或引用 `MTLRenderPipelineState`、`MTLRenderPipelineDescriptor`、shader function、shader library、encoder、buffer、texture、native handle 或 raw pointer；不实现 backend / Metal / AppKit、render execution、renderer state write 或 draw call；不运行 build / smoke。

## Read Inputs

- [2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-value-boundary-closure-review.md)
- [2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md)
- [2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Endpoint Assessment

`CjguiInternalRendererNoPipelineStateReadiness` is sufficient as the current no-pipeline-state lifecycle endpoint.

理由：

- Owner 已明确：`runtime/cjgui/src/runtime_renderer_pipeline_state.cj`。
- Canonical endpoint 已明确：`CjguiInternalRendererNoPipelineStateReadiness`。
- Default draft 已明确：`cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`。
- Upstream truth 只消费 `CjguiInternalRendererNoDrawCallReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`。
- Current truth 只包含 pipeline state lifecycle intent / shader function policy / pipeline descriptor policy / pipeline compatibility guard / no-pipeline-state readiness value facts。
- Open path 只表示 shader role、descriptor placeholder、compatibility relation 与 no-pipeline-state facts 可继续评估。
- Defer-only path 保持 defer，不伪造 pipeline readiness。
- Blocked / inconsistent path fail-closed blocked。
- Stop-line 已明确：不创建 pipeline state，不加载 shader library / function，不创建 descriptor，不调用 encoder，不绑定 buffer / texture，不提交 GPU work，不执行 draw call，不接 backend，不 render，不写 renderer state。

当前 endpoint 不是 pipeline state permission、shader library permission、descriptor permission、pipeline compile/cache permission、encoder binding permission、resource binding permission、backend readiness、render execution permission 或 renderer state write。

## Candidate Comparison

### A. P1 internal Renderer pipeline state lifecycle manifest stabilization bundle implementation

推荐。

`CjguiInternalRendererNoPipelineStateReadiness` 已经足够作为当前 no-pipeline-state lifecycle endpoint。下一步应固定 `runtime_renderer_pipeline_state.cj` 的 owner / truth / canonical endpoint / stop-line，避免在尾部继续新增同构 readiness / receipt / record / publication。

### B. Render execution preflight

暂缓。

Render execution 仍太靠近 GPU submission / backend execution / renderer state write。应等 pipeline state lifecycle manifest 后再评估，且仍只能 docs-only。

### C. Shader / library lifecycle preflight

暂缓。

当前 shader function policy 只表达 shader role placeholder / future selection facts，并未暴露 shader owner truth 缺口。只有 pipeline state manifest 发现 shader owner truth 不足时，才另开 docs-only preflight。

### D. Pipeline state lifecycle hardening

暂缓。

未发现 shader role / descriptor policy / compatibility 表达不足。当前 closure 已覆盖 shader role placeholder、descriptor policy、material / render pass / encoder / draw-call compatibility relation 与 failure / no-pipeline fallback。

### E. Pipeline-state receipt / record / publication

拒绝。

这会把 `CjguiInternalRendererNoPipelineStateReadiness` 继续尾部包装成薄 wrapper，缺少新增 owner truth。

### F. Backend-readiness wrapper

拒绝。

Backend-readiness wrapper 当前证据不足且容易变成 no-pipeline-state endpoint 的同构包装。Backend readiness 必须等 platform / command / drawable / command buffer / render pass / encoder / draw-call / pipeline state manifests 更稳定后另做 docs-only preflight。

### G. Pipeline state / Metal implementation

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

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

`CjguiInternalRendererNoPipelineStateReadiness` 已经是当前 no-pipeline-state lifecycle endpoint。它封住的是 shader role / descriptor policy / compatibility / no-pipeline-state value facts，而不是 pipeline-state receipt / record / publication。

本轮明确不批准：

- pipeline-state receipt / record / publication。
- backend-readiness wrapper。
- render-execution readiness wrapper。
- shader-library readiness wrapper。
- pipeline compile/cache wrapper。
- pipeline state / Metal implementation。
- render execution implementation。

若未来靠近 render execution / shader library / platform lifecycle，必须先 docs-only preflight，不能直接实现。

## Decision

选择 A：`P1 internal Renderer pipeline state lifecycle manifest stabilization bundle implementation`。

Manifest stabilization 应固定：

- owner file：`runtime/cjgui/src/runtime_renderer_pipeline_state.cj`
- canonical endpoint：`CjguiInternalRendererNoPipelineStateReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`
- current truth：pipeline state lifecycle intent / shader function policy / pipeline descriptor policy / pipeline compatibility guard / no-pipeline-state readiness value facts
- stop-line：不是 pipeline state permission、shader library permission、descriptor permission、pipeline compile/cache permission、encoder binding permission、resource binding permission、backend readiness、render execution permission 或 renderer state write。

## Next Opening

唯一 next opening：

`P1 internal Renderer pipeline state lifecycle manifest stabilization bundle implementation`

下一轮必须 docs-only，固定 `runtime_renderer_pipeline_state.cj` owner / truth / canonical endpoint / stop-line；不得创建 pipeline state、shader library / function、pipeline descriptor、encoder、buffer、texture、command buffer、render pass、drawable、platform object，不得实现 backend / Metal / AppKit、draw call execution、render execution 或 renderer state write。

## Downstream Manifest Stabilization

Renderer pipeline state lifecycle manifest stabilization 已完成：

- [2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime/cjgui/src/runtime_renderer_pipeline_state.cj` owner / truth / canonical endpoint / stop-line，并封账 `CjguiInternalRendererNoPipelineStateReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()` 作为当前 no-pipeline-state lifecycle endpoint。下一步只允许 docs-only `P1 internal Renderer render execution preflight decision`，不批准 pipeline-state receipt / record / publication、backend-readiness wrapper、render-execution readiness wrapper、shader / library implementation、pipeline state implementation、render execution 或 renderer state write。

## Validation

本轮 docs-only verification：

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check：通过，均能找到本 decision 与唯一 next opening。
- Forbidden check：通过；本轮没有 tracked `.cj` runtime code diff，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- Public declaration scan：通过，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：`risk_level=low`，`affected_processes=[]`，`affected_count=0`。

本轮按要求不运行 `cjpm build` / smoke。
