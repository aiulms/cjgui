# 渲染器真实 render pass 第一刀切片 manifest

日期：2026-05-08

状态：docs-only manifest stabilization / no runtime truth

## 文件定位

本 manifest 固定 [runtime_renderer_render_pass_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_real.cj) 的 owner、runtime input、canonical endpoint、default draft、current truth 与 stop-line。它只封账 real render pass first implementation slice，不修改 `.cj`，不新增第二个 runtime owner，不把 shell facts 写成 runtime truth。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_render_pass_real.cj`
- runtime input：`CjguiInternalRendererNoRealCommandBufferShellReadiness`
- canonical endpoint：`CjguiInternalRendererNoRealRenderPassShellReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealRenderPassShellDraft()`
- current truth：real render pass shell intent / render pass descriptor admission shell / attachment denial proof / encoder denial proof / render pass teardown / failure classification / no-real-render-pass-shell readiness facts

旧 lifecycle endpoint `CjguiInternalRendererNoRenderPassReadiness` 与 implementation admission endpoint `CjguiInternalRendererNoRenderPassImplementationReadiness` 仍只作为 historical evidence，不作为本 manifest 的 runtime input 或 endpoint。

## 当前事实

`RealRenderPassDescriptorAdmissionShell` 不创建真实 render pass descriptor，不创建 attachment object，不建立 encoder relation。

`RealRenderPassAttachmentDenialProof` 不创建 attachment texture view，不暴露 drawable texture，不建立 resource binding relation。

`RealRenderPassEncoderDenialProof` 不创建 encoding object，不调用 encoder factory，不执行 encoding finalization，不建立 pipeline relation。

`RealRenderPassTeardownFailureClassification` 只表达 missing render pass descriptor、wrong-thread、stale attachment 与 bridge optimism 的 fail-closed 分类，不发布 failure event 或 public diagnostics。

`NoRealRenderPassShellReadiness` 不是真实 render pass descriptor permission、attachment permission、texture view permission、encoder permission、command buffer permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

本轮 render pass first slice 的 build 只证明 owner shell 可编译，不证明真实 render pass descriptor、attachment、encoder、Metal resource、GPU submission 或 renderer state write 可用。

## 同形边界刹车

本 manifest 只做封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 `CjguiInternalRendererNoRealRenderPassShellReadiness` 包成 render-pass-ready、encoder-ready、GPU-submission、render-permission、renderer-state-write、receipt、record 或 publication wrapper。

## 停止线

- no real render pass descriptor creation。
- no attachment / texture view。
- no encoder creation。
- no `renderCommandEncoder`。
- no `endEncoding`。
- no real command buffer creation。
- no `commandBuffer`。
- no `commit`。
- no `present`。
- no `nextDrawable`。
- no pipeline / buffer / texture / resource binding。
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

- [real command buffer branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-buffer-branch-next-boundary-decision.md)
- [real render pass first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-first-implementation-preflight-decision.md)
- [real render pass first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-render-pass-first-implementation-slice-closure-review.md)
- [real render pass first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-first-implementation-slice-next-boundary-decision.md)
- [real command buffer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-buffer-first-implementation-slice-manifest.md)
- [render pass lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)
- [render pass implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md)
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [render execution implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-manifest.md)
- [renderer state write implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-state-write-implementation-admission-manifest.md)

## 唯一后续入口

`P1 internal Renderer real render pass branch closure / next real render pass decision`
