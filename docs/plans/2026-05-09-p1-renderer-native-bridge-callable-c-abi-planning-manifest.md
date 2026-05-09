# P1 渲染器 native bridge callable C ABI planning manifest

日期：2026-05-09

状态：manifest stabilization / internal value boundary only

## 文件定位

本 manifest 固定 native bridge callable `C ABI` planning value boundary 的 owner file、runtime input、canonical endpoint、default draft、current truth 与 stop-line。

本 manifest 不批准 callable `C ABI` implementation，不批准 FFI，不批准 runtime `.cj` FFI declaration，不批准修改 production native `.h` / `.m`，不批准 native object creation，不批准 public API。

## 固定项

- Owner file：`runtime/cjgui/src/runtime_renderer_native_bridge_callable_c_abi.cj`
- Runtime input：`CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness`
- Upstream default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeBuildSystemAdmissionDraft()`
- Canonical endpoint：`CjguiInternalRendererNoCallableCAbiReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCallableCAbiDraft()`
- Current truth：callable `C ABI` planning intent / callable naming policy / status-capability callable admission policy / no-resource callable guard / runtime FFI separation policy / no-callable-C-ABI readiness facts

## 当前事实

`CjguiInternalRendererCallableCAbiPlanningIntent` 只记录可以规划 callable surface，但不打开 implementation。

`CjguiInternalRendererCallableCAbiNamingPolicy` 只记录 production callable naming policy、status / capability query naming 与 smoke callable name reuse denial，不复用 `cjgui_app_run` / `cjgui_last_error_*`。

`CjguiInternalRendererStatusCapabilityCallableAdmissionPolicy` 只允许规划 bridge surface version query、bridge capability / status query、main-thread check query、no-resource init admission query 与 error taxonomy query，不实现这些 callable。

`CjguiInternalRendererNoResourceCallableGuard` 明确拒绝 window / view creation、Metal device / layer / queue creation、native handle / pointer return、destroy side effect、drawable / command buffer / GPU work 与 public runtime API。

`CjguiInternalRendererRuntimeFfiSeparationPolicy` 明确 native callable implementation 与 runtime FFI declaration 必须拆阶段：先 native callable + isolated probe，后续另开 runtime FFI preflight。

`CjguiInternalRendererNoCallableCAbiReadiness` 只确认当前没有 production native header / implementation edit、没有 callable `C ABI` function implementation、没有 runtime FFI declaration、没有 native handle / raw pointer、没有 native object creation、没有 renderer state write、没有 public diagnostics / API。

## 未改变项

本轮不修改：

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/cjpm.toml`
- package / build config
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `labs/macos_bridge_smoke/native/*`
- runtime `.cj` FFI declaration
- public API files
- `runtime/cjgui/src/runtime_state.cj`

## 同形边界刹车

本 manifest 只做 callable `C ABI` planning value boundary 封账，不新增 callable-ready wrapper、FFI-ready wrapper、native-bridge-ready wrapper、native-handle-ready wrapper、Metal / AppKit-ready wrapper、backend-ready wrapper、public diagnostics wrapper、receipt、record 或 publication。

不得把本 owner、build boundary、skeleton compile、C ABI surface contract、token ownership、teardown planning、smoke evidence 或 `cjpm` boundary script 包装成 callable implementation permission、runtime FFI permission、native bridge implementation permission、native object permission、GPU-submission permission、render permission、renderer-state-write permission 或 public API permission。

## 停止线

- no production native `.h` / `.m` modification。
- no callable `C ABI` implementation。
- no runtime `.cj` FFI declaration。
- no `runtime/cjgui/cjpm.toml` modification。
- no package / build config modification。
- no smoke native modification。
- no native handle / raw pointer。
- no raw pointer return。
- no AppKit / Metal object creation。
- no Cocoa / Metal / QuartzCore import in production skeleton。
- no retain / release / destroy。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics / API。
- no module-level mutable `var`。

## 证据链

- [callable C ABI preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-preflight-decision.md)
- [callable C ABI planning value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-planning-value-boundary-closure-review.md)
- [callable C ABI planning next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-next-boundary-decision.md)
- [native bridge cjpm integration first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-cjpm-integration-first-implementation-manifest.md)
- [native bridge build system integration implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-system-integration-implementation-manifest.md)
- [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md)
- [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md)
- [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md)

## 下游后续入口

`P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`

## 下游 callable C ABI 第一实现封账

下游 [native bridge callable C ABI first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-first-implementation-manifest-stabilization-closure-review.md) 已完成。该 downstream 使用本 manifest 的 callable naming、status / capability callable admission、no-resource callable guard 与 runtime FFI separation facts，只在 production native skeleton 中新增四个 no-resource callable。

该 downstream 不把 `CjguiInternalRendererNoCallableCAbiReadiness`、production native callable surface、probe script 或 skeleton compile 升格为 runtime FFI permission、runtime `.cj` FFI declaration permission、native object permission、native handle permission、raw pointer permission、Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

## 下游 runtime 接入阶段封账

下游 [native bridge no-resource callable runtime integration stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-callable-runtime-integration-stage-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-no-resource-callable-runtime-integration-stage-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续遵守本 manifest 的 runtime FFI separation policy，只新增 FFI declaration planning owner 与 symbol probe，不写真实 runtime FFI declaration，不新增 runtime FFI call。

该 downstream 不把 `CjguiInternalRendererNoCallableCAbiReadiness`、`CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`、production native callable surface、probe script 或 skeleton compile 升格为真实 FFI permission、runtime callable permission、native object permission、native handle permission、raw pointer permission、Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。
