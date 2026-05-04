# P1 Renderer render execution no-op next-boundary decision

日期：2026-05-04

状态：next-boundary decision

## Scope

本轮 docs-only 评估 `CjguiInternalRendererNoRenderExecutionReadiness` 是否已经足够作为当前 no-render-execution endpoint，并决定下一步是否先做 manifest stabilization。

本轮不修改 `.cj`，不执行 render，不提交 command buffer，不创建或引用 `MTLRenderCommandEncoder`、`MTLRenderPipelineState`、command buffer、drawable、render pass、GPU object、native handle 或 raw pointer；不实现 backend / Metal / AppKit、renderer state write、draw call 或 GPU submission；不运行 build / smoke。

## Read Inputs

- [2026-05-04-p1-internal-renderer-render-execution-no-op-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-render-execution-no-op-boundary-closure-review.md)
- [2026-05-04-p1-renderer-render-execution-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-preflight-decision.md)
- [2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)

## Endpoint Assessment

`CjguiInternalRendererNoRenderExecutionReadiness` 已经足够作为当前 no-render-execution endpoint。

理由：

- Runtime closure 已确认 owner file `runtime/cjgui/src/runtime_renderer_render_execution.cj` 只消费 `CjguiInternalRendererNoPipelineStateReadiness`。
- Current truth 已经覆盖 render execution intent / execution ordering policy / no-submit guard / completion observation policy / no-render-execution readiness value facts。
- Open path 只表达 no-op value facts 可继续评估；defer-only 保持 defer；blocked / inconsistent fail-closed blocked。
- `NoSubmitGuard` 已固定 command buffer commit / GPU submission / drawable presentation stop-line。
- `CompletionObservationPolicy` 只表达 future completion / failure observation facts，不注册 callback、不观察真实 GPU completion、不输出 diagnostics。
- `NoRenderExecutionReadiness` 明确当前没有 render execution、GPU submission、command buffer commit、encoder call、pipeline binding、drawable presentation、renderer state write、native handle 或 raw pointer。

当前未发现 execution ordering / no-submit / completion observation / rollback-no-draw 表达不足。因此本轮不选择 hardening，不继续新增 runtime owner，不打开 renderer state write 或 backend-readiness preflight。

## Candidate Comparison

### A. P1 internal Renderer render execution no-op manifest stabilization bundle implementation

推荐。

当前 endpoint 已经足够，下一步应固定 `runtime_renderer_render_execution.cj` 的 owner / truth / canonical endpoint / stop-line，并封账 no-render-execution endpoint。Manifest stabilization 能防止后续把 no-render-execution endpoint 继续包装成 receipt / record / publication、command-buffer-commit readiness wrapper、backend-readiness wrapper 或 renderer-state-write wrapper。

### B. Renderer state write preflight

暂缓。

Renderer state write 必须等 render execution no-op manifest 后再评估。当前 `CjguiInternalRendererNoRenderExecutionReadiness` 只允许 value facts，不是 renderer state write permission。

### C. Backend-readiness preflight revisit

暂缓。

Backend-readiness revisit 必须等 no-render-execution manifest 后再评估，避免把 render execution no-op endpoint 或 reference pack 包成 backend-readiness wrapper。

### D. Render execution hardening

暂缓。

仅在发现 execution ordering / no-submit / completion observation / rollback-no-draw 表达不足时选择。当前 closure 未暴露这类缺口。

### E. Render-execution receipt / record / publication

拒绝。

Thin wrapper 风险高，会把 `CjguiInternalRendererNoRenderExecutionReadiness` 换名包装成 publication-like tail。

### F. Command buffer commit readiness wrapper

拒绝。

当前 no-submit guard 明确禁止 command buffer commit。Commit readiness wrapper 会过早靠近 GPU submission。

### G. Backend-readiness wrapper

拒绝。

当前没有新的 backend owner / resource lifecycle / acceptance gate evidence。Backend readiness 不能由 no-render-execution endpoint 直接派生。

### H. Render execution / GPU submission / command buffer commit implementation

拒绝。

本阶段仍不执行 render、不 submit GPU work、不 commit command buffer。

### I. Renderer state write implementation

拒绝。

当前 no-render-execution endpoint 不是 renderer state write permission。

### J. Metal / AppKit / platform resource / native handle implementation

拒绝。

Platform resources 仍只能作为 future backend owner 的 policy vocabulary，不得进入 core renderer owner。

### K. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

这些分支不属于当前 renderer execution no-op closure。

### L. Public surface expansion

拒绝。

Public allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### M. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前 evidence 指向 manifest stabilization，而不是删除、合并或重命名 runtime owner。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮继续生效。

`CjguiInternalRendererNoRenderExecutionReadiness` 已经是当前 no-render-execution endpoint。下一步不批准：

- render-execution receipt / record / publication。
- command-buffer-commit readiness wrapper。
- backend-readiness wrapper。
- renderer-state-write readiness wrapper。
- GPU-submission wrapper。
- real render execution implementation。

若未来靠近 renderer state write / backend readiness / real render execution，必须先 docs-only preflight，且提供 concrete owner / lifecycle / resource ownership / failure rollback / no-side-effect evidence。不能直接实现 render execution、command buffer commit、GPU submission、renderer state write、backend / Metal / AppKit implementation 或 public surface expansion。

## Decision

选择 A：`P1 internal Renderer render execution no-op manifest stabilization bundle implementation`。

Manifest stabilization 应固定：

- owner file：`runtime/cjgui/src/runtime_renderer_render_execution.cj`
- canonical endpoint：`CjguiInternalRendererNoRenderExecutionReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`
- current truth：render execution intent / execution ordering policy / no-submit guard / completion observation policy / no-render-execution readiness value facts
- stop-line：no render execution, no command buffer commit, no GPU submission, no encoder call, no pipeline binding, no drawable presentation, no renderer state write, no platform object, no native handle / raw pointer, no backend implementation, no public surface expansion

唯一 next opening：

`P1 internal Renderer render execution no-op manifest stabilization bundle implementation`

下一轮仍必须 docs-only；不得执行 render、提交 command buffer、创建或引用 platform object、接 backend / Metal / AppKit、写 renderer state、扩展 public surface 或新增 receipt / record / publication wrapper。

## Validation

本轮 docs-only verification results：

- `git diff --check`：通过。
- Markdown absolute link missing target check：project docs scope 通过。一次全仓扫描命中了 `reference_repos/` 外部镜像中的上游绝对链接噪音，已按 CJGUI project docs scope 重跑。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability check：通过；四个入口均能找到本 decision 与唯一 next opening `P1 internal Renderer render execution no-op manifest stabilization bundle implementation`。
- Forbidden check：通过；tracked diff 无 `.cj` runtime code diff，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER`。工作区仍有前序未跟踪 renderer owner `.cj` files，本轮未修改它们。
- Public declaration scan：仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：risk `low`，affected processes `[]`。GitNexus reported indexed tracked docs symbols; this new untracked decision file is validated by Markdown / reachability checks above。

本轮按要求不运行 `cjpm build` / smoke。
