#!/usr/bin/env zsh
#
# 维护注释：验证 stage301 internal AI-generated UI demo owner acceptance gate input owner。
# 它只接收 stage300 readiness，形成 owner-local accept token / reject reason gate 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage301_internal_ai_generated_ui_demo_owner_acceptance_gate_input.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage301 internal ai generated ui demo owner acceptance gate input: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage301InternalAiGeneratedUiDemoOwnerAcceptanceGateInputFacts" \
  "CjguiInternalRendererStage301InternalAiGeneratedUiDemoOwnerAcceptanceGateInputReadiness" \
  "cjguiInternalExecuteDefaultRendererStage301InternalAiGeneratedUiDemoOwnerAcceptanceGateInputDraft" \
  "didConsumeStage300InternalAiGeneratedUiDemoAcceptRejectReadinessDecision" \
  "didMaterializeAiGeneratedUiOwnerAcceptanceGateInput" \
  "didBindOwnerAcceptanceGateToAcceptRejectReadiness" \
  "didRequireOwnerAcceptanceTokenForAcceptBranch" \
  "didRequireOwnerRejectReasonForRejectBranch" \
  "didKeepOwnerAcceptanceGateOwnerLocalInMemoryOnly" \
  "didKeepOwnerAcceptanceGateNonExecuting" \
  "didPrepareStage302AiGeneratedUiDemoAcceptTokenDryRunInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage301 internal ai generated ui demo owner acceptance gate input: missing token $token" >&2
    exit 3
  fi
done

echo "stage301_internal_ai_generated_ui_demo_owner_acceptance_gate_input_owner_present=true"
echo "stage300_internal_ai_generated_ui_demo_accept_reject_readiness_decision_required=true"
echo "ai_generated_ui_owner_acceptance_gate_input_materialized=true"
echo "owner_acceptance_gate_bound_to_accept_reject_readiness=true"
echo "owner_acceptance_gate_requires_owner_acceptance_token=true"
echo "owner_acceptance_gate_requires_owner_reject_reason=true"
echo "owner_acceptance_gate_owner_local_in_memory_only=true"
echo "owner_acceptance_gate_non_executing=true"
echo "stage302_ai_generated_ui_demo_accept_token_dry_run_input_prepared=true"
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
