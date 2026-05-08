# 渲染器真实 command buffer 第一刀切片 manifest

日期：2026-05-08

状态：docs-only manifest stabilization / no runtime truth

## 文件定位

本 manifest 固定 [runtime_renderer_command_buffer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_buffer_real.cj) 的 owner、runtime input、canonical endpoint、default draft、current truth 与 stop-line。它只封账 real command buffer first implementation slice，不修改 `.cj`，不新增 runtime owner，不把 shell facts 写成 runtime truth。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_command_buffer_real.cj`
- runtime input：`CjguiInternalRendererNoRealDrawableShellReadiness`
- canonical endpoint：`CjguiInternalRendererNoRealCommandBufferShellReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealCommandBufferShellDraft()`
- current truth：real command buffer shell intent / command buffer creation admission shell / commit denial proof / completion denial proof / command buffer teardown / failure classification / no-real-command-buffer-shell readiness facts

旧 lifecycle endpoint `CjguiInternalRendererNoCommandBufferReadiness` 与 implementation admission endpoint `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 仍只作为 historical evidence，不作为本 manifest 的 runtime input 或 endpoint。

## 当前事实

`RealCommandBufferCreationAdmissionShell` 不创建真实 command buffer，不调用 command queue factory，不建立 encoding relation。

`RealCommandBufferCommitDenialProof` 不调用 `commit`，不提交 work，不建立 presentation relation。

`RealCommandBufferCompletionDenialProof` 不注册 completion callback，不观察真实 GPU completion，不发布 state-visible truth。

`RealCommandBufferTeardownFailureClassification` 只表达 missing command buffer、wrong-thread、stale command buffer 与 bridge optimism 的 fail-closed 分类，不发布 failure event 或 public diagnostics。

`NoRealCommandBufferShellReadiness` 不是真实 command buffer permission、`commandBuffer` permission、`commit` permission、render pass permission、encoder permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

本轮 command buffer first slice 的 build 只证明 owner shell 可编译，不证明真实 command buffer、Metal resource、command queue factory、GPU submission 或 renderer state write 可用。

## 同形边界刹车

本 manifest 只做封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 `CjguiInternalRendererNoRealCommandBufferShellReadiness` 包成 command-buffer-ready、drawable-ready、backend-ready、GPU-submission、render-permission、renderer-state-write、receipt、record 或 publication wrapper。

## 停止线

- no real command buffer creation。
- no `commandBuffer`。
- no `commit`。
- no `present`。
- no `nextDrawable`。
- no drawable acquisition。
- no render pass。
- no encoder。
- no pipeline state。
- no draw call。
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

- [real drawable branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-branch-next-boundary-decision.md)
- [real command buffer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-buffer-first-implementation-preflight-decision.md)
- [real command buffer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-buffer-first-implementation-slice-closure-review.md)
- [real command buffer first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-buffer-first-implementation-slice-next-boundary-decision.md)
- [real drawable first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-manifest.md)
- [command buffer lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [real command buffer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md)
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)

## 下游 real render pass 第一刀

后续 real command buffer branch next-boundary decision、real render pass first implementation preflight、first slice、next-boundary 与 manifest stabilization 已记录在：

- [real command buffer branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-buffer-branch-next-boundary-decision.md)
- [real render pass first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-first-implementation-preflight-decision.md)
- [real render pass first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-render-pass-first-implementation-slice-closure-review.md)
- [real render pass first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-first-implementation-slice-next-boundary-decision.md)
- [real render pass first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-render-pass-first-implementation-slice-manifest.md)

该 downstream 只把 `CjguiInternalRendererNoRealCommandBufferShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferShellDraft()` 作为 runtime input，新增 no-real-render-pass-shell facts。它不改变本 manifest 的 no-real-command-buffer-shell endpoint，不批准真实 command buffer、`commandBuffer`、`commit`、render pass descriptor、attachment、texture view、encoder、GPU submission、renderer state write 或 public API。

## 唯一后续入口

`P1 internal Renderer real command buffer branch closure / next real command buffer decision`
