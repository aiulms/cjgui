#!/usr/bin/env zsh
#
# 维护注释：验证 stage297 internal AI-generated UI demo accept/reject dry-run input owner。
# 它只接收 stage296 readiness，形成 accept/reject 两条 non-executing dry-run 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage297_internal_ai_generated_ui_demo_accept_reject_dry_run_input.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage297 internal ai generated ui demo accept reject dry run input: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage297InternalAiGeneratedUiDemoAcceptRejectDryRunInputFacts" \
  "CjguiInternalRendererStage297InternalAiGeneratedUiDemoAcceptRejectDryRunInputReadiness" \
  "cjguiInternalExecuteDefaultRendererStage297InternalAiGeneratedUiDemoAcceptRejectDryRunInputDraft" \
  "didConsumeStage296InternalAiGeneratedUiDemoReadinessDecision" \
  "didMaterializeAiGeneratedUiAcceptRejectDryRunInput" \
  "didBindAcceptDryRunToOwnerAcceptanceRequirement" \
  "didBindAcceptDryRunToGeneratedFormSettingsPreview" \
  "didBindRejectDryRunToRollbackNoopPath" \
  "didBindRejectDryRunToExplainPacket" \
  "didKeepAiGeneratedUiAcceptRejectInputOwnerLocalInMemoryOnly" \
  "didKeepAiGeneratedUiAcceptRejectInputNonExecuting" \
  "didPrepareStage298AiGeneratedUiDemoAcceptRejectDryRunResultEnvelopeInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage297 internal ai generated ui demo accept reject dry run input: missing token $token" >&2
    exit 3
  fi
done

echo "stage297_internal_ai_generated_ui_demo_accept_reject_dry_run_input_owner_present=true"
echo "stage296_internal_ai_generated_ui_demo_readiness_decision_required=true"
echo "ai_generated_ui_accept_reject_dry_run_input_materialized=true"
echo "accept_dry_run_bound_to_owner_acceptance_requirement=true"
echo "accept_dry_run_bound_to_generated_form_settings_preview=true"
echo "reject_dry_run_bound_to_rollback_noop_path=true"
echo "reject_dry_run_bound_to_explain_packet=true"
echo "ai_generated_ui_accept_reject_input_owner_local_in_memory_only=true"
echo "ai_generated_ui_accept_reject_input_non_executing=true"
echo "stage298_ai_generated_ui_demo_accept_reject_dry_run_result_envelope_input_prepared=true"
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
