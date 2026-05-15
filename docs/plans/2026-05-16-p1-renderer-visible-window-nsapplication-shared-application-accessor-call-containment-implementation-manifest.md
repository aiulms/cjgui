# P1 Renderer NSApplication shared-application accessor call containment 实现清单

状态：manifest / internal native no-call containment / no backend-ready truth

## 主题

本 manifest 固定 `NSApplication` shared-application accessor call containment implementation 阶段的 owner、truth、endpoint、default draft、runtime input、probe 与 stop-line。

## Owner

- Runtime owner：[runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment.cj)
- Native header：[cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)
- Native source：[cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)
- Native probe：[verify_native_bridge_nsapplication_shared_application_accessor_call_containment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_accessor_call_containment.sh)
- Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_owner.sh)

## Canonical endpoint

- Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness`

## Truth

Truth 仅限 deterministic no-call containment values：accessor call blocked、no singleton accessor call、singleton creation blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、application side effect blocked、activation policy mutation blocked、activation blocked、event loop blocked、native visible order blocked、drawable blocked、render blocked、backend-ready truth blocked 与 no pointer / handle / `Class` / `id` return。

## Stop-line

本 manifest 不批准 actual `sharedApplication` call、`NSApplication` creation / activation、activation policy mutation、event loop、native visible-order implementation、production drawable acquisition、color attachment、encoder creation、draw、`commit`、`present`、GPU submission、render execution、renderer state write、backend-ready truth、public API 或 public C ABI。

## Downstream

该 endpoint 已接续到 [containment policy value boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-decision.md)。下一阶段只能做 value-only policy owner。
