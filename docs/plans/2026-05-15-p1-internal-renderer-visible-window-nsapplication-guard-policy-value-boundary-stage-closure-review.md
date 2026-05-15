# P1 内部 Renderer 可见窗口 NSApplication Guard Policy Value Boundary Stage Closure Review

## Closure 结论

`NSApplication` guard policy value boundary implementation 已完成。该阶段新增 runtime internal value owner 与 owner probe，但没有新增 native C ABI、没有修改 production native bridge、没有创建 `NSApplication`、没有 activation、没有 activation policy mutation、没有运行 event loop、没有 native visible order side effect、没有 drawable / render / GPU submission，也没有新增 public API。

## 新增 owner / probe

- Runtime owner：`CjguiInternalRendererVisibleWindowNsApplicationGuardPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationGuardPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness`
- Runtime file：[runtime_renderer_visible_window_nsapplication_guard_policy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_guard_policy.cj)
- Runtime owner probe：[verify_renderer_visible_window_nsapplication_guard_policy_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_guard_policy_owner.sh)

## Value facts

新增 owner 只固定 application singleton ownership required、main-thread gate required、application creation still-deferred、activation still-deferred、activation policy still-deferred、event loop still-deferred、bounded run loop required、auto-close required、headless / CI-like fail-closed route、native visible order still blocked、production drawable still blocked、render still blocked、no public surface、no renderer state write 与 no backend-ready truth facts。

## Stop-line 复核

未调用 application singleton creation、activation policy mutation、activation、event loop、`makeKeyAndOrderFront` / `orderFront`、production `nextDrawable`、encoder、draw、`commit` / `present` 或 render execution。未返回 pointer / handle / `id` / `Class`，未写 renderer state，未触碰 `runtime_state.cj`，未修改 `runtime/cjgui/cjpm.toml`，未新增 public declaration。

## Closure 判定

本阶段可以进入 manifest stabilization。下一边界仍只能先做 `NSApplication` creation / activation scope preflight，不得直接推进 application creation、activation policy mutation、activation、event loop 或 native visible order implementation。

