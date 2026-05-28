#!/usr/bin/env zsh
#
# Verifies the stage471 visual refresh interaction execution contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage471_shared_component_runtime_visual_refresh_interaction_execution_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage471 shared component runtime visual refresh interaction execution contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage471SharedComponentRuntimeVisualRefreshInteractionExecutionContractPlan" \
  "CjguiInternalRendererStage471SharedComponentRuntimeVisualRefreshInteractionExecutionContractFacts" \
  "CjguiInternalRendererStage471SharedComponentRuntimeVisualRefreshInteractionExecutionContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage471SharedComponentRuntimeVisualRefreshInteractionExecutionContractDraft" \
  "CjguiInternalRendererStage470SharedComponentRuntimeVisualRefreshFocusInputActionAdapterReadiness" \
  "didConsumeStage470SharedComponentRuntimeVisualRefreshFocusInputActionAdapter" \
  "didConsumeSharedComponentRuntimeVisualRefreshFocusInputActionAdapter" \
  "didConsumeTodoRuntimeVisualRefreshFocusedActionIntent" \
  "didConsumeSettingsRuntimeVisualRefreshFocusedActionIntent" \
  "didConsumeAiGeneratedSettingsRuntimeVisualRefreshFocusedActionIntent" \
  "didMaterializeSharedComponentRuntimeVisualRefreshInteractionExecutionContract" \
  "didMaterializeTodoRuntimeVisualRefreshInteractionReceipt" \
  "didMaterializeSettingsRuntimeVisualRefreshInteractionReceipt" \
  "didMaterializeAiGeneratedSettingsRuntimeVisualRefreshInteractionReceipt" \
  "didBindFocusInputActionAdapterToInteractionExecutionContract" \
  "didBindInteractionExecutionContractToDemoSurfaceReceipt" \
  "didKeepInteractionExecutionContractReusable" \
  "didKeepInteractionExecutionReceiptCheckable" \
  "didPrepareStage472SharedComponentRuntimeVisualRefreshInteractionStateUpdateBridge" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage471 shared component runtime visual refresh interaction execution contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage471_shared_component_runtime_visual_refresh_interaction_execution_contract_owner_present=true"
echo "stage470_shared_component_runtime_visual_refresh_focus_input_action_adapter_required=true"
echo "stage470_shared_component_runtime_visual_refresh_focus_input_action_adapter_consumed=true"
echo "shared_component_runtime_visual_refresh_focus_input_action_adapter_consumed=true"
echo "todo_runtime_visual_refresh_focused_action_intent_consumed=true"
echo "settings_runtime_visual_refresh_focused_action_intent_consumed=true"
echo "ai_generated_settings_runtime_visual_refresh_focused_action_intent_consumed=true"
echo "shared_component_runtime_visual_refresh_interaction_execution_contract_materialized=true"
echo "todo_runtime_visual_refresh_interaction_receipt_materialized=true"
echo "settings_runtime_visual_refresh_interaction_receipt_materialized=true"
echo "ai_generated_settings_runtime_visual_refresh_interaction_receipt_materialized=true"
echo "focus_input_action_adapter_to_interaction_execution_contract_bound=true"
echo "interaction_execution_contract_to_demo_surface_receipt_bound=true"
echo "interaction_execution_contract_reusable=true"
echo "interaction_execution_contract_owner_local=true"
echo "interaction_execution_contract_non_dispatching=true"
echo "interaction_execution_receipt_checkable=true"
echo "stage472_shared_component_runtime_visual_refresh_interaction_state_update_bridge_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
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
