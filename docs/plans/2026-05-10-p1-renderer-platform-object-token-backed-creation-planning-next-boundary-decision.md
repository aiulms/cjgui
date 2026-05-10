# P1 内部渲染器 platform object token-backed creation planning 后续边界

日期：2026-05-10

状态：next-boundary / planning complete

## 结论

token-backed object creation planning value boundary 已足够进入 manifest stabilization。当前 owner 固定了 future platform object creation 的 token-backed identity、main-thread guard、allocation still blocked、token issue-before-bind denial、revoke-before-destroy requirement 与 fail-closed failure classification，但仍不创建任何 platform object。

## 候选判断

A 采纳：`P1 internal Renderer platform object token-backed creation planning manifest stabilization bundle`

原因：planning facts 已由 internal owner 表达，下一步应先封账并同步索引。

B 推荐作为封账后唯一入口：`P1 internal Renderer platform object no-object creation callable preflight decision`

原因：若继续推进，只能先评估 no-object creation callable 是否可表达 creation admission / still blocked / token-binding denied facts；不得直接创建 AppKit object。

C 拒绝：direct AppKit object creation。

原因：本轮没有 object table implementation、没有 destroy implementation、没有 token-to-object binding policy implementation、没有 public API contract。

D 拒绝：public API / diagnostics。

原因：当前 facts 只在 internal owner 链内流转，不进入 public runtime surface。

## 后续入口

唯一后续入口：

`P1 internal Renderer platform object no-object creation callable preflight decision`

该入口必须从 preflight 开始，评估是否允许 no-object creation callable；不得创建 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer`，不得返回 native pointer / handle / `Class` / `id`，不得修改 `runtime/cjgui/cjpm.toml`，不得新增 public API，不得写 renderer state。

## 设计意图出口自检

- 本轮是否改变主题状态：是，token-backed object creation planning 从 preflight 进入 manifest stabilization runway。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_platform_object_token_backed_creation.cj`；truth 为 planning facts；stop-line 继续禁止 object creation、pointer / handle、public API、renderer state 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer platform object no-object creation callable preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
