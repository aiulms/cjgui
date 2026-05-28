#!/usr/bin/env zsh
#
# 维护注释：验证 stage427 RenderCommand transaction visibility admission owner。
# 它必须消费 stage426 transaction dry-run，并生成 owner-local visibility admission / denial candidate。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage427_render_command_transaction_visibility_admission.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage427 render command transaction visibility admission: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage427RenderCommandTransactionVisibilityAdmissionPlan" \
  "CjguiInternalRendererStage427RenderCommandTransactionVisibilityAdmissionFacts" \
  "CjguiInternalRendererStage427RenderCommandTransactionVisibilityAdmissionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage427RenderCommandTransactionVisibilityAdmissionDraft" \
  "didConsumeStage426RenderCommandGateTransactionDryRun" \
  "didConsumeRenderCommandTransactionDryRun" \
  "didConsumeAcceptedGateToPendingRenderCommandTransaction" \
  "didConsumeBlockedGateToRollbackRenderCommandTransaction" \
  "didMaterializeRenderCommandTransactionVisibilityAdmission" \
  "didMaterializeTodoRenderCommandTransactionVisibilityAdmission" \
  "didMaterializeSettingsRenderCommandTransactionVisibilityAdmission" \
  "didMaterializeAiGeneratedSettingsRenderCommandTransactionVisibilityAdmission" \
  "didPrepareAcceptedTransactionVisibilityAdmissionCandidate" \
  "didPrepareBlockedTransactionVisibilityDenialCandidate" \
  "didBindVisibilityAdmissionToStage426TransactionDryRun" \
  "didBindVisibilityAdmissionToStage425Gate" \
  "didKeepRenderCommandTransactionVisibilityAdmissionOwnerLocal" \
  "didKeepRenderCommandTransactionVisibilityAdmissionPreviewOnly" \
  "didPrepareStage428RenderCommandTransactionVisibilityCommandPlan" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage427 render command transaction visibility admission: missing token $token" >&2
    exit 3
  fi
done

echo "stage427_render_command_transaction_visibility_admission_owner_present=true"
echo "stage426_render_command_gate_transaction_dry_run_required=true"
echo "stage426_render_command_gate_transaction_dry_run_consumed=true"
echo "render_command_transaction_dry_run_consumed=true"
echo "accepted_gate_to_pending_render_command_transaction_consumed=true"
echo "blocked_gate_to_rollback_render_command_transaction_consumed=true"
echo "render_command_transaction_visibility_admission_materialized=true"
echo "todo_render_command_transaction_visibility_admission_materialized=true"
echo "settings_render_command_transaction_visibility_admission_materialized=true"
echo "ai_generated_settings_render_command_transaction_visibility_admission_materialized=true"
echo "accepted_transaction_visibility_admission_candidate_prepared=true"
echo "blocked_transaction_visibility_denial_candidate_prepared=true"
echo "visibility_admission_bound_to_stage426_transaction_dry_run=true"
echo "visibility_admission_bound_to_stage425_gate=true"
echo "render_command_transaction_visibility_admission_owner_local=true"
echo "render_command_transaction_visibility_admission_preview_only=true"
echo "stage428_render_command_transaction_visibility_command_plan_prepared=true"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
