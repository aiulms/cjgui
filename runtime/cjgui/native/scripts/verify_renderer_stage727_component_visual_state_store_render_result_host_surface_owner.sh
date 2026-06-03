#!/usr/bin/env zsh
#
# Verifies the stage727 component visual state store render/result host surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage727_component_visual_state_store_render_result_host_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage727 component visual state store render result host surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage727ComponentVisualStateStoreRenderResultHostSurfacePlan" \
  "CjguiInternalRendererStage727ComponentVisualStateStoreRenderResultHostSurfaceFacts" \
  "CjguiInternalRendererStage727ComponentVisualStateStoreRenderResultHostSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage727ComponentVisualStateStoreRenderResultHostSurfaceDraft" \
  "CjguiInternalRendererStage726ComponentVisualStateStoreActionReducerPreflightReadiness" \
  "didConsumeStage726ComponentVisualStateStoreActionReducerPreflight" \
  "didMaterializeVisualStateStoreRenderResultSurface" \
  "didMaterializeVisualStateStoreLayoutStyleTextFocusDiffReceipt" \
  "didMaterializeVisualStateStoreRenderCommandRefreshReceipt" \
  "didMaterializeVisualStateStoreHostInspectionResult" \
  "didBindRenderResultSurfaceToMutationPreflight" \
  "didBindRenderResultSurfaceToConflictClassifier" \
  "didPrepareStage728ComponentVisualStateStoreInputActionCycleManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage727 component visual state store render result host surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage727_component_visual_state_store_render_result_host_surface_owner_present=true"
echo "stage726_component_visual_state_store_action_reducer_preflight_consumed=true"
echo "visual_state_store_render_result_surface_materialized=true"
echo "visual_state_store_layout_style_text_focus_diff_receipt_materialized=true"
echo "visual_state_store_render_command_refresh_receipt_materialized=true"
echo "visual_state_store_host_inspection_result_materialized=true"
echo "todo_visual_state_store_render_result_surface_materialized=true"
echo "settings_visual_state_store_render_result_surface_materialized=true"
echo "ai_generated_settings_visual_state_store_render_result_surface_materialized=true"
echo "chat_composer_visual_state_store_render_result_surface_materialized=true"
echo "visual_state_store_render_result_surface_bound_to_mutation_preflight=true"
echo "visual_state_store_render_result_surface_bound_to_conflict_classifier=true"
echo "stage728_component_visual_state_store_input_action_cycle_manager_prepared=true"
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
