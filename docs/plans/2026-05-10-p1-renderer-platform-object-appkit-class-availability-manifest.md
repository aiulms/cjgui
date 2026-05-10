# P1 内部渲染器 platform object AppKit class availability 清单

日期：2026-05-10

状态：manifest stabilization / no-object class availability boundary

## 清单结论

platform object AppKit class availability stage 已封账，actual route 是 production AppKit class lookup boundary + no-object callable first implementation。Production native bridge 允许在已有 `#import <AppKit/AppKit.h>` 边界下使用 `NSClassFromString` 观察 `NSWindow` / `NSView` class availability，但只暴露 integer facts，不创建任何 AppKit object，不保存或返回 `Class` / `id`，不导入 Metal / QuartzCore，不返回 pointer / handle，不新增 public API，不写 renderer state。

该清单不批准 platform object creation，不批准 AppKit object permission，不批准 native handle / raw pointer，不批准 Metal / QuartzCore，不批准 backend-ready truth。

## Imports

允许：

- `#import <AppKit/AppKit.h>`，仅作为 production bridge compile / class lookup boundary。

继续禁止：

- `#import <Cocoa/Cocoa.h>`
- `#import <Metal/Metal.h>`
- `#import <QuartzCore/...>`
- 任何 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer` object creation。
- 任何 `MTLDevice` / `MTLCommandQueue` object creation。

## Native callable list

- `cjgui_native_bridge_appkit_nswindow_class_available(void)` -> `int32_t`
- `cjgui_native_bridge_appkit_nsview_class_available(void)` -> `int32_t`
- `cjgui_native_bridge_appkit_class_lookup_no_object_admission(void)` -> `int32_t`
- `cjgui_native_bridge_platform_object_allocation_still_blocked(void)` -> `int32_t`

Return contract：

- `22`：`NSWindow` class lookup available。
- `23`：`NSView` class lookup available。
- `24`：class lookup remains no-object admission fact。
- `-21`：platform object allocation still blocked。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_appkit_class_availability.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectAppKitImportReadiness`
- Actual route：internal no-object FFI call owner
- Observed facts：`NSWindow` class available、`NSView` class available、class lookup no-object admission、platform allocation still blocked、AppKit import prerequisite preserved、no `Class` / `id` / pointer / handle return、no AppKit object allocation、no Metal / QuartzCore、no public surface、no renderer state write、no backend-ready truth。

## Probe scripts

- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_class_availability.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_import.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`

这些 scripts 只验证 class lookup / symbol / link / no-object facts，不修改 source，不修改 package config，不执行 native lifecycle。

## Actual write set

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_platform_object_appkit_class_availability.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_class_availability.sh`
- Native probe allowlist / temporary package link scripts
- README / tracker / plans README / runtime README / design intent index / topic manifests
- 本阶段 preflight、closure、next-boundary、manifest 与 manifest closure

`runtime/cjgui/cjpm.toml` 未修改。Smoke native files 未修改。`runtime_state.cj` 未修改。

## 固定边界

- no `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer` creation。
- no `MTLDevice` / `MTLCommandQueue` creation。
- no Metal / QuartzCore import。
- no `Class` / `id` return。
- no native pointer / handle return。
- no class object storage。
- no token-to-resource binding。
- no raw pointer storage。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public API / diagnostics。
- no smoke native edits。
- no backend-ready truth。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-class-availability-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-appkit-class-availability-stage-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-class-availability-next-boundary-decision.md)
- [downstream AppKit main-thread admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-manifest.md)
- [platform object AppKit import manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-import-manifest.md)
- [native bridge teardown callable implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)
- [platform object native callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-native-callable-manifest.md)
- [native token table issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)

## 后续入口

本 manifest 原始唯一后续入口已被 downstream AppKit main-thread admission stage 消费：

`P1 internal Renderer platform object no-object AppKit main-thread admission preflight decision`

当前 canonical tail 以 [real NSView allocation feasibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-real-nsview-allocation-manifest.md) 为准，唯一后续入口转为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。该入口不得直接保存 long-lived `NSView`，不得创建 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`，不得创建 `MTLDevice` / `MTLCommandQueue`，不得返回 `Class` / `id` / native pointer / handle，不得新增 public API，不得写 renderer state，不得创建 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，AppKit class availability boundary 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_appkit_class_availability.cj`；truth 固定为 AppKit class availability、class lookup no-object admission 与 platform allocation still-blocked facts；stop-line 固定为 no AppKit object / no Metal / no `Class` / no `id` / no pointer / no public / no renderer state。
- 本轮是否改变唯一 next opening：是，历史转为 `P1 internal Renderer platform object no-object AppKit main-thread admission preflight decision`；当前已由 downstream token-backed creation planning、no-object creation callable 与 real `NSView` allocation feasibility manifest 接续为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
