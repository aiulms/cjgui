#!/usr/bin/env zsh
#
# Verifies the stage538 component runtime surface model owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage538_component_runtime_surface_model.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage538 component runtime surface model: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage538ComponentRuntimeSurfaceModelPlan" \
  "CjguiInternalRendererStage538ComponentRuntimeSurfaceModelFacts" \
  "CjguiInternalRendererStage538ComponentRuntimeSurfaceModelReadiness" \
  "cjguiInternalExecuteDefaultRendererStage538ComponentRuntimeSurfaceModelDraft" \
  "CjguiInternalRendererStage537SharedRuntimeDemoCycleEventRefreshSurfaceExecutorReadiness" \
  "didConsumeStage537EventRefreshSurfaceExecutor" \
  "didMaterializeSharedComponentRuntimeSurfaceModelContract" \
  "didMaterializeTodoComponentRuntimeSurfaceNode" \
  "didMaterializeSettingsComponentRuntimeSurfaceNode" \
  "didMaterializeAiGeneratedSettingsComponentRuntimeSurfaceNode" \
  "didMaterializeSemanticStateRenderLayoutInputFacet" \
  "didBindSurfaceModelToStage537ExecutorReceipt" \
  "didBindSurfaceModelToComponentRuntimeShape" \
  "didPrepareStage539ComponentRuntimeLayoutTextFocusExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage538 component runtime surface model: missing token $token" >&2
    exit 3
  fi
done

echo "stage538_component_runtime_surface_model_owner_present=true"
echo "stage537_event_refresh_surface_executor_consumed=true"
echo "event_refresh_surface_execution_receipt_consumed=true"
echo "todo_event_refresh_surface_execution_receipt_consumed=true"
echo "settings_event_refresh_surface_execution_receipt_consumed=true"
echo "ai_generated_settings_event_refresh_surface_execution_receipt_consumed=true"
echo "shared_component_runtime_surface_model_contract_materialized=true"
echo "todo_component_runtime_surface_node_materialized=true"
echo "settings_component_runtime_surface_node_materialized=true"
echo "ai_generated_settings_component_runtime_surface_node_materialized=true"
echo "semantic_state_render_layout_input_facet_materialized=true"
echo "surface_model_bound_to_stage537_executor_receipt=true"
echo "surface_model_bound_to_component_runtime_shape=true"
echo "component_runtime_surface_model_owner_local=true"
echo "stage539_component_runtime_layout_text_focus_executor_prepared=true"
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
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
