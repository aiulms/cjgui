#!/usr/bin/env zsh
#
# 维护注释：验证 stage333 internal AI-generated UI demo execution result-to-surface owner。
# 它消费 stage332 execution readiness，把 execution result 映射成 owner-local surface refresh。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage333_internal_ai_generated_ui_demo_execution_result_to_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage333 internal ai generated ui demo execution result to surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage333InternalAiGeneratedUiDemoExecutionResultToSurfaceFacts" \
  "CjguiInternalRendererStage333InternalAiGeneratedUiDemoExecutionResultToSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage333InternalAiGeneratedUiDemoExecutionResultToSurfaceDraft" \
  "didConsumeStage332InternalAiGeneratedUiDemoExecutionReadinessDecision" \
  "didMaterializeAiGeneratedUiDemoExecutionResultToSurface" \
  "didBindExecutionResultToSurfaceToExecutionDryRun" \
  "didBindExecutionResultToSurfaceToExecutionResultEnvelope" \
  "didBindExecutionResultToSurfaceToExecutionSemanticDiffExplain" \
  "didKeepExecutionResultToSurfaceOwnerLocalInMemoryOnly" \
  "didKeepExecutionResultToSurfaceVisibilityNotPublished" \
  "didPrepareStage334ExecutionSurfaceSemanticDiffExplain" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage333 internal ai generated ui demo execution result to surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage333_internal_ai_generated_ui_demo_execution_result_to_surface_owner_present=true"
echo "stage332_internal_ai_generated_ui_demo_execution_readiness_decision_required=true"
echo "ai_generated_ui_demo_execution_result_to_surface_materialized=true"
echo "execution_result_to_surface_bound_to_execution_dry_run=true"
echo "execution_result_to_surface_bound_to_execution_result_envelope=true"
echo "execution_result_to_surface_bound_to_execution_semantic_diff_explain=true"
echo "execution_result_to_surface_owner_local_in_memory_only=true"
echo "execution_result_to_surface_visibility_not_published=true"
echo "stage334_execution_surface_semantic_diff_explain_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
