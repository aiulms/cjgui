# P1 内部渲染器 platform object AppKit main-thread admission 后续边界

日期：2026-05-10

状态：后续边界 / docs-only

## 当前结论

AppKit main-thread admission / no-object callable 与 internal owner 已实现，当前应选择：

`P1 internal Renderer platform object AppKit main-thread admission manifest stabilization bundle`

manifest stabilization 完成后，唯一后续入口建议转为：

`P1 internal Renderer platform object token-backed object creation planning preflight decision`

## 选择理由

- Production bridge 已可表达 AppKit platform object creation 的 main-thread required / admitted / background denied / still blocked facts。
- 新增 callable 只返回 `int32_t` classification，不创建 AppKit / QuartzCore / Metal 对象。
- Runtime owner 已能在 internal-only 范围调用这些 no-object C ABI 并脱水 facts。
- 当前仍没有 platform object token-backed creation、native pointer / handle、`Class` / `id` return、renderer state write 或 public API。
- 下一步若继续前进，只能先做 token-backed object creation planning；不得直接创建 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer`。

## 暂缓与拒绝

- 暂缓：`P1 internal Renderer platform object token-backed object creation planning preflight decision`，必须在 manifest 封账后单独开。
- 暂缓：actual platform object creation，因为当前只有 no-object main-thread admission facts。
- 拒绝：direct `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer` creation。
- 拒绝：Metal / QuartzCore import 或 `MTLDevice` / `MTLCommandQueue`。
- 拒绝：`Class` / `id` / native pointer / native handle return。
- 拒绝：public API / public diagnostics。
- 拒绝：renderer state write、GPU submission、render execution 或 backend-ready truth。

## 同形边界刹车

不得把 AppKit main-thread admission、AppKit class availability、AppKit import、teardown admission、main-thread query 或 smoke evidence 包装成 platform object creation permission、AppKit object permission、native handle permission、Metal permission、backend-ready permission、public API permission、receipt、record 或 publication。AppKit main-thread admission 只证明未来对象创建必须受主线程准入约束，不证明 object exists。

## 设计意图出口自检

- 本轮是否改变主题状态：是，AppKit main-thread admission 已进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 是 `CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_platform_object_appkit_main_thread_admission.cj`；truth 为 AppKit platform object main-thread gate / creation still-blocked facts；stop-line 禁止 AppKit object、Metal / QuartzCore、`Class` / `id` / pointer / handle、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：是，短线进入 manifest stabilization，manifest 后转为 `P1 internal Renderer platform object token-backed object creation planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
