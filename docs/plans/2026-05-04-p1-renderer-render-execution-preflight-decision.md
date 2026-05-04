# P1 Renderer render execution preflight decision

日期：2026-05-04

状态：preflight decision

## Scope

本轮 docs-only 基于 pipeline state lifecycle manifest、draw call lifecycle manifest、encoder / render pass / command buffer manifests 和 backend / Metal reference pack，评估是否可以打开 render execution runway。

本轮不修改 `.cj`，不执行 render，不创建或引用 `MTLRenderCommandEncoder`、`MTLRenderPipelineState`、command buffer、drawable、render pass、native handle 或 raw pointer；不实现 backend / Metal / AppKit、renderer state write、draw call 或 GPU submission；不运行 build / smoke。

## Read Inputs

- [2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-pipeline-state-lifecycle-manifest-stabilization-closure-review.md)
- [2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Preflight Decision

允许打开 render execution runway，但下一步也只能是 internal no-op value boundary，不是真实 render execution。

若下一轮实现，建议新建 internal-only owner：

- `runtime/cjgui/src/runtime_renderer_render_execution.cj`

Input truth 应只消费当前 canonical tail：

- `CjguiInternalRendererNoPipelineStateReadiness`
- `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`

理由：pipeline state lifecycle manifest 已经把 material key / render pass / encoder / draw call compatibility relation 收束为 no-pipeline-state value facts。下一步若再组合 draw call / pipeline / encoder / render pass endpoints，容易把多个 upstream readiness 拼成 receipt / record / publication。组合关系应只作为 docs evidence 与 dehydrated relation vocabulary，不作为 runtime object or platform handle input。

Output truth 只能是：

- render execution intent value facts。
- execution ordering policy value facts。
- no-submit guard value facts。
- completion observation policy value facts。
- no-render-execution readiness value facts。

下一轮不得把 `CjguiInternalRendererNoPipelineStateReadiness`、draw-call endpoint、encoder endpoint、render-pass endpoint、command-buffer endpoint 或 reference pack 直接包装成 render-execution receipt / record / publication，也不得复用旧 handoff receipt 语义。

## Reference Evidence

Backend / Metal reference pack 与 lifecycle manifests 的 evidence 足以支撑一个 no-render-execution value boundary：

- Metal command structure evidence：command buffers 承载 encoded commands，并在 commit 后由 command queue 调度；commit 不等于立即执行，且 command buffer commit 后不可复用。
- Command buffer manifest evidence：`CjguiInternalRendererNoCommandBufferReadiness` 只表达 creation policy / commit timing guard / single-use / completion-failure value facts，不是 command buffer permission 或 submission permission。
- Render pass manifest evidence：`CjguiInternalRendererNoRenderPassReadiness` 只表达 attachment / load-store / clear-color value facts，不是 render pass descriptor ownership。
- Encoder manifest evidence：`CjguiInternalRendererNoEncoderReadiness` 只表达 encoding scope / pipeline binding guard / end-encoding policy value facts，不是 encoder object or begin/end encoding permission。
- Draw call manifest evidence：`CjguiInternalRendererNoDrawCallReadiness` 只表达 draw command shape / geometry source / sequencing guard value facts，不是 draw call execution。
- Pipeline state manifest evidence：`CjguiInternalRendererNoPipelineStateReadiness` 只表达 shader role / descriptor policy / compatibility guard value facts，不是 pipeline binding, compile, cache, or render permission。
- Completion evidence：Metal completion handlers and presentation callbacks belong to future backend owner; core value facts may only name completion / failure observation as dehydrated policy vocabulary, not callback registration。
- Frame pacing evidence：display refresh / MTKView / display link references prove frame timing is platform/backend-owned; render execution preflight may express frame pacing relation as value facts only, not a scheduler or callback implementation。

这些 evidence 只证明 render execution lifecycle 有独立 execution ordering / no-submit / completion observation / no-render-execution 语义空间，不批准 render execution、command buffer commit、GPU submission、encoder calls、draw calls、pipeline binding、resource binding、backend implementation、observer callback、event bus、telemetry、logging 或 renderer state write。

## Allowed Dehydrated Facts

下一轮若进入 value boundary，只允许表达以下脱水 facts：

- execution phase。
- command sequencing summary。
- no-submit guard。
- completion / failure observation policy。
- rollback / no-draw fallback。
- command buffer commit relation as policy vocabulary only。
- encoder end relation as policy vocabulary only。
- draw call relation as policy vocabulary only。
- pipeline state relation as policy vocabulary only。
- frame pacing relation as policy vocabulary only。

这些 facts 不能携带 encoder、pipeline state、command buffer、drawable、render pass、GPU object、native handle、raw pointer、platform resource token、backend object、completion callback、present callback、command queue callback、observer callback、telemetry event 或 renderer state write。

## Relationship Model

Render execution 与 command buffer commit / encoder end / draw call / pipeline state / frame pacing 的关系只能这样表达：

- command buffer relation 是 future commit / submission stop-line vocabulary，不是 commit permission。
- encoder relation 是 end-encoding boundary / command sequencing summary vocabulary，不是 encoder call。
- draw call relation 是 draw command shape and sequencing summary vocabulary，不是 draw command emission。
- pipeline state relation 是 compatibility / binding precondition vocabulary，不是 pipeline bind, compile, or cache。
- frame pacing relation 是 future scheduling / presentation timing vocabulary，不是 display link, timer, event loop, or callback binding。
- completion / failure relation 是 future backend-local outcome vocabulary，不是 observer callback、completion handler registration、telemetry、event bus、logging 或 public diagnostics。
- rollback / no-draw path 是 fail-closed value outcome vocabulary，不是 renderer state write, resource cleanup hook, backend callback, or external artifact.

Open path 只表示 render execution no-op facts 可继续评估；defer-only 保持 defer；blocked / inconsistent fail-closed blocked。它们不 create encoder, bind pipeline, issue draw, end encoding, commit command buffer, submit GPU work, present drawable, observe completion callback, write renderer state, or publish public diagnostics.

## Value Boundary vs Reference Hardening

不需要先做 render execution reference hardening。

理由：

- Reference pack 已提供 command buffer commit / completion, render pass / encoder, drawable, frame pacing 与 resource ownership evidence。
- Command buffer / render pass / encoder / draw call / pipeline state manifests 已分别封账 no-object / no-render endpoint，足以支撑 render execution no-op owner truth。
- 当前缺口不是资料不足，而是下一轮 value boundary 必须继续保护 no-submit / no-render / no-renderer-state-write stop-line。

## Candidate Comparison

### A. P1 internal Renderer render execution no-op value boundary bundle implementation

推荐。

Preflight evidence 足够证明 render execution lifecycle 有新增 execution ordering / no-submit / completion observation / no-render-execution 语义。下一轮若实现，也只能新增 internal value facts，不执行 render、不 commit command buffer、不 submit GPU work、不 present drawable、不调用 encoder、不发 draw call、不绑定 pipeline / buffer / texture、不接 backend、不写 renderer state。

### B. P1 internal Renderer render execution reference hardening docs bundle implementation

暂缓。

Reference pack 与前序 lifecycle manifests 已覆盖 command buffer lifecycle、encoder / render pass relation、draw call / pipeline relation、completion / failure observation 与 frame pacing。当前主要缺口不是资料不足。

### C. Backend-readiness preflight revisit

暂缓。

必须等 render execution no-op truth 后再评估，避免把 no-pipeline-state endpoint 或 reference pack 包成 backend-readiness wrapper。

### D. Renderer state write preflight

暂缓。

必须等 render execution truth 后再评估。当前 renderer state write 仍是 hard stop-line。

### E. Shader / library lifecycle preflight

暂缓。

当前 render execution evidence 未暴露 shader owner truth 缺口。Shader role / shader selection 仍由 pipeline state lifecycle 的 `ShaderFunctionPolicy` 作为 placeholder value facts 表达。

### F. Render execution / Metal implementation

拒绝。

### G. Renderer state write

拒绝。

### H. GPU submission / command buffer commit

拒绝。

### I. Metal / AppKit / platform resource / native handle implementation

拒绝。

### J. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### K. Public surface expansion

拒绝。

### L. Receipt / record / publication

拒绝。

Render execution boundary 不能是 `CjguiInternalRendererNoPipelineStateReadiness` 的 receipt / record / publication thin wrapper。

### M. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

允许选择 A 的原因不是继续包装 `CjguiInternalRendererNoPipelineStateReadiness`，而是 render execution runway 引入了新的不可替代语义：

- execution phase。
- command sequencing summary。
- no-submit guard。
- completion / failure observation policy。
- command buffer commit relation as policy-only vocabulary。
- encoder end relation as policy-only vocabulary。
- frame pacing relation as policy-only vocabulary。
- rollback / no-draw fallback。
- no-render-execution readiness。

本轮明确拒绝：

- render-execution receipt / record / publication。
- no-pipeline-state receipt / record / publication。
- backend-readiness wrapper。
- renderer-state-write readiness wrapper。
- command-buffer-commit readiness wrapper。
- GPU-submission readiness wrapper。
- render execution implementation。
- command buffer commit implementation。
- GPU submission implementation。

若下一轮进入 value boundary，仍必须禁止 render execution、command buffer commit、GPU submission、renderer state write implementation、encoder calls、draw calls、pipeline binding、buffer binding、texture binding、platform object implementation 或 backend implementation。

## Decision

Render execution runway 可以打开，但下一步只允许 internal no-op value boundary。

唯一 next opening：

`P1 internal Renderer render execution no-op value boundary bundle implementation`

下一轮默认 owner 可为 `runtime/cjgui/src/runtime_renderer_render_execution.cj`；只消费 `CjguiInternalRendererNoPipelineStateReadiness`；只输出 render execution intent / execution ordering policy / no-submit guard / completion observation policy / no-render-execution readiness value facts；不得执行 render，不得 commit command buffer，不得 submit GPU work，不得 present drawable，不得创建或引用 encoder、pipeline state、command buffer、drawable、render pass、GPU object、native handle 或 raw pointer，不得实现 backend / Metal / AppKit、draw call 或 renderer state write。

## Validation

本轮 docs-only verification results：

- `git diff --check`：通过。
- Markdown absolute link missing target check：通过；本 decision、README、GUI_TASK_TRACKER、docs/plans README、runtime README 与 downstream manifest/reference-pack links 均存在。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check：通过；四个入口均能找到本 preflight 与唯一 next opening `P1 internal Renderer render execution no-op value boundary bundle implementation`。
- Forbidden check：通过；无 tracked `.cj` runtime diff，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER`。工作区仍有前序未跟踪 renderer owner `.cj` files，本轮未修改它们。
- Public declaration scan：仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：risk `low`，affected processes `[]`。GitNexus reported `changed_count=13`, `affected_count=0`, `changed_files=7` for indexed unstaged docs; new untracked preflight file is validated by the Markdown / reachability checks above.

本轮按要求不运行 `cjpm build` / smoke。

## Downstream Render Execution No-op Value Boundary

Renderer render execution no-op value boundary 已完成：

- [2026-05-04-p1-internal-renderer-render-execution-no-op-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-render-execution-no-op-boundary-closure-review.md)

该 implementation 新增 `runtime/cjgui/src/runtime_renderer_render_execution.cj`，只消费 `CjguiInternalRendererNoPipelineStateReadiness`。Canonical endpoint 是 `CjguiInternalRendererNoRenderExecutionReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`。

Same-shape Boundary Brake 通过 execution ordering / no-submit / completion observation / rollback-no-draw / no-render-execution readiness 语义生效，不是 no-pipeline-state receipt / record / publication wrapper。下一步必须先 docs-only 做 render execution no-op closure / next-boundary decision，决定是否 manifest stabilization；不批准 backend-readiness wrapper、renderer state write preflight、command buffer commit、GPU submission 或真实 render execution。

## Downstream Render Execution No-op Next-boundary Decision

Renderer render execution no-op next-boundary decision 已完成：

- [2026-05-04-p1-renderer-render-execution-no-op-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRenderExecutionReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()` 已足够作为当前 no-render-execution endpoint。下一步选择 docs-only `P1 internal Renderer render execution no-op manifest stabilization bundle implementation`，固定 `runtime_renderer_render_execution.cj` owner / truth / canonical endpoint / stop-line。

Same-shape Boundary Brake 继续生效：不批准 render-execution receipt / record / publication、command-buffer-commit readiness wrapper、backend-readiness wrapper、renderer-state-write readiness wrapper、GPU-submission wrapper 或真实 render execution / GPU submission / command buffer commit / backend / Metal implementation。

## Downstream Render Execution No-op Manifest

Renderer render execution no-op manifest stabilization 已完成：

- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [2026-05-04-p1-internal-renderer-render-execution-no-op-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-render-execution-no-op-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_render_execution.cj` owner / truth / canonical endpoint / stop-line。Canonical endpoint 是 `CjguiInternalRendererNoRenderExecutionReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`。下一步选择 docs-only `P1 internal Renderer backend-readiness revisit preflight decision`，重评 backend-readiness owner / resource lifecycle / acceptance gate evidence；不批准直接实现 backend、renderer state write、command buffer commit、GPU submission 或真实 render execution。
