# P1 Renderer NSApplication shared-application accessor call containment 下一边界决策

状态：next-boundary decision / value policy only / no native side effect expansion

## 决策

选择 A 路线：进入 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment policy value boundary decision`。

## 已有上游

上游 endpoint 是 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentDraft()`，由 [runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment.cj) 产生。

该 endpoint 只证明 internal native no-call containment facts 可被 runtime 观察，不证明 actual `sharedApplication` accessor 可调用，也不证明 `NSApplication` 可创建或激活。

## 下一刀允许

下一刀允许新增 internal value-only owner：

- `runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy.cj`

该 owner 只能消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`，并把 containment facts 固定为 policy admission / readiness facts。

## 下一刀禁止

下一刀不得新增 native C ABI、`foreign func`、public API、public C ABI、diagnostics、renderer state write、actual application singleton accessor call、`NSApplication` creation、activation policy mutation、activation、event loop、native visible-order implementation、drawable acquisition、color attachment、encoder、draw、`commit`、`present`、GPU submission、render 或 backend-ready truth。

## 后续 opening

完成 policy value boundary 后，唯一后续 opening 应转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment stop-line reconciliation decision`
