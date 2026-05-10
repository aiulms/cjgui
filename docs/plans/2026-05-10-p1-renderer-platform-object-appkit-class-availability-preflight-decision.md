# P1 内部渲染器 platform object AppKit class availability 预检

日期：2026-05-10

状态：preflight decision / no-object class lookup

## 预检结论

本轮可以打开 platform object AppKit class availability runway，并选择 A 路线：实现 no-object AppKit class availability callable。上一轮 `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness` 已证明 production bridge 可 import AppKit 并保持 no-object facts；本轮只允许继续观察 `NSWindow` / `NSView` class 是否可见，不创建、保存或返回任何 class object、native object、pointer 或 handle。

该结论不批准 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer` allocation，不批准 Metal / QuartzCore，不批准 public API，不批准 renderer state write，不批准 backend-ready truth。

## 选择 A 的理由

- production bridge 已有 `#import <AppKit/AppKit.h>` 与 no-object import callable。
- class availability 可以通过 `NSClassFromString` 读取 class lookup 结果，并只脱水成 `int32_t` classification。
- `NSClassFromString` 不需要 `alloc` / `init` / `new`，不创建 window、view、application、layer、Metal device 或 command queue。
- 新增 callable 可以继续沿用 `cjgui_native_bridge_*` prefix，避免 smoke 名称与 public runtime API。
- package link route、isolated FFI probe、runtime internal owner 和 no-resource call probe 都已有 no-object callable 扩展模式。

## 允许新增的 native callable

- `cjgui_native_bridge_appkit_nswindow_class_available(void)` -> `int32_t`
- `cjgui_native_bridge_appkit_nsview_class_available(void)` -> `int32_t`
- `cjgui_native_bridge_appkit_class_lookup_no_object_admission(void)` -> `int32_t`
- `cjgui_native_bridge_platform_object_allocation_still_blocked(void)` -> `int32_t`

返回值只允许是整数 classification，不允许返回 `Class`、`id`、native pointer、native handle 或 token。

## 实现护栏

- 允许 `NSClassFromString(@"NSWindow")` / `NSClassFromString(@"NSView")` 一类 class lookup。
- 不允许保存 `Class` object 到 static/global/runtime state。
- 不允许 `alloc` / `init` / `new`。
- 不允许创建 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- 不允许导入 Metal / QuartzCore。
- 不允许修改 `runtime/cjgui/cjpm.toml`。
- 不允许修改 smoke native files。
- 不允许新增 public API / public diagnostics。
- 不允许触碰 `runtime/cjgui/src/runtime_state.cj`。

## Runtime owner 方案

- 新增 owner：`runtime/cjgui/src/runtime_renderer_platform_object_appkit_class_availability.cj`
- Runtime input：`CjguiInternalRendererNoPlatformObjectAppKitImportReadiness`
- Upstream draft：`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft()`
- Endpoint：`CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft()`

owner 只调用 class availability callable 并脱水为 internal facts：`NSWindow` class observed、`NSView` class observed、class lookup no-object admission observed、platform allocation still blocked observed、no pointer / handle、no object allocation、no Metal / QuartzCore、no public surface、no renderer state write。

## GitNexus impact

- `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness`：`UNKNOWN / not found`，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft`：`UNKNOWN / not found`，`impactedCount=0`。
- `cjgui_native_bridge_surface_capabilities`：`UNKNOWN / not found`，`impactedCount=0`。

这些符号属于近期新增 owner / native C ABI，当前索引未识别；本轮按规则记录为未索引，并继续使用源码读取、build、probe 与 forbidden scan 兜底。未出现 HIGH / CRITICAL。

## 预检选择

选择：

`P1 internal Renderer platform object no-object AppKit class availability first implementation bundle`

拒绝：

- direct `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer` creation。
- Metal / QuartzCore import。
- pointer / handle / `Class` / `id` return。
- public API / public diagnostics。
- renderer state write / backend-ready truth。

## 后续同步要求

实现后必须同步 README、tracker、plans README、runtime README、`DESIGN_INTENT_INDEX.md`、`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`，并给 AppKit import manifest / closure / next-boundary 补 downstream 指向。

## 设计意图出口自检

- 本轮是否改变主题状态：是，AppKit import 后续入口进入 class availability preflight。
- 本轮是否改变 canonical tail / endpoint：预检阶段暂未最终改变；若实现成功将新增 `CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft()`。
- 本轮是否改变 owner / truth / stop-line：预检阶段选择新增 owner；truth 仅限 class availability no-object facts；stop-line 继续禁止 object allocation、Metal / QuartzCore、pointer / handle、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：预检阶段暂未最终改变；若实现通过将进入 manifest stabilization。
- 是否同步 topic manifest：将在 closure 与 manifest 阶段同步。
- 已同步哪些 topic manifest：预检阶段待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
