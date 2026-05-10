# P1 内部渲染器 platform object AppKit import 后续边界

日期：2026-05-10

状态：后续边界 / docs-only

## 当前结论

AppKit import / no-object callable 与 internal owner 已实现并通过阶段 probe / build。当前应选择：

`P1 internal Renderer platform object AppKit import manifest stabilization bundle`

manifest stabilization 完成后，唯一后续入口建议转为：

`P1 internal Renderer platform object no-object AppKit class availability preflight decision`

该历史入口已由 [platform object AppKit class availability manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-class-availability-manifest.md) 接续并封账；当前 Renderer 唯一后续入口已转为 `P1 internal Renderer platform object no-object AppKit main-thread admission preflight decision`。

## 选择理由

- Production bridge 已可直接 import AppKit 并通过 Objective-C compile。
- 新增 callable 只返回 import available、no-object admission 与 platform object still blocked facts。
- Runtime owner 已能在 internal-only 范围调用这些 no-object C ABI 并脱水 facts。
- 新探针与 package-adjacent / temporary `cjpm` package link probe 已确认 no-object facts 可观察。
- 当前仍没有 AppKit class availability query、AppKit object creation、platform object token、native pointer / handle、Metal / QuartzCore、renderer state write 或 public API。

## 暂缓与拒绝

- 暂缓：`P1 internal Renderer platform object no-object AppKit class availability preflight decision`，必须在 manifest 封账后单独开。
- 暂缓：`P1 internal Renderer platform object token-backed creation preflight decision`，因为当前只有 import / no-object facts，没有 class availability 与 object lifecycle boundary。
- 拒绝：direct `NSWindow` / `NSView` / `CAMetalLayer` / `CALayer` creation。
- 拒绝：Metal / QuartzCore import 或 `MTLDevice` / `MTLCommandQueue`。
- 拒绝：native pointer / handle return。
- 拒绝：public API / public diagnostics。
- 拒绝：renderer state write、GPU submission、render execution 或 backend-ready truth。

## 下游接续

已由 downstream AppKit class availability stage 承接：新增 no-object class lookup callable 与 `CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft()`，只观察 `NSWindow` / `NSView` class availability，不返回 `Class` / `id` / pointer / handle，不创建 AppKit / Metal / QuartzCore object。

## 同形边界刹车

不得把 AppKit import、no-object callable、teardown admission、main-thread query 或 smoke evidence 包装成 platform object creation permission、AppKit object permission、native handle permission、Metal permission、backend-ready permission、public API permission、receipt、record 或 publication。AppKit import 只证明 production bridge 可编译并观察 no-object facts，不证明 object exists。

## 设计意图出口自检

- 本轮是否改变主题状态：是，AppKit import 已进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 是 `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_platform_object_appkit_import.cj`；truth 为 AppKit import / no-object facts；stop-line 禁止 AppKit object、Metal / QuartzCore、pointer / handle、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：是，短线进入 manifest stabilization；历史 manifest 后续入口为 `P1 internal Renderer platform object no-object AppKit class availability preflight decision`，当前已由 downstream manifest 接续为 `P1 internal Renderer platform object no-object AppKit main-thread admission preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
