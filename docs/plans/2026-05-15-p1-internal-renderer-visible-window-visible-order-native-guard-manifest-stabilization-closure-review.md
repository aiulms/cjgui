# P1 内部 Renderer 可见窗口 Visible Order Native Guard Manifest 稳定化封账复核

## 完成内容

本阶段将 visible-order native guard first slice 稳定为 manifest：

- 固定 owner 为 `runtime_renderer_visible_window_visible_order_native_guard.cj`。
- 固定 canonical endpoint 为 `CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderNativeGuardDraft()`。
- 固定 runtime input 为 `CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`。
- 固定 native guard facts 仍不是 application creation、activation 或 visible order implementation permission。

## 未越过的停止线

未创建 `NSApplication`，未 activation，未 order front，未运行 event loop，未调用 production `nextDrawable`，未创建 drawable color attachment、encoder、draw、GPU submission、render、renderer state write、public API 或 public diagnostics。未触碰 `runtime_state.cj` 与 `runtime/cjgui/cjpm.toml`。

## 下一 opening

`P1 internal Renderer visible-window production harness application creation and activation scope preflight decision`

## 设计意图出口自检

- 本 manifest 是 runtime/native guard truth 的导航封账，不是 backend-ready truth。
- 下一段仍必须是 scope preflight；未获批准前不得进入 application creation / activation implementation。
