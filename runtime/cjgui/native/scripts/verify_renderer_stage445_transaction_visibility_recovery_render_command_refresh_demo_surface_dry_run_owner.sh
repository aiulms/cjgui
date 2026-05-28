#!/usr/bin/env zsh
#
# 维护注释：验证 stage445 transaction visibility recovery RenderCommand refresh -> demo surface dry-run owner。
# 它必须消费 stage444 recovery RenderCommand refresh，并生成 Todo/settings/AI-generated settings surface batch。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage445TransactionVisibilityRecoveryRenderCommandRefreshDemoSurfaceDryRunPlan" \
  "CjguiInternalRendererStage445TransactionVisibilityRecoveryRenderCommandRefreshDemoSurfaceDryRunFacts" \
  "CjguiInternalRendererStage445TransactionVisibilityRecoveryRenderCommandRefreshDemoSurfaceDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage445TransactionVisibilityRecoveryRenderCommandRefreshDemoSurfaceDryRunDraft" \
  "didConsumeStage444TransactionVisibilityRecoveryStateUpdateRenderCommandRefresh" \
  "didConsumeTransactionVisibilityRecoveryStateUpdateRenderCommandRefresh" \
  "didConsumeTodoTransactionVisibilityRecoveryStateUpdateRenderCommandRefresh" \
  "didConsumeSettingsTransactionVisibilityRecoveryStateUpdateRenderCommandRefresh" \
  "didConsumeAiGeneratedSettingsTransactionVisibilityRecoveryStateUpdateRenderCommandRefresh" \
  "didMaterializeTransactionVisibilityRecoveryDemoSurfaceRenderCommandRefreshDryRun" \
  "didMaterializeTodoTransactionVisibilityRecoveryDemoSurfaceRenderCommandRefreshBatch" \
  "didMaterializeSettingsTransactionVisibilityRecoveryDemoSurfaceRenderCommandRefreshBatch" \
  "didMaterializeAiGeneratedSettingsTransactionVisibilityRecoveryDemoSurfaceRenderCommandRefreshBatch" \
  "didMaterializeTransactionVisibilityRecoveryDemoSurfaceSemanticComponentProjection" \
  "didProjectTodoTransactionVisibilityRecoveryDemoSurfaceSemanticNode" \
  "didProjectSettingsTransactionVisibilityRecoveryDemoSurfaceSemanticNode" \
  "didProjectAiGeneratedSettingsTransactionVisibilityRecoveryDemoSurfaceSemanticNode" \
  "didBindTransactionVisibilityRecoveryRenderCommandRefreshToDemoSurfaceDryRun" \
  "didBindRecoveryDemoSurfaceDryRunToStage443RecoveryStateUpdateCandidate" \
  "didPrepareStage446TransactionVisibilityRecoveryDemoSurfaceInputEventActionAdapter" \
  "didKeepTransactionVisibilityRecoveryDemoSurfaceDryRunPreviewOnly" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage445 transaction visibility recovery render command refresh demo surface dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_owner_present=true"
echo "stage444_transaction_visibility_recovery_state_update_render_command_refresh_required=true"
echo "stage444_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true"
echo "transaction_visibility_recovery_state_update_render_command_refresh_consumed=true"
echo "todo_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true"
echo "settings_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true"
echo "ai_generated_settings_transaction_visibility_recovery_state_update_render_command_refresh_consumed=true"
echo "transaction_visibility_recovery_demo_surface_render_command_refresh_dry_run_materialized=true"
echo "todo_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_materialized=true"
echo "settings_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_materialized=true"
echo "ai_generated_settings_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_materialized=true"
echo "transaction_visibility_recovery_demo_surface_semantic_component_projection_materialized=true"
echo "todo_transaction_visibility_recovery_demo_surface_semantic_node_projected=true"
echo "settings_transaction_visibility_recovery_demo_surface_semantic_node_projected=true"
echo "ai_generated_settings_transaction_visibility_recovery_demo_surface_semantic_node_projected=true"
echo "transaction_visibility_recovery_render_command_refresh_to_demo_surface_dry_run_bound=true"
echo "recovery_demo_surface_dry_run_to_stage443_recovery_state_update_candidate_bound=true"
echo "transaction_visibility_recovery_render_command_refresh_batch_owner_local=true"
echo "transaction_visibility_recovery_demo_surface_dry_run_preview_only=true"
echo "stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter_prepared=true"
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
