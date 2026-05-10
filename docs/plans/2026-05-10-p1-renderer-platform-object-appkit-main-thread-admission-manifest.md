# P1 内部渲染器 platform object AppKit main-thread admission 清单

日期：2026-05-10

状态：manifest stabilization / no-object main-thread admission boundary

## 清单结论

platform object AppKit main-thread admission stage 已封账，actual route 是 production no-object AppKit main-thread admission callable + runtime internal owner。Production native bridge 允许在已有 AppKit import boundary 下使用 `pthread_main_np()` 分类当前线程，并暴露 main-thread required / admitted / background denied / creation still-blocked integer facts；但仍不创建任何 AppKit / QuartzCore / Metal object，不返回 `Class` / `id` / native pointer / handle，不保存 native object 或 class object，不新增 public API，不写 renderer state。

该清单不批准 platform object creation，不批准 AppKit object permission，不批准 native handle / raw pointer，不批准 Metal / QuartzCore，不批准 backend-ready truth。

## Imports

允许：

- `#import <AppKit/AppKit.h>`，沿用上一阶段 production bridge compile / class lookup boundary。
- `pthread_main_np()`，仅用于当前线程分类。

继续禁止：

- `#import <Cocoa/Cocoa.h>`
- `#import <Metal/Metal.h>`
- `#import <QuartzCore/...>`
- 任何 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer` object creation。
- 任何 `MTLDevice` / `MTLCommandQueue` object creation。

## Native callable list

- `cjgui_native_bridge_appkit_platform_object_main_thread_required(void)` -> `int32_t`
- `cjgui_native_bridge_appkit_platform_object_main_thread_admitted(void)` -> `int32_t`
- `cjgui_native_bridge_appkit_platform_object_background_thread_denied(void)` -> `int32_t`
- `cjgui_native_bridge_appkit_platform_object_creation_still_blocked(void)` -> `int32_t`

Return contract：

- `25`：future AppKit platform object creation requires main-thread gate。
- `26`：current call is admitted by main-thread classification。
- `-22`：background-thread path denied。
- `-23`：platform object creation remains blocked。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_appkit_main_thread_admission.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness`
- Actual route：internal no-object FFI call owner
- Observed facts：main-thread required observed、main-thread admitted observed、background-thread denied observed、platform object creation still blocked observed、class availability prerequisite preserved、no `Class` / `id` / pointer / handle return、no AppKit object allocation、no Metal / QuartzCore、no public surface、no renderer state write、no backend-ready truth。

## Probe scripts

- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_main_thread_admission.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_class_availability.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_import.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`

这些 scripts 只验证 main-thread admission / symbol / link / no-object facts，不修改 source，不修改 package config，不执行 native lifecycle。

## Actual write set

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_platform_object_appkit_main_thread_admission.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_main_thread_admission.sh`
- Native probe allowlist / temporary package link scripts
- README / tracker / plans README / runtime README / design intent index / topic manifests
- 本阶段 preflight、closure、next-boundary、manifest 与 manifest closure

`runtime/cjgui/cjpm.toml` 未修改。Smoke native files 未修改。`runtime_state.cj` 未修改。

## 固定边界

- no `NSWindow` / `NSView` / `NSApplication` allocation。
- no `CALayer` / `CAMetalLayer` creation。
- no `MTLDevice` / `MTLCommandQueue` creation。
- no Metal / QuartzCore import。
- no `Class` / `id` / native pointer / native handle return。
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

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-appkit-main-thread-admission-stage-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-next-boundary-decision.md)
- [platform object AppKit class availability manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-class-availability-manifest.md)
- [platform object AppKit import manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-import-manifest.md)
- [native bridge teardown callable implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)
- [native token table issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)

## 后续入口

本 manifest 原始唯一后续入口已被 downstream token-backed creation planning stage 消费：

`P1 internal Renderer platform object token-backed object creation planning preflight decision`

当前 canonical tail 以 [real NSView allocation feasibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-real-nsview-allocation-manifest.md) 为准，唯一后续入口转为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。该入口不得直接创建 long-lived `NSView`、`NSWindow`、`NSApplication`、`CALayer` 或 `CAMetalLayer`，不得创建 `MTLDevice` / `MTLCommandQueue`，不得返回 `Class` / `id` / native pointer / handle，不得新增 public API，不得写 renderer state，不得创建 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，AppKit main-thread admission boundary 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_appkit_main_thread_admission.cj`；truth 固定为 AppKit platform object main-thread admission 与 creation still-blocked facts；stop-line 固定为 no AppKit object / no Metal / no `Class` / no `id` / no pointer / no public / no renderer state。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer platform object token-backed object creation planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
