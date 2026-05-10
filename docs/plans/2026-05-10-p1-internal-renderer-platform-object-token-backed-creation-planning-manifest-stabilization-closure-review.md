# P1 内部渲染器 platform object token-backed creation planning 清单封账复核

日期：2026-05-10

状态：manifest stabilization closure / planning value boundary

## 封账结论

token-backed creation planning stage 已完成 manifest stabilization。当前 canonical tail 固定为：

- Endpoint：`CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft()`
- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_token_backed_creation.cj`
- Runtime input：`CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness`

本阶段只证明 token-backed AppKit platform object creation 的 planning contract 已在 internal runtime 链路内固定，不证明 platform object exists，不批准 native object creation。

## 固定事实

- platform object creation intent 已存在，但仍是 planning intent。
- token-backed object identity policy 已固定。
- main-thread creation admission guard 已固定。
- allocation still blocked proof 已固定。
- no-pointer / no-handle return policy 已固定。
- token issue-before-bind denial 已固定。
- revoke-before-destroy requirement 已固定。
- class-unavailable / background-thread / allocation-blocked / token-table-disabled failure classification 已固定。
- `runtime/cjgui/cjpm.toml` 未修改。
- Smoke native files 未修改。
- `runtime_state.cj` 未修改。

## 停止线

- 不新增 native platform object C ABI。
- 不创建 `NSWindow` / `NSView` / `NSApplication`。
- 不创建 `CALayer` / `CAMetalLayer`。
- 不创建 `MTLDevice` / `MTLCommandQueue`。
- 不导入 Metal / QuartzCore。
- 不返回 `Class` / `id` / pointer / handle。
- 不保存 native object。
- 不实现 object table。
- 不把 token 绑定到真实 native object。
- 不新增 public API / diagnostics。
- 不写 renderer state。
- 不声明 backend-ready truth。

## 封账验证

本阶段最终验证已完成：

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
- GitNexus upstream impact 对上游 endpoint / default draft 已记录 not found / UNKNOWN、`impactedCount=0`，无 HIGH / CRITICAL；GitNexus `detect_changes(scope=unstaged)` 返回 `Risk level: low`、`Affected processes: 0`。

## 下游指向

唯一后续入口固定为：

该入口已由 no-object callable boundary 与 real `NSView` allocation feasibility stage 接续。当前唯一后续入口转为：

`P1 internal Renderer platform object token-backed NSView object table preflight decision`

该入口已由 no-object callable boundary 与 real `NSView` allocation feasibility stage 接续；后续仍必须从 token-backed `NSView` object table preflight 开始，不得跳过前置事实直接保存 AppKit object。

## 设计意图出口自检

- 本轮是否改变主题状态：是，token-backed creation planning 从 value boundary 进入 manifest stabilization closure。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_token_backed_creation.cj`；truth 固定为 token-backed creation planning facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、pointer / handle、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，当时固定为 `P1 internal Renderer platform object no-object creation callable preflight decision`；当前已由下游 no-object creation callable manifest 与 real `NSView` allocation feasibility stage 接续，唯一后续入口转为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
