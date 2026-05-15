# P1 内部 Renderer 可见窗口 NSApplication Shared-Application Guard Policy Value Boundary Stage Closure Review

## Closure 结论

`NSApplication` shared-application guard policy value boundary implementation 已完成。该阶段新增 runtime internal value owner 与 owner probe，但没有新增 native C ABI、没有修改 production native bridge、没有调用 application singleton accessor、没有创建 `NSApplication`、没有 activation、没有 activation policy mutation、没有运行 event loop、没有 native visible order side effect、没有 drawable / render / GPU submission，也没有新增 public API。

## 新增 owner / probe

- Runtime owner：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness`
- Runtime file：[runtime_renderer_visible_window_nsapplication_shared_application_guard_policy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_guard_policy.cj)
- Runtime owner probe：[verify_renderer_visible_window_nsapplication_shared_application_guard_policy_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_guard_policy_owner.sh)

## Value facts

新增 owner 只固定 application singleton accessor still blocked、application singleton creation still blocked、shared-application main-thread gate required、bounded run loop required、auto-close required、headless / CI-like fail-closed route、teardown before visible mode required、non-user-visible mode required、activation policy mutation still blocked、activation still blocked、event loop still blocked、native visible order still blocked、production drawable still blocked、render still blocked、no public surface、no renderer state write 与 no backend-ready truth facts。

## Stop-line 复核

未调用 `sharedApplication`、application singleton creation、activation policy mutation、activation、event loop、`makeKeyAndOrderFront` / `orderFront`、production `nextDrawable`、encoder、draw、`commit` / `present` 或 render execution。未返回 pointer / handle / `id` / `Class`，未写 renderer state，未触碰 `runtime_state.cj`，未修改 `runtime/cjgui/cjpm.toml`，未新增 public declaration。

## Closure 判定

本阶段可以进入 manifest stabilization。下一边界仍只能先做 shared-application accessor scope preflight，不得直接推进 application singleton accessor call、application creation、activation、event loop 或 native visible order implementation。
