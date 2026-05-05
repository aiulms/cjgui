# P1 Renderer command buffer commit / GPU submission preflight decision

日期：2026-05-05

状态：docs-only preflight decision

## Scope

本轮只评估是否允许打开 command buffer commit / GPU submission runway。

本轮不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 command buffer、render pass、encoder、pipeline state、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable、backend object、platform object、native handle 或 raw pointer；不调用 `commit`、`present`、`nextDrawable`、Metal、AppKit、Objective-C 或 FFI API；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)
- [2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [2026-05-04-p1-renderer-state-write-no-write-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

## Decision

允许打开 command buffer commit / GPU submission runway。

下一步选择 `P1 internal Renderer command buffer commit / GPU submission value boundary bundle implementation`，但下一步仍只能新增 internal value facts owner，不得真实创建 command buffer，不得调用 `commit` / `present` / `nextDrawable`，不得提交 GPU work，不得执行 render，不得写 renderer state。

默认 owner candidate：

- `runtime/cjgui/src/runtime_renderer_command_submission.cj`

Runtime input 建议只消费：

- `CjguiInternalRendererNoRealDrawableReadiness`

Docs evidence 可以引用 real command queue、no-draw backend shell、command buffer lifecycle、render execution no-op、state write no-write 和 backend / Metal reference pack，但不得作为多 runtime input。

Output truth 只能是：

- command submission intent value facts。
- command buffer commit policy value facts。
- drawable presentation gate value facts。
- GPU submission failure policy value facts。
- no-gpu-submission readiness value facts。

## Evidence

### Real drawable endpoint

[Real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md) 已封账 `CjguiInternalRendererNoRealDrawableReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()`。

该 endpoint 已有 drawable availability、acquisition guard、presentation ownership 与 no-real-drawable readiness 语义，并明确不查询真实 drawable pool、不调用 `nextDrawable`、不获取或持有 drawable、不 present drawable、不提交 command buffer。因此它足以作为 command submission runway 的单一 runtime input，但不授予 drawable permission、command buffer permission、GPU submission permission 或 render permission。

### Real command queue endpoint

[Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md) 已固定 queue creation policy、ownership guard、teardown policy 与 no-real-command-queue readiness value facts。

它提供 command queue lifecycle vocabulary，但仍不是 `MTLCommandQueue` permission，不创建 queue，不创建 command buffer，不提交 GPU work。它只能作为 docs evidence 说明 command submission owner 不能反向污染 queue owner truth。

### No-draw backend shell endpoint

[No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md) 已固定 backend shell lifecycle、no-draw execution gate、shell teardown policy 与 no-backend-shell readiness。

该 evidence 证明 command submission 不能跳过 no-draw gate：future submission facts 必须保留 no-draw / teardown / fallback relation，不能变成 backend shell implementation permission。

### Command buffer lifecycle endpoint

[Command buffer lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md) 已固定 command buffer lifecycle intent、creation policy、commit timing guard、single-use policy 与 no-command-buffer readiness。

该 evidence 已有 commit timing、single-use、completion / failure phase、rollback / no-draw fallback 词汇；这些词汇足以支撑下一轮 value-only command submission policy。但该 manifest 仍不批准 `MTLCommandBuffer` creation、commit、command queue / drawable use、render pass / encoder creation、backend implementation、render execution 或 renderer state write。

### Render execution no-op endpoint

[Render execution no-op manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md) 已固定 execution ordering policy、no-submit guard、completion observation policy 与 no-render-execution readiness。

该 evidence 明确 future command buffer / GPU submission 在当前边界被禁止，completion observation 只能是 future facts，不注册 callback、不观察真实 GPU completion。下一轮 command submission value boundary 必须继承 no-submit guard，不得变成 real render execution。

### State write no-write endpoint

[State write no-write manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-manifest.md) 已固定 state mutation policy、commit visibility guard、rollback state policy 与 no-state-write readiness。

该 evidence 防止 command submission preflight 混入 frame completion tracking 或 renderer state mutation。Command submission facts 只能描述 submission admission / failure / no-submit relation，不能写 `runtime_state.cj`，不能记录真实 frame completion，不能打开 public diagnostics。

### Backend / Metal reference pack

[Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 提供 Apple 官方 evidence：command buffer 承载 encoded commands 并最终被 commit 到 GPU；presentation 与 completion handlers 必须在 commit 前登记；command buffer commit 后不可复用；drawable 应 late-bound 并快速释放；completion / resource retention 必须由 future backend owner 管理。

Reference pack 只作为 docs evidence，不是 runtime input，不批准 Metal / AppKit implementation、command buffer creation、drawable acquisition、present、commit、GPU submission、callback registration、resource retention implementation 或 renderer state write。

### Risk ledger

[GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md) 中 GPU resource lifecycle、FFI ownership、main-thread UI resource、FFI error boundary 与 automated visual verification 风险继续生效。

这些风险要求下一轮 value boundary 明确 no-submit / no-native-handle / no-state-write stop-line，并把 verification strategy 保持在 docs / value facts 层，不把 smoke 或 bridge 经验提升成 runtime truth。

## Future Value Boundary Shape

若下一轮执行 value boundary，建议只新增 owner-local value facts：

- `CjguiInternalRendererCommandSubmissionIntent`：只表达 future command submission lifecycle intent，不是 submit implementation。
- `CjguiInternalRendererCommandBufferCommitPolicy`：只表达 command buffer commit phase / commit timing / single-use relation facts，不创建 command buffer，不调用 `commit`。
- `CjguiInternalRendererDrawablePresentationGate`：只表达 drawable presentation ordering / present-before-submit relation facts，不调用 `present`，不获取 drawable。
- `CjguiInternalRendererGpuSubmissionFailurePolicy`：只表达 completion / failure / rollback / no-draw fallback facts，不注册 callback，不观察真实 GPU completion。
- `CjguiInternalRendererNoGpuSubmissionReadiness`：明确当前没有 command buffer commit、drawable present、GPU submission、render execution、renderer state write、native handle、raw pointer 或 backend implementation。

允许脱水 facts：

- commit phase placeholder。
- presentation ordering relation。
- no-submit guard。
- completion / failure observation placeholder。
- resource-retention concern as future policy fact。
- rollback / no-draw fallback relation。
- renderer state write separation。

禁止进入 core / owner fields：

- command buffer object。
- drawable object。
- render pass / encoder / pipeline state object。
- `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`。
- Metal / AppKit / Objective-C / FFI API result。
- native handle / raw pointer。
- callback / observer / telemetry / event bus / public diagnostics。

## Candidate Comparison

### A. P1 internal Renderer command buffer commit / GPU submission value boundary bundle implementation

推荐选择。

Evidence 已足够：real drawable endpoint 封账了 no-real-drawable tail；real command queue endpoint 提供 queue lifecycle vocabulary；command buffer lifecycle manifest 提供 commit timing / single-use / failure relation；render execution no-op manifest 提供 no-submit guard；state write no-write manifest 防止状态写入泄漏；reference pack 提供 commit / present / completion / retention 官方 evidence。

下一轮仍只能做 internal value facts，不得真实 commit / present / submit。

### B. P1 internal Renderer command buffer commit owner preflight decision

谨慎备选，暂不选择。

如果 A 的 command buffer commit policy 与 drawable presentation gate 被证明过宽，可以拆出更窄 command buffer commit owner preflight。但当前 evidence 显示 commit / present / failure relation 已经需要在同一 no-submit gate 下共同表达，拆 B 会延迟但不明显降低当前 docs 风险。

### C. P1 internal Renderer drawable presentation owner preflight decision

谨慎备选，暂不选择。

如果 future value boundary 发现 drawable presentation gate 足以独立成 owner，再拆 C。当前阶段 presentation 必须与 command buffer commit timing 和 no-submit failure policy 一起防守，单独拆 C 容易变成 drawable-present-ready wrapper。

### D. Real backend shell implementation preflight

暂缓。

真实 backend shell implementation 必须等 command submission value facts 与 no-submit endpoint 固定后再评估，不能绕过 command buffer / drawable / failure policy。

### E. Render completion / frame completion tracking preflight

暂缓。

Completion / frame tracking 太接近 callback、observer、telemetry 和 renderer state visibility。当前只能保留 completion / failure observation placeholder，不能注册 callback 或记录真实 completion。

### F. Direct command buffer commit implementation

拒绝。

本轮不批准创建 command buffer，也不批准调用 `commit`。

### G. Direct drawable present implementation

拒绝。

本轮不批准获取 drawable，也不批准调用 `present`。

### H. GPU submission / render execution implementation

拒绝。

本轮不批准 submit GPU work、render execution、encoder calls、draw calls 或 command buffer execution。

### I. Renderer state write

拒绝。

本轮不写 renderer state，不碰 `runtime_state.cj`，不记录真实 frame completion。

### J. Public API / C ABI expansion

拒绝。

Public allowlist 不变。

### K. Receipt / record / publication

拒绝。

不得新增 command submission receipt / record / publication、GPU-submission wrapper、command-buffer-ready wrapper、drawable-present-ready wrapper、backend implementation wrapper 或 render-permission wrapper。

### L. Consolidation

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。

当前 evidence 指向新的 command submission value semantics，不是删除或合并。

## Same-shape Boundary Brake

本轮不得把 `CjguiInternalRendererNoRealDrawableReadiness` 包成 command submission receipt / record / publication、GPU-submission wrapper、command-buffer-ready wrapper、drawable-present-ready wrapper、backend implementation wrapper 或 render-permission wrapper。

选择 A 的原因是下一轮必须新增 commit policy / presentation gate / GPU submission failure / no-gpu-submission readiness 语义：

- Commit policy 只表达 future commit timing / single-use / no-commit facts。
- Presentation gate 只表达 future drawable presentation ordering / no-present facts。
- GPU submission failure policy 只表达 future completion / failure / rollback / no-draw facts。
- No-gpu-submission readiness 明确当前没有 commit、present、GPU submit、render execution、state write、native handle 或 raw pointer。

这不是 no-real-drawable tail wrapper，也不是 backend-ready permission。

## Future Stop-line

下一轮即使执行 value boundary，也仍必须禁止：

- 创建 command buffer、render pass、encoder、pipeline state。
- 调用 `commit`、`present`、`nextDrawable`。
- 获取 drawable 或持有 drawable texture。
- 调用 Metal / AppKit / Objective-C / FFI API。
- 创建 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`。
- commit / present / submit GPU work。
- 执行 render。
- 写 renderer state 或 `runtime_state.cj`。
- 修改 bridge / smoke / harness / native entry。
- 新增 native handle、raw pointer、module-level `var`、public declaration 或 C ABI。
- 接 diagnostics output、telemetry、observer、event bus 或 public API。

## Validation Plan

本轮验证限定 docs-only：

- `git diff --check`
- Markdown absolute link missing target check，限定 project docs scope，避开 `reference_repos/`
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability
- forbidden check：确认无 tracked `.cj` diff、无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`
- public declaration scan：仍只能有 `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`

## Unique Next Opening

`P1 internal Renderer command buffer commit / GPU submission value boundary bundle implementation`

## Downstream

Downstream command submission value boundary is now recorded in:

- [2026-05-05-p1-internal-renderer-command-submission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-command-submission-value-boundary-closure-review.md)

That closure added internal-only `runtime/cjgui/src/runtime_renderer_command_submission.cj`, consumed only `CjguiInternalRendererNoRealDrawableReadiness`, and sealed `CjguiInternalRendererNoGpuSubmissionReadiness` / `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()` as value-only no-gpu-submission facts. It did not create command buffer, call `commit` / `present` / `nextDrawable`, submit GPU work, execute render, write renderer state or expand public API / C ABI.

Downstream command submission next-boundary decision is now recorded in:

- [2026-05-05-p1-renderer-command-submission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-next-boundary-decision.md)

That decision confirms `CjguiInternalRendererNoGpuSubmissionReadiness` / `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()` is sufficient as the current no-gpu-submission endpoint and selects docs-only command submission manifest stabilization next.

Downstream command submission manifest stabilization is now recorded in:

- [2026-05-05-p1-renderer-command-submission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [2026-05-05-p1-internal-renderer-command-submission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-command-submission-manifest-stabilization-closure-review.md)

That manifest fixes `runtime_renderer_command_submission.cj` owner / truth / canonical endpoint / stop-line, keeps `CjguiInternalRendererNoGpuSubmissionReadiness` value-only, and moves the only next opening to docs-only real backend shell implementation preflight.
