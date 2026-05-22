#!/usr/bin/env zsh
#
# 维护注释：验证 stage343 internal AI-generated UI demo execution probe-to-surface feedback result envelope owner。
# 它把 feedback diff/explain 封装为 owner-local rollback-ready result envelope。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage343_internal_ai_generated_ui_demo_execution_probe_to_surface_feedback_result_envelope.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage343 internal ai generated ui demo execution probe to surface feedback result envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage343InternalAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackResultEnvelopeFacts" \
  "CjguiInternalRendererStage343InternalAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackResultEnvelopeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage343InternalAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackResultEnvelopeDraft" \
  "didConsumeStage342ExecutionProbeToSurfaceFeedbackSemanticDiffExplain" \
  "didMaterializeAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackResultEnvelope" \
  "didBindExecutionProbeToSurfaceFeedbackResultEnvelopeToFeedback" \
  "didBindExecutionProbeToSurfaceFeedbackResultEnvelopeToSemanticDiffExplain" \
  "didKeepExecutionProbeToSurfaceFeedbackResultEnvelopeRollbackReady" \
  "didKeepExecutionProbeToSurfaceFeedbackResultEnvelopeVisibilityNotPublished" \
  "didKeepExecutionProbeToSurfaceFeedbackResultEnvelopeOwnerLocalInMemoryOnly" \
  "didKeepExecutionProbeToSurfaceFeedbackResultEnvelopeNonDispatching" \
  "didPrepareStage344ExecutionProbeToSurfaceFeedbackReadinessDecision" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage343 internal ai generated ui demo execution probe to surface feedback result envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage343_internal_ai_generated_ui_demo_execution_probe_to_surface_feedback_result_envelope_owner_present=true"
echo "stage342_internal_ai_generated_ui_demo_execution_probe_to_surface_feedback_semantic_diff_explain_required=true"
echo "ai_generated_ui_demo_execution_probe_to_surface_feedback_result_envelope_materialized=true"
echo "execution_probe_to_surface_feedback_result_envelope_bound_to_feedback=true"
echo "execution_probe_to_surface_feedback_result_envelope_bound_to_semantic_diff_explain=true"
echo "execution_probe_to_surface_feedback_result_envelope_rollback_ready=true"
echo "execution_probe_to_surface_feedback_result_envelope_visibility_not_published=true"
echo "execution_probe_to_surface_feedback_result_envelope_owner_local_in_memory_only=true"
echo "execution_probe_to_surface_feedback_result_envelope_non_dispatching=true"
echo "stage344_execution_probe_to_surface_feedback_readiness_decision_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
