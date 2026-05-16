# P1 Renderer 可见窗口 NSApplication Shared-Application source readiness truth evidence recovery manifest

状态：manifest / docs-only / recovery path closed

## 阶段定位

本 manifest 记录 external preexisting singleton source readiness truth evidence recovery decision。本阶段只复核 evidence 是否可恢复 source readiness truth，并定义下一段 recovery preflight 边界。

结论：现有 evidence 仍不足，source readiness truth 不恢复。下一步只能进入 external owner witness packet recovery preflight。

## 上游

- [source readiness truth explicit approval manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-explicit-approval-manifest.md)
- [source readiness admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-admission-preflight-manifest.md)
- [witness truth admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-truth-admission-preflight-manifest.md)
- [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)
- [isolated actual accessor first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-manifest.md)

## 本阶段文档

- [source readiness truth evidence recovery decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-evidence-recovery-decision.md)
- [source readiness truth evidence recovery closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-evidence-recovery-closure-review.md)
- [source readiness truth evidence recovery next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-evidence-recovery-next-boundary-decision.md)

## Owner / Probe

本阶段不新增 runtime owner，不新增 owner probe，不新增 native probe。

继续复用并验证上游 owner / native probes：

- source readiness admission preflight owner；
- witness truth admission preflight owner；
- witness acceptance gate / payload validation / payload schema / admission policy / contract shape owners；
- external source readiness preflight owner；
- source-cleanup boundary owner；
- throwaway / isolated actual accessor native probes；
- shared-application accessor containment native probe。

## Canonical 状态

本阶段不新增 runtime owner。当前 canonical endpoint / default draft / runtime input 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightDraft()`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthAdmissionPreflightReadiness`

## Truth

- `source_readiness_truth_evidence_recovery_opened=true`
- `existing_probe_evidence_recovery_sufficient=false`
- `external_owner_witness_packet_preflight_required=true`
- `external_owner_provided_preexisting_singleton_witness_required=true`
- `main_thread_observation_evidence_required=true`
- `source_lifetime_evidence_required=true`
- `cleanup_ownership_evidence_required=true`
- `renderer_non_creation_evidence_required=true`
- `renderer_non_accessor_evidence_required=true`
- `dehydrated_witness_packet_required=true`
- `pointer_handle_class_id_witness_packet_allowed=false`
- `native_object_witness_packet_allowed=false`
- `throwaway_singleton_rejected_as_source_truth=true`
- `renderer_created_singleton_rejected_as_source_truth=true`
- `source_readiness_truth_recovered=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`

## Stop-line

不升级 source readiness truth；不实现 production singleton owner；不新增 source readiness truth runtime owner；不新增 production actual accessor call site；不新增 native C ABI；不调用 `NSApplication.sharedApplication`；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness packet recovery preflight decision`
