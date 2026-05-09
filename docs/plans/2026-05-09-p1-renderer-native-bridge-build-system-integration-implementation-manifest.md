# P1 渲染器 native bridge 构建系统接入实现 manifest

日期：2026-05-09

状态：manifest stabilization / no build config change

## 文件定位

本 manifest 固定 native bridge build system integration implementation value boundary 的 owner、runtime input、canonical endpoint、default draft、current truth 与 stop-line。

本 manifest 不批准修改 `runtime/cjgui/cjpm.toml`、package config 或 build config，不批准把 production `.m` 接入 `cjpm build`，不批准实现 callable C ABI / FFI，不批准新增 runtime `.cj` FFI declaration，不批准 native object creation，也不改变 production skeleton 与 probe 的 no-build-integration 边界。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_native_bridge_build_system_admission.cj`
- runtime input：`CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness`
- canonical endpoint：`CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeBuildSystemAdmissionDraft()`
- current truth：native bridge build system integration implementation intent / macOS-only build gate admission / native source inclusion denial proof / Objective-C compile-link admission policy / framework link denial proof / build failure classification / no-native-bridge-build-system-implementation readiness facts

## 当前事实

`NativeBridgeBuildSystemImplementationIntent` 只说明 isolated probe 成功后可以形成 build system implementation admission facts；它不授权 build config change。

`NativeBridgeMacOSBuildGateAdmission` 只表达 macOS-only build gate、non-macOS fallback 与 CI / headless behavior 的 admission facts；不修改 package config。

`NativeBridgeNativeSourceInclusionDenialProof` 明确 production native source 仍不得被纳入 `cjpm build`，probe 与 production build 继续分离。

`NativeBridgeBuildSystemObjectiveCCompileLinkAdmissionPolicy` 只表达 compiler path、`SDKROOT` discovery、deployment target 与 linker path 的 future policy；不调用 compiler，不改 build script。

`NativeBridgeFrameworkLinkDenialProof` 明确 framework link 仍未接入；未来 framework list 必须显式规划，当前不 import / link AppKit、Metal 或 QuartzCore。

`NativeBridgeBuildFailureClassification` 只分类 missing compiler、missing SDKROOT、package integration unsupported、non-macOS fallback 与 CI / headless failure；所有异常路径保持 fail-closed。

`NoNativeBridgeBuildSystemImplementationReadiness` 不是 `cjpm` integration permission、callable C ABI permission、FFI permission、native-handle permission、Metal / AppKit permission、backend-ready permission、renderer state write permission、public diagnostics permission 或 public API permission。

## 写集确认

本 manifest 对应 runtime owner 是唯一新增 `.cj` owner。本轮不修改以下文件：

- `runtime/cjgui/cjpm.toml`
- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `labs/macos_bridge_smoke/native/*`

## 同形边界刹车

本 manifest 只做构建系统接入实现准入封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 build system admission facts 包装成 `cjpm` integration permission、bridge-ready permission、callable-C-ABI-ready permission、FFI-ready permission、native-handle-ready permission、Metal / AppKit ready、backend-ready truth、GPU-submission permission、render permission、renderer-state-write permission、public diagnostics permission 或 public API permission。

## 停止线

- no `runtime/cjgui/cjpm.toml` modification。
- no package config / build config modification。
- no production `.m` `cjpm build` integration。
- no production skeleton modification。
- no probe script modification。
- no smoke lab native modification。
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
- no public diagnostics / API。

## 证据链

- [native bridge build system integration implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-system-integration-implementation-preflight-decision.md)
- [native bridge build system integration implementation value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-build-system-integration-implementation-value-boundary-closure-review.md)
- [native bridge build system integration implementation next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-system-integration-implementation-next-boundary-decision.md)
- [native bridge build probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-probe-manifest.md)
- [native bridge build integration planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-integration-planning-manifest.md)
- [production native bridge skeleton write-set manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md)
- [macOS bridge verification smoke topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 下游后续入口

`P1 internal Renderer native bridge cjpm integration first implementation manifest stabilization completed；native bridge callable C ABI first implementation manifest stabilization completed；native bridge no-resource callable runtime integration stage manifest stabilization completed；下游当前入口是 P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`

## 下游 callable C ABI planning 封账

下游 [native bridge callable C ABI planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-planning-manifest-stabilization-closure-review.md) 已完成。该 downstream 只把 `CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness` 作为 runtime input，并输出 `CjguiInternalRendererNoCallableCAbiReadiness` / `cjguiInternalExecuteDefaultRendererCallableCAbiDraft()`。

该 downstream 不把本 manifest 的 build system admission facts 升格为 callable C ABI implementation permission、FFI permission、runtime `.cj` FFI declaration permission、native bridge implementation permission、native object permission、native handle permission、raw pointer permission、Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。
