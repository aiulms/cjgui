# P1 Renderer 可见窗口 Visible Order 预检决策

## 决策结论

本阶段选择 A 路线：visible order 仍不得直接实现，下一刀只能先做 internal visible-order policy value boundary。

原因是 content-view attachment first slice 只证明不可见 `NSWindow` 可挂载 token-backed `NSView`，尚未固定 `NSApplication` / activation policy、bounded run loop、auto-close、user-visible side-effect、headless / CI-like fallback 与 cleanup ownership。直接调用 `makeKeyAndOrderFront` 会把当前 facts 误升级为可见窗口 permission，因此本预检不授权 visible order native implementation。

## 上游

- `CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowContentViewAttachmentDraft()`

## 下一刀允许的实现面

- 新增 internal-only runtime owner，建议文件为 `runtime_renderer_visible_window_visible_order_policy.cj`。
- 该 owner 只能消费 `CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness`。
- 该 owner 只能表达 visible-order policy facts：`NSApplication` ownership policy、activation still-deferred、bounded run loop requirement、auto-close requirement、headless / CI-like fail-closed route、no-drawable permission 与 cleanup co-ownership。
- 不新增 native C ABI、不修改 production native bridge、不修改 build config。

## 停止线

下一刀仍不允许调用 `makeKeyAndOrderFront`、`orderFront`、`activateIgnoringOtherApps`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。不得创建 `NSApplication`，不得返回 pointer / handle / `id` / `Class`，不得新增 public declaration，仍不得修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 下一边界

若本预检 docs / scan 全部通过，下一 opening 转为：

`P1 internal Renderer visible-window production harness visible-order policy value boundary bundle implementation`

该 next opening 仍不是 visible order native implementation；它只允许建立 policy facts。
