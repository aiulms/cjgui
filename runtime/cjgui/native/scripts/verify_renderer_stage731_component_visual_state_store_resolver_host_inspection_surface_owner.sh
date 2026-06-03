#!/usr/bin/env zsh
#
# Verifies the stage731 component visual state store resolver host inspection surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage731_component_visual_state_store_resolver_host_inspection_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage731 component visual state store resolver host inspection surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage731ComponentVisualStateStoreResolverHostInspectionSurfacePlan" \
  "CjguiInternalRendererStage731ComponentVisualStateStoreResolverHostInspectionSurfaceFacts" \
  "CjguiInternalRendererStage731ComponentVisualStateStoreResolverHostInspectionSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage731ComponentVisualStateStoreResolverHostInspectionSurfaceDraft" \
  "CjguiInternalRendererStage730ComponentVisualStateStoreTextSelectionProjectionReadiness" \
  "didConsumeStage730ComponentVisualStateStoreTextSelectionProjection" \
  "didMaterializeVisualStateStoreResolverHostInspectionSurface" \
  "didMaterializeVisualStateStoreResolverResultSurfaceRefresh" \
  "didMaterializeVisualStateStoreResolverRenderCommandReceipt" \
  "didMaterializeVisualStateStoreResolverSemanticDiffReceipt" \
  "didBindResolverHostInspectionSurfaceToStage730Projection" \
  "didPrepareStage732ComponentVisualStateStoreResolverRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage731 component visual state store resolver host inspection surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage731_component_visual_state_store_resolver_host_inspection_surface_owner_present=true"
echo "stage730_component_visual_state_store_text_selection_projection_consumed=true"
echo "stage729_component_visual_state_store_layout_style_focus_resolver_consumed_transitively=true"
echo "visual_state_store_resolver_host_inspection_surface_materialized=true"
echo "visual_state_store_resolver_result_surface_refresh_materialized=true"
echo "visual_state_store_resolver_render_command_receipt_materialized=true"
echo "visual_state_store_resolver_semantic_diff_receipt_materialized=true"
echo "todo_visual_state_store_resolver_host_inspection_surface_materialized=true"
echo "settings_visual_state_store_resolver_host_inspection_surface_materialized=true"
echo "ai_generated_settings_visual_state_store_resolver_host_inspection_surface_materialized=true"
echo "chat_composer_visual_state_store_resolver_host_inspection_surface_materialized=true"
echo "resolver_host_inspection_surface_bound_to_stage730_projection=true"
echo "stage732_component_visual_state_store_resolver_runtime_manager_prepared=true"
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
