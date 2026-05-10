# P1 内部渲染器 platform object no-object creation callable 预检

日期：2026-05-10

状态：preflight / no-object callable first slice

## 预检结论

本轮可以打开 platform object no-object creation callable runway。上游 `CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness` 已固定 token-backed creation planning、main-thread gate、allocation still blocked proof、token issue-before-bind denial 与 revoke-before-destroy requirement；这些证据足以新增一组 fail-closed / no-object production C ABI。

本轮选择 A：`P1 internal Renderer platform object no-object creation callable first implementation bundle`。允许新增四个只返回 `int32_t` classification 的 production native callable，并由 runtime internal owner 脱水成 facts。该选择不批准真实 AppKit object allocation，不批准 native pointer / handle，不批准 public API，不批准 renderer state write。

## 允许新增的 callable

- `cjgui_native_bridge_platform_object_create_no_object_admission(void)`
- `cjgui_native_bridge_platform_object_create_requires_main_thread(void)`
- `cjgui_native_bridge_platform_object_create_requires_token_contract(void)`
- `cjgui_native_bridge_platform_object_create_allocation_blocked(void)`

这些 callable 只能返回 deterministic integer facts。它们表达 creation entry 仍被阻断、main-thread gate 必须存在、token contract 必须存在、allocation 仍 blocked。

## Runtime 方案

- 新增 owner：`runtime/cjgui/src/runtime_renderer_platform_object_no_object_creation_call.cj`
- Runtime input：`CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft()`

owner 只允许调用 no-object creation callable，并把返回值脱水为 internal facts；不得新增 public API，不得写 renderer state，不得把 facts 包成 platform object permission。

## Probe 方案

新增 `runtime/cjgui/native/scripts/verify_native_bridge_platform_object_no_object_creation.sh`，验证：

- 四个新增符号存在并可调用。
- 返回值符合 fail-closed / no-object classification。
- native source 中没有 `alloc` / `init` / `new` 创建 AppKit object。
- 没有 Metal / QuartzCore import。
- 没有 pointer / handle / `Class` / `id` return 或 static storage。

## GitNexus 记录

编辑前对上游 `CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness` 与 `cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft` 运行 upstream impact。GitNexus 返回 not found / UNKNOWN，`impactedCount=0`，无 HIGH / CRITICAL；按近期新增 owner 未索引记录，并用源码、build、probe 与 scan 兜底。

## 停止线

- 不创建 `NSWindow` / `NSView` / `NSApplication`。
- 不创建 `CALayer` / `CAMetalLayer`。
- 不创建 `MTLDevice` / `MTLCommandQueue`。
- 不调用 `alloc` / `init` / `new`。
- 不导入 Metal / QuartzCore。
- 不返回 `Class` / `id` / pointer / handle。
- 不保存 native object 或 class object。
- 不实现 object table。
- 不把 token 绑定到真实 native object。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。
- 不新增 public API / diagnostics。
- 不触碰 `runtime_state.cj`。
- 不写 renderer state。
- 不声明 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，允许从 token-backed planning 进入 no-object creation callable first slice。
- 本轮是否改变 canonical tail / endpoint：预期会新增 `CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：预期新增 `runtime_renderer_platform_object_no_object_creation_call.cj`；truth 只允许 no-object creation fail-closed facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、pointer / handle、public API、renderer state 与 backend-ready truth。
- 本轮是否改变唯一 next opening：预期封账后转为 `P1 internal Renderer platform object real NSView allocation preflight decision`；当前已由 real `NSView` allocation feasibility stage 接续，唯一后续入口为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：待后续 manifest stabilization 同步。
- 已同步哪些 topic manifest：待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
