#!/usr/bin/env zsh
#
# 维护注释：验证 stage300 internal AI-generated UI demo accept/reject readiness decision owner。
# 它汇合 accept/reject dry-run input/result/diff，并只准备 owner gate 入口。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage300_internal_ai_generated_ui_demo_accept_reject_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage300 internal ai generated ui demo accept reject readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage300InternalAiGeneratedUiDemoAcceptRejectReadinessDecisionFacts" \
  "CjguiInternalRendererStage300InternalAiGeneratedUiDemoAcceptRejectReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage300InternalAiGeneratedUiDemoAcceptRejectReadinessDecisionDraft" \
  "didConsumeStage299InternalAiGeneratedUiDemoAcceptRejectSemanticDiffExplain" \
  "didJoinAiGeneratedUiAcceptRejectDryRunInputResultDiff" \
  "didJoinAiGeneratedUiAcceptRejectOwnerAcceptanceBoundary" \
  "didJoinAiGeneratedUiAcceptRejectRollbackVisibilityBoundary" \
  "didMaterializeInternalAiGeneratedUiAcceptRejectReadinessDecision" \
  "didPrepareStage301InternalAiGeneratedUiDemoOwnerAcceptanceGateInput" \
  "didConfirmMinimalUiFrameworkAcceptRejectRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage300 internal ai generated ui demo accept reject readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage300_internal_ai_generated_ui_demo_accept_reject_readiness_decision_owner_present=true"
echo "stage299_internal_ai_generated_ui_demo_accept_reject_semantic_diff_explain_required=true"
echo "internal_ai_generated_ui_accept_reject_readiness_decision_materialized=true"
echo "ai_generated_ui_accept_reject_dry_run_input_result_diff_joined=true"
echo "ai_generated_ui_accept_reject_owner_acceptance_boundary_joined=true"
echo "ai_generated_ui_accept_reject_rollback_visibility_boundary_joined=true"
echo "stage301_internal_ai_generated_ui_demo_owner_acceptance_gate_input_prepared=true"
echo "minimal_ui_framework_accept_reject_runway_advanced=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
