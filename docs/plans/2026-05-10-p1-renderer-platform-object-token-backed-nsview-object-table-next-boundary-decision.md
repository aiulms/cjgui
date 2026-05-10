# P1 内部渲染器 platform object token-backed NSView object table 下一段入口

日期：2026-05-10

状态：next boundary / no-allocation table shell

## 结论

本轮完成 B 路线：production `NSView` object table shell / slot lifecycle / token classification callable 已落地，但没有创建或保存 `NSView`。

原始唯一下一段入口：

`P1 internal Renderer platform object token-backed NSView create/destroy first slice preflight decision`

该入口已由 [token-backed NSView create/destroy first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-create-destroy-first-slice-manifest.md) 接续并封账。当前唯一下一段入口转为：

`P1 internal Renderer platform object NSView runtime FFI call owner preflight decision`

## 选择理由

- `NSView` allocation feasibility 已由 isolated probe 验证，但 production 仍未保存 `NSView`。
- 本轮 table shell 已能表达 fixed capacity、empty、token-not-bound、allocation blocked 与 destroy blocked facts。
- 当前 token issue / revoke 仍只证明 opaque token mechanics，不是 resource token。
- 当前 teardown admission 仍只证明 fail-closed classification，不执行真实 destroy / retain / release。
- 下一步若要靠近 create / destroy，必须先重新 preflight object table retention、main-thread confinement、token bind / revoke ordering、double-destroy failure 与 immediate cleanup / destroy 语义。

## 拒绝项

- 拒绝直接进入 long-lived `NSView` retention。
- 拒绝返回 native pointer / handle / `id` / `Class`。
- 拒绝创建 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- 拒绝 Metal / QuartzCore。
- 拒绝 public API / public diagnostics。
- 拒绝 renderer state write / backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，object table 阶段完成 no-allocation next-boundary。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 固定为 table shell / no-allocation / fail-closed facts；stop-line 禁止 retention、pointer / public / state / backend-ready。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer platform object token-backed NSView create/destroy first slice preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
