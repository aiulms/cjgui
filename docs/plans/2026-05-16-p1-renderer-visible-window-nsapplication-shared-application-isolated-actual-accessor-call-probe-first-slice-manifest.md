# P1 Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe First Slice 清单

状态：manifest / isolated probe evidence / blocker true

## 文档链

- [first slice preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-preflight-decision.md)
- [first slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-closure-review.md)
- [first slice next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-next-boundary-decision.md)
- [first slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-manifest-stabilization-closure-review.md)
- 上游：[approval reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-approval-reconciliation-manifest.md)

## 当前 endpoint

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Owner file：[runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj)
- Native probe：[verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh)

## Current truth

Current truth 只包含：

- explicit human approval for isolated actual-call first slice。
- actual accessor call site exists only inside isolated native probe。
- probe requires main-thread gate。
- probe calls accessor only when preexisting `NSApplication` singleton is already present。
- automation environment classification is fail-closed because preexisting singleton is absent。
- `accessor_call_attempted=false` in current run。
- `application_created=false` in current run。
- `classification=-240` / `side_effect_classification=fail_closed_preexisting_application_missing`。
- integer classification only / dehydrated facts only。
- no production native bridge change, no public API, no production public C ABI。

## Stop-line

不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不创建 `NSWindow`；不 visible order；不获取 drawable；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 artifact；不发布 diagnostics；不写 renderer state；不返回 Class / id / pointer / handle；不修改 `runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe preexisting-application harness decision`

## Blocker

`automation_blocker: true`

原因：在 no-create 约束下，当前 automation 环境没有 preexisting `NSApplication` singleton；继续观察 non-null accessor result 需要外部 preexisting singleton harness 或新的人工批准。

