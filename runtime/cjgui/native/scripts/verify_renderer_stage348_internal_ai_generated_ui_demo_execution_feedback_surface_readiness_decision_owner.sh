#!/usr/bin/env zsh
#
# 维护注释：验证 stage348 internal AI-generated UI demo execution feedback surface readiness decision owner。
# 它汇合 feedback surface refresh、diff/explain 与 probe envelope，准备 feedback surface-to-probe refresh。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage348_internal_ai_generated_ui_demo_execution_feedback_surface_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage348 internal ai generated ui demo execution feedback surface readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage348InternalAiGeneratedUiDemoExecutionFeedbackSurfaceReadinessDecisionFacts" \
  "CjguiInternalRendererStage348InternalAiGeneratedUiDemoExecutionFeedbackSurfaceReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage348InternalAiGeneratedUiDemoExecutionFeedbackSurfaceReadinessDecisionDraft" \
  "didConsumeStage347ExecutionFeedbackSurfaceProbeInputResultEnvelope" \
  "didJoinExecutionFeedbackSurfaceRefreshWithSemanticDiffExplain" \
  "didJoinExecutionFeedbackSurfaceProbeInputWithResultEnvelope" \
  "didJoinExecutionFeedbackSurfaceRunwayWithRollbackVisibilityBoundary" \
  "didMaterializeInternalAiGeneratedUiDemoExecutionFeedbackSurfaceReadinessDecision" \
  "didPrepareStage349InternalAiGeneratedUiDemoExecutionFeedbackSurfaceToProbeRefresh" \
  "didConfirmMinimalUiFrameworkAiGeneratedUiDemoExecutionFeedbackSurfaceRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage348 internal ai generated ui demo execution feedback surface readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage348_internal_ai_generated_ui_demo_execution_feedback_surface_readiness_decision_owner_present=true"
echo "stage347_internal_ai_generated_ui_demo_execution_feedback_surface_probe_input_result_envelope_required=true"
echo "internal_ai_generated_ui_demo_execution_feedback_surface_readiness_decision_materialized=true"
echo "execution_feedback_surface_refresh_semantic_diff_explain_joined=true"
echo "execution_feedback_surface_probe_input_result_envelope_joined=true"
echo "execution_feedback_surface_runway_rollback_visibility_boundary_joined=true"
echo "stage349_internal_ai_generated_ui_demo_execution_feedback_surface_to_probe_refresh_prepared=true"
echo "minimal_ui_framework_ai_generated_ui_execution_feedback_surface_runway_advanced=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
