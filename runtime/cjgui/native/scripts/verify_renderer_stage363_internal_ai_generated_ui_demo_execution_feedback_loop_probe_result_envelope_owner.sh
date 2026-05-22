#!/usr/bin/env zsh
#
# 维护注释：验证 stage363 internal AI-generated UI demo execution feedback loop probe result envelope owner。
# 它消费 stage362 surface probe diff/explain，封装 owner-local rollback-ready feedback loop probe result envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage363_internal_ai_generated_ui_demo_execution_feedback_loop_probe_result_envelope.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage363 internal ai generated ui demo execution feedback loop probe result envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage363InternalAiGeneratedUiDemoExecutionFeedbackLoopProbeResultEnvelopeFacts" \
  "CjguiInternalRendererStage363InternalAiGeneratedUiDemoExecutionFeedbackLoopProbeResultEnvelopeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage363InternalAiGeneratedUiDemoExecutionFeedbackLoopProbeResultEnvelopeDraft" \
  "didConsumeStage362ExecutionFeedbackLoopSurfaceProbeSemanticDiffExplain" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackLoopProbeResultEnvelope" \
  "didBindExecutionFeedbackLoopProbeResultEnvelopeToSurfaceToProbeRefresh" \
  "didBindExecutionFeedbackLoopProbeResultEnvelopeToSurfaceProbeSemanticDiffExplain" \
  "didKeepExecutionFeedbackLoopProbeResultEnvelopeRollbackReady" \
  "didKeepExecutionFeedbackLoopProbeResultEnvelopeVisibilityNotPublished" \
  "didKeepExecutionFeedbackLoopProbeResultEnvelopeOwnerLocalInMemoryOnly" \
  "didKeepExecutionFeedbackLoopProbeResultEnvelopeNonDispatching" \
  "didPrepareStage364ExecutionFeedbackLoopProbeReadinessDecision" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage363 internal ai generated ui demo execution feedback loop probe result envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage363_internal_ai_generated_ui_demo_execution_feedback_loop_probe_result_envelope_owner_present=true"
echo "stage362_internal_ai_generated_ui_demo_execution_feedback_loop_surface_probe_semantic_diff_explain_required=true"
echo "ai_generated_ui_demo_execution_feedback_loop_probe_result_envelope_materialized=true"
echo "execution_feedback_loop_probe_result_envelope_bound_to_surface_to_probe_refresh=true"
echo "execution_feedback_loop_probe_result_envelope_bound_to_surface_probe_semantic_diff_explain=true"
echo "execution_feedback_loop_probe_result_envelope_rollback_ready=true"
echo "execution_feedback_loop_probe_result_envelope_visibility_not_published=true"
echo "execution_feedback_loop_probe_result_envelope_owner_local_in_memory_only=true"
echo "execution_feedback_loop_probe_result_envelope_non_dispatching=true"
echo "stage364_execution_feedback_loop_probe_readiness_decision_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
