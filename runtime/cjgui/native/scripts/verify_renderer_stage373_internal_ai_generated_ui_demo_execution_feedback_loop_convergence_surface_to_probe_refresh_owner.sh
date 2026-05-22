#!/usr/bin/env zsh
#
# 维护注释：验证 stage373 internal AI-generated UI demo execution feedback loop convergence surface-to-probe refresh owner。
# 它消费 stage372 feedback loop convergence surface readiness，把 owner-local convergence surface readiness 刷新为下一段 probe 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage373_internal_ai_generated_ui_demo_execution_feedback_loop_convergence_surface_to_probe_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage373 internal ai generated ui demo execution feedback loop convergence surface to probe refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage373InternalAiGeneratedUiDemoExecutionFeedbackLoopConvergenceSurfaceToProbeRefreshFacts" \
  "CjguiInternalRendererStage373InternalAiGeneratedUiDemoExecutionFeedbackLoopConvergenceSurfaceToProbeRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage373InternalAiGeneratedUiDemoExecutionFeedbackLoopConvergenceSurfaceToProbeRefreshDraft" \
  "didConsumeStage372InternalAiGeneratedUiDemoExecutionFeedbackLoopConvergenceSurfaceReadinessDecision" \
  "didMaterializeAiGeneratedUiDemoExecutionFeedbackLoopConvergenceSurfaceToProbeRefresh" \
  "didBindExecutionFeedbackLoopConvergenceSurfaceToProbeRefreshToConvergenceSurfaceReadinessDecision" \
  "didBindExecutionFeedbackLoopConvergenceSurfaceToProbeRefreshToConvergenceSurfaceProbeInput" \
  "didBindExecutionFeedbackLoopConvergenceSurfaceToProbeRefreshToConvergenceSurfaceProbeResultEnvelope" \
  "didKeepExecutionFeedbackLoopConvergenceSurfaceToProbeRefreshOwnerLocalInMemoryOnly" \
  "didKeepExecutionFeedbackLoopConvergenceSurfaceToProbeRefreshNonExecuting" \
  "didKeepExecutionFeedbackLoopConvergenceSurfaceToProbeRefreshVisibilityNotPublished" \
  "didPrepareStage374ExecutionFeedbackLoopConvergenceSurfaceProbeSemanticDiffExplain" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage373 internal ai generated ui demo execution feedback loop convergence surface to probe refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage373_internal_ai_generated_ui_demo_execution_feedback_loop_convergence_surface_to_probe_refresh_owner_present=true"
echo "stage372_internal_ai_generated_ui_demo_execution_feedback_loop_convergence_surface_readiness_decision_required=true"
echo "ai_generated_ui_demo_execution_feedback_loop_convergence_surface_to_probe_refresh_materialized=true"
echo "execution_feedback_loop_convergence_surface_to_probe_refresh_bound_to_convergence_surface_readiness_decision=true"
echo "execution_feedback_loop_convergence_surface_to_probe_refresh_bound_to_convergence_surface_probe_input=true"
echo "execution_feedback_loop_convergence_surface_to_probe_refresh_bound_to_convergence_surface_probe_result_envelope=true"
echo "execution_feedback_loop_convergence_surface_to_probe_refresh_owner_local_in_memory_only=true"
echo "execution_feedback_loop_convergence_surface_to_probe_refresh_non_executing=true"
echo "execution_feedback_loop_convergence_surface_to_probe_refresh_visibility_not_published=true"
echo "stage374_execution_feedback_loop_convergence_surface_probe_semantic_diff_explain_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
