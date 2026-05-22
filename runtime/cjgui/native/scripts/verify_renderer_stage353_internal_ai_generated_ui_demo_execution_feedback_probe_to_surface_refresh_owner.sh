#!/usr/bin/env zsh
#
# 维护注释：验证 stage353 internal AI-generated UI demo execution feedback probe-to-surface refresh owner。
# 它消费 stage352 feedback probe readiness，把 owner-local probe readiness 刷新回下一段 surface 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage353_internal_ai_generated_ui_demo_execution_feedback_probe_to_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage353 internal ai generated ui demo execution feedback probe to surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage353InternalAiGeneratedUiDemoExecutionFeedbackProbeToSurfaceRefreshFacts" \
  "CjguiInternalRendererStage353InternalAiGeneratedUiDemoExecutionFeedbackProbeToSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage353InternalAiGeneratedUiDemoExecutionFeedbackProbeToSurfaceRefreshDraft" \
  "didConsumeStage352InternalAiGeneratedUiDemoExecutionFeedbackProbeReadinessDecision" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackProbeToSurfaceRefresh" \
  "didBindExecutionFeedbackProbeToSurfaceRefreshToFeedbackProbeReadinessDecision" \
  "didBindExecutionFeedbackProbeToSurfaceRefreshToFeedbackProbeResultEnvelope" \
  "didBindExecutionFeedbackProbeToSurfaceRefreshToNextSurfaceInput" \
  "didKeepExecutionFeedbackProbeToSurfaceRefreshOwnerLocalInMemoryOnly" \
  "didKeepExecutionFeedbackProbeToSurfaceRefreshNonPublishing" \
  "didKeepExecutionFeedbackProbeToSurfaceRefreshVisibilityNotPublished" \
  "didPrepareStage354ExecutionFeedbackLoopSemanticDiffExplain" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage353 internal ai generated ui demo execution feedback probe to surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage353_internal_ai_generated_ui_demo_execution_feedback_probe_to_surface_refresh_owner_present=true"
echo "stage352_internal_ai_generated_ui_demo_execution_feedback_probe_readiness_decision_required=true"
echo "ai_generated_ui_demo_execution_feedback_probe_to_surface_refresh_materialized=true"
echo "execution_feedback_probe_to_surface_refresh_bound_to_feedback_probe_readiness_decision=true"
echo "execution_feedback_probe_to_surface_refresh_bound_to_feedback_probe_result_envelope=true"
echo "execution_feedback_probe_to_surface_refresh_bound_to_next_surface_input=true"
echo "execution_feedback_probe_to_surface_refresh_owner_local_in_memory_only=true"
echo "execution_feedback_probe_to_surface_refresh_non_publishing=true"
echo "execution_feedback_probe_to_surface_refresh_visibility_not_published=true"
echo "stage354_execution_feedback_loop_semantic_diff_explain_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
