# P1 内部渲染器 platform object no-object creation callable 后续边界选择

日期：2026-05-10

状态：next-boundary / no-object callable completed

## 当前结论

platform object no-object creation callable 已完成 first slice。当前证据只证明 creation entry 可通过 internal C ABI 观察 no-object / main-thread / token contract / allocation blocked classification；不证明 AppKit object exists，不批准 `NSView` 或 `NSWindow` allocation。

## 候选选择

- A：`P1 internal Renderer platform object no-object creation callable manifest stabilization bundle`
- B：`P1 internal Renderer platform object real NSView allocation preflight decision`
- C：`P1 internal Renderer platform object creation blocker follow-up`
- D 拒绝：direct `NSWindow` / `NSView` / `NSApplication` creation。
- E 拒绝：Metal / QuartzCore / pointer handle / public API。

## 选择

选择 A 先完成 manifest stabilization。若验证全部通过，唯一后续入口固定为：

该入口已由 real `NSView` allocation feasibility stage 接续。当前唯一后续入口转为：

`P1 internal Renderer platform object token-backed NSView object table preflight decision`

该入口必须从 preflight 开始，且仍需重新评估 isolated allocation feasibility、main-thread gate、token binding、object table、teardown path、pointer / handle denial、public API denial 与 renderer state stop-line；不得从本阶段直接推导 object retention permission。

## Same-shape 刹车

不得把 no-object creation callable、token-backed planning、AppKit main-thread admission、token issue/revoke、teardown admission 或 smoke evidence 包装成 platform object creation permission、native object permission、native handle permission、Metal / QuartzCore permission、backend-ready truth、renderer state write、render、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-object creation callable 完成后转入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，tail 暂定为 `CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_platform_object_no_object_creation_call.cj`；truth 只限 fail-closed no-object facts；stop-line 继续禁止真实 object allocation。
- 本轮是否改变唯一 next opening：是，当时 manifest closure 后固定为 `P1 internal Renderer platform object real NSView allocation preflight decision`；当前已由 real `NSView` allocation feasibility stage 接续，唯一后续入口转为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
