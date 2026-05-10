# P1 内部渲染器 platform object AppKit import 清单稳定化复核

日期：2026-05-10

状态：manifest closure / AppKit import no-object boundary

## 封账结论

[platform object AppKit import manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-import-manifest.md) 已封账。当前 canonical endpoint 是 `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft()`，runtime input 是 `CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness`。

Downstream 已推进到 [AppKit class availability manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-class-availability-manifest.md)，并继续到 [AppKit main-thread admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-manifest.md)。

本轮只证明 production native bridge 可 import AppKit 并观察 no-object facts；不证明 platform object exists，不批准 AppKit object creation，不批准 native handle / pointer，不批准 Metal / QuartzCore，不批准 public API，不批准 backend-ready truth。

## 封账证据

- Production bridge 直接 `#import <AppKit/AppKit.h>`。
- 新增 no-object callable：`cjgui_native_bridge_appkit_import_available`、`cjgui_native_bridge_appkit_no_object_admission`、`cjgui_native_bridge_platform_object_create_still_blocked`。
- Runtime owner 调用上述 callable 并脱水为 internal facts。
- AppKit import probe 观测 import available、no-object admission 与 platform object still blocked。
- package-adjacent / temporary `cjpm` package link probe 继续确认 runtime package config 未修改。
- 主包 `cjpm build --skip-script` 通过，说明新增 owner 可被 runtime package 编译。

## 保持的停止线

- 未创建 `NSWindow` / `NSView` / `CAMetalLayer` / `CALayer`。
- 未创建 `MTLDevice` / `MTLCommandQueue`。
- 未导入 Metal / QuartzCore。
- 未返回 native pointer / handle。
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
- upstream teardown / platform object manifests 的 downstream 指向

## 后续入口

本 closure 的历史后续入口已由 downstream AppKit class availability stage 承接并封账：

`P1 internal Renderer platform object no-object AppKit class availability preflight decision`

当前 Renderer 唯一后续入口已继续转为：

`P1 internal Renderer platform object token-backed object creation planning preflight decision`

下游只允许观察 no-object class availability 与 main-thread admission facts，并继续维持 no object / no pointer / no public / no renderer state stop-line。不得直接创建 `NSWindow` / `NSView` / `CAMetalLayer` / `CALayer`，不得创建 `MTLDevice` / `MTLCommandQueue`，不得返回 native pointer / handle / `Class` / `id`，不得新增 public API，不得执行 render / GPU submission，不得写 renderer state。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object AppKit import 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_appkit_import.cj`；truth 固定为 AppKit import / no-object facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、pointer / handle、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，历史入口为 `P1 internal Renderer platform object no-object AppKit class availability preflight decision`，当前已由 downstream manifest 接续为 `P1 internal Renderer platform object no-object AppKit main-thread admission preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
