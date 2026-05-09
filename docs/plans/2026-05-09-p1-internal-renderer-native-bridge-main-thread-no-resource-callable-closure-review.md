# P1 内部渲染器 native bridge main-thread no-resource callable 收口复核

日期：2026-05-09

状态：implementation closure / ready for next-boundary

## 实际写集

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_native_bridge_main_thread_call.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`
- `labs/native_bridge_ffi_probe/README.md`
- `labs/native_bridge_ffi_probe/src/main.cj`
- `labs/native_bridge_ffi_probe/scripts/build_and_run.sh`
- 本阶段 docs / README / topic manifest。

## 新增 callable

`cjgui_native_bridge_is_main_thread`

返回值：

- `1`：当前线程是主线程。
- `0`：当前线程不是主线程。
- negative：unknown / unsupported。

实现路线为 `pthread_main_np()`。本轮只允许 `#include <pthread.h>`，未引入 Foundation、Cocoa、AppKit、Metal 或 QuartzCore。

## 新增 runtime owner

Owner：

`runtime/cjgui/src/runtime_renderer_native_bridge_main_thread_call.cj`

Endpoint：

`CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()`

Runtime input：

`CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness`

owner 只调用 `cjgui_native_bridge_is_main_thread()`，并输出 current-thread classification 的 internal dehydrated facts。

## 已观察事实

早期验证已观察：

- `main_thread_query_observed=true`
- `main_thread_observed=true`
- no-resource callable allowlist 已扩展到第五个 symbol。
- `cjpm build --skip-script` 在主包 static build 下通过。

该观察只证明 no-resource current-thread query 可调用，不证明可以创建 AppKit / Metal 对象。

## 保持边界

- 未新增 public API / diagnostics。
- 未调用 resource callable。
- 未创建 native object、native handle、raw pointer 或 native pointer return。
- 未导入 Foundation / Cocoa / Metal / QuartzCore。
- 未创建 AppKit / Metal 对象。
- 未调用 retain / release / destroy。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 smoke native files。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未写 renderer state。
- 未创建 backend-ready truth。

## 同形边界刹车

不得把 main-thread no-resource callable、pthread query、probe success 或 runtime owner facts 包装成 native object permission、AppKit permission、Metal permission、backend-ready permission、public API permission、resource callable permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，main-thread no-resource callable 已实现并进入 closure。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_main_thread_call.cj`；truth 限定为 current-thread classification facts；stop-line 继续禁止 public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转入 main-thread no-resource callable next-boundary。
- 是否同步 topic manifest：待 next-boundary / manifest 同步。
- 已同步哪些 topic manifest：待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
