# P1 Renderer 可见窗口 NSApplication Creation / Activation Scope 预检决策

## 决策结论

本阶段选择 A 路线：`NSApplication` creation、activation policy mutation、activation 与 AppKit event loop 仍不得直接实现。下一刀只能新增 internal value-style owner，用来把 guard policy facts 脱水为 creation / activation scope facts，并继续保持真实 AppKit side effect blocked。

原因是当前 `NSApplication` guard policy 只证明 runtime 已把 native guard facts 固定为 application singleton ownership required、main-thread gate required、creation / activation / activation policy / event loop still deferred、bounded run loop required、auto-close required、headless fail-closed、visible order still blocked、drawable still blocked、render still blocked、no renderer state write 与 no backend-ready truth。它没有证明 runtime 可以安全创建 shared application、修改 activation policy、激活应用、启动 event loop 或产生 user-visible ordering。

## 上游

- `CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationGuardPolicyDraft()`

## 下一刀允许的实现面

- 新增 internal-only runtime owner，建议文件为 `runtime_renderer_visible_window_nsapplication_creation_activation_scope.cj`。
- 该 owner 只能消费 `CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness`。
- 该 owner 只能表达 creation / activation scope facts：application singleton creation still blocked、activation policy mutation still blocked、activation still blocked、event loop still blocked、bounded run loop prerequisite required、auto-close prerequisite required、headless fail-closed route required、native visible order still blocked、production drawable still blocked、render still blocked、no public surface、no renderer state write 与 no backend-ready truth。
- 可新增 runtime owner probe，用于检查 owner symbols、upstream input、停止线和 forbidden tokens。
- 不新增 native C ABI、不修改 production native bridge、不新增 `foreign func`、不修改 build config。

## 停止线

下一刀仍不允许调用 `sharedApplication`、`setActivationPolicy`、`activateIgnoringOtherApps`、`run`、`makeKeyAndOrderFront`、`orderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。不得创建 `NSApplication`，不得 activation，不得运行 AppKit event loop，不得返回 pointer / handle / `id` / `Class`，不得新增 public declaration，仍不得修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 下一边界

若本预检 docs / scan 全部通过，下一 opening 转为：

`P1 internal Renderer visible-window production harness NSApplication creation and activation scope value boundary bundle implementation`

该 next opening 仍不是 `NSApplication` creation / activation implementation；它只允许建立 value-style scope facts。
