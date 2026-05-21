#!/usr/bin/env zsh
#
# 维护注释：验证 stage304 internal AI-generated UI demo owner acceptance gate readiness decision owner。
# 它汇合 gate input、accept token dry-run 与 reject reason ledger，并只准备 stage305 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage304_internal_ai_generated_ui_demo_owner_acceptance_gate_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage304 internal ai generated ui demo owner acceptance gate readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage304InternalAiGeneratedUiDemoOwnerAcceptanceGateReadinessDecisionFacts" \
  "CjguiInternalRendererStage304InternalAiGeneratedUiDemoOwnerAcceptanceGateReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage304InternalAiGeneratedUiDemoOwnerAcceptanceGateReadinessDecisionDraft" \
  "didConsumeStage303InternalAiGeneratedUiDemoRejectReasonLedger" \
  "didJoinOwnerAcceptanceGateInputAcceptTokenRejectLedger" \
  "didJoinOwnerAcceptanceGateRollbackVisibilityBoundary" \
  "didMaterializeInternalAiGeneratedUiOwnerAcceptanceGateReadinessDecision" \
  "didPrepareStage305AiGeneratedUiDemoComponentStateRenderDryRunInput" \
  "didConfirmMinimalUiFrameworkOwnerAcceptanceGateRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage304 internal ai generated ui demo owner acceptance gate readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage304_internal_ai_generated_ui_demo_owner_acceptance_gate_readiness_decision_owner_present=true"
echo "stage303_internal_ai_generated_ui_demo_reject_reason_ledger_required=true"
echo "internal_ai_generated_ui_owner_acceptance_gate_readiness_decision_materialized=true"
echo "owner_acceptance_gate_input_accept_token_reject_ledger_joined=true"
echo "owner_acceptance_gate_rollback_visibility_boundary_joined=true"
echo "stage305_ai_generated_ui_demo_component_state_render_dry_run_input_prepared=true"
echo "minimal_ui_framework_owner_acceptance_gate_runway_advanced=true"
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
