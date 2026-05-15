# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Native Guard Implementation 清单

## 清单定位

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor native guard implementation`。本阶段新增 runtime owner 与 owner probe，但没有新增 native bridge C ABI。

## Owner

- Runtime file：[runtime_renderer_visible_window_nsapplication_shared_application_accessor_native_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_native_guard.cj)
- Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_accessor_native_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_native_guard_owner.sh)

## Canonical endpoint

- Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness`

## Truth

Accessor native guard readiness 只表示 accessor scope 之后继续观察到 accessor call blocked、accessor scope blocked、singleton creation blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、activation policy / activation / event loop blocked、native visible order blocked、production drawable blocked、render blocked、no public surface、no public C ABI addition、no renderer state write 与 no backend-ready truth。

## Stop-line

本 endpoint 不是 application singleton accessor permission、`NSApplication` creation / activation permission、activation policy mutation permission、event loop permission、visible order permission、drawable permission、encoder / draw / `commit` / `present` permission、GPU submission、render execution、renderer state write、public diagnostics、public API、public C ABI 或 backend-ready truth。

## Downstream

下一 opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor guard policy value boundary decision`
