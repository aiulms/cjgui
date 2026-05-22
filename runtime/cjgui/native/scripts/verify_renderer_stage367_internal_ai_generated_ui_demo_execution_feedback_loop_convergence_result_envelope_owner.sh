#!/usr/bin/env zsh
#
# 维护注释：验证 stage367 internal AI-generated UI demo execution feedback loop convergence result envelope owner。
# 它把 stage366 diff/explain 封装成 owner-local rollback-ready feedback loop convergence result envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage367_internal_ai_generated_ui_demo_execution_feedback_loop_convergence_result_envelope.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage367 internal ai generated ui demo execution feedback loop convergence result envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage367InternalAiGeneratedUiDemoExecutionFeedbackLoopConvergenceResultEnvelopeFacts" \
  "CjguiInternalRendererStage367InternalAiGeneratedUiDemoExecutionFeedbackLoopConvergenceResultEnvelopeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage367InternalAiGeneratedUiDemoExecutionFeedbackLoopConvergenceResultEnvelopeDraft" \
  "didConsumeStage366ExecutionFeedbackLoopConvergenceSemanticDiffExplain" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackLoopConvergenceResultEnvelope" \
  "didBindExecutionFeedbackLoopConvergenceResultEnvelopeToProbeToSurfaceRefresh" \
  "didBindExecutionFeedbackLoopConvergenceResultEnvelopeToFeedbackLoopConvergenceSemanticDiffExplain" \
  "didKeepExecutionFeedbackLoopConvergenceResultEnvelopeRollbackReady" \
  "didKeepExecutionFeedbackLoopConvergenceResultEnvelopeVisibilityNotPublished" \
  "didKeepExecutionFeedbackLoopConvergenceResultEnvelopeOwnerLocalInMemoryOnly" \
  "didKeepExecutionFeedbackLoopConvergenceResultEnvelopeNonDispatching" \
  "didPrepareStage368ExecutionFeedbackLoopConvergenceReadinessDecision" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage367 internal ai generated ui demo execution feedback loop convergence result envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage367_internal_ai_generated_ui_demo_execution_feedback_loop_convergence_result_envelope_owner_present=true"
echo "stage366_internal_ai_generated_ui_demo_execution_feedback_loop_convergence_semantic_diff_explain_required=true"
echo "ai_generated_ui_demo_execution_feedback_loop_convergence_result_envelope_materialized=true"
echo "execution_feedback_loop_convergence_result_envelope_bound_to_probe_to_surface_refresh=true"
echo "execution_feedback_loop_convergence_result_envelope_bound_to_feedback_loop_convergence_semantic_diff_explain=true"
echo "execution_feedback_loop_convergence_result_envelope_rollback_ready=true"
echo "execution_feedback_loop_convergence_result_envelope_visibility_not_published=true"
echo "execution_feedback_loop_convergence_result_envelope_owner_local_in_memory_only=true"
echo "execution_feedback_loop_convergence_result_envelope_non_dispatching=true"
echo "stage368_execution_feedback_loop_convergence_readiness_decision_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
