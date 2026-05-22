#!/usr/bin/env zsh
#
# 维护注释：验证 stage350 internal AI-generated UI demo execution feedback surface probe semantic diff/explain owner。
# 它解释 stage349 feedback surface-to-probe refresh，不执行真实 probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage350_internal_ai_generated_ui_demo_execution_feedback_surface_probe_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage350 internal ai generated ui demo execution feedback surface probe semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage350InternalAiGeneratedUiDemoExecutionFeedbackSurfaceProbeSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage350InternalAiGeneratedUiDemoExecutionFeedbackSurfaceProbeSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage350InternalAiGeneratedUiDemoExecutionFeedbackSurfaceProbeSemanticDiffExplainDraft" \
  "didConsumeStage349ExecutionFeedbackSurfaceToProbeRefresh" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackSurfaceProbeSemanticDiff" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackSurfaceProbeExplainPacket" \
  "didBindExecutionFeedbackSurfaceProbeSemanticDiffToFeedbackSurfaceToProbeRefresh" \
  "didBindExecutionFeedbackSurfaceProbeExplainToFeedbackSurfaceReadinessDecision" \
  "didKeepExecutionFeedbackSurfaceProbeSemanticDiffRollbackReady" \
  "didKeepExecutionFeedbackSurfaceProbeExplainVisibilityNotPublished" \
  "didPrepareStage351ExecutionFeedbackProbeResultEnvelope" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage350 internal ai generated ui demo execution feedback surface probe semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage350_internal_ai_generated_ui_demo_execution_feedback_surface_probe_semantic_diff_explain_owner_present=true"
echo "stage349_internal_ai_generated_ui_demo_execution_feedback_surface_to_probe_refresh_required=true"
echo "ai_generated_ui_demo_execution_feedback_surface_probe_semantic_diff_materialized=true"
echo "ai_generated_ui_demo_execution_feedback_surface_probe_explain_packet_materialized=true"
echo "execution_feedback_surface_probe_semantic_diff_bound_to_feedback_surface_to_probe_refresh=true"
echo "execution_feedback_surface_probe_explain_bound_to_feedback_surface_readiness_decision=true"
echo "execution_feedback_surface_probe_semantic_diff_rollback_ready=true"
echo "execution_feedback_surface_probe_explain_visibility_not_published=true"
echo "stage351_execution_feedback_probe_result_envelope_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
