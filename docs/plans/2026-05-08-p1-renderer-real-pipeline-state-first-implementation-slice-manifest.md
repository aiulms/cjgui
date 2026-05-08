# 渲染器真实 pipeline state 第一刀切片 manifest

日期：2026-05-08

状态：docs-only manifest stabilization / no runtime truth

## 文件定位

本 manifest 固定 [runtime_renderer_pipeline_state_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_real.cj) 的 owner、runtime input、canonical endpoint、default draft、current truth 与 stop-line。它只封账 real pipeline state first implementation slice，不修改 `.cj`，不新增第二个 runtime owner，不把 shell facts 写成 runtime truth。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_pipeline_state_real.cj`
- runtime input：`CjguiInternalRendererNoRealEncoderShellReadiness`
- canonical endpoint：`CjguiInternalRendererNoRealPipelineStateShellReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealPipelineStateShellDraft()`
- current truth：real pipeline state shell intent / shader function denial proof / pipeline descriptor denial proof / pipeline binding denial proof / compatibility failure classification / no-real-pipeline-state-shell readiness facts

旧 lifecycle endpoint `CjguiInternalRendererNoPipelineStateReadiness` 与 implementation admission endpoint `CjguiInternalRendererNoPipelineStateImplementationReadiness` 仍只作为 historical evidence，不作为本 manifest 的 runtime input 或 endpoint。

## 当前事实

`RealPipelineStateShellIntent` 只表达未来 pipeline state shell intent，以及 shader denial、descriptor denial、binding denial 与 compatibility failure 分类的需要。

`RealPipelineStateShaderFunctionDenialProof` 不加载 shader library，不查找 shader function，不编译 shader。

`RealPipelineStateDescriptorDenialProof` 不创建 pipeline descriptor，不写 descriptor field，不绑定 color attachment、depth / stencil 或 render target relation。

`RealPipelineStateBindingDenialProof` 不绑定 pipeline object，不绑定 buffer、texture 或 resource，不 mutate encoder。

`RealPipelineStateCompatibilityFailureClassification` 只表达 missing pipeline state、shader mismatch、descriptor mismatch 与 encoder mismatch 的 fail-closed 分类，不发布 failure event 或 public diagnostics。

`NoRealPipelineStateShellReadiness` 不是真实 pipeline state permission、shader function permission、pipeline descriptor permission、pipeline binding permission、buffer / texture / resource binding permission、encoder permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

本轮 build 只证明 owner shell 可编译，不证明真实 pipeline state、shader、descriptor、encoder binding、GPU submission 或 renderer state write 可用。

## 同形边界刹车

本 manifest 只做封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 `CjguiInternalRendererNoRealPipelineStateShellReadiness` 包成 pipeline-ready、shader-ready、descriptor-ready、binding-ready、GPU-submission、render-permission、renderer-state-write、receipt、record 或 publication wrapper。

## 停止线

- no real pipeline state creation。
- no shader function load / compile。
- no pipeline descriptor creation。
- no pipeline binding。
- no buffer / texture / resource binding。
- no real encoder creation。
- no `renderCommandEncoder`。
- no `endEncoding`。
- no real render pass descriptor creation。
- no attachment / texture view。
- no real command buffer creation。
- no `commandBuffer`。
- no `commit`。
- no `present`。
- no `nextDrawable`。
- no GPU submission / render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no native bridge / Objective-C / Metal / AppKit / FFI modification。
- no C ABI / FFI declaration。
- no native handle / raw pointer。
- no retain / release / destroy。
- no public diagnostics / API。

## 证据链

- [real encoder branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-encoder-branch-next-boundary-decision.md)
- [real pipeline state first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-first-implementation-preflight-decision.md)
- [real pipeline state first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-pipeline-state-first-implementation-slice-closure-review.md)
- [real pipeline state first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-first-implementation-slice-next-boundary-decision.md)
- [real encoder first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-encoder-first-implementation-slice-manifest.md)
- [pipeline state lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [pipeline state implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md)
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [render execution implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-manifest.md)
- [renderer state write implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-state-write-implementation-admission-manifest.md)

## 唯一后续入口

`P1 internal Renderer real pipeline state branch closure / next real pipeline state decision`

## 下游指向

本 manifest 的下游已推进到 real draw call first-slice macro：

- [real pipeline state branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-branch-next-boundary-decision.md)
- [real draw call first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-draw-call-first-implementation-preflight-decision.md)
- [real draw call first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-draw-call-first-implementation-slice-closure-review.md)
- [real draw call first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-draw-call-first-implementation-slice-manifest.md)

这些下游文档只把 `CjguiInternalRendererNoRealPipelineStateShellReadiness` 作为 draw call shell planning evidence，不把它升格为真实 pipeline state、binding、GPU submission、render 或 public API permission。
