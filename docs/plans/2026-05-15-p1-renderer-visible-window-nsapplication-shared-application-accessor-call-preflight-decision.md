# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Preflight 决策

## 决策结论

本阶段选择 A/B 路线：允许新增 internal value-boundary owner，固定 accessor call preflight facts；不允许 actual application singleton accessor call。

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness` 足够作为 accessor call preflight 的上游，但仍不足以直接进入 `sharedApplication` call implementation。原因是 application singleton accessor call 可能触发 AppKit singleton lifecycle，风险边界不同于 no-side-effect guard / value policy facts。

本阶段批准的唯一 implementation 是 internal dehydrated preflight owner：

- owner file：[runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight.cj)
- owner probe：[verify_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight_owner.sh)
- canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightDraft()`
- runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`

## 上游

- [accessor call stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-stop-line-reconciliation-manifest.md)
- [accessor guard policy manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-accessor-guard-policy-value-boundary-manifest.md)

## Implementation scope

新增 owner 只能表达：

- actual application singleton accessor call still blocked。
- future native accessor call guard required。
- application singleton accessor scope still blocked。
- application singleton creation still blocked。
- main-thread gate / bounded run loop / auto-close / teardown before visible / non-user-visible 仍为 future accessor call 前置条件。
- headless / CI-like route 必须 fail-closed。
- activation policy mutation、activation、event loop、native visible order、production drawable 与 render 仍 blocked。
- no public surface、no renderer state write、no backend-ready truth。

## 不授权项

- 不调用 `sharedApplication`。
- 不创建 `NSApplication`。
- 不 activation，不 mutation activation policy。
- 不运行 AppKit event loop。
- 不调用 `makeKeyAndOrderFront` / `orderFront`。
- 不调用 production `nextDrawable`。
- 不创建 color attachment、command buffer、render command encoder 或 draw call。
- 不 `commit` / `present`，不提交 GPU work，不执行 render。
- 不写 renderer state。
- 不新增 public API / public C ABI / public diagnostics。
- 不修改 `runtime/cjgui/cjpm.toml` 或 `runtime/cjgui/src/runtime_state.cj`。

## GitNexus 结果

GitNexus 对 accessor guard policy endpoint / draft 与拟新增 accessor call preflight endpoint / draft 均返回 target not found / UNKNOWN / 0 impacted。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段必须以 source reading、owner probe、build、smoke、forbidden scan、protected path scan、manifest reachability 与最终 `detect-changes` 兜底。

## 下一边界

若 implementation、build、probe、smoke 与 closure scans 通过，当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call native side-effect containment preflight decision`

该 next opening 仍不是 actual `sharedApplication` call implementation。
