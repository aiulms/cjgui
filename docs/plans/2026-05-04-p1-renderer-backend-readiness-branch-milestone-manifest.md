# P1 Renderer backend-readiness branch milestone manifest

日期：2026-05-04

状态：branch milestone stabilization

## Purpose

本 milestone 总结并封账 renderer backend-readiness branch 的 owner / truth / evidence chain / canonical tail / stop-line。

本 milestone 是 docs-only。它不修改 `.cj`，不新建 runtime owner，不运行 build / smoke，不批准 backend implementation，不批准 platform resource implementation，不批准 command buffer commit / GPU submission / render execution / renderer state write，也不改变 AI-native operability / foreign surface intake 的结论。AI-native operability / foreign surface intake 仍只是 future radar，不改变当前 renderer backend-readiness branch milestone。

## Canonical Tail

当前 renderer backend-readiness branch canonical tail 是：

- `CjguiInternalRendererNoBackendReadyReadiness`
- `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`

Canonical owner file：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_readiness.cj`

Canonical runtime input：

- `CjguiInternalRendererNoStateWriteReadiness`
- `cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft()`

Reference pack 与所有 upstream manifests 只作为 docs evidence，不是 runtime input。

## Evidence Chain

完整 evidence chain：

1. Packet truth：[2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md)
   - `CjguiInternalRendererPacketOrderingHardeningResult`
   - `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`
2. Backend / Metal reference evidence：[2026-05-03-p1-renderer-backend-metal-reference-pack.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
   - reference pack only；不作为 runtime input。
3. Platform resource：[2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
   - `CjguiInternalRendererNoPlatformResourceReadiness`
   - `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`
4. Command queue：[2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
   - `CjguiInternalRendererNoCommandQueueReadiness`
   - `cjguiInternalExecuteDefaultRendererCommandQueueLifecycleDraft()`
5. Drawable acquisition：[2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
   - `CjguiInternalRendererNoDrawableReadiness`
   - `cjguiInternalExecuteDefaultRendererDrawableAcquisitionDraft()`
6. Command buffer：[2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
   - `CjguiInternalRendererNoCommandBufferReadiness`
   - `cjguiInternalExecuteDefaultRendererCommandBufferLifecycleDraft()`
7. Render pass：[2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
   - `CjguiInternalRendererNoRenderPassReadiness`
   - `cjguiInternalExecuteDefaultRendererRenderPassLifecycleDraft()`
8. Encoder：[2026-05-03-p1-renderer-encoder-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
   - `CjguiInternalRendererNoEncoderReadiness`
   - `cjguiInternalExecuteDefaultRendererEncoderLifecycleDraft()`
9. Draw call：[2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
   - `CjguiInternalRendererNoDrawCallReadiness`
   - `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`
10. Pipeline state：[2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
    - `CjguiInternalRendererNoPipelineStateReadiness`
    - `cjguiInternalExecuteDefaultRendererPipelineStateLifecycleDraft()`
11. Render execution no-op：[2026-05-04-p1-renderer-render-execution-no-op-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
    - `CjguiInternalRendererNoRenderExecutionReadiness`
    - `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`
12. Backend object owner：[2026-05-04-p1-renderer-backend-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-manifest.md)
    - `CjguiInternalRendererNoBackendObjectReadiness`
    - `cjguiInternalExecuteDefaultRendererBackendObjectOwnerDraft()`
13. Frame pacing owner：[2026-05-04-p1-renderer-frame-pacing-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-manifest.md)
    - `CjguiInternalRendererNoFrameSchedulerReadiness`
    - `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()`
14. Renderer state write no-write：[2026-05-04-p1-renderer-state-write-no-write-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-manifest.md)
    - `CjguiInternalRendererNoStateWriteReadiness`
    - `cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft()`
15. Backend-readiness tail：[2026-05-04-p1-renderer-backend-readiness-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-manifest.md)
    - `CjguiInternalRendererNoBackendReadyReadiness`
    - `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`

## Current Branch Truth

当前 branch 只形成 backend readiness value facts：

- backend readiness intent。
- platform lifecycle gate。
- execution admission gate。
- state visibility gate。
- no-backend-ready readiness。

这些 facts 不是 backend-ready permission，不是 backend implementation permission，不是 platform object permission，不是 render permission，不是 command buffer commit / GPU submission permission，也不是 renderer state write permission。

## Explicit Non-Implementation

当前 branch 仍然没有：

- backend object creation。
- platform object creation。
- Metal / AppKit implementation。
- `MTLDevice` / `CAMetalLayer` ownership。
- command queue creation。
- drawable acquisition。
- command buffer creation。
- command buffer commit。
- GPU submission。
- render pass / encoder / pipeline state creation。
- draw call execution。
- render execution。
- renderer state write。
- diagnostics / event bus / observer / telemetry。
- public API / public C ABI expansion。
- native handle / raw pointer surface。

## Reference Pack Role

[Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 只作为 evidence：

- Metal command structure 固定 `MTLDevice`、command queue、command buffer、encoder、render pass、pipeline state 等只能属于 future backend / platform owner。
- CAMetalLayer / drawable lifecycle 固定 drawable acquisition must be late-bound and backend-local。
- AppKit resize / backing scale / color / frame pacing 只能作为 dehydrated facts 过界。
- Completion / presentation / resource retention / failure handling 不能进入 core packet 或 current backend-readiness value facts。

Reference pack 不是 runtime input，不是 backend implementation plan，不是 platform resource implementation plan，也不是 command buffer commit / GPU submission permission。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 milestone 生效。

本 milestone 明确刹住 backend-readiness tail：

- 不再新增 backend-readiness receipt / record / publication。
- 不再新增 backend-ready permission wrapper。
- 不再新增 GPU-submission wrapper。
- 不再新增 render-permission wrapper。
- 不再新增 platform-object wrapper。
- 不再新增 renderer-state-write wrapper。
- 不再新增 command-buffer-commit wrapper。
- 不把 branch milestone 解释为真实 backend implementation 许可。

`CjguiInternalRendererNoBackendReadyReadiness` 已经是当前 renderer backend-readiness branch 的 canonical tail。继续包装 tail 会把同一 no-backend-ready result 换名，不会新增 owner truth、resource lifecycle、acceptance gate 或 implementation permission evidence。

## AI-native / Foreign Surface Intake Status

[AI-native operability / foreign surface risk intake](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-ai-native-operability-foreign-surface-risk-intake.md) 仍然只是 future radar：

- semantic physical operability / occlusion gate 暂不进入当前 renderer backend-readiness branch。
- semantic interaction stability / pending gate 暂不进入当前 renderer backend-readiness branch。
- layout-derived semantic association 暂不进入当前 renderer backend-readiness branch。
- foreign surface / browser-kernel containment 暂不进入当前 renderer backend-readiness branch。

本 milestone 不改变该 intake 的结论，也不让它抢占当前 renderer backend readiness milestone。

## Stop-line

继续禁止：

- no runtime code in this milestone round。
- no `.cj` modifications。
- no new runtime owner。
- no backend implementation。
- no Metal / AppKit implementation。
- no platform resource implementation。
- no backend object creation。
- no platform object creation。
- no `MTLDevice` / `CAMetalLayer` creation or ownership。
- no command queue creation。
- no drawable acquisition。
- no command buffer creation or commit。
- no GPU submission。
- no render pass / encoder / pipeline state creation。
- no draw call execution。
- no render execution。
- no renderer state write。
- no diagnostics / event bus / observer / telemetry / public diagnostics。
- no public API / public C ABI expansion。
- no native handle / raw pointer / platform resource token。
- no receipt / record / publication。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Candidate Comparison

### A. P1 internal Renderer real backend implementation preflight decision

推荐为下一阶段 opening。

该 opening 仍必须 docs-only，不实现 backend。它需要重新评估：

- real backend owner。
- platform object creation policy。
- lifecycle / teardown ownership。
- failure / no-draw path。
- GPU submission gate。
- renderer state write relation。
- smoke / harness strategy。
- platform bridge confinement。
- public surface stop-line。

### B. Platform resource implementation preflight

暂缓。

Platform resource owner 目前只封账 no-platform-resource value facts。进入真实 platform object creation 前，应先以 real backend implementation preflight 重新评估 backend owner / bridge confinement / teardown / smoke strategy。

### C. Command buffer commit / GPU submission preflight

暂缓。

Render execution no-op、backend-readiness manifest 与本 milestone 都明确 no-submit。该方向必须等 real backend implementation preflight 后再判断。

### D. Renderer state write real preflight

暂缓。

State write no-write endpoint 只表达 no-state-write readiness facts。真实 state write 与 frame completion tracking 必须等 backend owner / submission / completion policy 重新评估后再开。

### E. AI-native operability / occlusion gate preflight

暂缓。

已登记为 future radar，但不抢当前 renderer backend-readiness branch。

### F. Foreign surface / browser-kernel containment preflight

暂缓。

已登记为 future radar，但不进入当前 renderer backend-readiness branch。

### G. Backend / Metal / AppKit implementation

拒绝。

本 milestone 不批准直接实现。

### H. Public surface expansion

拒绝。

public allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### I. Receipt / record / publication

拒绝。

Backend-readiness tail 已封账，不再新增 receipt / record / publication。

### J. Consolidation

暂缓。

仅在明确 duplicate / low-value / self-wrapping evidence 出现时选择。当前没有这类 evidence；当前需要的是 real backend implementation preflight 的 docs-only decision，不是 consolidation。

## Decision

Renderer backend-readiness branch milestone 已封账。当前 branch canonical tail 是：

- `CjguiInternalRendererNoBackendReadyReadiness`
- `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`

唯一 next opening：

`P1 internal Renderer real backend implementation preflight decision`

下一轮仍必须 docs-only。它只能评估 real backend owner、platform object creation、lifecycle / teardown、failure / no-draw path、GPU submission gate、renderer state write relation 与 smoke strategy；不得实现 backend、Metal、AppKit、platform object、command buffer commit、GPU submission、render execution、renderer state write、diagnostics / event bus / observer / telemetry 或 public API。

## Downstream Real Backend Implementation Preflight

Renderer real backend implementation preflight 已完成：

- [2026-05-04-p1-renderer-real-backend-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-real-backend-implementation-preflight-decision.md)

该 preflight 判定可以从 no-backend-ready value facts 靠近真实 backend implementation，但不能直接实现。下一步必须继续 docs-only，先比较真实 backend 第一刀应该切在 platform object owner、Metal device / layer owner、command queue / drawable owner、no-draw backend shell，还是其他更小 owner。

Same-shape Boundary Brake 继续刹住 `CjguiInternalRendererNoBackendReadyReadiness`：不得把它包成 real-backend receipt、implementation-readiness wrapper、backend-ready permission wrapper、GPU-submission wrapper、render-permission wrapper、platform-object wrapper、diagnostics wrapper 或 public API wrapper。

唯一 next opening：

`P1 internal Renderer real backend first-slice owner preflight decision`

## Downstream Real Backend First-slice Owner Preflight

Renderer real backend first-slice owner preflight 已完成：

- [2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-real-backend-first-slice-owner-preflight-decision.md)

该 preflight 选择 `P1 internal Renderer backend platform object owner preflight decision` 作为下一阶段唯一 opening。它确认真实 backend 第一刀仍必须 docs-only，不批准 internal value boundary，也不批准 backend / Metal / AppKit implementation、platform object creation、command buffer commit、GPU submission、render execution、renderer state write 或 public API。

唯一 next opening：

`P1 internal Renderer backend platform object owner preflight decision`

## Downstream Backend Platform Object Owner Preflight

Renderer backend platform object owner preflight 已完成：

- [2026-05-04-p1-renderer-backend-platform-object-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-preflight-decision.md)

该 preflight 选择 `P1 internal Renderer backend platform object owner value boundary bundle implementation` 作为下一阶段唯一 opening。它只批准 internal value facts，不批准真实 platform object creation、native handle / raw pointer、`MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、render pass、encoder、pipeline state、command buffer commit、GPU submission、render execution、renderer state write、bridge / smoke / harness 修改、public API / C ABI expansion 或 diagnostics / telemetry / observer / event bus。

唯一 next opening：

`P1 internal Renderer backend platform object owner value boundary bundle implementation`

## Downstream Backend Platform Object Owner Value Boundary

Renderer backend platform object owner value boundary 已完成：

- [2026-05-04-p1-internal-renderer-backend-platform-object-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-platform-object-owner-value-boundary-closure-review.md)

该 implementation 新增 `runtime/cjgui/src/runtime_renderer_backend_platform_object.cj`，只消费 `CjguiInternalRendererNoBackendReadyReadiness`，canonical endpoint 是 `CjguiInternalRendererNoPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`。

Same-shape Boundary Brake 继续刹住 no-backend-ready tail：本轮新增的是 native resource ownership / lifecycle teardown / confinement failure / no-platform-object-readiness 语义，不是 platform object receipt / record / publication、native-handle readiness wrapper、backend implementation wrapper、Metal device readiness wrapper、backend-ready permission wrapper、GPU-submission wrapper 或 render-permission wrapper。

唯一 next opening：

`P1 internal Renderer backend platform object owner closure / next platform object decision`

## Downstream Backend Platform Object Owner Next-boundary Decision

Renderer backend platform object owner next-boundary decision 已完成：

- [2026-05-04-p1-renderer-backend-platform-object-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()` 已足够作为当前 no-platform-object endpoint，并选择 `P1 internal Renderer backend platform object owner manifest stabilization bundle implementation` 作为唯一 next opening。

Same-shape Boundary Brake 继续刹住 no-platform-object endpoint：不得新增 platform object receipt / record / publication、native-handle readiness wrapper、backend implementation wrapper、Metal device readiness wrapper、GPU-submission wrapper、render-permission wrapper 或 public API wrapper；不得把 backend-readiness branch milestone 解释为真实 platform object / backend implementation 许可。

唯一 next opening：

`P1 internal Renderer backend platform object owner manifest stabilization bundle implementation`

## Downstream Backend Platform Object Owner Manifest Stabilization

Renderer backend platform object owner manifest stabilization 已完成：

- [2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [2026-05-04-p1-internal-renderer-backend-platform-object-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-internal-renderer-backend-platform-object-owner-manifest-stabilization-closure-review.md)

该 manifest stabilization 固定 `runtime_renderer_backend_platform_object.cj` owner / truth / canonical endpoint / stop-line，继续不批准 platform object creation、native handle / raw pointer、`MTLDevice` / `CAMetalLayer`、Metal / AppKit backend implementation、command buffer commit、GPU submission、render execution、renderer state write、public API 或 C ABI expansion。

唯一 next opening：

`P1 internal Renderer Metal device-layer owner preflight decision`
