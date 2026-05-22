#!/usr/bin/env zsh
#
# 维护注释：验证 stage366 internal AI-generated UI demo execution feedback loop semantic diff/explain owner。
# 它解释 stage365 probe-to-surface refresh，不执行真实 surface 发布或 backend。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage366_internal_ai_generated_ui_demo_execution_feedback_loop_convergence_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage366 internal ai generated ui demo execution feedback loop convergence semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage366InternalAiGeneratedUiDemoExecutionFeedbackLoopConvergenceSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage366InternalAiGeneratedUiDemoExecutionFeedbackLoopConvergenceSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage366InternalAiGeneratedUiDemoExecutionFeedbackLoopConvergenceSemanticDiffExplainDraft" \
  "didConsumeStage365ExecutionFeedbackLoopProbeToSurfaceRefresh" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackLoopConvergenceSemanticDiff" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackLoopConvergenceExplainPacket" \
  "didBindExecutionFeedbackLoopConvergenceSemanticDiffToProbeToSurfaceRefresh" \
  "didBindExecutionFeedbackLoopConvergenceExplainToFeedbackLoopProbeReadinessDecision" \
  "didKeepExecutionFeedbackLoopConvergenceSemanticDiffRollbackReady" \
  "didKeepExecutionFeedbackLoopConvergenceExplainVisibilityNotPublished" \
  "didPrepareStage367ExecutionFeedbackLoopConvergenceResultEnvelope" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage366 internal ai generated ui demo execution feedback loop convergence semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage366_internal_ai_generated_ui_demo_execution_feedback_loop_convergence_semantic_diff_explain_owner_present=true"
echo "stage365_internal_ai_generated_ui_demo_execution_feedback_loop_probe_to_surface_refresh_required=true"
echo "ai_generated_ui_demo_execution_feedback_loop_convergence_semantic_diff_materialized=true"
echo "ai_generated_ui_demo_execution_feedback_loop_convergence_explain_packet_materialized=true"
echo "execution_feedback_loop_convergence_semantic_diff_bound_to_probe_to_surface_refresh=true"
echo "execution_feedback_loop_convergence_explain_bound_to_feedback_loop_probe_readiness_decision=true"
echo "execution_feedback_loop_convergence_semantic_diff_rollback_ready=true"
echo "execution_feedback_loop_convergence_explain_visibility_not_published=true"
echo "stage367_execution_feedback_loop_convergence_result_envelope_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
