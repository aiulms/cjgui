# P1 渲染器 native bridge teardown implementation planning manifest

日期：2026-05-09

状态：docs-only manifest stabilization / no teardown implementation

## 文件定位

本 manifest 固定 [runtime_renderer_native_bridge_teardown_plan.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_teardown_plan.cj) 的 owner、runtime input、canonical endpoint、default draft、current truth 与 stop-line。

本 manifest 不新增 runtime owner，不新增 production `.h` / `.m`，不修改 `labs/macos_bridge_smoke/native/*`，不实现 C ABI / FFI，不创建 native handle / raw pointer，不返回 native pointer，不调用 retain / release / destroy，不实现 destroy callback，不创建 Metal resource，不创建 backend ready truth，不写 renderer state，不发布 public diagnostics 或 public API。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_native_bridge_teardown_plan.cj`
- runtime input：`CjguiInternalRendererNoNativeHandleTokenReadiness`
- canonical endpoint：`CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()`
- current truth：native bridge teardown planning intent / destroy admission guard policy / token invalidation before destroy policy / double-destroy / dangling-token denial policy / main-thread destroy confinement policy / teardown failure classification / no-native-bridge-teardown-implementation readiness facts

## 当前事实

`NativeBridgeTeardownPlanningIntent` 只表达 future native bridge teardown planning intent，不实现 destroy，不调用 native bridge，不把 smoke destroy evidence 升格为 runtime truth。

`DestroyAdmissionGuardPolicy` 只表达 future destroy admission guard。它要求 valid token before destroy admission，但不调用 destroy，不实现 destroy callback。

`TokenInvalidationBeforeDestroyPolicy` 只表达 token invalidation before native destroy 的 planning policy。它不执行 token mutation side effect，不返回 native pointer。

`NativeBridgeTeardownSafetyDenialPolicy` 只表达 double-destroy denial、dangling-token denial、idempotent no-op planning 与 unsafe teardown fail-closed。

`MainThreadDestroyConfinementPolicy` 只表达 main-thread destroy confinement planning。它不调度 main-thread work，不调用 AppKit / Metal / Objective-C。

`NativeBridgeTeardownFailureClassification` 只表达 double-destroy、dangling-token、wrong-thread destroy、bridge optimism 与 rollback blocked 的 failure classification。它不发布 public diagnostics，不生成 runtime truth。

`NoNativeBridgeTeardownImplementationReadiness` 不是 native bridge implementation permission、destroy permission、retain / release permission、native handle permission、raw pointer permission、native pointer return permission、C ABI implementation permission、FFI permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、public diagnostics permission 或 public API permission。

本轮 build 只证明 Cangjie internal value owner 可编译，不证明 production teardown、destroy callback、native bridge、C ABI、FFI、native handle、Metal resource、backend ready truth、GPU submission、render、renderer state write 或 public diagnostics 可用。

## 同形边界刹车

本 manifest 只做封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` 包成 native bridge ready、destroy ready、native-handle ready、C-ABI-ready、Metal-ready、backend-ready、GPU-submission-ready、render permission、state-write permission、public diagnostics、receipt、record 或 publication wrapper。

## 停止线

- no `labs/macos_bridge_smoke/native/*` modification。
- no production `.h` / `.m`。
- no C ABI implementation。
- no FFI declaration。
- no native handle / raw pointer。
- no native pointer return。
- no retain / release / destroy。
- no destroy callback implementation。
- no backend ready truth。
- no backend object。
- no `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue`。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
- no `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API / C ABI expansion。
- no native bridge / Objective-C / Metal / AppKit / FFI modification。
- no module-level mutable `var`。

## 证据链

- [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md)
- [native handle token ownership manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-handle-token-ownership-manifest-stabilization-closure-review.md)
- [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [macOS bridge verification smoke topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 唯一后续入口

`P1 internal Renderer native bridge first production write-set preflight decision`

## 下游生产写集预检封账

下游 [native bridge first production write-set preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-first-production-write-set-preflight-decision.md) 已完成。该 downstream 继续使用本 manifest 的 destroy admission guard、token invalidation before destroy、double-destroy / dangling-token denial、main-thread destroy confinement 与 teardown failure classification 作为 production bridge skeleton planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` 升格为 native bridge implementation permission、destroy permission、retain / release permission、native handle permission、raw pointer permission、native pointer return permission、callable C ABI permission、FFI permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer production native bridge skeleton write-set contract bundle`

## 下游 skeleton 写集封账

下游 [production native bridge skeleton write-set manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-production-native-bridge-skeleton-write-set-manifest-stabilization-closure-review.md) 已完成。该 downstream 使用本 manifest 的 destroy admission guard、token invalidation before destroy、double-destroy / dangling-token denial、main-thread destroy confinement 与 teardown failure classification 作为 production bridge skeleton planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` 升格为 native bridge implementation permission、destroy permission、retain / release permission、native handle permission、raw pointer permission、native pointer return permission、callable C ABI permission、FFI permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics、public API 或 build config modification permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge build system integration preflight decision`

## 下游 callable C ABI planning 封账

下游 [native bridge callable C ABI planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-planning-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续使用本 manifest 的 destroy admission guard、token invalidation before destroy、double-destroy / dangling-token denial、main-thread destroy confinement 与 teardown failure classification 作为 callable no-resource guard 与 FFI separation 的 planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` 升格为 destroy permission、retain / release permission、callable C ABI implementation permission、FFI permission、runtime `.cj` FFI declaration permission、native bridge implementation permission、native handle permission、raw pointer permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge callable C ABI first implementation preflight decision`

## 下游 token table ownership hardening 封账

下游 [native token table ownership hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-token-table-ownership-hardening-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续使用本 manifest 的 token invalidation before destroy、double-destroy / dangling-token denial、main-thread destroy confinement 与 teardown failure classification 作为 revoke-before-destroy ordering 与 dangling-token failure classification 的 planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` 升格为 token table implementation permission、native token C ABI permission、native bridge implementation permission、destroy permission、retain / release permission、native handle permission、raw pointer permission、native pointer return permission、FFI permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge teardown callable preflight decision`

## 下游 teardown callable 封账

下游 [native bridge teardown callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-teardown-callable-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续使用本 manifest 的 destroy admission guard、token invalidation before destroy、double-destroy / dangling-token denial、main-thread destroy confinement 与 teardown failure classification 作为 no-destroy callable policy 与 revoke-before-destroy callable policy 的 planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` 升格为 native teardown C ABI permission、destroy permission、retain / release permission、token table implementation permission、native object permission、native handle permission、raw pointer permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge resource creation admission preflight decision`
