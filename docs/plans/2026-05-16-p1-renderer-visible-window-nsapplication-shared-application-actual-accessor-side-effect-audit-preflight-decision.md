# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Side-Effect Audit Preflight 决策

状态：preflight decision / implementation admission / no actual accessor call

## 决策结论

本阶段选择 A/B 路线：允许新增 internal no-call side-effect audit value-boundary owner，固定 actual accessor call 前的 side-effect audit facts；不允许 actual application singleton accessor call。

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness` 足够作为 audit owner 的上游，但仍不足以直接进入 `sharedApplication` call implementation。原因是 actual singleton accessor call 可能触发 AppKit singleton lifecycle / process-level side effects，必须先把 side-effect risk、main-thread gate、headless fail-closed、teardown-before-visible、artifact / diagnostics non-publication 与 rollback / cleanup evidence 固定成 no-call audit facts。

本阶段批准的唯一 implementation 是 internal dehydrated audit owner：

- owner file：[runtime_renderer_visible_window_nsapplication_shared_application_actual_accessor_side_effect_audit.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_actual_accessor_side_effect_audit.cj)
- owner probe：[verify_renderer_visible_window_nsapplication_shared_application_actual_accessor_side_effect_audit_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_actual_accessor_side_effect_audit_owner.sh)
- canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditDraft()`
- runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness`

## 上游

- [singleton accessor admission branch manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-singleton-accessor-admission-branch-manifest.md)
- [singleton accessor admission stop-line manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-singleton-accessor-admission-stop-line-reconciliation-manifest.md)

## Implementation scope

新增 owner 只能表达：

- singleton accessor admission readiness 已保留。
- actual application singleton accessor call 仍 blocked。
- actual accessor side-effect audit required。
- application singleton lifecycle side-effect risk classified。
- main-thread audit、headless fail-closed audit、teardown-before-visible audit、artifact / diagnostics non-publication audit 与 rollback / cleanup evidence 仍是 future actual-call 前置条件。
- application singleton creation、activation policy mutation、activation、event loop、native visible order、production drawable、render、artifact write、artifact publication、public diagnostics、renderer state write、backend-ready truth、public API 与 public C ABI 仍 blocked。

## 不授权项

- 不调用 `sharedApplication`。
- 不创建 `NSApplication`。
- 不 activation，不 mutation activation policy。
- 不运行 AppKit event loop 或 bounded pump。
- 不执行 actual teardown。
- 不写 artifact，不发布 diagnostics。
- 不调用 `makeKeyAndOrderFront` / `orderFront`。
- 不调用 production `nextDrawable`。
- 不创建 color attachment、command buffer、render command encoder 或 draw call。
- 不 `commit` / `present`，不提交 GPU work，不执行 render。
- 不写 renderer state。
- 不新增 public API / public C ABI。
- 不修改 `runtime/cjgui/cjpm.toml` 或 `runtime/cjgui/src/runtime_state.cj`。

## GitNexus 结果

GitNexus 对 singleton accessor admission endpoint / draft 与拟新增 actual accessor side-effect audit endpoint 均返回 target not found / UNKNOWN / 0 impacted。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段必须以 source reading、owner probe、build、smoke、forbidden scan、protected path scan、manifest reachability 与最终 `detect-changes` 兜底。

## 下一边界

若 implementation、build、probe、smoke 与 closure scans 通过，当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor side-effect audit stop-line reconciliation decision`

该 next opening 仍不是 `sharedApplication` call implementation。
