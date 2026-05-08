# 渲染器真实 command queue 第一刀切片 manifest

日期：2026-05-08

状态：docs-only manifest stabilization / no runtime truth

## 文件定位

本 manifest 固定 [runtime_renderer_command_queue_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_real.cj) 的 owner、runtime input、canonical endpoint、default draft、current truth 与 stop-line。它只封账 real command queue first implementation slice，不修改 `.cj`，不新增 runtime owner，不把任何 shell fact 写成 runtime truth。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_command_queue_real.cj`
- runtime input：`CjguiInternalRendererNoRealMetalDeviceLayerReadiness`
- canonical endpoint：`CjguiInternalRendererNoRealCommandQueueShellReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`
- current truth：real command queue shell intent / queue creation admission shell / command queue ownership proof / command queue teardown proof / command queue failure classification / no-real-command-queue shell readiness facts

旧 lifecycle endpoint `CjguiInternalRendererNoRealCommandQueueReadiness` 不作为本 manifest 的 endpoint，也不被本 manifest 复用为 first-slice truth。

## 当前事实

`RealCommandQueueShellIntent` 只表达 future command queue shell 第一刀意图。

`RealCommandQueueCreationAdmissionShell` 不创建真实 `MTLCommandQueue`，不调用 `newCommandQueue`，不创建 command buffer。

`RealCommandQueueOwnershipProof` 不保存 native handle，不创建 raw pointer，不暴露 foreign resource token。

`RealCommandQueueTeardownProof` 不调用 retain / release / destroy，不执行真实 teardown。

`RealCommandQueueFailureClassification` 只表达 unavailable queue creation、wrong-thread、dangling resource 与 bridge optimism 的 fail-closed 分类，不发布 failure event 或 public diagnostics。

`NoRealCommandQueueShellReadiness` 不是 queue-ready permission、backend-ready permission、drawable permission、command buffer permission、GPU submission permission、renderer state write permission 或 public API permission。

## 同形边界刹车

本 manifest 只做封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 `CjguiInternalRendererNoRealCommandQueueShellReadiness` 包成 queue-ready、backend-ready、native-handle-ready、drawable-ready、GPU-submission、render-permission、renderer-state-write、receipt、record 或 publication wrapper。

## 停止线

- no real `MTLCommandQueue`。
- no `newCommandQueue`。
- no native bridge / Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no native handle / raw pointer。
- no retain / release / destroy。
- no drawable acquisition / `nextDrawable`。
- no command buffer / `commit` / `present`。
- no GPU submission / render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no public diagnostics / API。

## 证据链

- [real command queue first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-preflight-decision.md)
- [real command queue first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-queue-first-implementation-slice-closure-review.md)
- [real command queue first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-next-boundary-decision.md)
- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md)

## 唯一后续入口

`P1 internal Renderer real command queue branch closure / next real command queue decision`
