# P1 内部渲染器 native bridge main-thread no-resource callable 预检

日期：2026-05-09

状态：preflight / implementation allowed

## 预检结论

本轮可以从 `CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness` 进入 main-thread no-resource callable first implementation。

选择 A：

`P1 internal Renderer native bridge main-thread no-resource callable first implementation bundle`

该选择只允许新增当前线程是否主线程的 no-resource query，不允许进入 AppKit 初始化、Metal / AppKit 对象创建、native handle、resource callable、renderer state write、public API 或 backend-ready truth。

## 实现路线

采用 `pthread_main_np()` 路线：

- production bridge `.m` 允许 `#include <pthread.h>`。
- 不允许 `#import <Foundation/Foundation.h>`。
- 不允许 `#import <Cocoa/Cocoa.h>`、`#import <Metal/Metal.h>` 或 `#import <QuartzCore/CAMetalLayer.h>`。
- 不创建 native object，不返回 pointer，不写 global mutable state。
- Darwin / macOS 下返回 `1` 或 `0`；非 Darwin fallback 返回 negative unknown / unsupported。

`pthread_main_np()` 只做当前线程分类，不调度 main-thread work，不创建 runloop，不触碰 AppKit / Metal。

## callable 合约

新增 callable：

`cjgui_native_bridge_is_main_thread`

返回类型：

`int32_t`

返回值：

- `1`：当前线程是主线程。
- `0`：当前线程不是主线程。
- negative：unknown / unsupported。

该 callable 只返回 dehydrated integer fact，不是 native bridge ready、resource ready、AppKit ready、Metal ready 或 backend ready。

## runtime owner 入口

本轮允许新增：

`runtime/cjgui/src/runtime_renderer_native_bridge_main_thread_call.cj`

建议 endpoint：

`CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness`

建议 default draft：

`cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()`

唯一 runtime input：

`CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness`

owner 只允许调用 `cjgui_native_bridge_is_main_thread()` 并把返回值脱水为 internal facts；不得 public，不得写 state，不得调用 resource callable。

## probe 策略

需要同步 no-resource probe allowlist：

- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`
- `labs/native_bridge_ffi_probe/scripts/build_and_run.sh`

package-adjacent、temporary `cjpm` package 与 isolated FFI probe 应实际观察 `main_thread_query_observed=true`；临时 executable 的主线程调用应观察 `main_thread_observed=true`。如果 toolchain / runtime 调度导致不能稳定观察主线程，应停止并写 blocker，不得扩大到 Foundation / AppKit。

## GitNexus 预检

已对以下 target 运行 upstream impact：

- `CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness`
- `cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft`
- `cjgui_native_bridge_surface_capabilities`

结果均为 UNKNOWN / not found，`impactedCount=0`。按近期新增 owner / native skeleton 未索引处理，继续用源码、build、probe、scan 与 `detect_changes` 兜底；未出现 HIGH / CRITICAL 风险。

## 停止线

- no public API。
- no public diagnostics。
- no resource callable。
- no native object / handle / raw pointer。
- no native pointer return。
- no Cocoa / Foundation / Metal / QuartzCore import。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no smoke native edits。
- no backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，main-thread no-resource callable 预检允许进入极窄 first implementation。
- 本轮是否改变 canonical tail / endpoint：预检阶段尚未改变；implementation 若成功将转为 `CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：预检阶段只批准新增 owner；truth 限定为 current-thread classification facts；stop-line 继续禁止 public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，进入 `P1 internal Renderer native bridge main-thread no-resource callable first implementation bundle`。
- 是否同步 topic manifest：待 implementation / manifest 阶段同步。
- 已同步哪些 topic manifest：待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
