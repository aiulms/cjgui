# P1 Renderer backend-readiness final preflight decision

日期：2026-05-04

状态：final preflight decision

## Scope

本轮是 docs-only final preflight。它不修改 `.cj`，不新建 runtime owner，不运行 build / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮只判断 backend-readiness value boundary 是否具备足够 owner / lifecycle coverage / acceptance gate evidence；不批准 backend / Metal / AppKit implementation。

## Inputs Read

- [2026-05-04-p1-renderer-state-write-no-write-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-manifest.md)
- [2026-05-04-p1-renderer-frame-pacing-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-manifest.md)
- [2026-05-04-p1-renderer-backend-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md)
- [2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [2026-05-04-p1-renderer-backend-readiness-revisit-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-revisit-preflight-decision.md)
- [2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md)
- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
- [2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)

## Decision

允许打开 `P1 internal Renderer backend-readiness value boundary bundle implementation`，但下一步仍只能是 internal value boundary，不是真实 backend / Metal / AppKit implementation。

默认候选 owner：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_readiness.cj`

唯一 runtime input 建议：

- `CjguiInternalRendererNoStateWriteReadiness`
- `cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft()`

Docs evidence 可以引用 packet / platform / command queue / drawable / command buffer / render pass / encoder / draw call / pipeline state / render execution no-op / backend object owner / frame pacing owner manifests 与 backend / Metal reference pack，但不得作为多 runtime input，也不得携带 platform object。

允许的 output truth 仅限：

- backend readiness intent value facts。
- platform lifecycle gate value facts。
- execution admission gate value facts。
- state visibility gate value facts。
- no-backend-ready readiness value facts。

## Evidence Sufficient For Value Boundary

当前 evidence 已足以支撑 backend-readiness value boundary，因为 no-op render pipeline chain 已完成从 packet truth 到 no-state-write 的关键 stop-line：

- Packet owner truth 已封账到 `CjguiInternalRendererPacketOrderingHardeningResult`，只表达 backend-agnostic ordering / material grouping / no-sort-no-merge facts。
- Platform resource owner 已封账到 `CjguiInternalRendererNoPlatformResourceReadiness`，明确 future device / layer / command queue / drawable / command buffer / render pass / encoder 只能作为 policy targets，不进入 core packet。
- Command queue lifecycle 已封账到 `CjguiInternalRendererNoCommandQueueReadiness`，只表达 ownership / creation guard / lifetime / rollback facts，不创建 queue。
- Drawable acquisition lifecycle 已封账到 `CjguiInternalRendererNoDrawableReadiness`，只表达 availability / acquisition timing / presentation ownership / no-draw fallback facts，不获取 drawable。
- Command buffer lifecycle 已封账到 `CjguiInternalRendererNoCommandBufferReadiness`，只表达 creation / commit timing / single-use / failure facts，不创建或提交 command buffer。
- Render pass lifecycle 已封账到 `CjguiInternalRendererNoRenderPassReadiness`，只表达 attachment / load-store / clear-color facts，不创建 descriptor、attachment 或 encoder。
- Encoder lifecycle 已封账到 `CjguiInternalRendererNoEncoderReadiness`，只表达 encoding scope / pipeline binding guard / end-encoding facts，不 begin / end encoding。
- Draw call lifecycle 已封账到 `CjguiInternalRendererNoDrawCallReadiness`，只表达 draw command shape / geometry source / sequencing facts，不发 draw call。
- Pipeline state lifecycle 已封账到 `CjguiInternalRendererNoPipelineStateReadiness`，只表达 shader role / descriptor policy / compatibility facts，不加载 shader、创建 descriptor、编译或缓存 pipeline。
- Render execution no-op 已封账到 `CjguiInternalRendererNoRenderExecutionReadiness`，只表达 execution ordering / no-submit / completion observation facts，不执行 render、不提交 GPU work。
- Backend object owner 已封账到 `CjguiInternalRendererNoBackendObjectReadiness`，只表达 backend object owner intent / lifecycle ownership / acceptance gate / platform confinement facts，不创建 backend object。
- Frame pacing owner 已封账到 `CjguiInternalRendererNoFrameSchedulerReadiness`，只表达 display timing / frame request gate / pacing failure facts，不创建 scheduler / timer / display link / render loop。
- Renderer state write no-write 已封账到 `CjguiInternalRendererNoStateWriteReadiness`，只表达 state mutation policy / commit visibility / rollback state / no-state-write facts，不写 renderer state。
- Backend / Metal reference pack 提供官方 lifecycle evidence：command buffer / render encoder / render pass lifecycle、`CAMetalLayer` drawable lifecycle、AppKit layer-backed view / resize lifecycle、frame pacing / display refresh、Retina scale / color space 与 resource ownership confinement。

这些 evidence 共同证明下一步可以新建 backend-readiness value facts 的 final gate。该 gate 必须聚合已封账的 lifecycle coverage 与 acceptance policy，但不能反向授权 backend implementation。

## Remaining Non-permissions

即使允许 backend-readiness value boundary，当前仍明确不允许：

- no backend object creation。
- no platform object creation。
- no `MTLDevice` / `CAMetalLayer` creation or ownership。
- no command queue / drawable / command buffer / render pass / encoder / pipeline state creation。
- no command buffer commit。
- no GPU submission。
- no render execution。
- no renderer state write。
- no frame completion recording。
- no public diagnostics。
- no public API / public C ABI expansion。

`CjguiInternalRendererNoBackendReadyReadiness` 或等价 future endpoint 若存在，也只能表示 internal no-backend-ready value facts；它不是 backend-ready permission、render permission、GPU submission permission、platform resource permission 或 renderer state write permission。

## Candidate Comparison

### A. P1 internal Renderer backend-readiness value boundary bundle implementation

推荐为唯一 next opening。

理由：

- Final evidence 已覆盖 platform resource、command queue、drawable、command buffer、render pass、encoder、draw call、pipeline state、render execution no-op、backend object owner、frame pacing owner 与 renderer state write no-write。
- 新 owner 可以只消费 `CjguiInternalRendererNoStateWriteReadiness`，并把 docs evidence 收束成 backend readiness intent / platform lifecycle gate / execution admission gate / state visibility gate / no-backend-ready readiness value facts。
- 下一轮仍必须保持 no-backend / no-platform-object / no-render / no-state-write。

### B. Backend-readiness final evidence hardening docs bundle

暂缓。

当前 evidence 文档已足以支撑 internal value boundary。若下一轮实现前发现 gate wording 或 lifecycle coverage 不清，再单独 harden。

### C. Real backend implementation preflight

暂缓，不应直接选择。

Backend-readiness value boundary 尚未落地前，不应进入 real backend implementation preflight。

### D. Renderer state write / frame pacing hardening

暂缓。

State write no-write 与 frame pacing owner manifest 已封账；当前未发现阻塞 backend-readiness value boundary 的表达缺口。

### E. Backend / Metal / AppKit / platform object implementation

拒绝。

### F. Command buffer commit / GPU submission / render execution

拒绝。

### G. Renderer state write implementation

拒绝。

### H. Backend-readiness receipt / record / publication

拒绝。

该方向会把 no-state-write endpoint 做成 thin wrapper，缺少新增 gate semantics。

### I. Dirty-region / UI integration

暂缓。

### J. Public surface expansion

拒绝。

### K. Consolidation

暂缓。

仅在明确 duplicate / low-value helper / self-wrapping evidence 出现时选择。当前需要的是 backend-readiness final value gate，而不是 consolidation。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 preflight 生效。

不得把 `CjguiInternalRendererNoStateWriteReadiness` 直接包成：

- backend-readiness receipt / record / publication。
- GPU-submission wrapper。
- backend-ready permission wrapper。
- render-permission wrapper。
- public diagnostics wrapper。

若选择下一步 A，必须证明新增语义是：

- platform lifecycle gate。
- execution admission gate。
- state visibility gate。
- no-backend-ready readiness value facts。

而不是 no-state-write tail wrapper。

## Decision Summary

Backend-readiness final preflight 结论：允许打开 backend-readiness value boundary runway。

唯一 next opening：

`P1 internal Renderer backend-readiness value boundary bundle implementation`

下一轮仍不得实现 backend、Metal、AppKit、platform object、command buffer commit、GPU submission、render execution、renderer state write、public diagnostics 或 public API。

## Downstream Backend-readiness Value Boundary Closure

Renderer backend-readiness value boundary 已完成：

- [2026-05-04-p1-internal-renderer-backend-readiness-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-readiness-value-boundary-closure-review.md)

该 closure 新增 `runtime/cjgui/src/runtime_renderer_backend_readiness.cj`，只消费 `CjguiInternalRendererNoStateWriteReadiness`，canonical endpoint 是 `CjguiInternalRendererNoBackendReadyReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`。它证明 backend-readiness boundary 新增 platform lifecycle gate / execution admission gate / state visibility gate / no-backend-ready 语义，不是 no-state-write receipt / record / publication、GPU-submission wrapper、backend-ready permission wrapper 或 render-permission wrapper。下一步必须先做 docs-only `P1 internal Renderer backend-readiness closure / next backend readiness decision`。

## Downstream Backend-readiness Next-boundary Decision

Renderer backend-readiness next-boundary decision 已完成：

- [2026-05-04-p1-renderer-backend-readiness-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoBackendReadyReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()` 已足够作为当前 no-backend-ready endpoint，并选择下一步 `P1 internal Renderer backend-readiness manifest stabilization bundle implementation`。下一步仍必须 docs-only，只固定 `runtime_renderer_backend_readiness.cj` owner / truth / canonical endpoint / stop-line，不批准 backend implementation、platform object creation、command buffer commit、GPU submission、render execution、renderer state write、diagnostics / event bus / observer / telemetry 或 public API。

## Downstream Backend-readiness Manifest Stabilization

Renderer backend-readiness manifest stabilization 已完成：

- [2026-05-04-p1-renderer-backend-readiness-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-manifest.md)
- [2026-05-04-p1-internal-renderer-backend-readiness-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-readiness-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime/cjgui/src/runtime_renderer_backend_readiness.cj` owner / truth / canonical endpoint / stop-line，并确认 `CjguiInternalRendererNoBackendReadyReadiness` 不是 backend-ready permission、render permission、GPU submission permission、platform object permission、renderer state write permission 或 public API permission。下一步转向 docs-only `P1 internal Renderer backend readiness branch milestone stabilization bundle implementation`，不批准 backend / Metal / AppKit implementation、platform object creation、command buffer commit、GPU submission、render execution、renderer state write、diagnostics / event bus / observer / telemetry 或 public API。
