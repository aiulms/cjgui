# P1 Renderer visible-window NSApplication shared-application external owner source witness route unavailable recovery manifest

状态：manifest / docs-only / stage 65

## Canonical endpoint

本阶段不新增 runtime endpoint。当前 canonical endpoint 仍是：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryValueBoundaryReadiness`

## Files

- [decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-external-owner-source-witness-route-unavailable-recovery-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-internal-renderer-visible-window-nsapplication-shared-application-external-owner-source-witness-route-unavailable-recovery-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-renderer-visible-window-nsapplication-shared-application-external-owner-source-witness-route-unavailable-recovery-next-boundary-decision.md)
- [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-internal-renderer-visible-window-nsapplication-shared-application-external-owner-source-witness-route-unavailable-recovery-manifest-stabilization-closure-review.md)

## Truth

- `human_provided_external_owner_source_witness_evidence_absent=true`
- `external_preexisting_singleton_owner_witness_route_available=false`
- `external_owner_source_evidence_available=false`
- `production_acceptable_external_owner_witness_packet=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `source_readiness_truth_value=false`
- `production_singleton_ownership_truth=false`
- `isolated_throwaway_probe_evidence_promoted_to_external_owner_truth=false`
- `isolated_throwaway_probe_evidence_promoted_to_production_ownership_truth=false`
- `internal_ownership_recovery_feasibility_selected=true`
- `no_production_singleton_truth_carry_forward=true`
- `new_runtime_owner_added=false`
- `new_owner_probe_added=false`
- `production_singleton_implementation=false`
- `production_actual_accessor_call_site=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

本 manifest 不授权 production singleton owner implementation、新的 `NSApplication.sharedApplication` 调用、activation、event loop、visible `NSWindow`、visible order、drawable、render、renderer state write、public API、public C ABI、`runtime_state.cj` write 或 `cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application internal ownership recovery feasibility preflight / no-production-singleton-truth carry-forward decision`
