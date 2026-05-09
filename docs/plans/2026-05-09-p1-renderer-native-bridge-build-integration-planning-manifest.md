# P1 渲染器 native bridge 构建接入规划 manifest

日期：2026-05-09

状态：manifest stabilization / no build config change

## 文件定位

本 manifest 固定 native bridge build integration planning value boundary 的 owner、runtime input、canonical endpoint、default draft、current truth 与 stop-line。

本 manifest 不批准修改 `runtime/cjgui/cjpm.toml`、build script 或 package config，不批准把 production `.m` 接入 build，不批准实现 callable C ABI / FFI，不批准 native object creation，也不改变 production skeleton 的 no-build-integration 边界。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_native_bridge_build_integration.cj`
- runtime input：`CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness`
- canonical endpoint：`CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()`
- current truth：native bridge build integration planning intent / macOS-only build gating policy / Objective-C compile-link admission policy / framework link policy / production bridge build probe policy / no-native-bridge-build-integration readiness facts

## 当前事实

`NativeBridgeBuildIntegrationPlanningIntent` 只说明 production skeleton 可作为 build planning evidence；它不把 skeleton manifest 转成 runtime endpoint，也不授权 build config change。

`NativeBridgeMacOSOnlyBuildGatingPolicy` 只表达 macOS-only build gating 与非 macOS no-op / deny posture 规划；不修改 package config，不改变平台编译行为。

`NativeBridgeObjectiveCCompileLinkAdmissionPolicy` 只表达未来 Objective-C compile / link invocation 的准入规划；不调用 compiler，不接入 production `.m`，不修改 build script。

`NativeBridgeFrameworkLinkPolicy` 只表达 framework link list 必须被显式规划；不导入 AppKit / Metal / QuartzCore，不链接 framework，不创建 native object。

`NativeBridgeProductionBuildProbePolicy` 只表达后续应先做 build probe preflight，并且 probe 不得要求 callable C ABI；不实现 FFI，不声明 runtime callable surface。

`NoNativeBridgeBuildIntegrationReadiness` 不是 build integration permission、C ABI implementation permission、FFI permission、native-handle permission、Metal / AppKit permission、backend-ready permission、renderer state write permission、public diagnostics permission 或 public API permission。

## 写集确认

本 manifest 对应 runtime owner 是唯一新增 `.cj` owner。production native skeleton 文件仍保持上一轮状态：

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`

本轮不修改这些 native skeleton 文件，不新增 production native 文件，不修改 `labs/macos_bridge_smoke/native/*`，不修改 `runtime/cjgui/cjpm.toml` 或任何 build script。

## 同形边界刹车

本 manifest 只做构建接入规划封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 build planning facts 包装成 build-ready permission、bridge-ready permission、C-ABI-ready permission、FFI-ready permission、native-handle-ready permission、Metal / AppKit ready、backend-ready truth、GPU-submission permission、render permission、renderer-state-write permission、public diagnostics permission 或 public API permission。

## 停止线

- no `runtime/cjgui/cjpm.toml` modification。
- no build script / package config modification。
- no production `.m` compile integration。
- no native skeleton modification。
- no smoke lab native modification。
- no production native file addition。
- no callable C ABI implementation。
- no FFI declaration。
- no runtime `.cj` FFI declaration。
- no native handle / raw pointer。
- no raw pointer return。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API。

## 证据链

- [native bridge build system integration preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-system-integration-preflight-decision.md)
- [native bridge build integration planning value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-build-integration-planning-value-boundary-closure-review.md)
- [native bridge build integration planning next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-integration-planning-next-boundary-decision.md)
- [native bridge build probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-probe-manifest.md)
- [production native bridge skeleton write-set manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md)
- [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md)
- [macOS bridge verification smoke topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 下游后续入口

`P1 internal Renderer native bridge build probe manifest stabilization completed；native bridge build system integration implementation manifest stabilization completed；native bridge cjpm integration first implementation manifest stabilization completed；下游当前入口是 P1 internal Renderer native bridge callable C ABI preflight decision`
