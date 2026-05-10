# P1 内部渲染器 platform object AppKit import 边界复核

日期：2026-05-10

状态：implementation closure / AppKit import no-object callable

## 实现结论

本轮按 preflight 选择 `P1 internal Renderer platform object AppKit import boundary bundle`，完成 production native bridge 的 AppKit import boundary first slice。该实现只证明 `#import <AppKit/AppKit.h>` 在 production bridge 中可编译，并通过 no-object callable 暴露 capability / admission / still-blocked facts；不创建 `NSWindow` / `NSView` / `CAMetalLayer` / `CALayer`，不导入 Metal / QuartzCore，不返回 pointer / handle，不新增 public API，不写 renderer state。

## 实际写集

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_platform_object_appkit_import.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_import.sh`
- native skeleton / symbol / call / package link probe allowlist scripts
- README、tracker、plans README、runtime README、设计意图索引、topic manifests
- 本阶段 preflight / closure / next-boundary / manifest 文档

`runtime/cjgui/cjpm.toml` 未修改，smoke native files 未修改，`runtime_state.cj` 未修改。

## 新增 callable

- `cjgui_native_bridge_appkit_import_available(void)`：返回 AppKit import boundary availability fact。
- `cjgui_native_bridge_appkit_no_object_admission(void)`：返回 no-object AppKit admission fact。
- `cjgui_native_bridge_platform_object_create_still_blocked(void)`：返回 platform object creation still-blocked classification。

这些 callable 都只返回 `int32_t`，不返回 token、native pointer、native handle 或 object identity。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_appkit_import.cj`
- Runtime input：`CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness`
- Endpoint：`CjguiInternalRendererNoPlatformObjectAppKitImportReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft()`
- Truth：AppKit import available、no-object admission、platform object still blocked、main-thread / token / teardown prerequisite preserved、no Metal / QuartzCore、no object、no pointer / handle、no public surface、no renderer state write、no backend-ready truth。

该 owner 只在 internal-only 范围调用 no-object AppKit import C ABI 并脱水 facts，不扩 runtime public surface。

## 验证记录

阶段实现后已通过：

- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_import.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `cjpm build --target-dir /tmp/cjgui-renderer-platform-object-appkit-import-target --skip-script`

probe 已观测 `appkit_import_observed=true`、`appkit_no_object_admission_observed=true` 与 `platform_object_still_blocked_observed=true`，同时确认 `platform_object_created=false`、`native_pointer_returned=false`、`metal_quartzcore_imported=false`、`public_api_modified=false`。

最终矩阵仍需在 manifest closure 前统一复核 smoke、diff、whitespace、link target、public declaration scan、protected path 与 GitNexus detect。

## 下游接续

本 closure 的历史后续入口已由 [platform object AppKit class availability manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-class-availability-manifest.md) 接续并封账。下游新增 no-object class availability callable 与 `runtime_renderer_platform_object_appkit_class_availability.cj`，只观察 `NSWindow` / `NSView` class availability、class lookup no-object admission 与 platform allocation still-blocked facts；不返回 `Class` / `id` / native pointer / handle，不创建 AppKit / Metal / QuartzCore object，不改变本 closure 的 stop-line。

## 停止线复核

- no `NSWindow` / `NSView` / `CAMetalLayer` / `CALayer` creation。
- no `MTLDevice` / `MTLCommandQueue`。
- no Metal / QuartzCore import。
- no resource creation callable invocation。
- no token-to-resource binding。
- no raw pointer / native pointer / native handle。
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

编辑 runtime / native symbols 前已对 `CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness`、`cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft` 与 `cjgui_native_bridge_surface_capabilities` 运行 upstream impact。GitNexus 返回 not found / UNKNOWN，`impactedCount=0`，未出现 HIGH / CRITICAL；本轮以源码、build、probe 与 forbidden scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object AppKit import 从 preflight 进入 production import / no-object callable boundary。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_appkit_import.cj`；truth 固定为 AppKit import / no-object callable facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、pointer / handle、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，closure 后进入 manifest stabilization。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
