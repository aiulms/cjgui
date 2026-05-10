# P1 内部渲染器 platform object 真实 NSView allocation 下一段入口

日期：2026-05-10

状态：next boundary / feasibility-only

## 结论

本轮只完成 isolated `NSView` allocation feasibility + planning owner，不进入 production immediate-release callable，也不进入 token-backed retention implementation。

该入口已由 [token-backed NSView object table stage](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-manifest.md) 接续。当前唯一下一段入口转为：

`P1 internal Renderer platform object token-backed NSView create/destroy first slice preflight decision`

## 选择理由

- isolated `NSView` allocation 可作为 feasibility evidence，但 production retention 仍没有 object table。
- 当前 token issue / revoke table 只保存 opaque token mechanics，不保存 native object。
- 当前 teardown admission callable 只做 fail-closed classification，不执行真实 destroy / retain / release。
- 当前 no-object creation callable 仍声明 allocation blocked，不能被绕过。
- 如果下一步要保存 `NSView`，必须先评估 token-backed object table、destroy ordering、revoke-before-destroy、double-destroy、main-thread confinement 与 pointer denial。

## 拒绝项

- 拒绝直接新增 production `NSView` retention C ABI。
- 拒绝返回 native pointer / handle / `id` / `Class`。
- 拒绝创建 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- 拒绝 Metal / QuartzCore。
- 拒绝 public API / public diagnostics。
- 拒绝 renderer state write / backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，真实 `NSView` allocation 入口收束到 feasibility-only next-boundary。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 固定为 feasibility planning facts；stop-line 禁止 production retention 与 pointer / public / state。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
