# P1 内部渲染器 platform object token-backed creation planning 值边界复核

日期：2026-05-10

状态：closure / planning value boundary

## 实现结论

本轮按 preflight 选择 planning value boundary，新增 `runtime/cjgui/src/runtime_renderer_platform_object_token_backed_creation.cj`。该 owner 只消费 `CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness`，固定 token-backed platform object creation 的准入合同、main-thread guard、allocation still blocked proof、token issue-before-bind denial、revoke-before-destroy requirement 与 fail-closed failure classification。

本轮未新增 native platform object C ABI，未修改 production native `.h/.m`，未创建任何 AppKit / QuartzCore / Metal object，未返回 `Class` / `id` / pointer / handle，未实现 object table，未把 token 绑定到真实 native object。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_token_backed_creation.cj`
- Runtime input：`CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness`
- Endpoint：`CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft()`
- Actual route：planning value boundary

## 固定 facts

- platform object creation intent。
- token-backed object identity policy。
- main-thread creation admission guard。
- allocation still blocked proof。
- no-pointer / no-handle return policy。
- token issue-before-bind denial。
- revoke-before-destroy requirement。
- class-unavailable failure classification。
- background-thread failure classification。
- allocation-blocked failure classification。
- token-table-disabled failure classification。
- no-native-platform-object-C-ABI facts。
- no-platform-object-token-backed-creation readiness facts。

## 停止线复核

- 不新增 native platform object C ABI。
- 不创建 `NSWindow` / `NSView` / `NSApplication`。
- 不创建 `CALayer` / `CAMetalLayer`。
- 不创建 `MTLDevice` / `MTLCommandQueue`。
- 不返回 `Class` / `id` / native pointer / native handle。
- 不保存 native object。
- 不实现 object table。
- 不绑定 token 到真实 native object。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。
- 不新增 public API / diagnostics。
- 不触碰 `runtime_state.cj`。
- 不写 renderer state。
- 不声明 backend-ready truth。

## GitNexus 记录

编辑前对 `CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness` 与 `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft` 运行 upstream impact。GitNexus 返回 not found / UNKNOWN，`impactedCount=0`，无 HIGH / CRITICAL；按近期新增 owner 未索引记录，并用源码、build、probe 与 scan 兜底。

## 验证记录

本阶段验证已完成：

- AppKit import probe、AppKit class availability probe、AppKit main-thread admission probe、teardown admission probe、token issue/revoke probe、no-resource call probe、isolated FFI probe、package link probe、`cjpm` package link probe、skeleton compile、symbol probe 与 `cjpm` boundary 均通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-platform-object-token-backed-creation-planning-target --skip-script` 通过；输出仍包含既有 unused warning，不构成本阶段失败。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check` 通过。
- Markdown absolute link missing target check：`missing_count=0`。
- README / tracker / plans README / runtime README / `DESIGN_INTENT_INDEX.md` / 三个 topic manifest reachability：`missing_count=0`。
- 中文标题正文抽查：`problem_count=0`。
- `runtime_state.cj` 行数仍为 `10065`，且 `runtime/cjgui/cjpm.toml`、smoke native files、`runtime_state.cj` 无 diff。
- Comment-aware public declaration scan 仍只发现 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- Native forbidden scan 未发现 Metal / QuartzCore import、AppKit / QuartzCore / Metal object allocation、retain / release、drawable / command buffer / commit / present、pointer / handle / `Class` / `id` 返回或静态保存模式。
- Owner header / stop-line scan 通过。
- GitNexus `detect_changes(scope=unstaged)` 返回 `Risk level: low`、`Affected processes: 0`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，token-backed object creation planning value boundary 已新增。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_token_backed_creation.cj`；truth 固定为 planning facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、pointer / handle、public API、renderer state 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，closure 后进入 manifest stabilization，再转向 `P1 internal Renderer platform object no-object creation callable preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
