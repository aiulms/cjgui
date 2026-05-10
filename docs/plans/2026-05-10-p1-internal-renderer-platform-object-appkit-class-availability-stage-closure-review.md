# P1 内部渲染器 platform object AppKit class availability 阶段复核

日期：2026-05-10

状态：implementation closure / no-object class availability callable

## 实现结论

本轮按 preflight 选择 `P1 internal Renderer platform object no-object AppKit class availability first implementation bundle`，完成 production native bridge 的 no-object AppKit class availability first slice。该实现只通过 `NSClassFromString` 观察 `NSWindow` / `NSView` class availability，并把结果脱水为 `int32_t` internal facts；不创建 `NSWindow`、不创建 `NSView`、不创建 `NSApplication`、不创建 `CALayer` / `CAMetalLayer`，不返回 `Class` / `id` / pointer / handle，不导入 Metal / QuartzCore，不新增 public API，不写 renderer state。

## 实际写集

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_platform_object_appkit_class_availability.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_class_availability.sh`
- AppKit import、package link、temporary `cjpm` package link、symbol、skeleton、no-resource call 与 related probe allowlist scripts
- README、tracker、plans README、runtime README、设计意图索引、topic manifests
- 本阶段 preflight、closure、next-boundary、manifest 与 manifest closure 文档

`runtime/cjgui/cjpm.toml` 未修改，smoke native files 未修改，`runtime_state.cj` 未修改。

## 新增 callable

- `cjgui_native_bridge_appkit_nswindow_class_available(void)`：返回 `NSWindow` class lookup availability fact。
- `cjgui_native_bridge_appkit_nsview_class_available(void)`：返回 `NSView` class lookup availability fact。
- `cjgui_native_bridge_appkit_class_lookup_no_object_admission(void)`：返回 class lookup 仍是 no-object admission fact。
- `cjgui_native_bridge_platform_object_allocation_still_blocked(void)`：返回 platform object allocation still-blocked classification。

这些 callable 只返回 `int32_t`，不返回 `Class`、`id`、native pointer、native handle 或 token，不保存 class object，不执行 allocation。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_appkit_class_availability.cj`
- Runtime input：`CjguiInternalRendererNoPlatformObjectAppKitImportReadiness`
- Endpoint：`CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft()`
- Truth：`NSWindow` class observed、`NSView` class observed、class lookup no-object admission observed、platform object allocation still blocked observed、no `Class` / `id` / pointer / handle return、no AppKit object allocation、no Metal / QuartzCore、no public surface、no renderer state write、no backend-ready truth。

该 owner 只在 internal-only 范围调用 no-object AppKit class availability C ABI 并脱水 facts，不扩 runtime public surface。

## Downstream 指向

- [AppKit main-thread admission preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-preflight-decision.md)
- [AppKit main-thread admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-manifest.md)

## 验证记录

阶段实现后已通过：

- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_class_availability.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_import.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_teardown_admission.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_token_issue_revoke.sh`
- `labs/native_bridge_ffi_probe/scripts/build_and_run.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `cjpm build --target-dir /tmp/cjgui-renderer-platform-object-appkit-class-availability-target --skip-script`

class availability probe 已观测 `nswindow_class_available_observed=true`、`nsview_class_available_observed=true`、`class_lookup_no_object_admission_observed=true` 与 `platform_object_allocation_still_blocked_observed=true`，同时确认 `appkit_object_allocated=false`、`class_pointer_returned=false`、`native_pointer_returned=false`、`metal_quartzcore_imported=false`、`public_api_modified=false`。

## 停止线复核

- no `NSWindow` / `NSView` / `NSApplication` allocation。
- no `CALayer` / `CAMetalLayer` creation。
- no `MTLDevice` / `MTLCommandQueue` creation。
- no Metal / QuartzCore import。
- no `Class` / `id` / native pointer / native handle return。
- no class object storage。
- no token-to-resource binding。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public API / diagnostics。
- no smoke native edits。
- no backend-ready truth。

## GitNexus 记录

编辑 runtime / native symbols 前已对 `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness`、`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft` 与 `cjgui_native_bridge_surface_capabilities` 运行 upstream impact。GitNexus 返回 not found / UNKNOWN，`impactedCount=0`，未出现 HIGH / CRITICAL；本轮以源码、build、probe 与 forbidden scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object AppKit import 后续入口进入 no-object class availability implementation。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_appkit_class_availability.cj`；truth 固定为 AppKit class lookup availability 与 no-object still-blocked facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、`Class` / `id` / pointer / handle、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，closure 后进入 manifest stabilization，再转向 `P1 internal Renderer platform object no-object AppKit main-thread admission preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
