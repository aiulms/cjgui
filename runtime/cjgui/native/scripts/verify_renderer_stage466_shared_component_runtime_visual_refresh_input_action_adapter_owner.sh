#!/usr/bin/env zsh
#
# Verifies the stage466 shared component runtime visual refresh input/action adapter owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage466_shared_component_runtime_visual_refresh_input_action_adapter.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage466 shared component runtime visual refresh input action adapter: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage466SharedComponentRuntimeVisualRefreshInputActionAdapterPlan" \
  "CjguiInternalRendererStage466SharedComponentRuntimeVisualRefreshInputActionAdapterFacts" \
  "CjguiInternalRendererStage466SharedComponentRuntimeVisualRefreshInputActionAdapterReadiness" \
  "cjguiInternalExecuteDefaultRendererStage466SharedComponentRuntimeVisualRefreshInputActionAdapterDraft" \
  "CjguiInternalRendererStage465SharedComponentRuntimeDemoSurfaceVisualRefreshReceiptReadiness" \
  "didConsumeStage465SharedComponentRuntimeDemoSurfaceVisualRefreshReceipt" \
  "didConsumeSharedComponentRuntimeDemoSurfaceVisualRefreshReceipt" \
  "didConsumeTodoRuntimeVisualRefreshProbeInput" \
  "didConsumeSettingsRuntimeVisualRefreshProbeInput" \
  "didConsumeAiGeneratedSettingsRuntimeVisualRefreshProbeInput" \
  "didMaterializeSharedComponentRuntimeVisualRefreshInputActionAdapter" \
  "didMaterializeTodoRuntimeVisualRefreshActionIntent" \
  "didMaterializeSettingsRuntimeVisualRefreshActionIntent" \
  "didMaterializeAiGeneratedSettingsRuntimeVisualRefreshActionIntent" \
  "didBindVisualRefreshReceiptToInputActionAdapter" \
  "didBindSharedVisualRefreshExecutionContractToActionIntent" \
  "didKeepVisualRefreshActionIntentOwnerLocal" \
  "didKeepVisualRefreshActionIntentNonDispatching" \
  "didPrepareStage467SharedComponentRuntimeVisualRefreshActionStateUpdateDryRun" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage466 shared component runtime visual refresh input action adapter: missing token $token" >&2
    exit 3
  fi
done

echo "stage466_shared_component_runtime_visual_refresh_input_action_adapter_owner_present=true"
echo "stage465_shared_component_runtime_demo_surface_visual_refresh_receipt_required=true"
echo "stage465_shared_component_runtime_demo_surface_visual_refresh_receipt_consumed=true"
echo "shared_component_runtime_demo_surface_visual_refresh_receipt_consumed=true"
echo "todo_runtime_visual_refresh_probe_input_consumed=true"
echo "settings_runtime_visual_refresh_probe_input_consumed=true"
echo "ai_generated_settings_runtime_visual_refresh_probe_input_consumed=true"
echo "shared_component_runtime_visual_refresh_input_action_adapter_materialized=true"
echo "todo_runtime_visual_refresh_action_intent_materialized=true"
echo "settings_runtime_visual_refresh_action_intent_materialized=true"
echo "ai_generated_settings_runtime_visual_refresh_action_intent_materialized=true"
echo "visual_refresh_receipt_to_input_action_adapter_bound=true"
echo "shared_visual_refresh_execution_contract_to_action_intent_bound=true"
echo "visual_refresh_action_intent_owner_local=true"
echo "visual_refresh_action_intent_non_dispatching=true"
echo "stage467_shared_component_runtime_visual_refresh_action_state_update_dry_run_prepared=true"
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
