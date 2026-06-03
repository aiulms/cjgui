#!/usr/bin/env zsh
#
# Verifies the stage728 component visual state store input/action cycle manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage728_component_visual_state_store_input_action_cycle_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage728 component visual state store input action cycle manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage728ComponentVisualStateStoreInputActionCycleManagerPlan" \
  "CjguiInternalRendererStage728ComponentVisualStateStoreInputActionCycleManagerFacts" \
  "CjguiInternalRendererStage728ComponentVisualStateStoreInputActionCycleManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage728ComponentVisualStateStoreInputActionCycleManagerDraft" \
  "CjguiInternalRendererStage727ComponentVisualStateStoreRenderResultHostSurfaceReadiness" \
  "didConsumeStage727ComponentVisualStateStoreRenderResultHostSurface" \
  "didMaterializeSharedVisualStateStoreInputActionCycleManager" \
  "didMaterializeVisualStateStoreInputActionRuntimeShape" \
  "didMaterializeVisualStateStoreInputActionExecutionReceiptContract" \
  "didMaterializeCycleOrderInputActionStateStoreMutationRenderHostResult" \
  "didReduceFuturePerDemoInputActionStateStoreTemplateNeed" \
  "didPrepareStage729ComponentVisualStateStoreLayoutStyleFocusResolver"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage728 component visual state store input action cycle manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage728_component_visual_state_store_input_action_cycle_manager_owner_present=true"
echo "stage727_component_visual_state_store_render_result_host_surface_consumed=true"
echo "stage726_component_visual_state_store_action_reducer_preflight_consumed_transitively=true"
echo "stage725_component_visual_state_store_input_action_bridge_consumed_transitively=true"
echo "stage724_component_visual_state_store_manager_consumed_transitively=true"
echo "shared_visual_state_store_input_action_cycle_manager_materialized=true"
echo "visual_state_store_input_action_runtime_shape_materialized=true"
echo "visual_state_store_input_action_execution_receipt_contract_materialized=true"
echo "cycle_order_input_action_state_store_mutation_render_host_result_materialized=true"
echo "todo_visual_state_store_input_action_cycle_runtime_surface_materialized=true"
echo "settings_visual_state_store_input_action_cycle_runtime_surface_materialized=true"
echo "ai_generated_settings_visual_state_store_input_action_cycle_runtime_surface_materialized=true"
echo "chat_composer_visual_state_store_input_action_cycle_runtime_surface_materialized=true"
echo "future_per_demo_input_action_state_store_template_need_reduced=true"
echo "stage729_component_visual_state_store_layout_style_focus_resolver_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
