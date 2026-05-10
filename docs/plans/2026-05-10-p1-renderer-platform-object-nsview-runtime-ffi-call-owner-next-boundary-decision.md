# P1 渲染器 platform object NSView runtime FFI call owner 下一阶段选择

日期：2026-05-10

状态：next-boundary decision / 进入 renderer backend shell integration 预检

## 本轮选择

选择 A：

`P1 internal Renderer platform object NSView renderer backend shell integration preflight decision`

选择理由：

- `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness` 已成为当前 platform object runtime-call tail。
- Runtime owner 已在 internal-only 范围内复用既有 `foreign func` declarations，并执行局部 create / classify / destroy / stale / double-destroy 序列。
- Runtime-adjacent probe 已覆盖 create -> classify valid -> occupied count -> destroy -> stale -> double destroy fail-closed。
- Token 仍只在函数局部使用，不返回 public surface，不写 renderer state。
- `runtime/cjgui/cjpm.toml` 仍未修改；package config integration 不是本轮 truth。

## 拒绝路线

- 拒绝直接进入 public API。
- 拒绝把 `NSView` token 暴露成 pointer / handle / `id` / `Class`。
- 拒绝直接创建 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- 拒绝导入 Metal / QuartzCore。
- 拒绝直接进入 command queue、drawable、command buffer、GPU submission 或 render execution。
- 拒绝写 renderer state 或触碰 `runtime_state.cj`。

## 下一阶段边界

下一阶段只能是 docs-only preflight，判断 `NSView` runtime-call facts 是否足以进入 renderer backend shell integration planning。它不得把 `NSView` token 解释成 backend-ready resource，不得创建 layer / Metal resource，不得新增 public diagnostics，不得绕过 main-thread / token / teardown / package link stop-line。

## 下游完成记录

下游 [NSView backend shell integration manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-backend-shell-integration-manifest.md) 已完成。新的唯一 next opening 为 `P1 internal Renderer CAMetalLayer attachment planning preflight decision`，但仍只允许 planning preflight，不授权 `CAMetalLayer` / `CALayer` creation、Metal / QuartzCore import、renderer state write、public API、GPU submission、render execution 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime internal `NSView` FFI call owner 已封账，下一阶段转入 renderer backend shell integration 预检。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_platform_object_nsview_runtime_call.cj`；truth 仅限 runtime-call facts；stop-line 继续禁止 public / pointer / window / layer / Metal / renderer state / render。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer platform object NSView renderer backend shell integration preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
