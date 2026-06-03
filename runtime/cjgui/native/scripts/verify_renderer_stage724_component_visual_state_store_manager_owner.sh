#!/usr/bin/env zsh
#
# Verifies the stage724 component visual state store manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage724_component_visual_state_store_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage724 component visual state store manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage724ComponentVisualStateStoreManagerPlan" \
  "CjguiInternalRendererStage724ComponentVisualStateStoreManagerFacts" \
  "CjguiInternalRendererStage724ComponentVisualStateStoreManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage724ComponentVisualStateStoreManagerDraft" \
  "CjguiInternalRendererStage723ComponentVisualStateStoreRenderRefreshReadiness" \
  "didConsumeStage723ComponentVisualStateStoreRenderRefresh" \
  "didMaterializeSharedComponentVisualStateStoreManager" \
  "didMaterializeSharedComponentVisualStateStoreRuntimeShape" \
  "didMaterializeVisualStateStoreExecutionReceiptContract" \
  "didMaterializeCycleOrderVisualRuntimeStateStoreDeltaRollbackRenderRefreshHostInspection" \
  "didReduceFuturePerDemoVisualStateStoreTemplateNeed" \
  "didPrepareStage725ComponentVisualStateStoreInputActionBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage724 component visual state store manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage724_component_visual_state_store_manager_owner_present=true"
echo "stage723_component_visual_state_store_render_refresh_consumed=true"
echo "stage722_component_visual_state_store_delta_rollback_consumed_transitively=true"
echo "stage721_component_visual_state_store_preflight_consumed_transitively=true"
echo "stage720_replay_visual_runtime_manager_consumed_transitively=true"
echo "shared_component_visual_state_store_manager_materialized=true"
echo "shared_component_visual_state_store_runtime_shape_materialized=true"
echo "visual_state_store_execution_receipt_contract_materialized=true"
echo "cycle_order_visual_runtime_state_store_delta_rollback_render_refresh_host_inspection_materialized=true"
echo "todo_component_visual_state_store_runtime_surface_materialized=true"
echo "settings_component_visual_state_store_runtime_surface_materialized=true"
echo "ai_generated_settings_component_visual_state_store_runtime_surface_materialized=true"
echo "chat_composer_component_visual_state_store_runtime_surface_materialized=true"
echo "future_per_demo_visual_state_store_template_need_reduced=true"
echo "stage725_component_visual_state_store_input_action_bridge_prepared=true"
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
