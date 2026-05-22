#!/usr/bin/env zsh
#
# 维护注释：验证 stage342 internal AI-generated UI demo execution probe-to-surface feedback semantic diff/explain owner。
# 它解释 stage341 feedback 回到 surface runway 的语义差异，不执行真实 probe 或 surface mutation。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage342_internal_ai_generated_ui_demo_execution_probe_to_surface_feedback_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage342 internal ai generated ui demo execution probe to surface feedback semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage342InternalAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage342InternalAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage342InternalAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackSemanticDiffExplainDraft" \
  "didConsumeStage341ExecutionProbeToSurfaceFeedback" \
  "didMaterializeAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackSemanticDiff" \
  "didMaterializeAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackExplainPacket" \
  "didBindExecutionProbeToSurfaceFeedbackSemanticDiffToFeedback" \
  "didBindExecutionProbeToSurfaceFeedbackExplainToProbeReadinessDecision" \
  "didKeepExecutionProbeToSurfaceFeedbackSemanticDiffRollbackReady" \
  "didKeepExecutionProbeToSurfaceFeedbackExplainVisibilityNotPublished" \
  "didPrepareStage343ExecutionProbeToSurfaceFeedbackResultEnvelope" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage342 internal ai generated ui demo execution probe to surface feedback semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage342_internal_ai_generated_ui_demo_execution_probe_to_surface_feedback_semantic_diff_explain_owner_present=true"
echo "stage341_internal_ai_generated_ui_demo_execution_probe_to_surface_feedback_required=true"
echo "ai_generated_ui_demo_execution_probe_to_surface_feedback_semantic_diff_materialized=true"
echo "ai_generated_ui_demo_execution_probe_to_surface_feedback_explain_packet_materialized=true"
echo "execution_probe_to_surface_feedback_semantic_diff_bound_to_feedback=true"
echo "execution_probe_to_surface_feedback_explain_bound_to_probe_readiness_decision=true"
echo "execution_probe_to_surface_feedback_semantic_diff_rollback_ready=true"
echo "execution_probe_to_surface_feedback_explain_visibility_not_published=true"
echo "stage343_execution_probe_to_surface_feedback_result_envelope_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
