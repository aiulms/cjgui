# 渲染器真实 drawable 第一刀切片 manifest

日期：2026-05-08

状态：docs-only manifest stabilization / no runtime truth

## 文件定位

本 manifest 固定 [runtime_renderer_drawable_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_real.cj) 的 owner、runtime input、canonical endpoint、default draft、current truth 与 stop-line。它只封账 real drawable first implementation slice，不修改 `.cj`，不新增 runtime owner，不把 shell facts 写成 runtime truth。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_drawable_real.cj`
- runtime input：`CjguiInternalRendererNoRealCommandQueueShellReadiness`
- canonical endpoint：`CjguiInternalRendererNoRealDrawableShellReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()`
- current truth：real drawable shell intent / drawable availability admission shell / drawable acquisition denial proof / presentation denial proof / drawable teardown / failure classification / no-real-drawable-shell readiness facts

旧 lifecycle endpoint `CjguiInternalRendererNoRealDrawableReadiness` 与 implementation admission endpoint `CjguiInternalRendererNoRealDrawableImplementationReadiness` 仍只作为 historical evidence，不作为本 manifest 的 runtime input 或 endpoint。

## 当前事实

`RealDrawableAvailabilityAdmissionShell` 不查询真实 drawable pool，不保存 drawable token，不创建 native resource surface。

`DrawableAcquisitionDenialProof` 不获取 drawable，不暴露 drawable texture，不执行 blocking foreign call。

`DrawablePresentationDenialProof` 不调用 presentation，不创建 command buffer relation，不提交 work。

`DrawableTeardownFailureClassification` 只表达 unavailable drawable、wrong-thread、stale drawable 与 bridge optimism 的 fail-closed 分类，不发布 failure event 或 public diagnostics。

`NoRealDrawableShellReadiness` 不是 drawable-ready permission、`nextDrawable` permission、present permission、command buffer permission、native handle permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 同形边界刹车

本 manifest 只做封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 `CjguiInternalRendererNoRealDrawableShellReadiness` 包成 drawable-ready、queue-ready、backend-ready、native-handle-ready、GPU-submission、render-permission、renderer-state-write、receipt、record 或 publication wrapper。

## 停止线

- no drawable acquisition。
- no `nextDrawable`。
- no `present`。
- no command buffer / `commandBuffer`。
- no `commit`。
- no GPU submission / render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no native bridge / Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no native handle / raw pointer。
- no retain / release / destroy。
- no public diagnostics / API。

## 证据链

- [real drawable first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-preflight-decision.md)
- [real drawable first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-drawable-first-implementation-slice-closure-review.md)
- [real drawable first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-next-boundary-decision.md)
- [real command queue first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-manifest.md)
- [real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)
- [real drawable implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md)

## 唯一后续入口

`P1 internal Renderer real drawable branch closure / next real drawable decision`

## 后续已接入

后续 real drawable branch closure 已完成，并进入 real command buffer first-slice macro：

- [real drawable branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-branch-next-boundary-decision.md)
- [real command buffer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-buffer-first-implementation-preflight-decision.md)
- [real command buffer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-buffer-first-implementation-slice-manifest.md)
