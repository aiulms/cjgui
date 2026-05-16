# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call First Slice Explicit Human Approval Manifest

状态：manifest / approval missing / no-call stop-line

## Manifest

本 manifest 封存 actual accessor call first slice explicit human approval decision 阶段。本阶段只确认当前自动化继续请求不足以授权 first slice；不新增 runtime owner、native probe、production C ABI 或 actual accessor call implementation。

## 原文链

- [decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-first-slice-explicit-human-approval-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-first-slice-explicit-human-approval-decision-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-first-slice-explicit-human-approval-decision-next-boundary-decision.md)
- [post-witness-packet actual-call preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-post-witness-packet-actual-accessor-call-preflight-manifest.md)

## Canonical endpoint

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness`

## Default draft

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightDraft()`

## Runtime inputs

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`

## Truth

- `actual_accessor_call_first_slice_explicit_human_approval_granted=false`
- `generic_continue_is_not_first_slice_approval=true`
- `actual_accessor_call_first_slice_opened=false`
- `actual_accessor_call_implementation=false`
- `production_actual_accessor_call_site=false`
- `production_singleton_owner_implementation=false`
- `production_singleton_ownership_truth=false`
- `witness_truth=false`
- `source_readiness_truth=false`
- `renderer_state_write=false`
- `backend_ready_truth=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

不调用 application singleton accessor；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call first-slice explicit human approval decision`
