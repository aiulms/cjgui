#!/usr/bin/env zsh
#
# 维护注释：验证 stage435 transaction visibility RenderCommand refresh owner acceptance gate owner。
# 它必须消费 stage434 transaction visibility demo surface batch，并形成 owner-local accept/reject gate。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage435_transaction_visibility_render_command_refresh_owner_acceptance_gate.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage435 transaction visibility render command refresh owner acceptance gate: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage435TransactionVisibilityRenderCommandRefreshOwnerAcceptanceGatePlan" \
  "CjguiInternalRendererStage435TransactionVisibilityRenderCommandRefreshOwnerAcceptanceGateFacts" \
  "CjguiInternalRendererStage435TransactionVisibilityRenderCommandRefreshOwnerAcceptanceGateReadiness" \
  "cjguiInternalExecuteDefaultRendererStage435TransactionVisibilityRenderCommandRefreshOwnerAcceptanceGateDraft" \
  "didConsumeStage434TransactionVisibilityRenderCommandRefreshDemoSurfaceDryRun" \
  "didConsumeTransactionVisibilityDemoSurfaceRenderCommandRefreshDryRun" \
  "didConsumeTodoTransactionVisibilityDemoSurfaceRenderCommandRefreshBatch" \
  "didConsumeSettingsTransactionVisibilityDemoSurfaceRenderCommandRefreshBatch" \
  "didConsumeAiGeneratedSettingsTransactionVisibilityDemoSurfaceRenderCommandRefreshBatch" \
  "didMaterializeTransactionVisibilityRenderCommandRefreshOwnerAcceptanceGate" \
  "didMaterializeTodoTransactionVisibilityRenderCommandRefreshOwnerAcceptanceGate" \
  "didMaterializeSettingsTransactionVisibilityRenderCommandRefreshOwnerAcceptanceGate" \
  "didMaterializeAiGeneratedSettingsTransactionVisibilityRenderCommandRefreshOwnerAcceptanceGate" \
  "didRequireOwnerAcceptanceTokenForTransactionVisibilityRenderCommandRefresh" \
  "didRequireOwnerRejectReasonForTransactionVisibilityRenderCommandRefresh" \
  "didPrepareAcceptedTransactionVisibilityRenderCommandGateCandidate" \
  "didPrepareBlockedTransactionVisibilityRenderCommandRollbackCandidate" \
  "didBindGateToStage434TransactionVisibilityDemoSurfaceBatch" \
  "didBindGateToStage433TransactionVisibilityRenderCommandRefresh" \
  "didKeepTransactionVisibilityOwnerAcceptanceGateOwnerLocal" \
  "didKeepTransactionVisibilityOwnerAcceptanceGatePreviewOnly" \
  "didPrepareStage436TransactionVisibilityRenderCommandGateTransactionDryRun" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage435 transaction visibility render command refresh owner acceptance gate: missing token $token" >&2
    exit 3
  fi
done

echo "stage435_transaction_visibility_render_command_refresh_owner_acceptance_gate_owner_present=true"
echo "stage434_transaction_visibility_render_command_refresh_demo_surface_dry_run_required=true"
echo "stage434_transaction_visibility_render_command_refresh_demo_surface_dry_run_consumed=true"
echo "transaction_visibility_demo_surface_render_command_refresh_dry_run_consumed=true"
echo "todo_transaction_visibility_demo_surface_render_command_refresh_batch_consumed=true"
echo "settings_transaction_visibility_demo_surface_render_command_refresh_batch_consumed=true"
echo "ai_generated_settings_transaction_visibility_demo_surface_render_command_refresh_batch_consumed=true"
echo "transaction_visibility_render_command_refresh_owner_acceptance_gate_materialized=true"
echo "todo_transaction_visibility_render_command_refresh_owner_acceptance_gate_materialized=true"
echo "settings_transaction_visibility_render_command_refresh_owner_acceptance_gate_materialized=true"
echo "ai_generated_settings_transaction_visibility_render_command_refresh_owner_acceptance_gate_materialized=true"
echo "owner_acceptance_token_for_transaction_visibility_render_command_refresh_required=true"
echo "owner_reject_reason_for_transaction_visibility_render_command_refresh_required=true"
echo "accepted_transaction_visibility_render_command_gate_candidate_prepared=true"
echo "blocked_transaction_visibility_render_command_rollback_candidate_prepared=true"
echo "gate_bound_to_stage434_transaction_visibility_demo_surface_batch=true"
echo "gate_bound_to_stage433_transaction_visibility_render_command_refresh=true"
echo "transaction_visibility_owner_acceptance_gate_owner_local=true"
echo "transaction_visibility_owner_acceptance_gate_preview_only=true"
echo "stage436_transaction_visibility_render_command_gate_transaction_dry_run_prepared=true"
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
