# P1 内部渲染器 platform object no-object creation callable 阶段复核

日期：2026-05-10

状态：closure / no-object callable first implementation

## 实现结论

本轮按 preflight 选择 no-object callable first slice。Production native bridge 新增四个 platform object creation fail-closed callable，runtime 新增 internal owner 观察这些 callable 并脱水为 facts。

该阶段只证明 creation entry 仍被 no-object admission、main-thread requirement、token contract requirement 与 allocation blocked 分类约束；不创建任何 AppKit / QuartzCore / Metal object，不返回 `Class` / `id` / pointer / handle，不保存 native object，不实现 object table，不把 token 绑定到真实 native object。

## 实际写集

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/native/scripts/verify_native_bridge_platform_object_no_object_creation.sh`
- `runtime/cjgui/src/runtime_renderer_platform_object_no_object_creation_call.cj`
- 相关 native probe allowlist / package link probe。
- 本阶段 preflight、closure、next-boundary、manifest 与 manifest closure。
- README / tracker / plans README / runtime README / design intent index / topic manifests。

`runtime/cjgui/cjpm.toml` 未修改。Smoke native files 未修改。`runtime_state.cj` 未修改。

## Native callable

- `cjgui_native_bridge_platform_object_create_no_object_admission(void)` -> `int32_t`
- `cjgui_native_bridge_platform_object_create_requires_main_thread(void)` -> `int32_t`
- `cjgui_native_bridge_platform_object_create_requires_token_contract(void)` -> `int32_t`
- `cjgui_native_bridge_platform_object_create_allocation_blocked(void)` -> `int32_t`

Return contract：

- `27`：creation entry 只允许 no-object admission。
- `28`：future creation 必须经过 main-thread gate。
- `29`：future creation 必须经过 token contract。
- `-24`：allocation 仍 fail-closed blocked。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_no_object_creation_call.cj`
- Runtime input：`CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft()`
- Actual route：internal no-object FFI call owner

## Probe 记录

新增 probe 先在 RED 阶段确认缺少 `cjgui_native_bridge_platform_object_create_no_object_admission` 会失败；实现后 GREEN 阶段通过并观察：

- no-object admission observed。
- requires main-thread observed。
- requires token contract observed。
- allocation blocked observed。
- appkit object allocated false。
- native pointer returned false。
- Metal / QuartzCore imported false。
- public API modified false。

## 停止线复核

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

## GitNexus 记录

编辑前对 `CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness` 与 `cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft` 运行 upstream impact。GitNexus 返回 not found / UNKNOWN，`impactedCount=0`，无 HIGH / CRITICAL；按近期新增 owner 未索引记录，并用源码、build、probe 与 scan 兜底。

## 验证记录

本阶段最终验证以 manifest stabilization closure 的命令输出为准，目标包括新增 no-object creation probe、既有 native bridge probes、`cjpm build`、macOS smoke、diff / Markdown / public declaration / native forbidden / protected path / GitNexus detect changes。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object no-object creation callable first slice 已实现。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_no_object_creation_call.cj`；truth 固定为 no-object creation fail-closed facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、pointer / handle、object table、token binding、public API、renderer state 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，closure 后进入 manifest stabilization；当前已由 real `NSView` allocation feasibility stage 接续，唯一后续入口转向 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
