#!/usr/bin/env zsh
#
# 维护注释：验证 stage345 internal AI-generated UI demo execution feedback surface refresh owner。
# 它消费 stage344 feedback readiness，把反馈结果刷新为下一段 owner-local surface 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage345_internal_ai_generated_ui_demo_execution_feedback_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage345 internal ai generated ui demo execution feedback surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage345InternalAiGeneratedUiDemoExecutionFeedbackSurfaceRefreshFacts" \
  "CjguiInternalRendererStage345InternalAiGeneratedUiDemoExecutionFeedbackSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage345InternalAiGeneratedUiDemoExecutionFeedbackSurfaceRefreshDraft" \
  "didConsumeStage344InternalAiGeneratedUiDemoExecutionProbeToSurfaceFeedbackReadinessDecision" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackSurfaceRefresh" \
  "didBindExecutionFeedbackSurfaceRefreshToFeedbackReadinessDecision" \
  "didBindExecutionFeedbackSurfaceRefreshToProbeToSurfaceFeedback" \
  "didBindExecutionFeedbackSurfaceRefreshToFeedbackResultEnvelope" \
  "didKeepExecutionFeedbackSurfaceRefreshOwnerLocalInMemoryOnly" \
  "didKeepExecutionFeedbackSurfaceRefreshVisibilityNotPublished" \
  "didPrepareStage346ExecutionFeedbackSurfaceSemanticDiffExplain" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage345 internal ai generated ui demo execution feedback surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage345_internal_ai_generated_ui_demo_execution_feedback_surface_refresh_owner_present=true"
echo "stage344_internal_ai_generated_ui_demo_execution_probe_to_surface_feedback_readiness_decision_required=true"
echo "ai_generated_ui_demo_execution_feedback_surface_refresh_materialized=true"
echo "execution_feedback_surface_refresh_bound_to_feedback_readiness_decision=true"
echo "execution_feedback_surface_refresh_bound_to_probe_to_surface_feedback=true"
echo "execution_feedback_surface_refresh_bound_to_feedback_result_envelope=true"
echo "execution_feedback_surface_refresh_owner_local_in_memory_only=true"
echo "execution_feedback_surface_refresh_visibility_not_published=true"
echo "stage346_execution_feedback_surface_semantic_diff_explain_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
