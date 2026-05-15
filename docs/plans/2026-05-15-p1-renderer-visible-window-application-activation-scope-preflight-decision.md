# P1 Renderer 可见窗口 Application Activation Scope 预检决策

## 决策结论

本阶段选择 A 路线：application creation / activation 仍不得直接实现，下一刀只能先做 internal application activation policy value boundary。

原因是 visible-order native guard 只证明当前 production bridge 能返回 no-side-effect guard facts：application ownership required、application creation deferred、activation deferred、bounded run loop required、auto-close required、headless fail-closed、content-view prerequisite required、visible order still blocked、drawable still blocked 与 render still blocked。它没有授权创建 `NSApplication`、activation、event loop 或 user-visible side effect。

## 上游

- `CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderNativeGuardDraft()`

## 下一刀允许的实现面

- 新增 internal-only runtime owner，建议文件为 `runtime_renderer_visible_window_application_activation_policy.cj`。
- 该 owner 只能消费 `CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`。
- 该 owner 只能表达 application singleton ownership scope、main-thread gate、creation still-deferred、activation still-deferred、bounded run loop requirement、auto-close requirement、headless / CI-like fail-closed route、content-view prerequisite 与 no-render permission facts。
- 不新增 native C ABI、不修改 production native bridge、不新增 `foreign func`、不修改 build config。

## 停止线

下一刀仍不允许调用 `sharedApplication`、`setActivationPolicy`、`activateIgnoringOtherApps`、`run`、`makeKeyAndOrderFront`、`orderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。不得创建 `NSApplication`，不得 activation，不得运行 AppKit event loop，不得返回 pointer / handle / `id` / `Class`，不得新增 public declaration，仍不得修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 下一边界

若本预检 docs / scan 全部通过，下一 opening 转为：

`P1 internal Renderer visible-window production harness application activation policy value boundary bundle implementation`

该 next opening 仍不是 `NSApplication` creation / activation implementation；它只允许建立 value-style policy facts。

