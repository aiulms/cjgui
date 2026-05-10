# P1 内部渲染器 platform object AppKit class availability 后续边界

日期：2026-05-10

状态：后续边界 / docs-only

## 当前结论

AppKit class availability / no-object callable 与 internal owner 已实现并通过阶段 probe / build。当前应选择：

`P1 internal Renderer platform object AppKit class availability manifest stabilization bundle`

manifest stabilization 完成后，唯一后续入口建议转为：

`P1 internal Renderer platform object no-object AppKit main-thread admission preflight decision`

Downstream 已由 [AppKit main-thread admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-manifest.md) 消费，当前 canonical tail 后续入口为 `P1 internal Renderer platform object token-backed object creation planning preflight decision`。

## 选择理由

- Production bridge 已可直接 import AppKit 并通过 `NSClassFromString` 观察 `NSWindow` / `NSView` class availability。
- 新增 callable 只返回 class availability、class lookup no-object admission 与 allocation still-blocked integer facts。
- Runtime owner 已能在 internal-only 范围调用这些 no-object C ABI 并脱水 facts。
- class availability probe、package-adjacent link probe、temporary `cjpm` package link probe 与 no-resource call probe 均已观测新增 facts。
- 当前仍没有 AppKit object creation、platform object token、native pointer / handle、Metal / QuartzCore、renderer state write 或 public API。

## 暂缓与拒绝

- 暂缓：`P1 internal Renderer platform object no-object AppKit main-thread admission preflight decision`，必须在 manifest 封账后单独开。
- 暂缓：`P1 internal Renderer platform object token-backed creation preflight decision`，因为当前只有 class availability facts，没有 AppKit object lifecycle boundary。
- 拒绝：direct `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer` creation。
- 拒绝：Metal / QuartzCore import 或 `MTLDevice` / `MTLCommandQueue`。
- 拒绝：`Class` / `id` / native pointer / native handle return。
- 拒绝：public API / public diagnostics。
- 拒绝：renderer state write、GPU submission、render execution 或 backend-ready truth。

## 同形边界刹车

不得把 AppKit class availability、AppKit import、no-object callable、teardown admission、main-thread query 或 smoke evidence 包装成 platform object creation permission、AppKit object permission、native handle permission、Metal permission、backend-ready permission、public API permission、receipt、record 或 publication。AppKit class availability 只证明 production bridge 可观察类可见性并保持 no-object facts，不证明 object exists。

## 设计意图出口自检

- 本轮是否改变主题状态：是，AppKit class availability 已进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 是 `CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_platform_object_appkit_class_availability.cj`；truth 为 AppKit class availability / no-object still-blocked facts；stop-line 禁止 AppKit object、Metal / QuartzCore、`Class` / `id` / pointer / handle、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：是，短线进入 manifest stabilization，manifest 后转为 `P1 internal Renderer platform object no-object AppKit main-thread admission preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
