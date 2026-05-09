# 渲染器 native teardown contract 硬化 manifest

日期：2026-05-07
状态：docs-only manifest stabilization / no native implementation / no runtime truth

## 文件定位

本文件封账 `P1 internal Renderer native teardown contract hardening manifest stabilization bundle implementation` 的 manifest。它只固定已存在 owner 的 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line，不新增 runtime owner，不修改 `.cj`，不靠近 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、retain / release / destroy、native handle、GPU submission、renderer state write 或 public API。

本 manifest 不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不替代具体 preflight、closure 或 next-boundary decision。开后续 Renderer gate 前，仍应先从 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md) 进入，再读取对应 topic manifest 和关键原文链。

## 固定项

- Owner file：`runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj`
- Canonical endpoint：`CjguiInternalRendererNoNativeTeardownImplementationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`
- Runtime input：`CjguiInternalRendererNoRealBackendPlatformObjectReadiness`
- Current truth：native teardown contract intent / ownership release policy / teardown failure classification / main-thread confinement guard / no-native-teardown-implementation readiness facts

后续若新增 runtime owner 文件，仍必须保留文件头维护注释，覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake。注释只解释维护边界，不得把 teardown facts 或 admission facts 解释成 native bridge、native handle、Metal resource、backend-ready、renderer state write 或 public API permission。

## 当前事实

`CjguiInternalRendererNativeTeardownContractIntent` 只表达 future native lifecycle 前的 teardown contract hardening intent。它不是 native bridge permission、native handle permission、backend-ready permission 或 Metal resource permission。

`CjguiInternalRendererNativeOwnershipReleasePolicy` 只表达 owner-local release ordering、idempotent teardown expectation、double-release risk fail-closed 与 dangling resource risk fail-closed。`NativeOwnershipReleasePolicy` 不调用 retain / release / destroy，不释放真实 native resource，不创建或保存 native handle，不执行真实 teardown。

`CjguiInternalRendererNativeTeardownFailureClassification` 只表达 failure classification。`NativeTeardownFailureClassification` 只表达 double-release、dangling pointer、wrong-thread、bridge optimism、stale resource、already closed 与 create unavailable 等 fail-closed 分类；它不发布 failure event，不生成 public diagnostics，不把 failure fact 升格为 runtime truth。

`CjguiInternalRendererNativeMainThreadConfinementGuard` 只表达 main-thread confinement guard。`NativeMainThreadConfinementGuard` 不调用 AppKit / Metal / Objective-C，不调度 main-thread work，不调用 platform API，不写 renderer state。

`CjguiInternalRendererNoNativeTeardownImplementationReadiness` 只收束 no-native-teardown-implementation readiness facts。`NoNativeTeardownImplementationReadiness` 不是 native bridge permission、retain / release / destroy permission、native handle permission、C ABI / FFI permission、Metal / AppKit permission、backend-ready permission、renderer state write permission、public diagnostics permission 或 public API permission。

## 证据链关系

本 manifest 承接：

- [native teardown contract hardening preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-preflight-decision.md)
- [native teardown contract hardening value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-value-boundary-closure-review.md)
- [native teardown contract hardening next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-next-boundary-decision.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)

`CjguiInternalRendererNoRealBackendPlatformObjectReadiness` 是唯一 runtime input。`CjguiInternalRendererNoNativeResourceBridgeReadiness`、native resource bridge manifest、real backend platform object slice manifest、backend platform object owner manifest、Metal reference pack 与 smoke evidence 仍只作为 docs evidence，不被升格为 runtime input 或 permission wrapper。

## 同形边界刹车

本轮只做 manifest 封账，不新增 tail wrapper。不得把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness`、native resource bridge manifest、real backend platform object shell、smoke evidence 或 topic manifest 包成 native-teardown-ready wrapper、native-handle-ready wrapper、bridge-ready wrapper、Metal-ready wrapper、backend-ready wrapper、resource-ready wrapper、GPU-submission wrapper、render-permission wrapper、public diagnostics wrapper、receipt / record / publication。

如果后续靠近 native bridge、Objective-C、Metal、AppKit、native handle、raw pointer、C ABI / FFI、retain / release / destroy、真实 platform object、Metal device、GPU submission、renderer state write、public diagnostics 或 public API，必须先开更窄 docs-only preflight。

## 停止线

继续禁止：

- no native bridge modification。
- no Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no bridge call。
- no retain / release / destroy。
- no native handle。
- no raw pointer。
- no `MTLDevice`。
- no `CAMetalLayer`。
- no `MTLCommandQueue`。
- no drawable。
- no command buffer。
- no render pass。
- no encoder。
- no pipeline state。
- no draw call。
- no GPU submission。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics / API。
- no backend ready truth。

## 下一阶段候选

A 推荐：`P1 internal Renderer real Metal device-layer first implementation preflight decision`

理由：native teardown contract hardening endpoint 已由 value boundary、next-boundary decision 与本 manifest 固定。下一步可以 docs-only 评估 real Metal device-layer 第一刀是否可打开，但仍不得直接创建 `MTLDevice` / `CAMetalLayer`，不得修改 native bridge / Objective-C / Metal / AppKit，必须先冻结第一刀 write set、teardown proof、failure mode、main-thread confinement 与验证策略。

B 暂缓：`P1 internal Renderer native bridge write-set preflight decision`

C 暂缓：`P1 internal Renderer native resource token preflight decision`

D 暂缓：`P1 internal Renderer native teardown contract hardening follow-up`

E 拒绝：direct native bridge / Objective-C / Metal / AppKit modification

F 拒绝：direct retain / release / destroy implementation

G 拒绝：direct native handle / raw pointer creation

H 拒绝：direct `MTLDevice` / `CAMetalLayer` creation without preflight

I 拒绝：direct command queue / drawable / command buffer

J 拒绝：direct render / GPU submission

K 拒绝：direct renderer state write

L 拒绝：public API / C ABI expansion

M 拒绝：receipt / record / publication wrapper

N consolidation 仅在明确 duplicate / self-wrapping evidence 出现时选择

## 下游同步

本 manifest 同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [native teardown contract hardening preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-preflight-decision.md)
- [native teardown contract hardening next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-next-boundary-decision.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)

## 唯一后续入口

`P1 internal Renderer real Metal device-layer first implementation preflight decision`

## 下游真实 Metal device-layer 第一刀预检

下游 real Metal device-layer first implementation preflight decision 已完成：

- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)

该 downstream decision 继续把本 manifest 固定的 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()` 作为 readiness evidence，不把 native teardown facts 升格为 native bridge permission、retain / release / destroy permission、native handle permission、Objective-C / Metal / AppKit permission、backend-ready permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice bundle`

## 下游真实 Metal device-layer 第一刀切片

下游 real Metal device-layer first implementation slice 已完成：

- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)
- [runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj)

该 downstream slice 只把本 manifest 固定的 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 作为 runtime input，并输出 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`。它不把 native teardown hardening facts 升格为 native bridge permission、retain / release / destroy permission、native handle permission、`MTLDevice` / `CAMetalLayer` creation permission、backend-ready permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice closure / next real Metal device-layer decision`

## 下游真实 Metal device-layer 切片后续边界决策

下游 real Metal device-layer first implementation slice next-boundary decision 已完成：

- [real Metal device-layer first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-next-boundary-decision.md)

该 downstream decision 继续把本 manifest 固定的 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()` 作为 upstream readiness evidence，并确认 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` 足够作为 no-real-metal-device-layer shell endpoint。由于 downstream slice 的 build verification 未完成，下一步优先补 build verification follow-up；这不把 native teardown facts 或 downstream shell facts 升格为 native bridge permission、retain / release / destroy permission、native handle permission、`MTLDevice` / `CAMetalLayer` creation permission、backend-ready permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice build verification follow-up`

## 下游真实 Metal device-layer manifest 封账

下游 real Metal device-layer first implementation slice manifest stabilization 已完成：

- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [real Metal device-layer first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream manifest 继续只把本 manifest 的 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 作为 upstream readiness evidence。它不把 native teardown facts、downstream shell 或 build recovery 升格为 native bridge permission、retain / release / destroy permission、native handle permission、真实 `MTLDevice` / `CAMetalLayer` permission、backend-ready permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`

## 下游真实 Metal device-layer 分支后续边界决策

下游 real Metal device-layer branch next-boundary decision 已完成：

- [real Metal device-layer branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-metal-device-layer-branch-next-boundary-decision.md)

该 downstream decision 继续只把本 manifest 固定的 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 作为上游 readiness evidence，不把 native teardown facts、downstream shell endpoint、first slice manifest 或 build recovery closure 升格为 native bridge permission、retain / release / destroy permission、native handle permission、真实 `MTLDevice` / `CAMetalLayer` permission、`MTLCommandQueue` permission、backend-ready permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real command queue first implementation preflight decision`

## 下游真实 command queue 第一刀预检

下游 real command queue first implementation preflight decision 已完成：

- [real command queue first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-preflight-decision.md)

该 downstream decision 继续只把本 manifest 固定的 native teardown contract hardening facts 作为 teardown / ownership / failure vocabulary evidence。它不把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness`、downstream Metal shell endpoint 或 topic manifest 升格为 native bridge permission、retain / release / destroy permission、native handle permission、`MTLCommandQueue` permission、`newCommandQueue` permission、backend-ready permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real command queue first implementation slice bundle`

## 下游真实 command queue 第一刀切片

下游 real command queue first implementation slice 已完成：

- [real command queue first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-queue-first-implementation-slice-closure-review.md)
- [runtime_renderer_command_queue_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_real.cj)

该 downstream slice 继续只把本 manifest 固定的 native teardown hardening facts 作为 teardown / ownership / failure vocabulary evidence。它直接消费 downstream Metal shell endpoint `CjguiInternalRendererNoRealMetalDeviceLayerReadiness`，并输出 `CjguiInternalRendererNoRealCommandQueueShellReadiness`。

该 downstream slice 不把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness`、downstream Metal shell endpoint 或 topic manifest 升格为 native bridge permission、retain / release / destroy permission、native handle permission、真实 `MTLCommandQueue` permission、`newCommandQueue` permission、backend-ready permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real command queue first implementation slice closure / next real command queue decision`

## 下游真实 command queue 封账与 drawable 第一刀

下游 real command queue first slice 已完成后续边界、manifest stabilization 与 branch closure：

- [real command queue first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-next-boundary-decision.md)
- [real command queue first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-manifest.md)
- [real command queue first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-queue-first-implementation-slice-manifest-stabilization-closure-review.md)
- [real command queue branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-branch-next-boundary-decision.md)

下游 real drawable first implementation preflight 与 first slice manifest stabilization 也已完成：

- [real drawable first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-preflight-decision.md)
- [real drawable first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-drawable-first-implementation-slice-closure-review.md)
- [real drawable first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-manifest.md)

这些 downstream 文档继续只把本 manifest 固定的 native teardown hardening facts 作为 teardown / ownership / failure vocabulary evidence。`CjguiInternalRendererNoNativeTeardownImplementationReadiness` 仍不是 native bridge permission、retain / release / destroy permission、native handle permission、drawable permission、`nextDrawable` permission、present permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real drawable branch closure / next real drawable decision`

## 下游 native bridge 写集规划重置

下游 [native bridge write-set planning reset decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-native-bridge-write-set-planning-reset-decision.md) 已完成。该 decision 继续只把本 manifest 固定的 native teardown contract intent、ownership release policy、teardown failure classification 与 main-thread confinement guard 作为正式 bridge planning evidence。

该 downstream decision 不把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 升格为 native bridge permission、retain / release / destroy permission、native handle permission、C ABI / FFI permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer native bridge C ABI surface contract preflight decision`

## 下游 C ABI surface contract 封账

下游 [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-c-abi-surface-contract-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续只把本 manifest 的 ownership release policy、teardown failure classification 与 main-thread confinement guard 作为 planning evidence，不把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 升格为 C ABI implementation permission、FFI permission、native bridge implementation permission、native handle permission、retain / release / destroy permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、renderer state write 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native handle token ownership planning preflight decision`

## 下游 native handle token ownership 封账

下游 [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-handle-token-ownership-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续只把本 manifest 的 ownership release policy、teardown failure classification 与 main-thread confinement guard 作为 token ownership planning evidence，不把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 升格为 native handle permission、raw pointer permission、native pointer return permission、native bridge implementation permission、C ABI implementation permission、FFI permission、retain / release / destroy permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、renderer state write 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge teardown implementation planning preflight decision`

## 下游 native bridge teardown implementation planning 封账

下游 [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-teardown-implementation-planning-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续把本 manifest 的 ownership release policy、teardown failure classification、double-release / dangling pointer fail-closed vocabulary 与 main-thread confinement guard 作为 planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 升格为 native bridge implementation permission、destroy permission、retain / release permission、native handle permission、raw pointer permission、C ABI implementation permission、FFI permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、renderer state write 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge first production write-set preflight decision`

## 下游生产写集预检封账

下游 [native bridge first production write-set preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-first-production-write-set-preflight-decision.md) 已完成。该 downstream 继续把本 manifest 的 ownership release policy、teardown failure classification、double-release / dangling pointer fail-closed vocabulary 与 main-thread confinement guard 作为 production bridge skeleton planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 升格为 native bridge implementation permission、destroy permission、retain / release permission、native handle permission、raw pointer permission、callable C ABI permission、FFI permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer production native bridge skeleton write-set contract bundle`
