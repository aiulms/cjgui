# P1 Renderer 可见窗口 NSApplication Shared-Application Native Guard 实现后续边界决策

## 决策结论

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationNativeGuardDraft()` 足够作为当前 shared-application native guard no-side-effect endpoint。

下一阶段选择：

`P1 internal Renderer visible-window production harness NSApplication shared-application guard policy value boundary decision`

## 当前 canonical endpoint

- Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationNativeGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationNativeGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness`
- Owner file：[runtime_renderer_visible_window_nsapplication_shared_application_native_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_native_guard.cj)

## 允许的下一刀

下一刀只能做 internal shared-application guard policy value boundary：消费当前 native guard readiness，把 native integer facts 投影为 value-style policy readiness / blocked facts。

可新增 runtime internal owner 与 owner probe；如需 native bridge 变更，必须另开 preflight decision，不得在 policy value boundary 中顺手新增 native behavior。

## 明确禁止

下一刀仍不得调用 application singleton accessor，不得创建 `NSApplication`，不得 activation 或修改 activation policy，不得运行 AppKit event loop，不得做 native visible order implementation，不得调用 production `nextDrawable`，不得创建 drawable color attachment / render encoder，不得 draw，不得 `commit` / `present`，不得提交 GPU work，不得执行 render，不得写 renderer state，不得新增 public API / public C ABI。

## 不是权限

当前 native guard facts 不是 application singleton accessor permission、application-ready、visible-ready、drawable-ready、render-ready、state-write-ready、backend-ready truth、diagnostics publication 或 public API permission。
