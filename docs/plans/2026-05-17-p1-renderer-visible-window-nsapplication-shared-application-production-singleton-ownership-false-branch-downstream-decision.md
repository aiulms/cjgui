# P1 Renderer visible-window NSApplication shared-application production singleton ownership false-branch downstream decision

状态：decision / preflight / internal readiness owner

## 结论

本轮使用用户预授权继续推进，选择新增 internal-only readiness owner：

- [runtime_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_false_branch_downstream.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_false_branch_downstream.cj)
- [verify_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_false_branch_downstream_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_false_branch_downstream_owner.sh)

Canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipFalseBranchDownstreamDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness`

## 依据

上游 production singleton ownership value boundary 已打开，但以下 truth 仍保持 false：

- `source_readiness_truth_value=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `production_singleton_ownership_truth=false`

因此本轮不能进入 production singleton owner implementation、production actual accessor call site、cleanup execution 或 AppKit lifecycle control。正确的下游动作是把 false ownership branch 记录为 value-only readiness，并明确路由回 source readiness / witness truth evidence gap。

## 允许范围

- 新增 internal-only value owner。
- 新增 owner probe。
- 只消费 stage 59 value boundary readiness。
- 固定 false branch classification 与 evidence-gap routing。
- 保持 production singleton ownership truth false。
- 保持 production implementation 与 production actual accessor call site blocked。

## Stop-line

本 decision 不授权 production `NSApplication.sharedApplication` call site、production singleton owner implementation、cleanup / teardown execution、activation、activation policy mutation、AppKit event loop、bounded run-loop pump、visible order、drawable、render、renderer state write、public API 或 production C ABI。

## GitNexus

编辑前已用 `cangjie-live-codelattice` 运行 impact：

- stage 59 endpoint：`UNKNOWN` / not found / impactedCount 0。
- stage 59 default draft：`UNKNOWN` / not found / impactedCount 0。
- planned stage 60 endpoint：`UNKNOWN` / not found / impactedCount 0。
- planned stage 60 default draft：`UNKNOWN` / not found / impactedCount 0。

这些结果按规则记录为 graph coverage gap，不作为安全证明；本轮安全性由源码读取、owner probe、build、forbidden scan 与 protected-path scan 兜底。
