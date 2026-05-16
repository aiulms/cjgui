# P1 Renderer 可见窗口 NSApplication Shared-Application source readiness truth explicit approval manifest

状态：manifest / docs-only / source readiness truth blocked

## 阶段定位

本 manifest 记录 source readiness truth explicit approval decision / preflight。用户批准打开判断口，但不批准 production singleton owner implementation。本阶段只判断 evidence 是否足够升级 source readiness truth。

结论：evidence 不足，source readiness truth 仍 blocked。

## 上游

- [source readiness admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-admission-preflight-manifest.md)
- [witness truth admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-truth-admission-preflight-manifest.md)
- [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)
- [isolated actual accessor first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-manifest.md)

## 本阶段文档

- [source readiness truth explicit approval decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-explicit-approval-decision.md)
- [source readiness truth explicit approval closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-explicit-approval-closure-review.md)
- [source readiness truth explicit approval next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-truth-explicit-approval-next-boundary-decision.md)

## Canonical 状态

本阶段不新增 runtime owner。当前 canonical endpoint / default draft / runtime input 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightDraft()`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthAdmissionPreflightReadiness`

## Truth

- `source_readiness_truth_approval_decision_opened=true`
- `source_readiness_truth_evidence_sufficient=false`
- `source_readiness_truth_upgrade_allowed=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`
- `throwaway_singleton_rejected_as_source_truth=true`
- `renderer_created_singleton_rejected_as_source_truth=true`
- `isolated_accessor_probe_missing_preexisting_singleton_blocks_truth=true`
- `external_owner_witness_truth_required_before_truth_upgrade=true`
- `source_lifetime_truth_required_before_truth_upgrade=true`
- `cleanup_ownership_truth_required_before_truth_upgrade=true`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- `public_api_modified=false`
- `production_public_c_abi_added=false`

## Stop-line

不实现 production singleton owner；不把 source readiness truth 解释为 actual `NSApplication` ownership；不调用 `NSApplication.sharedApplication`；不调用 `setActivationPolicy` / `activateIgnoringOtherApps` / `run` / `stop` / `terminate`；不创建 `NSWindow` / `NSView` / `CAMetalLayer`；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact / diagnostics publication；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness truth evidence recovery decision`
