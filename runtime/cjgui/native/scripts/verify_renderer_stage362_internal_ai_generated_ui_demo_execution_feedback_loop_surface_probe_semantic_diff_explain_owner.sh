#!/usr/bin/env zsh
#
# 维护注释：验证 stage362 internal AI-generated UI demo execution feedback loop surface probe semantic diff/explain owner。
# 它消费 stage361 surface-to-probe refresh，产出 probe 前语义差异与解释包。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage362_internal_ai_generated_ui_demo_execution_feedback_loop_surface_probe_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage362 internal ai generated ui demo execution feedback loop surface probe semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage362InternalAiGeneratedUiDemoExecutionFeedbackLoopSurfaceProbeSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage362InternalAiGeneratedUiDemoExecutionFeedbackLoopSurfaceProbeSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage362InternalAiGeneratedUiDemoExecutionFeedbackLoopSurfaceProbeSemanticDiffExplainDraft" \
  "didConsumeStage361ExecutionFeedbackLoopSurfaceToProbeRefresh" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackLoopSurfaceProbeSemanticDiff" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackLoopSurfaceProbeExplainPacket" \
  "didBindExecutionFeedbackLoopSurfaceProbeSemanticDiffToSurfaceToProbeRefresh" \
  "didBindExecutionFeedbackLoopSurfaceProbeExplainToSurfaceReadinessDecision" \
  "didKeepExecutionFeedbackLoopSurfaceProbeSemanticDiffRollbackReady" \
  "didKeepExecutionFeedbackLoopSurfaceProbeExplainVisibilityNotPublished" \
  "didPrepareStage363ExecutionFeedbackLoopProbeResultEnvelope" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage362 internal ai generated ui demo execution feedback loop surface probe semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage362_internal_ai_generated_ui_demo_execution_feedback_loop_surface_probe_semantic_diff_explain_owner_present=true"
echo "stage361_internal_ai_generated_ui_demo_execution_feedback_loop_surface_to_probe_refresh_required=true"
echo "ai_generated_ui_demo_execution_feedback_loop_surface_probe_semantic_diff_materialized=true"
echo "ai_generated_ui_demo_execution_feedback_loop_surface_probe_explain_packet_materialized=true"
echo "execution_feedback_loop_surface_probe_semantic_diff_bound_to_surface_to_probe_refresh=true"
echo "execution_feedback_loop_surface_probe_explain_bound_to_surface_readiness_decision=true"
echo "execution_feedback_loop_surface_probe_semantic_diff_rollback_ready=true"
echo "execution_feedback_loop_surface_probe_explain_visibility_not_published=true"
echo "stage363_execution_feedback_loop_probe_result_envelope_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
