# P1 Renderer real backend first-slice owner preflight decision

日期：2026-05-04

状态：docs-only preflight decision

## Scope

本轮决定真实 backend 的第一刀应该切在哪里。

本轮不修改 `.cj`，不新建 runtime owner，不运行 build / smoke，不触碰 runtime state、package manifest、smoke、harness、native bridge 或 entry，不实现 backend / Metal / AppKit / platform object / command buffer commit / GPU submission / renderer state write，也不把 `labs/macos_bridge_smoke` 代码提升为 runtime truth。

## Inputs Read

- [2026-05-04-p1-renderer-real-backend-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-real-backend-implementation-preflight-decision.md)
- [2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)
- [2026-05-04-p1-renderer-backend-readiness-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
- [2026-04-25-p0-macos-bridge-smoke-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

## Decision

真实 backend 第一刀选择：

`P1 internal Renderer backend platform object owner preflight decision`

这是下一轮 docs-only preflight，不是 internal value boundary，不是 runtime owner implementation，也不是 Metal / AppKit backend implementation。

理由：

- 真实 backend 的硬前置不是单个 `MTLDevice` / `CAMetalLayer`，而是 platform object / native resource 的 create / retain / release / teardown / failure / confinement owner。
- Backend / Metal reference pack、platform resource owner manifest、command queue / drawable / command buffer manifests 都已证明 future resources 必须 backend-local，但仍没有真实 platform object ownership truth。
- AppKit / Metal bridge boundary preflight 与 smoke closure 已证明 bridge feasibility、teardown ordering、main-thread owner、capability / error / auto-close evidence；这些证据最自然承接到 platform object owner preflight，而不是直接承接到 device-layer implementation。
- no-draw backend shell 是可行的后续候选，但若在 platform object owner 之前选择它，容易变成另一个 backend shell wrapper，不能回答真实 native resource confinement 和 teardown 的硬问题。

## First Slice Boundary

第一刀必须仍是 docs-only decision / preflight。

本轮不批准 internal value boundary，因为下一步还需要先回答：

- platform object owner 是否是 future backend owner、platform adapter owner，还是单独 owner。
- create / retain / release / teardown 的 owner 语义如何和 backend-readiness value facts 对齐。
- platform object failure / degraded / no-draw path 是否先进入 owner preflight，还是等 no-draw backend shell preflight。
- bridge smoke 的 lifecycle evidence 哪些可以进入 runtime strategy，哪些必须留在 lab-only evidence。
- public C ABI、diagnostics、event bus、telemetry 是否继续维持 stop-line。

## Candidate Comparison

### A. P1 internal Renderer backend platform object owner preflight decision

选择。

这是当前最小、风险最低、最能承接现有 evidence 的第一刀。它只评估真实 platform object / native resource owner 是否应作为第一刀，重点是 create / retain / release / teardown / failure / confinement。

它不创建 platform object，不创建 backend object，不接 `MTLDevice`、`CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder 或 pipeline state。它只是把真实 implementation 前最硬的 ownership question 拆出来。

### B. P1 internal Renderer Metal device-layer owner preflight decision

暂缓。

Device / layer ownership 是真实 backend 的核心问题，但它已经比 platform object owner 更靠近具体 Metal / AppKit 对象。当前还未决定 platform object owner 是否统一持有 device / layer / queue / drawable lifecycle，因此不应先选 B。

### C. P1 internal Renderer no-draw backend shell preflight decision

暂缓。

No-draw backend shell 可以承接 backend lifecycle、no-draw path、teardown path 与 smoke strategy，但在 platform object ownership 未冻结前，shell 很容易绕过 native resource confinement 问题，退化成 no-backend-ready tail wrapper。它应在 backend platform object owner preflight 后重新评估。

### D. P1 internal Renderer command queue / drawable real lifecycle preflight decision

暂缓。

Command queue / drawable real lifecycle 必须等 platform object owner 和 device / layer owner 决策更清楚后再开。当前所有 command queue / drawable endpoints 仍是 no-command-queue / no-drawable value facts。

### E. P1 internal Renderer command buffer commit / GPU submission preflight decision

拒绝当前选择，后续暂缓。

该方向过早。当前没有真实 platform object owner、device / layer owner、command queue owner、drawable owner，也没有 command buffer commit gate implementation permission。

### F. P1 internal Renderer renderer state write real preflight decision

暂缓。

真实 state write 必须晚于 no-draw / backend lifecycle、submission / completion policy 和 renderer state visibility relation。当前仍保持 no-state-write。

### G. P1 internal Renderer dirty-region / invalidation preflight decision

暂缓。

Dirty-region / invalidation 属于 render scheduling / UI system 方向。当前 first slice 仍是 backend ownership，不打开 UI scheduling。

### H. P1 semantic physical operability / occlusion gate preflight

暂缓。

已登记为 future radar，但不抢当前 backend first slice。

### I. P1 foreign surface / browser-kernel containment preflight

暂缓。

已登记为 future radar，但不进入当前 backend first slice。

### J. Direct Metal / AppKit backend implementation

拒绝。

本轮不批准直接实现。

### K. Direct command buffer commit / GPU submission / render execution

拒绝。

当前 no-submit / no-render-execution stop-line 未变。

### L. Public API / public C ABI expansion

拒绝。

Public allowlist 未变；bridge smoke 的实验期 C ABI 不能升级为 runtime public surface。

### M. Receipt / record / publication / backend-ready permission wrapper

拒绝。

继续包装 `CjguiInternalRendererNoBackendReadyReadiness` 不会新增 owner / lifecycle / teardown / failure / smoke strategy 语义。

## Evidence Mapping

可承接到下一轮 A 的 evidence：

- Backend-readiness branch milestone：证明 no-backend-ready value facts 已封账，且不能继续 wrapper。
- Backend-readiness manifest：提供 platform lifecycle gate / execution admission gate / state visibility gate 的 no-backend-ready facts。
- Backend / Metal reference pack：证明 device、layer、queue、drawable、command buffer、render pass、encoder、pipeline state 必须 future backend-local。
- Platform resource owner manifest：证明 platform resource confinement 已经是 value policy，但还没有真实 owner。
- Command queue / drawable / command buffer manifests：证明 lifecycle facts 已拆开，但仍无真实 platform object。
- AppKit / Metal bridge preflight：提供 handle lifecycle、main-thread owner、error categories、narrow bridge shape、capability query、verification strategy 与 teardown ordering questions。
- Bridge cleanup closure：证明 lab bridge 内部持有 native objects 和 auto-close destroy path 可行，但仍不是 runtime truth。
- P0 smoke closure：证明 bridge reachability 和 manual visual smoke feasibility，但不证明 renderer command system。
- Risk ledger：提醒 GPU resource lifecycle、FFI ownership、main-thread exclusivity、runloop overfitting、pixel hash illusion 与 foreign surface containment 是 first-slice 风险。

仍不能升格为 truth 的 evidence：

- `labs/macos_bridge_smoke` 的 Objective-C ownership model。
- `cjgui_app_run()` / last-error C ABI。
- 单窗口 / 单实例 bridge context。
- Manual visual result。
- screenshot / pixel hash baseline。
- Any native object pointer, handle, callback, diagnostics output, telemetry, event bus, or public API shape.

## Same-shape Boundary Brake

本轮刹住 `CjguiInternalRendererNoBackendReadyReadiness` 与 backend-readiness milestone：

- 不把它们包成 first-slice receipt / record / publication。
- 不把它们包成 real-backend readiness wrapper。
- 不把它们包成 backend-ready permission wrapper。
- 不把它们包成 GPU-submission wrapper。
- 不把它们包成 render-permission wrapper。
- 不把它们包成 public diagnostics / public API wrapper。

下一步必须新增真实 owner / lifecycle / teardown / failure / smoke strategy 语义，而不是继续 no-backend-ready tail wrapper。

## Stop-line

本轮与下一轮 opening 前继续禁止：

- no `.cj` modifications。
- no runtime owner。
- no `MTLDevice` creation。
- no `CAMetalLayer` creation。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation。
- no render pass / encoder / pipeline state creation。
- no command buffer commit。
- no drawable present。
- no GPU submission。
- no render execution。
- no renderer state write。
- no bridge / smoke / harness / native entry modification。
- no public API。
- no public C ABI expansion。
- no browser / foreign surface。
- no diagnostics output。
- no telemetry。
- no observer。
- no event bus。

## Downstream

Unique next opening:

`P1 internal Renderer backend platform object owner preflight decision`

下一轮仍必须 docs-only。它只能评估真实 platform object / native resource owner 的 create / retain / release / teardown / failure / confinement strategy，不得实现 backend、Metal、AppKit、platform object、command buffer commit、GPU submission、render execution、renderer state write、public API、diagnostics output、telemetry、observer 或 event bus。

## Downstream Backend Platform Object Owner Preflight

Renderer backend platform object owner preflight 已完成：

- [2026-05-04-p1-renderer-backend-platform-object-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-preflight-decision.md)

该 preflight 允许打开 backend platform object owner runway，并选择下一轮 `P1 internal Renderer backend platform object owner value boundary bundle implementation`。下一轮仍只是 internal value facts，不是真实 platform object creation。

默认候选 owner 是 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object.cj`，runtime input 只建议消费 `CjguiInternalRendererNoBackendReadyReadiness`。Output truth 仅限 backend platform object owner intent / native resource ownership policy / lifecycle teardown policy / confinement failure policy / no-platform-object-readiness value facts。

唯一 next opening：

`P1 internal Renderer backend platform object owner value boundary bundle implementation`
