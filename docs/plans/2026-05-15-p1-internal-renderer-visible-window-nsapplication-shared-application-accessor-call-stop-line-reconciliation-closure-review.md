# P1 内部 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Stop-Line Reconciliation Closure Review

## Closure 结论

`NSApplication` shared-application accessor call stop-line reconciliation 已完成 docs-only 封账。本阶段没有新增 runtime owner、没有新增 native C ABI、没有修改 production native bridge、没有调用 application singleton accessor、没有创建 `NSApplication`、没有 activation、没有 activation policy mutation、没有运行 event loop、没有 native visible order side effect、没有 drawable / render / GPU submission，也没有新增 public API。

## 当前 canonical endpoint

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyDraft()`

## Runtime input

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness`

## Reconciliation facts

- accessor guard policy endpoint 可以作为 future accessor call preflight 的上游。
- future accessor call preflight 必须先保持 no-call，并明确区分 accessor call discussion 与 accessor call implementation。
- accessor native guard / guard policy facts 不能被包装为 application-ready、visible-ready、drawable-ready、render-ready、backend-ready、renderer state write 或 public API permission。
- actual `sharedApplication` call 若未来被考虑，必须另开 implementation decision，并重新验证 main-thread、bounded run loop、auto-close、teardown-before-visible、non-user-visible、headless fail-closed 与 cleanup co-ownership。

## Stop-line 复核

本阶段未调用 `sharedApplication`、`setActivationPolicy`、`activateIgnoringOtherApps`、`run`、`makeKeyAndOrderFront`、`orderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。未返回 pointer / handle / `id` / `Class`，未写 renderer state，未触碰 `runtime_state.cj`，未修改 `runtime/cjgui/cjpm.toml`，未新增 public declaration。

## Closure 判定

本阶段可以进入 manifest stabilization。下一边界只能是 `NSApplication` shared-application accessor call preflight decision，不得直接进入 application singleton accessor call implementation、application creation、activation、event loop、native visible order、drawable、render、renderer state write 或 backend-ready truth。
