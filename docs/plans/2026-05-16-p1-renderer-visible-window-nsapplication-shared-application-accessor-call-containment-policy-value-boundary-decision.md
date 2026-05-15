# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Containment Policy Value Boundary 决策

状态：value-boundary decision / no runtime truth

## 决策结论

本阶段选择 A 路线：允许下一刀新增 internal value-boundary owner，固定 accessor call containment policy facts；不允许 actual application singleton accessor call。

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness` 已足够作为 policy value boundary 的上游。下一刀只能把 containment observation 固定为 policy facts，不得新增 native C ABI、不得调用 native resource、不得把 containment facts 升级为 application-ready / visible-ready / drawable-ready / render-ready / backend-ready truth。

## 上游

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentDraft()`
- [native side-effect containment preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-native-side-effect-containment-preflight-decision.md)

## 下一刀允许的实现面

- 新增 runtime internal owner：[runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy.cj)
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy_owner.sh)
- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`

## policy facts

新增 owner 只能表达：

- containment readiness preserved。
- actual accessor call still blocked。
- no singleton accessor call preserved。
- singleton creation still blocked。
- application side effect still blocked。
- main-thread gate、bounded run loop、auto-close、teardown before visible、non-user-visible 仍 required。
- activation policy mutation、activation、event loop、native visible order、production drawable 与 render 仍 blocked。
- no pointer / handle / `Class` / `id` return。
- no public surface、no renderer state write、no backend-ready truth。
- policy facts value-only。

## 严格禁止

下一刀不得新增 native C ABI 或 `foreign func`，不得调用 `sharedApplication`、`setActivationPolicy`、`activateIgnoringOtherApps`、`run`、`makeKeyAndOrderFront`、`orderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。不得创建 `NSApplication`，不得 activation，不得修改 activation policy，不得运行 AppKit event loop，不得做 native visible order implementation，不得返回 pointer / handle / `id` / `Class`，不得新增 public declaration，不得写 renderer state，不得修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## GitNexus 结果

GitNexus 对 containment endpoint / default draft 与新增 native containment callable 返回 target not found / UNKNOWN / impactedCount 0。该结果只说明近期新增 symbols 未被索引覆盖，不能作为安全证明；下一刀必须以 source reading、owner probe、build、forbidden scan、protected path scan 与 manifest reachability 兜底。

## 下一边界

若 implementation、owner probe、build 与 scans 通过，下一 opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment stop-line reconciliation decision`

该 next opening 仍不是 application singleton accessor call、`NSApplication` creation / activation、visible order、drawable acquisition、GPU submission、render、renderer state write、backend-ready truth、public API 或 public C ABI permission。
