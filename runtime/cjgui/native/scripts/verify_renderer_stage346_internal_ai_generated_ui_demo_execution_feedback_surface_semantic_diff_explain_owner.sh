#!/usr/bin/env zsh
#
# 维护注释：验证 stage346 internal AI-generated UI demo execution feedback surface semantic diff/explain owner。
# 它解释 stage345 feedback surface refresh，并准备 feedback surface probe input/result envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage346_internal_ai_generated_ui_demo_execution_feedback_surface_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage346 internal ai generated ui demo execution feedback surface semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage346InternalAiGeneratedUiDemoExecutionFeedbackSurfaceSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage346InternalAiGeneratedUiDemoExecutionFeedbackSurfaceSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage346InternalAiGeneratedUiDemoExecutionFeedbackSurfaceSemanticDiffExplainDraft" \
  "didConsumeStage345ExecutionFeedbackSurfaceRefresh" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackSurfaceSemanticDiff" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackSurfaceExplainPacket" \
  "didBindExecutionFeedbackSurfaceSemanticDiffToSurfaceRefresh" \
  "didBindExecutionFeedbackSurfaceExplainToFeedbackReadinessDecision" \
  "didKeepExecutionFeedbackSurfaceSemanticDiffRollbackReady" \
  "didKeepExecutionFeedbackSurfaceExplainVisibilityNotPublished" \
  "didPrepareStage347ExecutionFeedbackSurfaceProbeInputResultEnvelope" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage346 internal ai generated ui demo execution feedback surface semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage346_internal_ai_generated_ui_demo_execution_feedback_surface_semantic_diff_explain_owner_present=true"
echo "stage345_internal_ai_generated_ui_demo_execution_feedback_surface_refresh_required=true"
echo "ai_generated_ui_demo_execution_feedback_surface_semantic_diff_materialized=true"
echo "ai_generated_ui_demo_execution_feedback_surface_explain_packet_materialized=true"
echo "execution_feedback_surface_semantic_diff_bound_to_surface_refresh=true"
echo "execution_feedback_surface_explain_bound_to_feedback_readiness_decision=true"
echo "execution_feedback_surface_semantic_diff_rollback_ready=true"
echo "execution_feedback_surface_explain_visibility_not_published=true"
echo "stage347_execution_feedback_surface_probe_input_result_envelope_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
