# P1 Renderer NSApplication shared-application accessor call containment policy value boundary 阶段封账

状态：stage closure / internal value policy / no native expansion

## 完成内容

本阶段接续 [containment policy value boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-decision.md)，新增 value-only policy owner：

- [runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy.cj)
- [verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy_owner.sh)

## 当前 endpoint

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`

## Truth

本阶段只把 containment readiness 固定成 policy facts / admission / readiness：actual application singleton accessor call blocked、no singleton accessor call、singleton creation blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、application side effect blocked、activation policy mutation blocked、activation blocked、event loop blocked、native visible order blocked、drawable blocked、render blocked、no public surface、no renderer state write 与 no backend-ready truth。

## Stop-line

本阶段没有新增 native C ABI，没有新增 `foreign func`，没有 public API / public C ABI，没有 actual application singleton accessor call，没有创建 `NSApplication`，没有 activation，没有修改 activation policy，没有运行 event loop，没有进入 native visible order，没有获取 drawable，没有创建 color attachment / encoder，没有 draw、`commit`、`present` 或 GPU submission，没有写 renderer state，没有创建 backend-ready truth。

## 下一边界

下一阶段进入 [containment policy next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-next-boundary-decision.md)，只允许做 accessor call containment stop-line reconciliation decision。
