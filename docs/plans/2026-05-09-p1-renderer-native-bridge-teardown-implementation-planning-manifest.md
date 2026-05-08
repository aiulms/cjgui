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
