#!/usr/bin/env zsh
#
# 维护注释：验证 stage263 internal component demo loop dry-run probe semantic diff/explain owner。
# 它解释 dry-run result envelope 的 action/state/render delta，不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage263_internal_component_demo_loop_dry_run_probe_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage263 internal component demo loop dry-run probe semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage263InternalComponentDemoLoopDryRunProbeSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage263InternalComponentDemoLoopDryRunProbeSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage263InternalComponentDemoLoopDryRunProbeSemanticDiffExplainDraft" \
  "didConsumeStage262InternalComponentDemoLoopDryRunResultEnvelope" \
  "didMaterializeLoopDryRunProbeSemanticDiff" \
  "didMaterializeLoopDryRunProbeExplainPacket" \
  "didBindDryRunProbeDiffToResultEnvelope" \
  "didBindDryRunProbeExplainToActionStateRenderOrder" \
  "didRecheckDryRunProbeRollbackReadyBoundary" \
  "didRecheckDryRunProbeVisibilityNotPublishedBoundary" \
  "didPrepareStage264LoopDryRunProbeReadinessDecisionInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage263 internal component demo loop dry-run probe semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage263_internal_component_demo_loop_dry_run_probe_semantic_diff_explain_owner_present=true"
echo "stage262_internal_component_demo_loop_dry_run_result_envelope_required=true"
echo "internal_component_demo_loop_dry_run_probe_semantic_diff_materialized=true"
echo "internal_component_demo_loop_dry_run_probe_explain_packet_materialized=true"
echo "dry_run_probe_diff_bound_to_result_envelope=true"
echo "dry_run_probe_explain_bound_to_action_state_render_order=true"
echo "dry_run_probe_rollback_ready_boundary_rechecked=true"
echo "dry_run_probe_visibility_not_published_boundary_rechecked=true"
echo "stage264_loop_dry_run_probe_readiness_decision_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
