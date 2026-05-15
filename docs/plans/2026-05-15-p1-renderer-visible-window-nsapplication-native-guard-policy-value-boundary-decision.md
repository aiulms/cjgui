# P1 Renderer 可见窗口 NSApplication Native Guard Policy Value Boundary 决策

## 决策结论

本阶段选择 A 路线：`NSApplication` native guard no-side-effect integer facts 不能直接升级为 application creation、activation policy mutation、activation、event loop 或 user-visible ordering permission。下一刀只能新增 internal value-style policy owner，用来把 native guard observation 脱水为更明确的 application guard policy facts。

原因是当前 `NSApplication` native guard 只证明 production bridge 能返回 deterministic guard facts：application ownership required、main-thread required、creation deferred、activation deferred、activation policy deferred、event loop deferred、bounded run loop required、auto-close required、headless fail-closed、visible order still blocked、drawable still blocked 与 render still blocked。它没有创建 `NSApplication`，没有调用 `sharedApplication` / `setActivationPolicy` / activation API，也没有运行 AppKit event loop。

## 上游

- `CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationNativeGuardDraft()`

## 下一刀允许的实现面

- 新增 internal-only runtime owner，建议文件为 `runtime_renderer_visible_window_nsapplication_guard_policy.cj`。
- 该 owner 只能消费 `CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness`。
- 该 owner 只能表达 application guard policy facts：application singleton ownership required、main-thread gate required、creation / activation / activation policy / event loop still deferred、bounded run loop required、auto-close required、headless fail-closed route、visible order still blocked、production drawable still blocked、render still blocked 与 no-backend-ready truth。
- 可新增 runtime owner probe，用于检查 owner symbols、upstream input、停止线和 forbidden tokens。
- 不新增 native C ABI、不修改 production native bridge、不新增 `foreign func`、不修改 build config。

## 停止线

下一刀仍不允许调用 `sharedApplication`、`setActivationPolicy`、`activateIgnoringOtherApps`、`run`、`makeKeyAndOrderFront`、`orderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。不得创建 `NSApplication`，不得 activation，不得运行 AppKit event loop，不得返回 pointer / handle / `id` / `Class`，不得新增 public declaration，仍不得修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 下一边界

若本决策 docs / scan 全部通过，下一 opening 转为：

`P1 internal Renderer visible-window production harness NSApplication native guard policy value boundary bundle implementation`

该 next opening 仍不是 `NSApplication` creation / activation implementation；它只允许建立 value-style policy facts。

