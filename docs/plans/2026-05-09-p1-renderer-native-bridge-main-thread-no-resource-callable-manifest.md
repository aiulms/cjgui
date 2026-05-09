# P1 内部渲染器 native bridge main-thread no-resource callable 清单

日期：2026-05-09

状态：manifest stabilization / internal-only no-resource callable

## 固定对象

- Native callable：`cjgui_native_bridge_is_main_thread`
- Native header：`runtime/cjgui/native/cjgui_native_bridge.h`
- Native implementation：`runtime/cjgui/native/cjgui_native_bridge.m`
- Runtime owner：`runtime/cjgui/src/runtime_renderer_native_bridge_main_thread_call.cj`
- Endpoint：`CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()`
- Runtime input：`CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness`

## callable 合约

`cjgui_native_bridge_is_main_thread(void)` 返回 `int32_t`：

- `1`：当前线程是主线程。
- `0`：当前线程不是主线程。
- negative：unknown / unsupported。

实现使用 `pthread_main_np()`。本阶段允许 `#include <pthread.h>`；继续禁止 Foundation、Cocoa、AppKit、Metal 与 QuartzCore import。

## runtime facts

Default draft 产出：

- `didConfirmMainThreadQueryObserved`
- `didConfirmCurrentThreadIsMainThread`
- `didFailClosedOnUnknownMainThreadResult`
- `didConfirmNoPublicSurface`
- `didConfirmNoResourceCallable`
- `didConfirmNoNativeObjectHandleOrPointer`
- `didConfirmNoFoundationCocoaMetalOrQuartzCoreImport`
- `didConfirmNoRendererStateWrite`
- `didConfirmNoBackendReadyTruth`

这些 facts 只说明 current-thread classification 可以被 internal owner 脱水，不说明可以创建 AppKit / Metal 对象或启动 native bridge。

## probe 固定

已扩展 allowlist / observed facts：

- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`
- `labs/native_bridge_ffi_probe/scripts/build_and_run.sh`

允许 callable list 现在为：

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`
- `cjgui_native_bridge_is_main_thread`

## Package link 状态

- `runtime/cjgui/cjpm.toml` 未修改。
- production `.m` 未正式接入 `runtime/cjgui` 主包 package config。
- script-managed temporary package route 仍是实际 executable call verification route。
- 主包 static build 证明源码可编译，不等于 runtime executable package link guarantee。

## 停止线

- no public API / diagnostics。
- no resource callable。
- no native object / handle / raw pointer。
- no native pointer return。
- no Foundation / Cocoa / Metal / QuartzCore import。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no smoke native edits。
- no backend-ready truth。

## 后续入口

唯一后续入口：

`P1 internal Renderer native bridge native token callable preflight decision`

该入口只能评估 token callable 的 no-resource / no-pointer / no-native-handle 边界；不得直接创建 native handle、native object、resource callable、AppKit / Metal 对象、public API 或 backend-ready truth。

## 下游接续

该入口已由 [native token callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-manifest.md) 接续。当前全局唯一后续入口已经转为 `P1 internal Renderer native token table ownership hardening preflight decision`；main-thread callable 仍只作为 token table planning 的 gate evidence，不是 token table、native handle、native object 或 backend-ready permission。

## 设计意图出口自检

- 本轮是否改变主题状态：是，main-thread no-resource callable 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_main_thread_call.cj`；truth 固定为 current-thread classification facts；stop-line 继续禁止 public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge native token callable preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
