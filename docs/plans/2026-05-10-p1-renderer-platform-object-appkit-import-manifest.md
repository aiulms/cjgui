# P1 内部渲染器 platform object AppKit import 清单

日期：2026-05-10

状态：manifest stabilization / AppKit import no-object boundary

## 清单结论

platform object AppKit import stage 已封账，actual route 是 production AppKit import boundary + no-object callable first implementation。Production native bridge 允许直接 `#import <AppKit/AppKit.h>`，但只暴露 import / no-object / still-blocked integer facts，不创建任何 AppKit object，不导入 Metal / QuartzCore，不返回 pointer / handle，不新增 public API，不写 renderer state。

该清单不批准 platform object creation，不批准 AppKit object permission，不批准 native handle / raw pointer，不批准 Metal / QuartzCore，不批准 backend-ready truth。

## Imports

允许：

- `#import <AppKit/AppKit.h>`，仅作为 production bridge compile / import boundary。

继续禁止：

- `#import <Cocoa/Cocoa.h>`
- `#import <Metal/Metal.h>`
- `#import <QuartzCore/...>`
- 任何 `NSWindow` / `NSView` / `CAMetalLayer` / `CALayer` object creation。
- 任何 `MTLDevice` / `MTLCommandQueue` object creation。

## Native callable list

- `cjgui_native_bridge_appkit_import_available(void)` -> `int32_t`
- `cjgui_native_bridge_appkit_no_object_admission(void)` -> `int32_t`
- `cjgui_native_bridge_platform_object_create_still_blocked(void)` -> `int32_t`

Return contract：

- `20`：AppKit import boundary available。
- `21`：AppKit no-object admission fact。
- `-20`：platform object creation still blocked。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_appkit_import.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectAppKitImportReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft()`
- Runtime input：`CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness`
- Actual route：internal no-object FFI call owner
- Observed facts：AppKit import available、no-object admission、platform object still blocked、main-thread prerequisite preserved、token / teardown prerequisite preserved、no Metal / QuartzCore、no native object / pointer / handle、no public surface、no renderer state write、no backend-ready truth。

## Probe scripts

- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_import.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`

这些 scripts 只验证 import / symbol / link / no-object facts，不修改 source，不修改 package config，不执行 native lifecycle。

## Actual write set

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_platform_object_appkit_import.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_import.sh`
- Native probe allowlist scripts
- README / tracker / plans README / runtime README / design intent index / topic manifests
- 本阶段 preflight、closure、next-boundary、manifest 与 manifest closure

`runtime/cjgui/cjpm.toml` 未修改。Smoke native files 未修改。`runtime_state.cj` 未修改。

## 固定边界

- no `NSWindow` / `NSView` / `CAMetalLayer` / `CALayer` creation。
- no `MTLDevice` / `MTLCommandQueue` creation。
- no Metal / QuartzCore import。
- no token-to-resource binding。
- no raw pointer storage。
- no native pointer / handle return。
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

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-import-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-appkit-import-boundary-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-import-next-boundary-decision.md)
- [downstream AppKit class availability manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-class-availability-manifest.md)
- [downstream AppKit main-thread admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-manifest.md)
- [native bridge teardown callable implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)
- [platform object native callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-native-callable-manifest.md)
- [main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md)
- [native token table issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)

## 历史入口与下游接续

本 manifest 的历史后续入口已由 downstream AppKit class availability stage 承接并封账：

`P1 internal Renderer platform object no-object AppKit class availability preflight decision`

当前 Renderer 唯一后续入口已继续转为：

`P1 internal Renderer platform object token-backed NSView object table preflight decision`

下游已观察 `NSWindow` / `NSView` class availability、main-thread admission no-object facts、token-backed creation planning facts、no-object creation fail-closed facts 与 isolated `NSView` allocation feasibility facts；不得直接保存 long-lived `NSView`，不得创建 `NSWindow` / `NSApplication` / `CAMetalLayer` / `CALayer`，不得创建 `MTLDevice` / `MTLCommandQueue`，不得返回 native pointer / handle / `Class` / `id`，不得新增 public API，不得写 renderer state，不得创建 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，AppKit import boundary 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_appkit_import.cj`；truth 固定为 AppKit import available、no-object admission 与 platform object still blocked facts；stop-line 固定为 no AppKit object / no Metal / no pointer / no public / no renderer state。
- 本轮是否改变唯一 next opening：是，历史入口为 `P1 internal Renderer platform object no-object AppKit class availability preflight decision`，当前已由 downstream manifest 接续为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
