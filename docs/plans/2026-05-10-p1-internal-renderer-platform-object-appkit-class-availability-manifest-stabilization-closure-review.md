# P1 内部渲染器 platform object AppKit class availability 清单稳定化复核

日期：2026-05-10

状态：manifest closure / no-object class availability boundary

## 封账结论

[platform object AppKit class availability manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-class-availability-manifest.md) 已封账。当前 canonical endpoint 是 `CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft()`，runtime input 是 `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness`。

Downstream 已推进到 [AppKit main-thread admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-manifest.md)，当前项目 tail 以 main-thread admission manifest 为准。

本轮只证明 production native bridge 可观察 `NSWindow` / `NSView` class availability 并保持 no-object facts；不证明 platform object exists，不批准 AppKit object creation，不批准 native handle / pointer，不批准 Metal / QuartzCore，不批准 public API，不批准 backend-ready truth。

## 封账证据

- Production bridge 已有 `#import <AppKit/AppKit.h>`，并新增 no-object class lookup callable。
- 新增 callable：`cjgui_native_bridge_appkit_nswindow_class_available`、`cjgui_native_bridge_appkit_nsview_class_available`、`cjgui_native_bridge_appkit_class_lookup_no_object_admission`、`cjgui_native_bridge_platform_object_allocation_still_blocked`。
- Runtime owner 调用上述 callable 并脱水为 internal facts。
- AppKit class availability probe 观测 `NSWindow` / `NSView` class availability、class lookup no-object admission 与 platform allocation still blocked。
- package-adjacent / temporary `cjpm` package link probe 继续确认 runtime package config 未修改。
- 主包 `cjpm build --skip-script` 通过，说明新增 owner 可被 runtime package 编译。

## 保持的停止线

- 未创建 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- 未创建 `MTLDevice` / `MTLCommandQueue`。
- 未导入 Metal / QuartzCore。
- 未返回 `Class` / `id` / native pointer / handle。
- 未保存 class object。
- 未绑定 token 到 native object。
- 未调用 retain / release / destroy。
- 未提交 GPU work，未执行 render。
- 未修改 `runtime_state.cj`。
- 未新增 public API / diagnostics。
- 未修改 smoke native files。

## 主题同步

已同步：

- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/DESIGN_INTENT_INDEX.md`
- `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`
- `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`
- `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`
- upstream AppKit import manifest / closure / next-boundary 的 downstream 指向

## 后续入口

唯一后续入口：

`P1 internal Renderer platform object no-object AppKit main-thread admission preflight decision`

下一轮必须先做 docs-only preflight，评估是否允许 no-object AppKit main-thread admission。不得直接创建 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer`，不得创建 `MTLDevice` / `MTLCommandQueue`，不得返回 `Class` / `id` / native pointer / handle，不得新增 public API，不得执行 render / GPU submission，不得写 renderer state。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object AppKit class availability 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_appkit_class_availability.cj`；truth 固定为 AppKit class lookup / no-object facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、`Class` / `id` / pointer / handle、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer platform object no-object AppKit main-thread admission preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
