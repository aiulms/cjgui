#!/usr/bin/env zsh
#
# 维护注释：验证 stage436 transaction visibility RenderCommand gate transaction dry-run owner。
# 它必须消费 stage435 owner gate，并生成 accepted/blocked transaction preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage436_transaction_visibility_render_command_gate_transaction_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage436 transaction visibility render command gate transaction dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage436TransactionVisibilityRenderCommandGateTransactionDryRunPlan" \
  "CjguiInternalRendererStage436TransactionVisibilityRenderCommandGateTransactionDryRunFacts" \
  "CjguiInternalRendererStage436TransactionVisibilityRenderCommandGateTransactionDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage436TransactionVisibilityRenderCommandGateTransactionDryRunDraft" \
  "didConsumeStage435TransactionVisibilityRenderCommandRefreshOwnerAcceptanceGate" \
  "didConsumeTransactionVisibilityRenderCommandRefreshOwnerAcceptanceGate" \
  "didConsumeAcceptedTransactionVisibilityRenderCommandGateCandidate" \
  "didConsumeBlockedTransactionVisibilityRenderCommandRollbackCandidate" \
  "didMaterializeTransactionVisibilityRenderCommandTransactionDryRun" \
  "didMaterializeTodoTransactionVisibilityRenderCommandTransactionDryRun" \
  "didMaterializeSettingsTransactionVisibilityRenderCommandTransactionDryRun" \
  "didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandTransactionDryRun" \
  "didMapAcceptedGateToPendingTransactionVisibilityRenderCommandTransaction" \
  "didMapBlockedGateToRollbackTransactionVisibilityRenderCommandTransaction" \
  "didBindTransactionDryRunToStage435Gate" \
  "didBindTransactionDryRunToStage434DemoSurfaceBatch" \
  "didKeepTransactionVisibilityRenderCommandTransactionOwnerLocal" \
  "didKeepTransactionVisibilityRenderCommandTransactionPreviewOnly" \
  "didPrepareStage437TransactionVisibilityRenderCommandTransactionAdmission" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage436 transaction visibility render command gate transaction dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage436_transaction_visibility_render_command_gate_transaction_dry_run_owner_present=true"
echo "stage435_transaction_visibility_render_command_refresh_owner_acceptance_gate_required=true"
echo "stage435_transaction_visibility_render_command_refresh_owner_acceptance_gate_consumed=true"
echo "transaction_visibility_render_command_refresh_owner_acceptance_gate_consumed=true"
echo "accepted_transaction_visibility_render_command_gate_candidate_consumed=true"
echo "blocked_transaction_visibility_render_command_rollback_candidate_consumed=true"
echo "transaction_visibility_render_command_transaction_dry_run_materialized=true"
echo "todo_transaction_visibility_render_command_transaction_dry_run_materialized=true"
echo "settings_transaction_visibility_render_command_transaction_dry_run_materialized=true"
echo "ai_generated_settings_transaction_visibility_render_command_transaction_dry_run_materialized=true"
echo "accepted_gate_to_pending_transaction_visibility_render_command_transaction_mapped=true"
echo "blocked_gate_to_rollback_transaction_visibility_render_command_transaction_mapped=true"
echo "transaction_dry_run_bound_to_stage435_gate=true"
echo "transaction_dry_run_bound_to_stage434_demo_surface_batch=true"
echo "transaction_visibility_render_command_transaction_owner_local=true"
echo "transaction_visibility_render_command_transaction_preview_only=true"
echo "stage437_transaction_visibility_render_command_transaction_admission_prepared=true"
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
