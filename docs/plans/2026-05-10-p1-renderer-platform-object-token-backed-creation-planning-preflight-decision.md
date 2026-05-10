# P1 内部渲染器 platform object token-backed creation planning 预检

日期：2026-05-10

状态：preflight / planning value boundary

## 预检结论

本轮可以打开 `P1 internal Renderer platform object token-backed object creation planning stage bundle`，但只能选择 planning value boundary。当前证据链已经具备 AppKit import、`NSWindow` / `NSView` class availability、AppKit platform object main-thread admission、native token issue / revoke、teardown admission fail-closed classification 与 platform object native callable no-object admission facts；这些证据足够定义 token-backed object creation 的准入合同，但仍不足以创建真实 AppKit object。

本轮选择 A：新增 internal runtime owner，固定 token-backed platform object creation planning facts；不新增 native platform object C ABI，不创建 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer`，不返回 `Class` / `id` / pointer / handle，不修改 `runtime/cjgui/cjpm.toml`。

## 证据链判断

- AppKit import manifest 证明 production bridge 可编译 AppKit import boundary，但不创建 object。
- AppKit class availability manifest 证明可观察 `NSWindow` / `NSView` class availability，但不返回或保存 `Class` / `id`。
- AppKit main-thread admission manifest 证明 future platform object creation 必须受 main-thread gate 约束，并且 creation 仍 blocked。
- Native token issue / revoke manifest 证明 bridge-local opaque token mechanics 可内部验证，但 token 不绑定 native object。
- Token table ownership / implementation / shell manifests 只固定 table safety policy，不授权 object table。
- Platform object native callable manifest 固定 no-object admission policy，不新增 resource callable。
- Teardown admission manifest 固定 destroy-not-supported、revoke-before-destroy 与 double-destroy fail-closed classification，不执行真实 destroy。

## 本轮选择

A 推荐并采纳：`P1 internal Renderer platform object token-backed creation planning value boundary bundle`

原因：

- token-backed object identity policy 可以先以 internal facts 固定。
- main-thread creation admission guard 可消费上游 `CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness`。
- allocation still blocked proof 必须继续存在。
- token issue-before-bind 必须继续 denial，避免无 object token 被误认为 resource token。
- revoke-before-destroy requirement 已有 teardown admission 支撑，但不能升格为 destroy permission。
- failure classification 可以固定为 class-unavailable / background-thread / allocation-blocked / token-table-disabled。

B 暂缓：no-object creation callable first implementation。需要先封账 token-backed planning。

C 拒绝：actual `NSWindow` / `NSView` / `NSApplication` creation。当前无 object table、无 destroy implementation、无 public contract，且本阶段硬边界禁止。

D 拒绝：返回 pointer / handle / `Class` / `id`。这会突破 no-object planning stop-line。

## 允许写集

- 新增 `runtime/cjgui/src/runtime_renderer_platform_object_token_backed_creation.cj`。
- 新增本阶段 closure、next-boundary、manifest 与 manifest closure。
- 同步 README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX 与三个 topic manifest。
- 给 AppKit import / class availability / main-thread admission / token issue-revoke / platform object native callable / teardown admission upstream 文档补 downstream 指向。

## 禁止写集

- 不修改 production native `.h/.m`。
- 不新增 native platform object C ABI。
- 不新增 native probe，除非只做 planning consistency scan；本轮不需要。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。
- 不触碰 `runtime_state.cj`。
- 不新增 public API / diagnostics。

## GitNexus 记录

编辑 runtime symbol 前已对上游 endpoint / default draft 运行 upstream impact：

- `CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft`

GitNexus 返回 not found / UNKNOWN，`impactedCount=0`，无 HIGH / CRITICAL。该结果符合近期新增 owner 尚未索引的预期；本轮用源码、`cjpm build`、existing probes、protected path scan、public declaration scan 与 native forbidden scan 兜底。

## 停止线

- no native platform object C ABI。
- no `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- no `MTLDevice` / `MTLCommandQueue`。
- no Metal / QuartzCore import。
- no `Class` / `id` / pointer / handle return。
- no native object storage。
- no object table implementation。
- no token binding to real native object。
- no public API / diagnostics。
- no renderer state write。
- no backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 AppKit main-thread admission 进入 token-backed object creation planning。
- 本轮是否改变 canonical tail / endpoint：预期改变为 `CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft()`。
- 本轮是否改变 owner / truth / stop-line：预期新增 `runtime_renderer_platform_object_token_backed_creation.cj`；truth 只固定 planning facts；stop-line 继续禁止 object creation、pointer / handle、public API、renderer state 与 backend-ready truth。
- 本轮是否改变唯一 next opening：预期封账后转为 `P1 internal Renderer platform object no-object creation callable preflight decision`。
- 是否同步 topic manifest：本轮需要同步。
- 已同步哪些 topic manifest：计划同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
