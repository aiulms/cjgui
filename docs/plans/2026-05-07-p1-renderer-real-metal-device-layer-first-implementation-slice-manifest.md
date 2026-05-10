# 渲染器真实 Metal device-layer 第一刀切片 manifest

日期：2026-05-07

状态：docs-only manifest stabilization / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real Metal device-layer first implementation slice manifest stabilization bundle implementation`。本轮只为既有 [runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj) 做 manifest 封账，不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 protected paths。

本 manifest 不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不替代 owner shell、closure review、build recovery closure 或 topic manifest。它只固定当前 real Metal device-layer first implementation slice 的 owner、truth、canonical endpoint、default draft、runtime input 与 stop-line。

后续新增 `.cj` owner 文件仍必须保留文件头维护注释，覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake；注释只解释维护边界，不得把 shell facts、admission facts 或 readiness facts 写成实现许可。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj`
- canonical endpoint：`CjguiInternalRendererNoRealMetalDeviceLayerReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`
- runtime input：`CjguiInternalRendererNoNativeTeardownImplementationReadiness`
- current truth：real Metal device-layer intent / device shell policy / layer binding shell policy / teardown proof / no-real-metal-device-layer readiness facts

当前 endpoint 只作为 no-real-metal-device-layer shell endpoint。它不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，不创建 backend ready truth，也不把 upstream native teardown facts 升格为 native bridge、Metal / AppKit、native handle、GPU submission、renderer state write 或 public API permission。

## 当前事实

`CjguiInternalRendererRealMetalDeviceLayerIntent` 只表达 real Metal device-layer first-slice intent。它不是 `MTLDevice` creation intent 的执行许可，也不是 `CAMetalLayer` binding permission。

`CjguiInternalRendererRealMetalDeviceShellPolicy` 只表达 device shell policy facts。`RealMetalDeviceShellPolicy` 不创建真实 `MTLDevice`，不查询真实 device，不调用 Metal / AppKit / Objective-C / FFI，不持有 native handle 或 raw pointer。

`CjguiInternalRendererRealMetalLayerBindingShellPolicy` 只表达 layer binding shell policy facts。`RealMetalLayerBindingShellPolicy` 不创建真实 `CAMetalLayer`，不绑定 native layer，不读取真实 layer state，不获取 drawable，不创建 command queue 或 command buffer。

`CjguiInternalRendererRealMetalDeviceLayerTeardownProof` 只表达 teardown proof placeholder facts。`RealMetalDeviceLayerTeardownProof` 不调用 retain / release / destroy，不执行真实 teardown，不调用 bridge，也不释放真实 native resource。

`CjguiInternalRendererNoRealMetalDeviceLayerReadiness` 只封住当前 no-real-metal-device-layer readiness facts。`NoRealMetalDeviceLayerReadiness` 不是真实 `MTLDevice` permission、真实 `CAMetalLayer` permission、native handle permission、command queue permission、drawable permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

上一轮 build recovery 只证明 owner shell 的构造参数一致性与构建可用性，不证明真实 Metal resource 可用，不证明 native bridge / Objective-C / Metal / AppKit 路径可用，也不证明 command queue、drawable、GPU submission、renderer state write、backend ready truth 或 public API 可以打开。

## 证据链关系

本 manifest 采用以下证据链，但不把任何证据升格为 runtime truth：

- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)
- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)
- [real Metal device-layer first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-next-boundary-decision.md)
- [real Metal device-layer first slice build recovery closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-slice-build-recovery-stabilization-closure-review.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)

这些文档共同证明当前 shell endpoint 足够进入 manifest stabilization；它们不授予真实 `MTLDevice` / `CAMetalLayer`、native bridge、C ABI / FFI、native handle、command queue、drawable、command buffer、GPU submission、renderer state write、backend ready truth 或 public API permission。

## 同形边界刹车

本轮只做 manifest 封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或新的 endpoint。

明确拒绝：

- Metal-ready wrapper。
- device-ready wrapper。
- layer-ready wrapper。
- native-handle-ready wrapper。
- backend-ready wrapper。
- resource-ready wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- public diagnostics wrapper。
- receipt / record / publication。

`CjguiInternalRendererNoRealMetalDeviceLayerReadiness` 不得继续包装成 platform-ready、Metal-ready、device-ready、layer-ready、backend-ready、resource-ready 或 implementation-ready endpoint。下一阶段只能做 branch closure / next decision，不能跳到 command queue、drawable、command buffer、GPU work、renderer state write、backend ready truth 或 public API。

## 停止线

本 manifest 继续固定：

- no native bridge modification。
- no Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no bridge call。
- no retain / release / destroy。
- no native handle。
- no raw pointer。
- no real `MTLDevice`。
- no real `CAMetalLayer`。
- no `MTLCommandQueue`。
- no drawable。
- no command buffer。
- no render pass。
- no encoder。
- no pipeline state。
- no shader / descriptor creation。
- no draw call。
- no GPU submission。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no public diagnostics / API。
- no backend ready truth。

## 下一阶段候选

A 推荐：`P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`

理由：owner shell 已完成 slice、next-boundary decision、build verification follow-up、build recovery 与本 manifest 封账。下一步应做 branch closure / next decision，确认是否 stop here、转 native bridge write-set preflight、转 real command queue first implementation preflight，或继续 shell hardening；不得继续新增同构 wrapper。

B 暂缓：`P1 internal Renderer native bridge write-set preflight decision`

C 暂缓：`P1 internal Renderer real command queue first implementation preflight`

D 暂缓：`P1 internal Renderer real Metal device-layer shell hardening`

E 拒绝：direct native bridge / Objective-C / Metal / AppKit modification。

F 拒绝：direct native handle / raw pointer creation。

G 拒绝：direct real `MTLDevice` / `CAMetalLayer` creation without preflight。

H 拒绝：direct command queue / drawable / command buffer。

I 拒绝：direct render / GPU submission。

J 拒绝：direct renderer state write。

K 拒绝：public API / C ABI expansion。

L 拒绝：receipt / record / publication wrapper。

M consolidation 仅在明确 duplicate / self-wrapping evidence 出现时选择。

## 下游同步

本 manifest 同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)
- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)
- [real Metal device-layer first slice build recovery closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-slice-build-recovery-stabilization-closure-review.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)

## 唯一后续入口

`P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`

## 下游分支后续边界决策

下游 real Metal device-layer branch next-boundary decision 已完成：

- [real Metal device-layer branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-metal-device-layer-branch-next-boundary-decision.md)

该 decision 确认本 manifest 固定的 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 足够作为当前 no-real-metal-device-layer shell endpoint，并确认 first slice manifest 足够作为分支阶段封账。它不把本 manifest、build recovery closure 或 shell endpoint 升格为真实 `MTLDevice` / `CAMetalLayer` permission、native handle permission、command queue permission、drawable permission、GPU submission permission、renderer state write permission、backend ready truth 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real command queue first implementation preflight decision`

## 下游真实 command queue 第一刀预检

下游 real command queue first implementation preflight decision 已完成：

- [real command queue first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-preflight-decision.md)

该 downstream decision 只把本 manifest 固定的 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 作为上游 planning endpoint。它不把本 manifest、owner shell 或 build recovery 解释成 `MTLCommandQueue` permission、`newCommandQueue` permission、native handle permission、queue-ready wrapper、drawable permission、command buffer permission、GPU submission permission、renderer state write permission、backend ready truth 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real command queue first implementation slice bundle`

## 下游真实 command queue 第一刀切片

下游 real command queue first implementation slice 已完成：

- [real command queue first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-queue-first-implementation-slice-closure-review.md)
- [runtime_renderer_command_queue_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_real.cj)

该 downstream slice 只把本 manifest 固定的 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 作为上游 runtime input。它新增 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`，只表达 command queue shell intent、creation admission shell、ownership proof、teardown proof、failure classification 与 no-real-command-queue shell readiness facts。

该 downstream slice 不把本 manifest、owner shell 或 build recovery 解释成真实 `MTLCommandQueue` permission、`newCommandQueue` permission、native handle permission、queue-ready wrapper、drawable permission、command buffer permission、GPU submission permission、renderer state write permission、backend ready truth 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real command queue first implementation slice closure / next real command queue decision`

## 下游真实 command queue 封账与 drawable 第一刀

下游 real command queue first slice 已完成后续边界、manifest stabilization 与 branch closure：

- [real command queue first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-next-boundary-decision.md)
- [real command queue first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-manifest.md)
- [real command queue first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-queue-first-implementation-slice-manifest-stabilization-closure-review.md)
- [real command queue branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-branch-next-boundary-decision.md)

下游 real drawable first implementation preflight 与 first slice manifest stabilization 已完成：

- [real drawable first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-preflight-decision.md)
- [real drawable first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-drawable-first-implementation-slice-closure-review.md)
- [real drawable first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-manifest.md)

这些 downstream 文档继续只把本 manifest 固定的 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 作为上游 shell evidence。该 endpoint 仍不是真实 `MTLDevice` / `CAMetalLayer`、`MTLCommandQueue`、drawable acquisition、`nextDrawable`、present、command buffer、GPU submission、renderer state write、backend ready truth 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real drawable branch closure / next real drawable decision`

## 下游 CAMetalLayer no-attach planning

下游 `NSView` backend shell integration 之后，`CAMetalLayer` attachment planning 已完成：

- [CAMetalLayer attachment planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-cametallayer-attachment-planning-manifest.md)
- [CAMetalLayer attachment planning closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-cametallayer-attachment-planning-stage-closure-review.md)

该 downstream 只固定 no-attach planning facts，不复用本 manifest 的 real Metal device-layer shell 作为真实 `MTLDevice` / `CAMetalLayer` permission；不 import QuartzCore / Metal，不创建或 attach layer，不获取 drawable，不提交 GPU work，不写 renderer state，不发布 backend-ready truth。
