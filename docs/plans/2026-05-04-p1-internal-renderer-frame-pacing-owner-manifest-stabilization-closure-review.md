# P1 internal Renderer frame pacing owner manifest stabilization closure review

日期：2026-05-04

状态：manifest stabilization closure

## Scope

本轮 docs-only 固定 `runtime_renderer_frame_pacing.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-frame-scheduler endpoint。

本轮未修改任何 `.cj`，未运行 `cjpm build` / smoke，未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

## Read Inputs

- [runtime_renderer_frame_pacing.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_frame_pacing.cj)
- [2026-05-04-p1-renderer-frame-pacing-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-next-boundary-decision.md)
- [2026-05-04-p1-internal-renderer-frame-pacing-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-frame-pacing-owner-value-boundary-closure-review.md)
- [2026-05-04-p1-renderer-frame-pacing-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-backend-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md)
- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)

## Manifest Result

新增 manifest：

- [2026-05-04-p1-renderer-frame-pacing-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-manifest.md)

Manifest 固定：

- Owner file：`runtime/cjgui/src/runtime_renderer_frame_pacing.cj`
- Canonical upstream endpoint：`CjguiInternalRendererNoBackendObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`
- Canonical endpoint：`CjguiInternalRendererNoFrameSchedulerReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()`
- Current truth：frame pacing owner intent / display timing policy / frame request gate / pacing failure policy / no-frame-scheduler readiness value facts

## Boundary Conclusion

`DisplayTimingPolicy` 不创建 timer / display link / run loop，不创建 frame clock，不绑定 platform callback。

`FrameRequestGate` 不调度 frame、不触发 render loop、不启动 continuous frame driver、不请求 platform drawable、不提交 command buffer、不提交 GPU work。

`PacingFailurePolicy` 不观察真实 platform failure、不注册 callback、不发布 diagnostics、不输出 telemetry、不写 renderer state。

`NoFrameSchedulerReadiness` 不是 scheduler permission、display-link permission、backend readiness、renderer-state-write readiness、render permission、command-buffer-commit permission 或 GPU-submission permission。

当前没有 `CVDisplayLink` / `MTKView` draw loop / timer / platform scheduler implementation，没有 backend / Metal / AppKit implementation，没有 command buffer commit、GPU submission、render execution 或 renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 closure 生效。

本轮是 manifest 封账，明确拒绝：

- frame pacing receipt / record / publication。
- scheduler-readiness wrapper。
- backend-readiness wrapper。
- renderer-state-write readiness wrapper。
- command-buffer-commit wrapper。
- GPU-submission wrapper。
- real scheduler / timer / display link / render loop。

`CjguiInternalRendererNoFrameSchedulerReadiness` 已经是当前 no-frame-scheduler endpoint。继续包装只会产生 tail wrapper，不产生新的 owner truth。

未来靠近 renderer state write / backend readiness / real scheduler，必须先 docs-only preflight。

## Next Stage Candidate Comparison

### A. P1 internal Renderer renderer state write preflight decision

推荐。

Frame pacing owner manifest 已经封账；下一步可以 docs-only 评估 renderer state write owner / lifecycle / acceptance gate / rollback evidence。该 preflight 不允许实现 renderer state write。

### B. Backend-readiness revisit

暂缓。

通常等 renderer state write preflight 后再评估，避免把 no-frame-scheduler endpoint 包成 backend-readiness wrapper。

### C. Frame pacing hardening

暂缓。

仅在发现 display timing / request gate / failure policy 表达不足时选择。当前未发现该缺口。

### D. Frame scheduler / timer / display link implementation

拒绝。

### E. Backend / Metal / platform implementation

拒绝。

### F. GPU submission / command buffer commit / render execution

拒绝。

### G. Receipt / record / publication

拒绝。

### H. Dirty-region / UI integration

暂缓。

### I. Public surface expansion

拒绝。

### J. Consolidation

仅在明确 duplicate / self-wrapping evidence 出现时选择。当前不选择。

## Validation

本轮 docs-only，不运行 `cjpm build` / smoke。

Validation results：

- `git diff --check` passed.
- Markdown absolute link missing target check passed，project docs scope only。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability passed.
- Forbidden check passed：无 tracked `.cj` diff、无 protected path diff/status。
- Public declaration scan passed：仍只能有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：low risk，affected processes empty.

## Next Opening

唯一 next opening：

`P1 internal Renderer renderer state write preflight decision`

下一轮必须 docs-only；不得实现 renderer state write，不得接 backend / Metal / AppKit，不得实现 frame scheduler / display link / render loop，不得 commit command buffer，不得 GPU submission，不得 render。
