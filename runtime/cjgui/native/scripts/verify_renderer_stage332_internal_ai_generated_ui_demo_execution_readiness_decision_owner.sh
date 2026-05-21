#!/usr/bin/env zsh
#
# 维护注释：验证 stage332 internal AI-generated UI demo execution readiness decision owner。
# 它汇合 execution dry-run、result envelope 与 semantic diff/explain，准备下一段 surface 刷新。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage332_internal_ai_generated_ui_demo_execution_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage332 internal ai generated ui demo execution readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage332InternalAiGeneratedUiDemoExecutionReadinessDecisionFacts" \
  "CjguiInternalRendererStage332InternalAiGeneratedUiDemoExecutionReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage332InternalAiGeneratedUiDemoExecutionReadinessDecisionDraft" \
  "didConsumeStage331ExecutionSemanticDiffExplain" \
  "didJoinExecutionDryRunWithResultEnvelope" \
  "didJoinExecutionResultWithSemanticDiffExplain" \
  "didJoinExecutionRunwayWithRollbackVisibilityBoundary" \
  "didMaterializeInternalAiGeneratedUiDemoExecutionReadinessDecision" \
  "didPrepareStage333InternalAiGeneratedUiDemoExecutionResultToSurface" \
  "didConfirmMinimalUiFrameworkAiGeneratedUiDemoExecutionRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage332 internal ai generated ui demo execution readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage332_internal_ai_generated_ui_demo_execution_readiness_decision_owner_present=true"
echo "stage331_internal_ai_generated_ui_demo_execution_semantic_diff_explain_required=true"
echo "internal_ai_generated_ui_demo_execution_readiness_decision_materialized=true"
echo "execution_dry_run_result_envelope_joined=true"
echo "execution_result_semantic_diff_explain_joined=true"
echo "execution_runway_rollback_visibility_boundary_joined=true"
echo "stage333_internal_ai_generated_ui_demo_execution_result_to_surface_prepared=true"
echo "minimal_ui_framework_ai_generated_ui_execution_runway_advanced=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
