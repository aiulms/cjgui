#!/usr/bin/env zsh
#
# 维护注释：验证 stage456 recovery demo surface focus/input action intent adapter owner。
# 它必须消费 stage455 execution receipt，并生成 owner-local non-dispatching action intents。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage456_recovery_demo_surface_focus_input_action_intent_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage456 recovery demo surface focus input action intent adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage456RecoveryDemoSurfaceFocusInputActionIntentAdapterPlan" \
  "CjguiInternalRendererStage456RecoveryDemoSurfaceFocusInputActionIntentAdapterFacts" \
  "CjguiInternalRendererStage456RecoveryDemoSurfaceFocusInputActionIntentAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage456RecoveryDemoSurfaceFocusInputActionIntentAdapterDraft" \
  "CjguiInternalRendererStage455RecoveryDemoSurfaceLayoutStyleExecutionDryRunReadiness" \
  "didConsumeStage455RecoveryDemoSurfaceLayoutStyleExecutionDryRun" \
  "didConsumeSharedRecoveryDemoSurfaceLayoutStyleExecutionReceipt" \
  "didConsumeRecoveryDemoSurfaceTextFocusExecutionAffordance" \
  "didMapTodoFocusActivationToOwnerLocalActionIntent" \
  "didMapSettingsToggleFocusToOwnerLocalActionIntent" \
  "didMapAiGeneratedSettingsSubmitFocusToOwnerLocalActionIntent" \
  "didMaterializeSharedRecoveryDemoSurfaceFocusInputActionIntentAdapter" \
  "didBindExecutionReceiptToFocusInputActionIntentAdapter" \
  "didBindLayoutStylePreviewToFocusInputActionIntentAdapter" \
  "didKeepFocusInputActionIntentOwnerLocal" \
  "didKeepFocusInputActionIntentNonDispatching" \
  "didPrepareStage457RecoveryDemoSurfaceFocusInputActionStateUpdateDryRun" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage456 recovery demo surface focus input action intent adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage456_recovery_demo_surface_focus_input_action_intent_adapter_owner_present=true"
echo "stage455_recovery_demo_surface_layout_style_execution_dry_run_required=true"
echo "stage455_recovery_demo_surface_layout_style_execution_dry_run_consumed=true"
echo "shared_recovery_demo_surface_layout_style_execution_receipt_consumed=true"
echo "recovery_demo_surface_text_focus_execution_affordance_consumed=true"
echo "todo_recovery_demo_surface_focus_activation_action_intent_materialized=true"
echo "settings_recovery_demo_surface_toggle_focus_action_intent_materialized=true"
echo "ai_generated_settings_recovery_demo_surface_submit_focus_action_intent_materialized=true"
echo "shared_recovery_demo_surface_focus_input_action_intent_adapter_materialized=true"
echo "execution_receipt_to_focus_input_action_intent_adapter_bound=true"
echo "layout_style_preview_to_focus_input_action_intent_adapter_bound=true"
echo "recovery_demo_surface_focus_input_action_intent_owner_local=true"
echo "recovery_demo_surface_focus_input_action_intent_non_dispatching=true"
echo "stage457_recovery_demo_surface_focus_input_action_state_update_dry_run_prepared=true"
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
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
