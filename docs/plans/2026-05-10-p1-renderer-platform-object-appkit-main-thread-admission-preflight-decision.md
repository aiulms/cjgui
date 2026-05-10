# P1 内部渲染器 platform object AppKit main-thread admission 预检

日期：2026-05-10

状态：preflight / no-object AppKit main-thread admission

## 预检结论

选择 A：`P1 internal Renderer platform object no-object AppKit main-thread admission first implementation bundle`。

当前上游 `CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness` 已封账，production bridge 已允许 AppKit import 与 `NSWindow` / `NSView` class lookup facts。本阶段可以新增 no-object main-thread admission callable，用于固定 future AppKit platform object creation 必须受 main-thread gate 约束；但仍不创建 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer`，不返回 `Class` / `id` / pointer / handle，不导入 Metal / QuartzCore，不修改 `runtime/cjgui/cjpm.toml`，不扩 public API，不写 renderer state。

## 选择理由

- `pthread_main_np()` 已在既有 main-thread callable 与 token issue/revoke 路径中使用，适合继续表达 no-object current-thread classification。
- 上一阶段 AppKit class availability 已证明 production bridge 的 AppKit import 与 class lookup 可编译；本阶段不需要新增 framework 或 package config。
- 新增 callable 只返回 `int32_t` classification：main-thread required、current main-thread admitted、background-thread denied、platform object creation still blocked。
- Runtime owner 只消费 `CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness`，只把 C ABI 返回值脱水为 internal facts，不进入 public surface。
- Probe 可复用 AppKit import / class availability / package link / no-resource call 链路，并新增专门的 main-thread admission probe。

## 允许实现

- `cjgui_native_bridge_appkit_platform_object_main_thread_required(void)` -> `int32_t`
- `cjgui_native_bridge_appkit_platform_object_main_thread_admitted(void)` -> `int32_t`
- `cjgui_native_bridge_appkit_platform_object_background_thread_denied(void)` -> `int32_t`
- `cjgui_native_bridge_appkit_platform_object_creation_still_blocked(void)` -> `int32_t`
- Runtime owner：`runtime/cjgui/src/runtime_renderer_platform_object_appkit_main_thread_admission.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft()`

## 继续禁止

- 创建 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- 导入或使用 Metal / QuartzCore。
- 返回 `Class` / `id` / native pointer / native handle。
- 保存 native object 或 class object。
- 修改 `runtime/cjgui/cjpm.toml`。
- 修改 smoke native files。
- 新增 public API / public diagnostics。
- 修改 `runtime/cjgui/src/runtime_state.cj`。
- 写 renderer state、提交 GPU work、执行 render 或声明 backend-ready truth。

## GitNexus 记录

已对上游 endpoint / default draft 运行 upstream impact：

- `CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness`：not found / `UNKNOWN`，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft`：not found / `UNKNOWN`，`impactedCount=0`。
- `cjgui_native_bridge_surface_capabilities`：not found / `UNKNOWN`，`impactedCount=0`。

未出现 HIGH / CRITICAL；按近期新增 owner 未索引处理，本轮用源码、build、probe 与 forbidden scan 兜底。

## 同形边界刹车

不得把 AppKit main-thread admission、AppKit class availability、AppKit import、teardown admission、main-thread query 或 smoke evidence 包装成 platform object creation permission、AppKit object permission、native handle permission、Metal permission、backend-ready permission、public API permission、receipt、record 或 publication。Main-thread admission 只证明 future platform object creation 必须受 main-thread gate 约束，不证明对象存在。

## 设计意图出口自检

- 本轮是否改变主题状态：是，AppKit class availability 后续入口进入 no-object main-thread admission implementation。
- 本轮是否改变 canonical tail / endpoint：预期是，新增 `CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft()`。
- 本轮是否改变 owner / truth / stop-line：预期是，新增 owner 只承载 AppKit platform object main-thread admission no-object facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、`Class` / `id` / pointer / handle、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：预期是，manifest 后转为 `P1 internal Renderer platform object token-backed object creation planning preflight decision`。
- 是否同步 topic manifest：预期同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
