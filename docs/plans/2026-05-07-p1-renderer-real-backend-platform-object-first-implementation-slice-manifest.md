# 渲染器真实后端 platform object 第一刀实现切片 manifest

日期：2026-05-07
状态：docs-only manifest stabilization / no runtime truth / no backend ready permission

## 文件定位

本文件封账 `P1 internal Renderer real backend platform object first implementation slice bundle` 的 manifest。它只固定已存在 owner shell 的 owner、truth、canonical endpoint、default draft、runtime input 与 stop-line，不新增 runtime owner，不修改 `.cj`，不创建真实 platform object，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI。

本 manifest 不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不替代具体 closure。开后续 Renderer gate 前，仍应先从 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md) 进入，再读取对应 topic manifest 和关键原文链。

## 固定项

- Owner file：`runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj`
- Canonical endpoint：`CjguiInternalRendererNoRealBackendPlatformObjectReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- Current truth：real backend platform object intent / shell policy / teardown proof / failure policy / no-real-backend-platform-object readiness facts

后续若新增 runtime owner 文件，仍必须保留文件头维护注释，覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake。注释只解释维护边界，不得把 shell facts 或 admission facts 解释成实现许可。

## 当前事实

`CjguiInternalRendererRealBackendPlatformObjectIntent` 只表达真实后端 platform object 第一刀的意图事实。它不是 backend object，也不是 native resource。

`CjguiInternalRendererRealBackendPlatformObjectShellPolicy` 只表达 internal shell policy。它不创建 native platform object，不创建 backend object，不创建 native handle 或 raw pointer。

`CjguiInternalRendererRealBackendPlatformObjectTeardownProof` 只表达 teardown proof 的占位事实。它不调用 retain / release / destroy，也不执行真实 teardown。

`CjguiInternalRendererRealBackendPlatformObjectFailurePolicy` 只表达 fail-closed failure policy。它不发布 backend-ready failure event，不生成 public diagnostics。

`CjguiInternalRendererNoRealBackendPlatformObjectReadiness` 只收束 no-real-backend-platform-object readiness facts。它不是 native platform object permission、native handle permission、backend ready permission、Metal device permission、resource-ready permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 证据链关系

本 manifest 承接：

- [real backend platform object first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md)
- [real backend platform object first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md)
- [real backend platform object first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-next-boundary-decision.md)
- [platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)

`CjguiInternalRendererNoPlatformObjectImplementationReadiness` 是唯一 runtime input。`CjguiInternalRendererNoNativeResourceBridgeReadiness`、backend platform object owner manifest 与 native resource bridge manifest 仍只作为 upstream evidence，不被升格为 runtime input 或 permission wrapper。

## 同形边界刹车

本轮只做 manifest 封账，不新增 tail wrapper。不得把 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`、platform object admission、native resource bridge、backend platform object owner manifest 或 preflight evidence 包成 platform-ready wrapper、native-handle-ready wrapper、backend-ready wrapper、resource-ready wrapper、Metal-device wrapper、GPU-submission wrapper、render-permission wrapper、public diagnostics wrapper、receipt / record / publication。

如果后续靠近 native bridge、Objective-C、Metal、AppKit、native handle、raw pointer、C ABI / FFI、retain / release / destroy、真实 platform object、Metal device、GPU submission、renderer state write、public diagnostics 或 public API，必须先开更窄 docs-only preflight。

## 停止线

- 不修改 native bridge / Objective-C / Metal / AppKit 代码。
- 不新增 C ABI / FFI declaration。
- 不调用 bridge / retain / release / destroy。
- 不创建 native handle / raw pointer。
- 不创建 `MTLDevice`、`CAMetalLayer` 或 `MTLCommandQueue`。
- 不获取 drawable，不创建 command buffer，不创建 render pass，不创建 encoder。
- 不创建 pipeline state / shader / descriptor，不发出 draw call。
- 不提交 GPU work，不执行 render。
- 不写 renderer state，不触碰 `runtime_state.cj`，不新增 module-level `var`。
- 不发布 public diagnostics / API，不扩 public API。
- 不创建 backend ready truth，不把 backend 标记为 ready。

## 下一阶段候选

A 推荐：`P1 internal Renderer real backend platform object branch closure / next real platform object decision`

理由：当前 shell endpoint 已由 slice、next-boundary decision 与本 manifest 固定。下一步应只做 branch closure / next decision，判断是否 stop、转向 native teardown hardening、转向 Metal device-layer preflight，或继续保持等待，不应直接靠近 native bridge / Metal。

B 暂缓：`P1 internal Renderer native teardown contract hardening preflight decision`

C 暂缓：`P1 internal Renderer real Metal device-layer first implementation preflight`

D 暂缓：`P1 internal Renderer real backend platform object shell hardening`

E 拒绝：direct native bridge / Objective-C / Metal / AppKit modification

F 拒绝：direct native handle / raw pointer creation

G 拒绝：direct `MTLDevice` / `CAMetalLayer` creation

H 拒绝：direct command queue / drawable / command buffer

I 拒绝：direct render / GPU submission

J 拒绝：direct renderer state write

K 拒绝：public API / C ABI expansion

L 拒绝：receipt / record / publication wrapper

M consolidation 仅在明确 duplicate / self-wrapping evidence 出现时选择

## 唯一后续入口

`P1 internal Renderer real backend platform object branch closure / next real platform object decision`

## 下游分支后续边界决策

下游 branch next-boundary decision 已完成：

- [real backend platform object branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-branch-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 足够作为当前 no-real-backend-platform-object shell endpoint。它不把本 manifest 升格为 native platform object permission、native handle permission、backend-ready permission、Metal device permission、resource-ready permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer native teardown contract hardening preflight decision`

## 下游 native teardown 合约硬化预检

下游 native teardown contract hardening preflight decision 已完成：

- [native teardown contract hardening preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-preflight-decision.md)

该 decision 判定本 manifest 的 `RealBackendPlatformObjectTeardownProof` 仍只是 teardown proof 占位事实，不足以直接授权 native bridge、retain / release / destroy、native handle、Objective-C、Metal、AppKit 或 real Metal device-layer first implementation preflight。它只选择下一步新增 teardown hardening value boundary，不把 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` 升格为 platform-ready、native-handle-ready、bridge-ready、Metal-ready、resource-ready、backend-ready、GPU-submission 或 public API wrapper。

新的下游后续入口：

`P1 internal Renderer native teardown contract hardening value boundary bundle implementation`

## 下游 native teardown value boundary

下游 native teardown contract hardening value boundary 已完成：

- [native teardown contract hardening value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-value-boundary-closure-review.md)
- [runtime_renderer_native_teardown_contract.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj)

该 boundary 消费本 manifest 固定的 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`，并输出 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`。它不把本 shell endpoint 升格为 native platform object permission、native handle permission、backend-ready permission、Metal device permission、resource-ready permission、GPU submission permission、renderer state write permission 或 public API permission；只补充 ownership release policy、teardown failure classification、main-thread confinement guard 与 no-native-teardown-implementation facts。

新的下游后续入口：

`P1 internal Renderer native teardown contract hardening closure / next native teardown decision`

## 下游 native teardown 后续边界决策

下游 native teardown contract hardening closure / next decision 已完成：

- [native teardown contract hardening next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()` 足够作为当前 no-native-teardown-implementation endpoint。它不把本 shell manifest、`CjguiInternalRendererNoRealBackendPlatformObjectReadiness` 或 teardown proof 占位事实升格为 native platform object permission、native handle permission、native bridge permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer native teardown contract hardening manifest stabilization bundle implementation`

## 下游 native teardown manifest 稳定化

下游 native teardown contract hardening manifest stabilization 已完成：

- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [native teardown contract hardening manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-manifest-stabilization-closure-review.md)

该 manifest 消费本 manifest 固定的 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`，并固定 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`。它不把本 shell endpoint 升格为 native platform object permission、native handle permission、native bridge permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation preflight decision`

## 下游真实 Metal device-layer 第一刀预检

下游 real Metal device-layer first implementation preflight decision 已完成：

- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)

该 decision 继续消费本 manifest 固定的 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` 作为 upstream readiness evidence，并选择下一步进入极窄 real Metal device-layer first implementation slice。它不把本 shell endpoint 升格为 native platform object permission、native handle permission、native bridge permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice bundle`

## 下游真实 Metal device-layer 第一刀切片

下游 real Metal device-layer first implementation slice 已完成：

- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)
- [runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj)

该 downstream slice 没有把本 shell manifest 升格为 platform object permission、native handle permission、native bridge permission、`MTLDevice` / `CAMetalLayer` creation permission、backend-ready permission、GPU submission permission、renderer state write permission 或 public API permission。它只在 native teardown hardening endpoint 之后新增 real Metal device-layer shell facts。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice closure / next real Metal device-layer decision`
