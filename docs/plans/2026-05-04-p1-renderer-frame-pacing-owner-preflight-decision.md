# P1 Renderer frame pacing owner preflight decision

日期：2026-05-04

状态：docs-only preflight decision

## Scope

本轮 docs-only 基于 backend object owner manifest、render execution no-op manifest 与 backend / Metal reference pack，评估是否可以打开 frame pacing owner runway。

本轮不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不实现 frame scheduler / display link / render loop / timer / backend / Metal / AppKit / command buffer commit / GPU submission / renderer state write。

## Read Inputs

- [2026-05-04-p1-renderer-backend-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md)
- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)

## Preflight Decision

允许打开 frame pacing owner runway，但下一步也只能是 internal value boundary，不是真实 scheduler、timer、display link 或 render loop。

选择下一阶段：

`P1 internal Renderer frame pacing owner value boundary bundle implementation`

默认候选 owner：

- `runtime/cjgui/src/runtime_renderer_frame_pacing.cj`

唯一 runtime input：

- `CjguiInternalRendererNoBackendObjectReadiness`
- `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`

Output truth 只能是：

- frame pacing owner intent value facts。
- display timing policy value facts。
- frame request gate value facts。
- pacing failure policy value facts。
- no-frame-scheduler readiness value facts。

Frame pacing owner readiness 明确不等于 frame scheduler permission、display link permission、render loop permission、timer permission、backend readiness、platform object permission、GPU submission permission、command buffer commit permission、render execution permission 或 renderer state write permission。

## Why Evidence Is Sufficient For A Value Boundary

Backend object owner manifest 已固定 `CjguiInternalRendererNoBackendObjectReadiness`，并明确 frame pacing 仍不是 backend object readiness。Render execution no-op manifest 已固定 `CjguiInternalRendererNoRenderExecutionReadiness`，并把 frame pacing relation 限定为 dehydrated policy vocabulary，不授予 submit / render / state write 权限。

Reference pack 已提供足够官方 evidence 来拆出 frame pacing owner value boundary：

- Display refresh evidence：`MTKView` 支持 timed updates、draw notifications 与 explicit drawing；`NSWindow.displayLink(target:selector:)`、`CADisplayLink` 与 `CVDisplayLink` 都表明 display timing 是 platform-level lifecycle concern。
- Drawable acquisition timing evidence：`CAMetalLayer.nextDrawable()` 可等待 drawable availability，也可能失败 / timeout；drawable 应 late-bound and short-lived，因此 frame request gate 必须能表达 no-draw / defer / failure。
- AppKit resize / backing scale evidence：layer-backed view、backing scale、`convertToBacking(_:)` 与 drawable size / color relation 说明 frame pacing 需要接收 dehydrated resize / scale / color facts，而不是持有 `NSView` / layer / `CAMetalLayer`。
- Backend object lifecycle evidence：backend object owner 已有 init / active / teardown / failure / rollback / no-render value facts，但它不负责 display timing policy，也不能把 no-backend-object endpoint 直接包装成 frame scheduler readiness。

因此下一刀可以新增 frame pacing owner intent / display timing policy / frame request gate / pacing failure policy / no-frame-scheduler readiness 语义。该新增语义不是 `CjguiInternalRendererNoBackendObjectReadiness` 的 receipt / record / publication，因为它必须回答 display timing 如何作为 value facts 被限定、frame request gate 如何不触发 render、pacing failure 如何表达 rollback / no-draw、以及当前为什么仍没有 scheduler / display link / timer。

## Reference Concepts That Remain Future-Only

以下名词只能作为 future reference concept、forbidden implementation concept 或 policy vocabulary：

- `CVDisplayLink`
- `CADisplayLink`
- `NSWindow.displayLink(target:selector:)`
- `MTKView` timed update / draw loop
- AppKit run loop
- platform timer
- render loop
- frame scheduler

本 preflight 不批准创建、引用、调用、注册、持有或桥接这些对象 / callback / timer；也不批准把它们放入 core packet、backend object facts、public API、C ABI、native handle 或 raw pointer surface。

## Relationship To Existing Endpoints

### Backend object owner

[Backend object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md) 固定 `CjguiInternalRendererNoBackendObjectReadiness`。Frame pacing owner value boundary 只能把它作为唯一 runtime input，读取 no-backend-object / platform confinement / backend lifecycle acceptance facts；不能把它包装成 frame pacing receipt / scheduler readiness wrapper。

### Render execution no-op

[Render execution no-op manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md) 固定 `CjguiInternalRendererNoRenderExecutionReadiness`。Frame pacing owner 与 render execution 的关系只能作为 no-submit / no-render / completion-failure / no-draw fallback vocabulary；不能执行 render、commit command buffer、submit GPU work、present drawable、调用 encoder 或写 renderer state。

### Backend / Metal reference pack

[Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 只提供 display refresh、drawable acquisition timing、AppKit resize / scale / color 与 resource ownership evidence。它不是 runtime input，不批准 frame scheduler、display link、timer、backend object、platform object 或 render loop implementation。

## Candidate Comparison

### A. P1 internal Renderer frame pacing owner value boundary bundle implementation

选择。

当前 evidence 已足以证明 frame pacing owner 有新增 display timing / frame request gate / pacing failure / no-frame-scheduler 语义。下一轮仍只能新建 internal-only value owner，不实现 scheduler / timer / display link / render loop，不创建 platform object，不提交 command buffer，不 GPU submission，不执行 render，不写 renderer state。

### B. P1 internal Renderer frame pacing reference hardening docs bundle implementation

暂缓 / 备选。

Reference pack 已覆盖 display refresh、drawable acquisition timing、AppKit resize / backing scale 与 backend object lifecycle relation。若下一轮发现 display timing vocabulary 不足，再做 docs hardening；当前不需要先补参考包。

### C. P1 internal Renderer renderer state write preflight decision

暂缓。

Renderer state write 仍是 hard stop-line。通常应等 frame pacing owner truth 和 backend-readiness revisit 再评估，避免把 frame request / completion / no-draw facts 误解成 state write permission。

### D. P1 internal Renderer backend-readiness value boundary revisit

暂缓。

Backend object owner 已封账，但 frame pacing owner truth 仍需先形成 value facts。否则 backend-readiness value boundary 容易退化成 no-backend-object tail wrapper。

### E. Display link / render loop / frame scheduler implementation

拒绝。

### F. Backend / Metal / platform / native handle implementation

拒绝。

### G. GPU submission / command buffer commit / render execution

拒绝。

### H. Dirty-region / UI system

暂缓。

### I. Public surface expansion

拒绝。

### J. Receipt / record / publication

拒绝。

Frame pacing owner value boundary 不能成为 `CjguiInternalRendererNoBackendObjectReadiness` 的 frame pacing receipt / record / publication，也不能成为 backend-readiness wrapper、renderer-state-write wrapper 或 scheduler-readiness wrapper。

### K. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。当前风险是下游 thin wrapper，而不是 consolidation need。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮生效。

本轮允许 A 的前提是：frame pacing owner value boundary 必须新增 display timing / frame request gate / pacing failure / no-frame-scheduler readiness 语义。

明确拒绝：

- 把 `CjguiInternalRendererNoBackendObjectReadiness` 直接包成 frame pacing receipt / record / publication。
- backend-readiness wrapper。
- renderer-state-write wrapper。
- scheduler-readiness wrapper。
- command-buffer-commit wrapper。
- GPU-submission wrapper。
- frame scheduler / display link / render loop / timer implementation。

若下一轮选择 A，仍必须禁止 scheduler / timer / display link / render loop implementation、backend object creation、platform object creation、native handle、raw pointer、command buffer commit、GPU submission、render execution 和 renderer state write。

## Decision

本轮批准打开 frame pacing owner runway，但只批准下一轮 internal value boundary。

唯一 next opening：

`P1 internal Renderer frame pacing owner value boundary bundle implementation`

下一轮若执行，默认 owner 为 `runtime/cjgui/src/runtime_renderer_frame_pacing.cj` 或等价 internal-only owner；只消费 `CjguiInternalRendererNoBackendObjectReadiness`；只输出 frame pacing owner intent / display timing policy / frame request gate / pacing failure policy / no-frame-scheduler readiness value facts。

下一轮仍不得实现 frame scheduler、display link、render loop、timer、backend、Metal / AppKit、platform object、native handle、raw pointer、command buffer commit、GPU submission、render execution、draw call、renderer state write 或 public surface expansion。

## Downstream Value Boundary Closure

Renderer frame pacing owner value boundary 已完成：

- [2026-05-04-p1-internal-renderer-frame-pacing-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-frame-pacing-owner-value-boundary-closure-review.md)

该 closure 新增 `runtime/cjgui/src/runtime_renderer_frame_pacing.cj`，固定 `CjguiInternalRendererNoFrameSchedulerReadiness` / `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()` 作为当前 no-frame-scheduler endpoint。下一步转入 docs-only `P1 internal Renderer frame pacing owner closure / next frame pacing decision`，不批准 frame scheduler / timer / display link / render loop、backend / Metal / AppKit、command buffer commit、GPU submission、render execution 或 renderer state write。

## Downstream Next-boundary Decision

Renderer frame pacing owner next-boundary decision 已完成：

- [2026-05-04-p1-renderer-frame-pacing-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoFrameSchedulerReadiness` / `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()` 已足够作为当前 no-frame-scheduler endpoint。下一步选择 docs-only `P1 internal Renderer frame pacing owner manifest stabilization bundle implementation`，不批准 frame pacing receipt / record / publication、backend-readiness wrapper、renderer-state-write readiness wrapper、command-buffer-commit wrapper、GPU-submission wrapper 或 real scheduler / display link / render loop。

## Downstream Manifest Stabilization

Renderer frame pacing owner manifest stabilization 已完成：

- [2026-05-04-p1-renderer-frame-pacing-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-frame-pacing-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-frame-pacing-owner-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_frame_pacing.cj` owner / truth / canonical endpoint / stop-line，并封账 `CjguiInternalRendererNoFrameSchedulerReadiness` / `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()`。下一步转入 docs-only `P1 internal Renderer renderer state write preflight decision`，不批准 renderer state write implementation、backend / Metal / AppKit implementation、frame scheduler / display link / render loop、command buffer commit、GPU submission 或 render execution。
