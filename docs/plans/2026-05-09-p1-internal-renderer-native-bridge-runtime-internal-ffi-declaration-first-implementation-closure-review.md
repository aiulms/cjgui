# P1 内部渲染器 native bridge runtime internal FFI declaration 第一实现复核

日期：2026-05-09

状态：closure review / internal declaration landed / no runtime call

## 本轮落点

本轮新增 [runtime_renderer_native_bridge_runtime_ffi_declaration.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_runtime_ffi_declaration.cj)。

本轮还修正 [verify_native_bridge_package_link_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh) 的 probe-only runtime library path 设置，使临时 direct `cjc` probe 在执行阶段能找到 `libcangjie-runtime.dylib`。该修正只影响 probe 执行环境，不修改 `runtime/cjgui/cjpm.toml`，不修改 production native `.h` / `.m` 行为，也不接入 runtime FFI call。

该 owner 只消费 `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`，新增 canonical endpoint `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft()`。

本轮实际写入四个 internal-only `foreign func` declaration：

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

这些 declaration 没有被调用，没有 public wrapper，没有 runtime FFI call verification owner，没有 resource callable。

## 为什么新增更窄 owner

旧 [runtime_renderer_native_bridge_ffi_declaration.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_ffi_declaration.cj) 仍代表 no-actual-FFI-declaration planning facts。本轮如果直接翻转旧 endpoint，会把 planning endpoint 包装成 implementation permission。

因此本轮新增更窄 owner，只把 script-managed package link evidence 转为 internal declaration facts，并把 endpoint 命名为 `NoNativeBridgeRuntimeFfiCallReadiness`，明确当前 stop-line 是 no runtime call。

## GitNexus 影响记录

- `CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`：GitNexus 返回 UNKNOWN / not found，按近期新增 owner 未索引处理。
- `cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft`：GitNexus 返回 UNKNOWN / not found，按近期新增 owner 未索引处理。
- `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`：GitNexus 返回 UNKNOWN / not found，按近期新增 owner 未索引处理。
- `cjguiInternalExecuteDefaultRendererNativeBridgeCjpmPackageLinkDraft`：GitNexus 返回 UNKNOWN / not found，按近期新增 owner 未索引处理。

本轮未出现 HIGH / CRITICAL 风险；继续用源码阅读、`cjpm build`、native probes、smoke 与扫描兜底。

## 已验证的边界

`cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-runtime-ffi-declaration-first-implementation-target --skip-script` 已通过。

该 build 证明：在 `runtime/cjgui` 主包内声明未调用的 internal `foreign func` 不需要修改 `runtime/cjgui/cjpm.toml`，也不会把 production `.m` 接入主包 package link。

`verify_native_bridge_package_link_probe.sh` 已在 probe-only runtime library path 修正后通过；该结果仍只是 package-adjacent direct link evidence，不是 `runtime/cjgui` 主包 link 或 runtime FFI call evidence。

## 未发生事项

- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 production native `.h` / `.m` 行为。
- 未修改 smoke native files。
- 未新增 runtime FFI call。
- 未新增 public API / diagnostics。
- 未调用 resource callable。
- 未创建 native object、native handle、raw pointer 或 pointer return。
- 未导入或调用 Cocoa / Metal / QuartzCore。
- 未写 renderer state，未触碰 `runtime_state.cj`。

## 同形边界刹车

不得把 internal `foreign func` declaration、script-managed package link evidence、native symbol probe、isolated FFI probe 或本 closure 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

本轮只证明 runtime 内部可以声明 no-resource C ABI，不证明 GUI backend ready。

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime internal FFI declaration 第一实现已落地。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner；truth 限于 internal foreign declaration 与 no-runtime-call facts；stop-line 继续禁止 public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转向 manifest stabilization，完成后建议进入 internal no-resource FFI call verification bundle。
- 是否同步 topic manifest：是，随 stage manifest 一并同步。
- 已同步哪些 topic manifest：待 manifest stabilization 完成后同步 `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
