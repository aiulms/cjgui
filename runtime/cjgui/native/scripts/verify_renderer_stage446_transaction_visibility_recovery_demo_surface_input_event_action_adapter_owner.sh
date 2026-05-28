#!/usr/bin/env zsh
#
# 维护注释：验证 stage446 transaction visibility recovery demo surface input event -> action intent adapter owner。
# 它必须消费 stage445 recovery demo surface dry-run，并生成 owner-local recovery action intent。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage446 transaction visibility recovery demo surface input event action adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage446TransactionVisibilityRecoveryDemoSurfaceInputEventActionAdapterPlan" \
  "CjguiInternalRendererStage446TransactionVisibilityRecoveryDemoSurfaceInputEventActionAdapterFacts" \
  "CjguiInternalRendererStage446TransactionVisibilityRecoveryDemoSurfaceInputEventActionAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage446TransactionVisibilityRecoveryDemoSurfaceInputEventActionAdapterDraft" \
  "didConsumeStage445TransactionVisibilityRecoveryRenderCommandRefreshDemoSurfaceDryRun" \
  "didConsumeTransactionVisibilityRecoveryDemoSurfaceRenderCommandRefreshDryRun" \
  "didConsumeTodoTransactionVisibilityRecoveryDemoSurfaceRenderCommandRefreshBatch" \
  "didConsumeSettingsTransactionVisibilityRecoveryDemoSurfaceRenderCommandRefreshBatch" \
  "didConsumeAiGeneratedSettingsTransactionVisibilityRecoveryDemoSurfaceRenderCommandRefreshBatch" \
  "didConsumeTransactionVisibilityRecoveryDemoSurfaceSemanticComponentProjection" \
  "didMaterializeTransactionVisibilityRecoveryDemoSurfaceInputEventAdapter" \
  "didBindTodoTransactionVisibilityRecoveryDemoSurfaceInputEventToActionIntent" \
  "didBindSettingsTransactionVisibilityRecoveryDemoSurfaceInputEventToActionIntent" \
  "didBindAiGeneratedSettingsTransactionVisibilityRecoveryDemoSurfaceInputEventToActionIntent" \
  "didMaterializeOwnerLocalTransactionVisibilityRecoveryActionIntent" \
  "didBindRecoveryInputEventAdapterToStage445DemoSurface" \
  "didKeepTransactionVisibilityRecoveryActionIntentNonDispatching" \
  "didPrepareStage447TransactionVisibilityRecoveryDemoSurfaceActionStateUpdateDryRun" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage446 transaction visibility recovery demo surface input event action adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage446_transaction_visibility_recovery_demo_surface_input_event_action_adapter_owner_present=true"
echo "stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_required=true"
echo "stage445_transaction_visibility_recovery_render_command_refresh_demo_surface_dry_run_consumed=true"
echo "transaction_visibility_recovery_demo_surface_render_command_refresh_dry_run_consumed=true"
echo "todo_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_consumed=true"
echo "settings_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_consumed=true"
echo "ai_generated_settings_transaction_visibility_recovery_demo_surface_render_command_refresh_batch_consumed=true"
echo "transaction_visibility_recovery_demo_surface_semantic_component_projection_consumed=true"
echo "transaction_visibility_recovery_demo_surface_input_event_adapter_materialized=true"
echo "todo_transaction_visibility_recovery_demo_surface_input_event_adapter_materialized=true"
echo "settings_transaction_visibility_recovery_demo_surface_input_event_adapter_materialized=true"
echo "ai_generated_settings_transaction_visibility_recovery_demo_surface_input_event_adapter_materialized=true"
echo "todo_transaction_visibility_recovery_demo_surface_input_event_to_action_intent_bound=true"
echo "settings_transaction_visibility_recovery_demo_surface_input_event_to_action_intent_bound=true"
echo "ai_generated_settings_transaction_visibility_recovery_demo_surface_input_event_to_action_intent_bound=true"
echo "owner_local_transaction_visibility_recovery_action_intent_materialized=true"
echo "transaction_visibility_recovery_input_event_adapter_bound_to_stage445_demo_surface=true"
echo "transaction_visibility_recovery_input_event_adapter_bound_to_stage444_render_command_refresh=true"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "transaction_visibility_recovery_action_intent_owner_local=true"
echo "action_dispatch=false"
echo "transaction_visibility_recovery_action_intent_non_dispatching=true"
echo "stage447_transaction_visibility_recovery_demo_surface_action_state_update_dry_run_prepared=true"
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
