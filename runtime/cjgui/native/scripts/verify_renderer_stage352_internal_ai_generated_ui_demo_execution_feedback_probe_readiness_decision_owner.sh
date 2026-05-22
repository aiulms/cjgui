#!/usr/bin/env zsh
#
# 维护注释：验证 stage352 internal AI-generated UI demo execution feedback probe readiness decision owner。
# 它汇合 feedback surface-to-probe refresh、probe diff/explain 与 result envelope，准备下一段 feedback probe-to-surface refresh。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage352_internal_ai_generated_ui_demo_execution_feedback_probe_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage352 internal ai generated ui demo execution feedback probe readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage352InternalAiGeneratedUiDemoExecutionFeedbackProbeReadinessDecisionFacts" \
  "CjguiInternalRendererStage352InternalAiGeneratedUiDemoExecutionFeedbackProbeReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage352InternalAiGeneratedUiDemoExecutionFeedbackProbeReadinessDecisionDraft" \
  "didConsumeStage351ExecutionFeedbackProbeResultEnvelope" \
  "didJoinExecutionFeedbackSurfaceToProbeRefreshWithSemanticDiffExplain" \
  "didJoinExecutionFeedbackProbeResultEnvelopeWithSurfaceProbeDiffExplain" \
  "didJoinExecutionFeedbackProbeRunwayWithRollbackVisibilityBoundary" \
  "didMaterializeInternalAiGeneratedUiDemoExecutionFeedbackProbeReadinessDecision" \
  "didPrepareStage353InternalAiGeneratedUiDemoExecutionFeedbackProbeToSurfaceRefresh" \
  "didConfirmMinimalUiFrameworkAiGeneratedUiDemoExecutionFeedbackProbeRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage352 internal ai generated ui demo execution feedback probe readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage352_internal_ai_generated_ui_demo_execution_feedback_probe_readiness_decision_owner_present=true"
echo "stage351_internal_ai_generated_ui_demo_execution_feedback_probe_result_envelope_required=true"
echo "internal_ai_generated_ui_demo_execution_feedback_probe_readiness_decision_materialized=true"
echo "execution_feedback_surface_to_probe_refresh_semantic_diff_explain_joined=true"
echo "execution_feedback_probe_result_envelope_surface_probe_diff_explain_joined=true"
echo "execution_feedback_probe_runway_rollback_visibility_boundary_joined=true"
echo "stage353_internal_ai_generated_ui_demo_execution_feedback_probe_to_surface_refresh_prepared=true"
echo "minimal_ui_framework_ai_generated_ui_execution_feedback_probe_runway_advanced=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
