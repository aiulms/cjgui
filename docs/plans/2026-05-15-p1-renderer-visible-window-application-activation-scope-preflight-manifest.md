# P1 Renderer 可见窗口 Application Activation Scope 预检 Manifest

## 阶段摘要

本 manifest 封账 application creation / activation scope preflight docs-only 决策。结论是：visible-order native guard facts 不足以直接授权 `NSApplication` creation、activation、event loop 或 user-visible side effect；下一刀只能先补 internal application activation policy value boundary。

## 当前 owner

- Upstream owner：`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`
- Current canonical endpoint：`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`
- Current default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderNativeGuardDraft()`
- 本阶段不新增 runtime owner、不新增 native C ABI、不新增 probe。

## 事实边界

只承认 application creation / activation scope 尚未被固定。当前 runtime truth 仍停在 visible-order native guard no-side-effect facts；application singleton ownership scope、main-thread gate、bounded run loop、auto-close、activation side effect 与 user-visible ordering 均仍 deferred。

## 停止线

不创建 `NSApplication`；不 activation；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 present / commit / draw / render；不提交 GPU work；不写 renderer state；不扩 public API；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`
- Current：application activation scope preflight docs-only decision
- Downstream next opening：`P1 internal Renderer visible-window production harness application activation policy value boundary bundle implementation`

## 设计意图出口自检

- manifest 已同步当前 truth、stop-line 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。

