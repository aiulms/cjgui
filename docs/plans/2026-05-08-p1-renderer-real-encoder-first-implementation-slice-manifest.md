# 渲染器真实 encoder 第一刀切片 manifest

日期：2026-05-08

状态：docs-only manifest stabilization / no runtime truth

## 文件定位

本 manifest 固定 [runtime_renderer_encoder_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_encoder_real.cj) 的 owner、runtime input、canonical endpoint、default draft、current truth 与 stop-line。它只封账 real encoder first implementation slice，不修改 `.cj`，不新增第二个 runtime owner，不把 shell facts 写成 runtime truth。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_encoder_real.cj`
- runtime input：`CjguiInternalRendererNoRealRenderPassShellReadiness`
- canonical endpoint：`CjguiInternalRendererNoRealEncoderShellReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealEncoderShellDraft()`
- current truth：real encoder shell intent / encoder creation admission shell / binding denial proof / end-encoding denial proof / encoder teardown / failure classification / no-real-encoder-shell readiness facts

旧 lifecycle endpoint `CjguiInternalRendererNoEncoderReadiness` 与 implementation admission endpoint `CjguiInternalRendererNoEncoderImplementationReadiness` 仍只作为 historical evidence，不作为本 manifest 的 runtime input 或 endpoint。

## 当前事实

`RealEncoderCreationAdmissionShell` 不创建真实 encoder，不调用 encoder factory，不修改 render pass descriptor。

`RealEncoderBindingDenialProof` 不绑定 pipeline、buffer、texture、sampler 或 resource，不建立 draw relation。

`RealEncoderEndEncodingDenialProof` 不调用 `endEncoding`，不 finalize command buffer，不建立 work submission 或 completion observation relation。

`RealEncoderTeardownFailureClassification` 只表达 missing encoder object、wrong-thread、stale encoding scope 与 bridge optimism 的 fail-closed 分类，不发布 failure event 或 public diagnostics。

`NoRealEncoderShellReadiness` 不是真实 encoder permission、`renderCommandEncoder` permission、`endEncoding` permission、pipeline / buffer / texture / resource binding permission、command buffer permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

本轮 encoder first slice 的 build 只证明 owner shell 可编译，不证明真实 encoder、Metal resource、command buffer relation、resource binding、GPU submission 或 renderer state write 可用。

## 同形边界刹车

本 manifest 只做封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 `CjguiInternalRendererNoRealEncoderShellReadiness` 包成 encoder-ready、binding-ready、pipeline-ready、GPU-submission、render-permission、renderer-state-write、receipt、record 或 publication wrapper。

## 停止线

- no real encoder creation。
- no `renderCommandEncoder`。
- no `endEncoding`。
- no pipeline / buffer / texture / resource binding。
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

- [real render pass branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-branch-next-boundary-decision.md)
- [real encoder first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-encoder-first-implementation-preflight-decision.md)
- [real encoder first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-encoder-first-implementation-slice-closure-review.md)
- [real encoder first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-encoder-first-implementation-slice-next-boundary-decision.md)
- [real render pass first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-first-implementation-slice-manifest.md)
- [encoder lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)
- [encoder implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md)
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [render execution implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-manifest.md)
- [renderer state write implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-state-write-implementation-admission-manifest.md)

## 下游 real pipeline state 第一刀

real pipeline state first-slice macro 已完成并消费本 manifest 固定的 `CjguiInternalRendererNoRealEncoderShellReadiness` / `cjguiInternalExecuteDefaultRendererRealEncoderShellDraft()` 作为唯一 runtime input evidence。

- [real encoder branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-encoder-branch-next-boundary-decision.md)
- [real pipeline state first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-first-implementation-preflight-decision.md)
- [real pipeline state first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-pipeline-state-first-implementation-slice-closure-review.md)
- [real pipeline state first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-first-implementation-slice-next-boundary-decision.md)
- [real pipeline state first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-first-implementation-slice-manifest.md)
- [real pipeline state first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-pipeline-state-first-implementation-slice-manifest-stabilization-closure-review.md)

下游 endpoint 是 `CjguiInternalRendererNoRealPipelineStateShellReadiness` / `cjguiInternalExecuteDefaultRendererRealPipelineStateShellDraft()`。它只表达 pipeline state shell intent、shader function denial proof、pipeline descriptor denial proof、pipeline binding denial proof、compatibility failure classification 与 no-real-pipeline-state-shell readiness facts；不创建真实 pipeline state，不加载 / 编译 shader function，不创建 pipeline descriptor，不绑定 pipeline / buffer / texture / resource，不创建 encoder、GPU submission、render、renderer state write、backend ready truth 或 public API。

## 唯一后续入口

`P1 internal Renderer real encoder branch closure / next real encoder decision`
