# P1 内部渲染器 native bridge no-resource runtime FFI call owner 清单

日期：2026-05-09

状态：manifest stabilization / internal-only runtime owner

## 固定对象

- Owner：`runtime/cjgui/src/runtime_renderer_native_bridge_no_resource_call.cj`
- Endpoint：`CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft()`
- Runtime input：`CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`
- Probe：`runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`

## 调用清单

owner 只调用以下 no-resource C ABI：

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

禁止调用：

- create / destroy resource callable。
- native handle / token / pointer return callable。
- AppKit / Metal object callable。
- drawable / command buffer / commit / present callable。
- public runtime API wrapper。

## 固定 facts

Default draft 产出：

- `didConfirmSurfaceVersionObserved`
- `didConfirmCapabilitiesObserved`
- `didConfirmStatusOkObserved`
- `didConfirmNoResourceAdmissionObserved`
- `didFailClosedOnUnexpectedNoResourceResult`
- `didConfirmNoPublicSurface`
- `didConfirmNoResourceCallable`
- `didConfirmNoNativeObjectHandleOrPointer`
- `didConfirmNoMetalOrAppKitUsage`
- `didConfirmNoRendererStateWrite`
- `didConfirmNoBackendReadyTruth`

这些 facts 只说明 internal side-effect-free interop 已在 owner 中表达，不说明 GUI backend ready。

## Package link 状态

- `runtime/cjgui/cjpm.toml` 未修改。
- Production `.m` 未正式接入 `runtime/cjgui` 主包 package config。
- Script-managed temporary `cjpm` package link route 仍是实际 C ABI execution probe。
- 主包 static build 已证明含 actual call owner 的源码可编译，但这不是 runtime executable link guarantee。

## 停止线

- no public API / diagnostics。
- no resource callable。
- no native object / handle / raw pointer。
- no native pointer return。
- no Cocoa / Metal / QuartzCore import。
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

`P1 internal Renderer native bridge main-thread no-resource callable preflight decision`

该入口只能评估是否增加 main-thread classification 这类 no-resource callable；不得直接进入 resource callable、native object、Metal / AppKit、public API 或 backend-ready truth。

## 下游接续

下游 [main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md) 已完成。该阶段新增 `cjgui_native_bridge_is_main_thread(void)` 与 `runtime/cjgui/src/runtime_renderer_native_bridge_main_thread_call.cj`，将 canonical endpoint 推进为 `CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()`，并只把当前线程分类返回值脱水成 internal facts。该下游不改变本清单 stop-line：no-resource runtime FFI call owner 与 main-thread query 都不是 public API、resource callable、native object、Metal / AppKit、renderer state write 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-resource runtime FFI call owner 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_no_resource_call.cj`；truth 固定为四个 no-resource C ABI observed facts；stop-line 继续禁止 public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge main-thread no-resource callable preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
