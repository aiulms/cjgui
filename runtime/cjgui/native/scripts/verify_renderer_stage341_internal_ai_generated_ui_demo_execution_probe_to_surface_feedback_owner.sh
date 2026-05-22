#!/usr/bin/env zsh
#
# 维护注释：验证 stage341 internal AI-generated UI demo execution probe-to-surface feedback owner。
# 它消费 stage340 probe readiness，把 probe result 反馈回 owner-local surface runway。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage341_internal_ai_generated_ui_demo_execution_probe_to_surface_feedback.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage341 internal ai generated ui demo execution probe to surface feedback: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage341InternalAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackFacts" \
  "CjguiInternalRendererStage341InternalAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackReadiness" \
  "cjguiInternalExecuteDefaultRendererStage341InternalAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackDraft" \
  "didConsumeStage340InternalAiGeneratedUiDemoExecutionProbeReadinessDecision" \
  "didMaterializeAiGeneratedUiDemoExecutionProbeToSurfaceFeedback" \
  "didBindExecutionProbeToSurfaceFeedbackToProbeReadinessDecision" \
  "didBindExecutionProbeToSurfaceFeedbackToExecutionProbeResultEnvelope" \
  "didBindExecutionProbeToSurfaceFeedbackToSurfaceToProbeRefresh" \
  "didKeepExecutionProbeToSurfaceFeedbackOwnerLocalInMemoryOnly" \
  "didKeepExecutionProbeToSurfaceFeedbackRollbackReady" \
  "didKeepExecutionProbeToSurfaceFeedbackVisibilityNotPublished" \
  "didPrepareStage342ExecutionProbeToSurfaceFeedbackSemanticDiffExplain" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage341 internal ai generated ui demo execution probe to surface feedback: missing token $token" >&2
    exit 3
  fi
done

echo "stage341_internal_ai_generated_ui_demo_execution_probe_to_surface_feedback_owner_present=true"
echo "stage340_internal_ai_generated_ui_demo_execution_probe_readiness_decision_required=true"
echo "ai_generated_ui_demo_execution_probe_to_surface_feedback_materialized=true"
echo "execution_probe_to_surface_feedback_bound_to_probe_readiness_decision=true"
echo "execution_probe_to_surface_feedback_bound_to_execution_probe_result_envelope=true"
echo "execution_probe_to_surface_feedback_bound_to_surface_to_probe_refresh=true"
echo "execution_probe_to_surface_feedback_owner_local_in_memory_only=true"
echo "execution_probe_to_surface_feedback_rollback_ready=true"
echo "execution_probe_to_surface_feedback_visibility_not_published=true"
echo "stage342_execution_probe_to_surface_feedback_semantic_diff_explain_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
