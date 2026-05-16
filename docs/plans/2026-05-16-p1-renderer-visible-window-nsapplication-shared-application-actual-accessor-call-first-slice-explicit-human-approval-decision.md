# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call First Slice Explicit Human Approval 决策

状态：decision / approval missing / no actual accessor call

## Decision

本阶段接在 [post-witness-packet actual-call preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-post-witness-packet-actual-accessor-call-preflight-manifest.md) 之后，只处理当前唯一 next opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call first-slice explicit human approval decision`

当前输入是自动化继续请求，不是明确的 actual-call first slice 人工批准。因此本阶段裁定：不进入 first slice，不新增 runtime owner，不新增 native probe，不创建 production actual accessor call site，不调用 `NSApplication.sharedApplication`。

## Approval 状态

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

## Canonical 状态

当前 canonical endpoint 保持：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness`

当前 default draft 保持：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightDraft()`

当前 runtime inputs 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`

## Stop-line

Stop-line 保持：不调用 application singleton accessor；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## GitNexus 预检结果

GitNexus 对当前 canonical endpoint 与 default draft 仍返回 target not found / `UNKNOWN` / 0 impacted。该结果只说明图索引未覆盖近期新增符号，不能作为安全证明；本阶段继续以源码读取、owner/native probes、build、forbidden scan、protected path scan、public declaration scan、manifest/docs reachability 与最终 `detect-changes` 兜底。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call first-slice explicit human approval decision`
