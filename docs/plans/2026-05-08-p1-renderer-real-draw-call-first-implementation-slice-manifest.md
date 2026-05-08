# P1 渲染器真实 draw call 第一切片清单

状态：完成 / manifest stabilization / no-real-draw-call

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_draw_call_real.cj`
- runtime input：`CjguiInternalRendererNoRealPipelineStateShellReadiness`
- canonical endpoint：`CjguiInternalRendererNoRealDrawCallShellReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealDrawCallShellDraft()`
- current truth：real draw call shell intent / primitive command denial proof / geometry binding denial proof / draw ordering admission shell / draw execution denial proof / no-real-draw-call-shell readiness facts

## 语义范围

`RealDrawCallShellIntent` 只声明后续 draw call 第一刀的 internal shell intent，不发出 draw command。

`RealDrawPrimitiveCommandDenialProof` 只记录 primitive command denial，不调用 primitive draw API。

`RealDrawGeometryBindingDenialProof` 只记录 geometry binding denial，不绑定 pipeline、buffer、texture 或 resource。

`RealDrawOrderingAdmissionShell` 只表达 ordering admission shell，不执行排序副作用，不提交 GPU work。

`RealDrawExecutionDenialProof` 只表达 draw execution denial，不执行 render，不写 renderer state。

`NoRealDrawCallShellReadiness` 不是 draw call permission、primitive command permission、binding permission、GPU submission permission、render permission、renderer state write permission、backend ready truth、public diagnostics permission 或 public API permission。

## 停止线

- no real draw call
- no `drawPrimitives`
- no `drawIndexedPrimitives`
- no pipeline / buffer / texture / resource binding
- no real pipeline state
- no shader function load / compile
- no pipeline descriptor creation
- no real encoder
- no `renderCommandEncoder`
- no `endEncoding`
- no command buffer
- no `commandBuffer`
- no `commit`
- no `present`
- no `nextDrawable`
- no GPU submission
- no render execution
- no renderer state write
- no `runtime_state.cj` modification
- no public API / C ABI
- no native bridge / Objective-C / Metal / AppKit / FFI
- no native handle / raw pointer
- no retain / release / destroy
- no module-level mutable `var`

## 同构边界刹车

本 manifest 只做封账，不新增 tail wrapper。明确拒绝 draw-ready wrapper、binding-ready wrapper、GPU-submission wrapper、render-permission wrapper、renderer-state-write wrapper、public diagnostics wrapper、receipt / record / publication。

## 设计意图出口自检

- 本轮改变主题状态：是，real draw call first slice 完成 manifest stabilization。
- 本轮改变 canonical tail / endpoint：是，最新 runtime shell endpoint 固定为 `CjguiInternalRendererNoRealDrawCallShellReadiness`。
- 本轮改变 owner / truth / stop-line：是，固定 `runtime_renderer_draw_call_real.cj` 的 owner / truth / stop-line。
- 本轮改变唯一 next opening：是，转为 `P1 internal Renderer real draw call branch closure / next real draw call decision`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real draw call branch closure / next real draw call decision`

## 下游真实 render execution 第一切片

后续 real draw call branch closure 已把本 manifest 的 `CjguiInternalRendererNoRealDrawCallShellReadiness` 作为上游 evidence，并选择进入 real render execution first-slice macro：

- [real draw call branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-draw-call-branch-next-boundary-decision.md)
- [real render execution first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-execution-first-implementation-preflight-decision.md)
- [real render execution first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-execution-first-implementation-slice-manifest.md)

该 downstream 只把 draw call shell facts 作为 planning evidence，不把 `NoRealDrawCallShellReadiness` 升格为 draw call、resource binding、GPU submission、render execution、renderer state write 或 public API permission。
