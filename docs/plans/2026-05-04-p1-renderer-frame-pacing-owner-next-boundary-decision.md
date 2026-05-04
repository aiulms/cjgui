# P1 Renderer frame pacing owner next boundary decision

日期：2026-05-04

状态：docs-only next-boundary decision

## Scope

本轮 docs-only 评估 `CjguiInternalRendererNoFrameSchedulerReadiness` 是否已经足够作为当前 no-frame-scheduler endpoint，并决定下一步是否先做 manifest stabilization，还是进入 renderer state write / backend-readiness 相关 preflight。

本轮不修改 `.cj`，不运行 `cjpm build` / smoke，不实现 frame scheduler / timer / display link / render loop / backend / Metal / AppKit / command buffer commit / GPU submission / render execution / renderer state write。

## Read Inputs

- [runtime_renderer_frame_pacing.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_frame_pacing.cj)
- [2026-05-04-p1-internal-renderer-frame-pacing-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-frame-pacing-owner-value-boundary-closure-review.md)
- [2026-05-04-p1-renderer-frame-pacing-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-preflight-decision.md)
- [2026-05-04-p1-renderer-backend-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md)
- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)

## Endpoint Assessment

`CjguiInternalRendererNoFrameSchedulerReadiness` / `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()` 已足够作为当前 no-frame-scheduler endpoint。

理由：

- Owner file 已存在：`runtime/cjgui/src/runtime_renderer_frame_pacing.cj`。
- 唯一 runtime input 已固定：`CjguiInternalRendererNoBackendObjectReadiness`。
- Current truth 已覆盖 frame pacing owner intent / display timing policy / frame request gate / pacing failure policy / no-frame-scheduler readiness value facts。
- Open path 从 no-backend-object readiness 形成 display timing / frame request / pacing failure / no-frame-scheduler facts。
- Defer path 保持 defer，不伪造 scheduler readiness。
- Blocked / inconsistent path fail-closed blocked。
- Endpoint 明确确认没有 frame scheduler、frame clock、frame callback、continuous frame driver、backend object、platform object、command buffer commit、GPU submission、render side effect 或 renderer state mutation。

该 endpoint 不是 scheduler permission、timer permission、display link permission、render loop permission、backend readiness、renderer state write、render permission、command-buffer-commit permission、GPU-submission permission、receipt、record 或 publication。

## Decision

选择下一阶段：

`P1 internal Renderer frame pacing owner manifest stabilization bundle implementation`

推荐原因：

- Value boundary 已落地，当前最需要固定 owner / truth / canonical endpoint / stop-line。
- 直接进入 renderer state write preflight 仍太早，容易把 frame request / no-draw / pacing failure facts 误读成 renderer state write permission。
- 直接进入 backend-readiness revisit 仍有 thin-wrapper 风险，应该先把 no-frame-scheduler endpoint 封账。
- 任何 real scheduler / display link / render loop 都仍未获得许可。

## Candidate Comparison

### A. P1 internal Renderer frame pacing owner manifest stabilization bundle implementation

推荐。

下一轮必须 docs-only，固定 `runtime_renderer_frame_pacing.cj` 的 owner / truth / canonical endpoint / stop-line，并封账 `CjguiInternalRendererNoFrameSchedulerReadiness`。Manifest 应明确 frame pacing owner intent / display timing policy / frame request gate / pacing failure policy / no-frame-scheduler readiness 的 current truth，并拒绝 scheduler / timer / display link / render loop implementation。

### B. P1 internal Renderer renderer state write preflight decision

暂缓。

Renderer state write 仍是 hard stop-line。需要等 frame pacing owner manifest 封账后，再 docs-only 判断是否存在 state write owner / acceptance gate / rollback evidence。

### C. P1 internal Renderer backend-readiness revisit preflight decision

暂缓。

Backend-readiness revisit 需要已封账的 backend object owner、render execution no-op 与 frame pacing owner manifest 共同作为 evidence。当前先封 frame pacing owner endpoint，避免 backend-readiness wrapper 回潮。

### D. Frame pacing owner hardening

暂缓。

当前未发现 display timing / frame request gate / pacing failure / no-frame-scheduler 表达不足。若 manifest round 发现语义空洞，再选择 hardening。

### E. Frame pacing receipt / record / publication

拒绝。

这会把 `CjguiInternalRendererNoFrameSchedulerReadiness` 继续包装成 tail wrapper，缺少新增 owner truth。

### F. Backend-readiness wrapper

拒绝。

No-frame-scheduler endpoint 不是 backend readiness，不能被直接包装成 backend-readiness value。

### G. Renderer-state-write readiness wrapper

拒绝。

Frame request / no-draw / pacing failure facts 不是 renderer state write permission。

### H. Command-buffer-commit wrapper / GPU-submission wrapper

拒绝。

Frame pacing owner 明确不 commit command buffer、不提交 GPU work。

### I. Real scheduler / display link / render loop implementation

拒绝。

`CVDisplayLink` / `MTKView` draw loop / run loop / timer 仍只可作为 future reference concepts，不批准实现、桥接、调用、注册、持有或注入 core packet。

### J. Backend / Metal / AppKit / platform object implementation

拒绝。

### K. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### L. Public surface expansion

拒绝。

### M. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前优先事项是 manifest stabilization，不是合并 owner。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮继续生效。

`CjguiInternalRendererNoFrameSchedulerReadiness` 不再继续包装成 tail wrapper。当前 endpoint 只代表：

- frame pacing owner intent facts。
- display timing policy facts。
- frame request gate facts。
- pacing failure policy facts。
- no-frame-scheduler readiness facts。

它不是：

- scheduler permission。
- timer permission。
- display link permission。
- render loop permission。
- backend readiness。
- renderer state write。
- render permission。
- command buffer commit permission。
- GPU submission permission。
- frame pacing receipt / record / publication。
- backend-readiness wrapper。
- renderer-state-write readiness wrapper。

若未来靠近 renderer state write / backend readiness / real scheduler / display link / render loop，必须先做 docs-only preflight，不能直接实现。

## Next Opening

唯一 next opening：

`P1 internal Renderer frame pacing owner manifest stabilization bundle implementation`

下一轮必须 docs-only，不修改 `.cj`，不运行 build / smoke，不实现 frame scheduler / timer / display link / render loop、backend / Metal / AppKit、command buffer commit、GPU submission、render execution 或 renderer state write。

## Downstream Manifest Stabilization

Renderer frame pacing owner manifest stabilization 已完成：

- [2026-05-04-p1-renderer-frame-pacing-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-frame-pacing-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-frame-pacing-owner-manifest-stabilization-closure-review.md)

该 manifest 封账 current no-frame-scheduler endpoint，并把 next opening 转向 docs-only `P1 internal Renderer renderer state write preflight decision`。该 downstream 不批准 renderer state write implementation、backend-readiness wrapper、command-buffer-commit wrapper、GPU-submission wrapper、frame scheduler / display link / render loop 或 backend / Metal / AppKit implementation。
