# P1 Renderer command queue lifecycle next-boundary decision

日期：2026-05-03

状态：docs-only next-boundary decision

## Purpose

本 decision 评估 `CjguiInternalRendererNoCommandQueueReadiness` 是否已经足够作为当前 no-command-queue lifecycle endpoint，并决定下一步是否先做 manifest stabilization。

本轮不修改 `.cj`，不创建 command queue，不实现 backend / Metal / AppKit / CAMetalLayer / command buffer / render execution / renderer state write，不运行 build / smoke。

Upstream references：

- [2026-05-03-p1-internal-renderer-command-queue-lifecycle-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-queue-lifecycle-value-boundary-closure-review.md)
- [2026-05-03-p1-renderer-command-queue-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-preflight-decision.md)
- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)

## Current Endpoint

Current command queue lifecycle owner：

- `runtime/cjgui/src/runtime_renderer_command_queue.cj`

Current canonical endpoint：

- `CjguiInternalRendererNoCommandQueueReadiness`
- `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`

Current upstream endpoint：

- `CjguiInternalRendererNoPlatformResourceReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`

Current truth：

- command queue lifecycle intent value facts。
- lifecycle ownership policy value facts。
- creation guard value facts。
- lifetime / shutdown / rollback policy value facts。
- no-command-queue readiness value facts。

`CjguiInternalRendererNoCommandQueueReadiness` 已经足够作为当前 no-command-queue lifecycle endpoint。它不是 command queue creation permission，不是 backend readiness，不是 platform object readiness，不是 command buffer permission，不是 render permission，也不是 renderer state write。

## Endpoint Sufficiency

Endpoint sufficiency 判断：

- Open path 已能把 no-platform-resource readiness 投影为 command queue lifecycle intent / ownership / creation guard / lifetime facts。
- Defer-only path 已保持 upstream defer，不伪造 queue lifecycle readiness。
- Blocked / inconsistent path 已 fail-closed，不把 no-platform-resource readiness 升级为 backend / command buffer / render permission。
- `CjguiInternalRendererCommandQueueLifecycleOwnershipPolicy` 避免复用已属于 platform resource owner 的 `CjguiInternalRendererCommandQueueOwnershipPolicy`，没有 owner-truth 冲突。
- 当前没有发现 lifecycle ownership / creation guard / lifetime policy 表达不足。

因此下一步应先做 manifest stabilization，固定 owner / truth / canonical endpoint / stop-line，而不是立即进入 drawable acquisition 或 command buffer lifecycle。

## Candidate Comparison

### A. P1 internal Renderer command queue lifecycle manifest stabilization bundle implementation

推荐。

理由：

- `CjguiInternalRendererNoCommandQueueReadiness` 已足够作为当前 endpoint。
- 需要先固定 `runtime_renderer_command_queue.cj` owner / truth / canonical endpoint / stop-line。
- Manifest 可以封住 command queue lifecycle tail，避免继续生成 command queue receipt / record / publication 或 backend-readiness wrapper。

### B. Drawable acquisition lifecycle preflight

暂缓。

Drawable acquisition 靠近 `CAMetalLayer` / drawable pool / late-bound drawable timing。应等 command queue lifecycle manifest 后再评估，且仍只能 docs-only preflight。

### C. Command buffer lifecycle preflight

暂缓。

Command buffer lifecycle 必须等 command queue owner truth 和 drawable owner truth 都封账后再拆；当前不批准 command buffer readiness wrapper。

### D. Command queue lifecycle hardening

暂缓。

仅在发现 lifecycle ownership / creation guard / lifetime policy 表达不足时选择。当前 closure 未发现这类缺口。

### E. Command queue receipt / record / publication

拒绝。

Thin wrapper 风险高，会把 `CjguiInternalRendererNoCommandQueueReadiness` 换名包装为同构尾巴。

### F. Backend-readiness wrapper

拒绝。

当前 backend-readiness 证据仍不足，且容易变成 command queue endpoint 的薄包装。

### G. Command queue / Metal implementation

拒绝。

### H. Command buffer / render execution / renderer state write

拒绝。

### I. Metal / AppKit / platform resource / native handle implementation

拒绝。

### J. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

### K. Public surface expansion

拒绝。

Public allowlist remains only：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

### L. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前没有这类 evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮继续生效：

- `CjguiInternalRendererNoCommandQueueReadiness` 已经是当前 no-command-queue endpoint。
- 不批准 command queue receipt / record / publication。
- 不批准 backend-readiness wrapper。
- 不批准 command buffer readiness wrapper。
- 不把 drawable acquisition 或 command buffer lifecycle 混入 command queue lifecycle closure。

若未来靠近 drawable acquisition / command buffer / platform lifecycle，必须先 docs-only preflight，引用 reference pack 中的具体 evidence，并继续禁止直接实现平台对象、command queue、command buffer、render pass、encoder、render execution 或 renderer state write。

## Stop-line

继续禁止：

- no runtime code in this decision round。
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
- no receipt / record / publication wrapper。
- no backend-readiness wrapper。
- no command buffer readiness wrapper。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public surface expansion。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Decision

`CjguiInternalRendererNoCommandQueueReadiness` 已经足够作为当前 no-command-queue lifecycle endpoint。

下一步选择：

`P1 internal Renderer command queue lifecycle manifest stabilization bundle implementation`

Manifest stabilization 应固定：

- owner file：`runtime/cjgui/src/runtime_renderer_command_queue.cj`
- canonical endpoint：`CjguiInternalRendererNoCommandQueueReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`
- current truth：command queue lifecycle intent / lifecycle ownership policy / creation guard / lifetime policy / no-command-queue readiness value facts
- stop-line：不是真实 command queue、backend readiness、platform object readiness、drawable acquisition permission、command buffer permission、render permission 或 renderer state write。

## Next Opening

`P1 internal Renderer command queue lifecycle manifest stabilization bundle implementation`

## Downstream Manifest Stabilization

Renderer command queue lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-command-queue-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-queue-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_command_queue.cj` owner / truth / canonical endpoint / stop-line，并选择 `P1 internal Renderer drawable acquisition lifecycle preflight decision` 作为下一阶段 opening。
