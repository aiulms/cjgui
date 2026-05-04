# P1 Renderer frame pacing owner manifest

日期：2026-05-04

状态：manifest stabilization

## Purpose

本 manifest 固定 `runtime_renderer_frame_pacing.cj` 的 owner / truth / canonical endpoint / stop-line，并封账当前 no-frame-scheduler endpoint。

它不是 frame scheduler implementation manifest，不是 display link / timer / render loop plan，不是 backend-readiness manifest，不是 renderer state write manifest，也不是 command-buffer-commit / GPU-submission manifest。它只记录 frame pacing owner intent、display timing policy、frame request gate、pacing failure policy 与 no-frame-scheduler readiness 的 internal value facts。

## Owner / Truth

Owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_frame_pacing.cj`

Canonical upstream endpoint：

- `CjguiInternalRendererNoBackendObjectReadiness`
- `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoFrameSchedulerReadiness`
- `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()`

Current truth：

- frame pacing owner intent value facts。
- display timing policy value facts。
- frame request gate value facts。
- pacing failure policy value facts。
- no-frame-scheduler readiness value facts。

## Current Pipeline

当前 frame pacing owner value pipeline：

1. `CjguiInternalRendererNoBackendObjectReadiness`
2. `CjguiInternalRendererFramePacingOwnerIntent`
3. `CjguiInternalRendererDisplayTimingPolicy`
4. `CjguiInternalRendererFrameRequestGate`
5. `CjguiInternalRendererPacingFailurePolicy`
6. `CjguiInternalRendererNoFrameSchedulerReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()`
- 只调用 `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`。
- 不读取 Queue / Action / Runtime lower-level mutable facts。
- 不接 backend / Metal / AppKit implementation。
- 不创建 frame scheduler。
- 不创建 timer / display link / run loop。
- 不启动 render loop。
- 不创建 backend object。
- 不创建 platform object。
- 不提交 command buffer。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不注册 callback。
- 不观察真实 platform failure。
- 不暴露 native handle / raw pointer。

## Value Semantics

`CjguiInternalRendererFramePacingOwnerIntent` 只表达 future frame pacing owner intent。它不是 frame scheduler implementation、backend-readiness wrapper、renderer-state-write wrapper、receipt、record 或 publication。

`CjguiInternalRendererDisplayTimingPolicy` 只表达 future display timing / display refresh / drawable timing / resize-scale-color relation facts。它不创建 timer，不创建 display link，不创建 run loop，不创建 frame clock，不绑定 platform callback。

`CjguiInternalRendererFrameRequestGate` 只表达 future frame request admission / defer / no-draw fallback facts。它不调度 frame，不触发 render loop，不启动 continuous frame driver，不请求 platform drawable，不提交 command buffer，不提交 GPU work。

`CjguiInternalRendererPacingFailurePolicy` 只表达 future frame drop / defer / no-draw / rollback facts。它不观察真实 platform failure，不注册 callback，不发布 diagnostics，不输出 telemetry，不写 renderer state。

`CjguiInternalRendererNoFrameSchedulerReadiness` 是当前 no-frame-scheduler endpoint。Readiness 只表示该 internal value boundary 可以继续评估，不代表 scheduler permission、timer permission、display-link permission、render-loop permission、backend readiness、renderer-state-write readiness、render permission、command-buffer-commit permission 或 GPU-submission permission。

## Explicit Non-Truth

`CjguiInternalRendererNoFrameSchedulerReadiness` 明确不是：

- scheduler permission。
- timer permission。
- display-link permission。
- render-loop permission。
- backend readiness。
- backend permission。
- backend object permission。
- platform object permission。
- renderer-state-write readiness。
- renderer state write permission。
- render permission。
- command buffer commit permission。
- GPU submission permission。
- drawable acquisition permission。
- callback registration permission。
- platform failure observation permission。
- `CVDisplayLink` implementation。
- `MTKView` draw loop implementation。
- timer implementation。
- platform scheduler implementation。
- command buffer commit implementation。
- frame pacing receipt / record / publication。
- scheduler-readiness wrapper。
- backend-readiness wrapper。
- renderer-state-write readiness wrapper。
- command-buffer-commit wrapper。
- GPU-submission wrapper。
- public API / public C ABI。

当前没有 frame scheduler、timer、display link、run loop、platform scheduler、render loop、backend object、platform object、native handle、raw pointer、command buffer commit、GPU submission、render execution 或 renderer state write。

## Relationship Facts

Frame pacing owner 与 backend object owner / render execution no-op / drawable timing / resize / scale / color / no-draw fallback 的关系只能作为 dehydrated lifecycle facts 表达：

- display refresh relation facts。
- drawable timing relation facts。
- resize / scale / color relation facts。
- frame request admission facts。
- deferred frame facts。
- no-draw fallback facts。
- pacing failure facts。
- rollback facts。
- no-submit / no-render stop-line facts。

这些 facts 不能携带 scheduler, timer, display link, run loop, platform scheduler, backend object, platform object, command buffer, drawable, encoder, pipeline state, GPU object, native handle, raw pointer, callback, observer, telemetry output, diagnostics publication, render loop or renderer state write.

## Reference Evidence

[Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 支撑本 manifest：

- Display refresh / frame pacing 是 platform/backend lifecycle concern。
- Drawable acquisition timing 可等待、失败或 defer，因此 frame request gate 必须能表达 no-draw / defer / failure facts。
- AppKit resize / backing scale / color relation 可作为 dehydrated facts 过界，但不能携带 view / layer / drawable / platform object。
- Backend object owner 已固定 no-backend-object endpoint，但不负责 display timing policy 或 frame request gate。
- Render execution no-op 已固定 no-submit / no-render endpoint，不能被 frame pacing owner 转换成 render permission。

这些 evidence 支撑 frame pacing owner truth，但不批准 `CVDisplayLink` / `MTKView` draw loop / timer / platform scheduler、backend implementation、platform object creation、command buffer commit、GPU submission、render execution 或 renderer state write。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 manifest 生效。

本轮选择 manifest 封账，明确拒绝：

- frame pacing receipt / record / publication。
- scheduler-readiness wrapper。
- backend-readiness wrapper。
- renderer-state-write readiness wrapper。
- command-buffer-commit wrapper。
- GPU-submission wrapper。
- frame scheduler / timer / display link / render loop implementation。
- backend / Metal / AppKit / platform object implementation。
- public surface expansion。

`CjguiInternalRendererNoFrameSchedulerReadiness` 已经是当前 no-frame-scheduler endpoint。继续新增 receipt / record / publication 或 readiness wrapper 会把同一结果换名包装，缺少新的 owner truth、consumer、lifecycle 或 backend evidence。

若未来靠近 renderer state write / backend readiness / real scheduler，必须先做 docs-only preflight，并引用本 manifest、[2026-05-04-p1-renderer-frame-pacing-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-next-boundary-decision.md) 与 reference pack 的具体 evidence。

## Stop-line

继续禁止：

- no runtime code in this manifest round。
- no `.cj` modifications。
- no frame scheduler implementation。
- no timer implementation。
- no display link implementation。
- no run loop implementation。
- no render loop implementation。
- no backend / Metal / AppKit implementation。
- no backend object creation。
- no platform object creation。
- no command buffer commit。
- no GPU submission。
- no render execution。
- no renderer state write。
- no callback registration。
- no platform failure observation。
- no native handle / raw pointer / platform resource token。
- no scheduler-readiness wrapper。
- no backend-readiness wrapper。
- no renderer-state-write readiness wrapper。
- no command-buffer-commit wrapper。
- no GPU-submission wrapper。
- no frame pacing receipt / record / publication。
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

### A. P1 internal Renderer renderer state write preflight decision

推荐为下一阶段 opening。

理由：

- Frame pacing owner manifest 已固定 no-frame-scheduler endpoint。
- Backend object owner、render execution no-op 与 frame pacing owner 都已明确不是 renderer state write permission。
- 下一步可以 docs-only 评估 renderer state write 是否具备 owner / acceptance gate / rollback evidence，但仍不得实现 state write。

### B. P1 internal Renderer backend-readiness revisit

暂缓。

通常等 renderer state write preflight 后再重新评估 backend-readiness，避免 backend readiness 把 no-frame-scheduler endpoint 包成 thin wrapper。

### C. Frame pacing hardening

暂缓。

仅在发现 display timing / request gate / failure policy 表达不足时选择。当前 manifest 未发现该缺口。

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

暂缓。

仅在明确 duplicate / self-wrapping evidence 出现时选择。当前 manifest 选择封账，不做 consolidation。

## Decision

This manifest stabilizes and closes the frame pacing owner endpoint.

Unique next opening:

`P1 internal Renderer renderer state write preflight decision`

下一轮必须 docs-only，评估 renderer state write owner / lifecycle / acceptance gate / rollback evidence；不得实现 renderer state write，不得接 backend / Metal / AppKit，不得实现 frame scheduler / display link / render loop，不得 commit command buffer，不得 GPU submission，不得 render。

## Downstream Renderer State Write Preflight

Renderer state write preflight 已完成：

- [2026-05-04-p1-renderer-state-write-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-preflight-decision.md)

该 preflight 以 `CjguiInternalRendererNoFrameSchedulerReadiness` / `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()` 为唯一 future runtime input，判定下一步可以进入 renderer state write no-write internal value boundary。该 downstream 只允许表达 renderer state write intent / state mutation policy / commit visibility guard / rollback state policy / no-state-write readiness value facts；不批准 renderer state write、global mutable state、module-level `var`、frame completion recording、backend readiness implementation、command buffer commit、GPU submission、backend / Metal / AppKit / platform object、public diagnostics 或 public API。

Renderer state write no-write value boundary 已完成：

- [2026-05-04-p1-internal-renderer-state-write-no-write-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-state-write-no-write-boundary-closure-review.md)

该 closure 只消费本 manifest 固定的 `CjguiInternalRendererNoFrameSchedulerReadiness`，并把 downstream endpoint 固定为 `CjguiInternalRendererNoStateWriteReadiness` / `cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft()`。该 endpoint 不是 renderer state write permission、backend readiness、command-buffer-commit permission、GPU-submission permission、render execution permission、frame completion record 或 public API permission。

Renderer state write no-write next-boundary decision 已完成：

- [2026-05-04-p1-renderer-state-write-no-write-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-next-boundary-decision.md)

该 decision 确认 downstream no-state-write endpoint 已足够，下一步先做 renderer state write no-write manifest stabilization；不得把 `CjguiInternalRendererNoFrameSchedulerReadiness` 或 `CjguiInternalRendererNoStateWriteReadiness` 包成 state-write receipt / record / publication、backend-readiness wrapper、GPU-submission wrapper、frame-completion wrapper、command-buffer-commit wrapper、real renderer state write、render completion tracking、backend / Metal / AppKit implementation、platform object、public diagnostics 或 public API。

Renderer state write no-write manifest stabilization 已完成：

- [2026-05-04-p1-renderer-state-write-no-write-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-manifest.md)
- [2026-05-04-p1-internal-renderer-state-write-no-write-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-state-write-no-write-manifest-stabilization-closure-review.md)

该 manifest 封账 downstream no-state-write endpoint，确认 `StateMutationPolicy` 不写 renderer state / `runtime_state.cj`，`CommitVisibilityGuard` 不提交 command buffer / GPU work / frame completion，`RollbackStatePolicy` 只表达 dehydrated rollback facts。下一步转向 docs-only `P1 internal Renderer backend-readiness final preflight decision`，不批准 backend implementation、platform object、command buffer commit、GPU submission、render execution、renderer state write、public diagnostics 或 public API。

Renderer backend-readiness final preflight 已完成：

- [2026-05-04-p1-renderer-backend-readiness-final-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-final-preflight-decision.md)

该 final preflight 引用本 manifest 的 display timing / frame request gate / pacing failure / no-frame-scheduler evidence 作为 docs evidence，而不是 runtime input。下一步若进入 backend-readiness value boundary，只能消费 `CjguiInternalRendererNoStateWriteReadiness`，只输出 backend readiness intent / platform lifecycle gate / execution admission gate / state visibility gate / no-backend-ready readiness value facts；不批准 frame scheduler、display link、render loop、backend implementation、platform object、command buffer commit、GPU submission、render execution 或 renderer state write。

Renderer backend-readiness branch milestone stabilization 已完成：

- [2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)
- [2026-05-04-p1-internal-renderer-backend-readiness-branch-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-readiness-branch-milestone-stabilization-closure-review.md)

该 milestone 将本 manifest 的 `CjguiInternalRendererNoFrameSchedulerReadiness` 固定为 backend-readiness branch evidence chain 中的 frame pacing owner endpoint。它不改变本 manifest 的 no-frame-scheduler stop-line，不批准 frame scheduler / display link / timer / render loop、backend implementation、platform object、command buffer commit、GPU submission、render execution 或 renderer state write。
