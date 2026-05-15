# P1 内部 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Containment Stop-Line Reconciliation Closure Review

状态：closure review / docs-only / no runtime truth

## Closure 结论

`NSApplication` shared-application accessor call containment stop-line reconciliation 已完成 docs-only 封账。本阶段没有新增 runtime owner、没有新增 native C ABI、没有修改 production native bridge、没有新增 `foreign func` 或 probe、没有调用 application singleton accessor、没有创建 `NSApplication`、没有 activation、没有 activation policy mutation、没有运行 event loop、没有 native visible order side effect、没有 drawable / render / GPU submission，也没有新增 public API。

## 当前 canonical endpoint

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`

## Runtime input

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`

## Reconciliation facts

- containment policy endpoint 足够作为当前 no-call containment endpoint。
- containment policy endpoint 足够作为下一段 branch-level next decision 的上游 input。
- 当前不继续新增同构 no-call wrapper；继续包装 blocked facts 不会增加新的 owner、teardown、verification、lifecycle 或 implementation admission 语义。
- actual `sharedApplication` call 若未来被考虑，必须另开 implementation decision，并重新验证 main-thread、bounded run loop、auto-close、teardown-before-visible、non-user-visible、headless fail-closed 与 cleanup co-ownership。

## Stop-line 复核

本阶段未调用 `sharedApplication`、`setActivationPolicy`、`activateIgnoringOtherApps`、`run`、`makeKeyAndOrderFront`、`orderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。未返回 pointer / handle / `id` / `Class`，未写 renderer state，未触碰 `runtime_state.cj`，未修改 `runtime/cjgui/cjpm.toml`，未新增 public declaration。

## Closure 判定

本阶段可以进入 manifest stabilization。下一边界只能是 `NSApplication` shared-application accessor call containment branch closure / next accessor call decision`，不得直接进入 application singleton accessor call implementation、application creation、activation、event loop、native visible order、drawable、render、renderer state write 或 backend-ready truth。
