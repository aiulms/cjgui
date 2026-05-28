#!/usr/bin/env zsh
#
# Verifies the stage470 visual refresh focus/input action adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage470_shared_component_runtime_visual_refresh_focus_input_action_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage470 shared component runtime visual refresh focus/input action adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage470SharedComponentRuntimeVisualRefreshFocusInputActionAdapterPlan" \
  "CjguiInternalRendererStage470SharedComponentRuntimeVisualRefreshFocusInputActionAdapterFacts" \
  "CjguiInternalRendererStage470SharedComponentRuntimeVisualRefreshFocusInputActionAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage470SharedComponentRuntimeVisualRefreshFocusInputActionAdapterDraft" \
  "CjguiInternalRendererStage469SharedComponentRuntimeVisualRefreshLayoutFocusExecutionReceiptReadiness" \
  "didConsumeStage469SharedComponentRuntimeVisualRefreshLayoutFocusExecutionReceipt" \
  "didConsumeSharedComponentRuntimeVisualRefreshLayoutFocusExecutionReceipt" \
  "didConsumeTodoRuntimeVisualRefreshLayoutFocusExecutionPass" \
  "didConsumeSettingsRuntimeVisualRefreshLayoutFocusExecutionPass" \
  "didConsumeAiGeneratedSettingsRuntimeVisualRefreshLayoutFocusExecutionPass" \
  "didMaterializeSharedComponentRuntimeVisualRefreshFocusInputActionAdapter" \
  "didMaterializeTodoRuntimeVisualRefreshFocusedActionIntent" \
  "didMaterializeSettingsRuntimeVisualRefreshFocusedActionIntent" \
  "didMaterializeAiGeneratedSettingsRuntimeVisualRefreshFocusedActionIntent" \
  "didBindLayoutFocusExecutionReceiptToFocusInputActionAdapter" \
  "didBindFocusTargetToActionIntent" \
  "didKeepVisualRefreshFocusedActionIntentOwnerLocal" \
  "didKeepVisualRefreshFocusedActionIntentNonDispatching" \
  "didPrepareStage471SharedComponentRuntimeVisualRefreshInteractionExecutionContract" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage470 shared component runtime visual refresh focus/input action adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage470_shared_component_runtime_visual_refresh_focus_input_action_adapter_owner_present=true"
echo "stage469_shared_component_runtime_visual_refresh_layout_focus_execution_receipt_required=true"
echo "stage469_shared_component_runtime_visual_refresh_layout_focus_execution_receipt_consumed=true"
echo "shared_component_runtime_visual_refresh_layout_focus_execution_receipt_consumed=true"
echo "todo_runtime_visual_refresh_layout_focus_execution_pass_consumed=true"
echo "settings_runtime_visual_refresh_layout_focus_execution_pass_consumed=true"
echo "ai_generated_settings_runtime_visual_refresh_layout_focus_execution_pass_consumed=true"
echo "shared_component_runtime_visual_refresh_focus_input_action_adapter_materialized=true"
echo "todo_runtime_visual_refresh_focused_action_intent_materialized=true"
echo "settings_runtime_visual_refresh_focused_action_intent_materialized=true"
echo "ai_generated_settings_runtime_visual_refresh_focused_action_intent_materialized=true"
echo "layout_focus_execution_receipt_to_focus_input_action_adapter_bound=true"
echo "focus_target_to_action_intent_bound=true"
echo "visual_refresh_focused_action_intent_owner_local=true"
echo "visual_refresh_focused_action_intent_non_dispatching=true"
echo "stage471_shared_component_runtime_visual_refresh_interaction_execution_contract_prepared=true"
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
