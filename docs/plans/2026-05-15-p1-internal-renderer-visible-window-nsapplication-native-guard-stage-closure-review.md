# P1 内部 Renderer 可见窗口 NSApplication Native Guard Stage Closure Review

## Closure 结论

`NSApplication` native guard no-side-effect implementation 已完成。该阶段新增 production native bridge guard callables、runtime internal owner、native probe 与 runtime owner probe，但没有创建 application singleton、没有 activation、没有运行 event loop、没有 native visible order side effect、没有 drawable / render / GPU submission，也没有新增 public API。

## 新增 owner / probe

- Runtime owner：`CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationNativeGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness`
- Runtime file：[runtime_renderer_visible_window_nsapplication_native_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_native_guard.cj)
- Native probe：[verify_native_bridge_nsapplication_native_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_native_guard.sh)
- Runtime owner probe：[verify_renderer_visible_window_nsapplication_native_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_native_guard_owner.sh)

## Native bridge additions

新增 `cjgui_native_bridge_nsapplication_guard_*` internal C ABI callables。它们只返回 deterministic `int32_t` facts：ownership required、main-thread required、creation deferred、activation deferred、activation policy deferred、event loop deferred、bounded run loop required、auto-close required、headless fail-closed、visible order still blocked、drawable still blocked 与 render still blocked。

## Stop-line 复核

未调用 application singleton creation、activation policy mutation、activation、event loop、`makeKeyAndOrderFront` / `orderFront`、production `nextDrawable`、encoder、draw、`commit` / `present` 或 render execution。未返回 pointer / handle / `id` / `Class`，未写 renderer state，未触碰 `runtime_state.cj`，未修改 `runtime/cjgui/cjpm.toml`，未新增 public declaration。

## Closure 判定

本阶段可以进入 manifest stabilization。下一边界仍只能先做 policy value boundary decision，不得直接推进 application creation / activation 或 native visible order implementation。
