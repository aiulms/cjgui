# P1 Renderer NSApplication shared-application accessor call containment policy value boundary 清单

状态：manifest / value-only policy owner / no backend-ready truth

## 主题

本 manifest 固定 accessor call containment policy value boundary 的 owner、truth、endpoint、default draft、runtime input、probe 与 stop-line。

## Owner

- Runtime owner：[runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy.cj)
- Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy_owner.sh)

## Canonical endpoint

- Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`

## Truth

Truth 仅限 internal value policy facts：containment readiness preserved、actual application singleton accessor call blocked、no singleton accessor call、singleton creation blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、application side effect blocked、activation policy mutation blocked、activation blocked、event loop blocked、native visible order blocked、production drawable blocked、render blocked、no pointer / handle / `Class` / `id` return、no public surface、no renderer state write 与 no backend-ready truth。

## Stop-line

本 manifest 不批准 actual `sharedApplication` call、`NSApplication` creation / activation、activation policy mutation、event loop、native visible-order implementation、production drawable acquisition、color attachment、encoder creation、draw、`commit`、`present`、GPU submission、render execution、renderer state write、backend-ready truth、public API、public C ABI、新 native C ABI 或新 `foreign func`。

## Downstream

唯一 next opening 是 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment stop-line reconciliation decision`。
