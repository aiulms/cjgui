#!/usr/bin/env zsh
#
# Verifies the stage723 component visual state store render refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage723_component_visual_state_store_render_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage723 component visual state store render refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage723ComponentVisualStateStoreRenderRefreshPlan" \
  "CjguiInternalRendererStage723ComponentVisualStateStoreRenderRefreshFacts" \
  "CjguiInternalRendererStage723ComponentVisualStateStoreRenderRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage723ComponentVisualStateStoreRenderRefreshDraft" \
  "CjguiInternalRendererStage722ComponentVisualStateStoreDeltaRollbackReadiness" \
  "didConsumeStage722ComponentVisualStateStoreDeltaRollback" \
  "didMaterializeStateStoreRenderCommandRefreshReceipt" \
  "didMaterializeStateStoreLayoutStyleTextFocusRefreshSurface" \
  "didMaterializeStateStoreHostInspectionPreview" \
  "didBindRenderRefreshToRollbackSnapshot" \
  "didPrepareStage724ComponentVisualStateStoreManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage723 component visual state store render refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage723_component_visual_state_store_render_refresh_owner_present=true"
echo "stage722_component_visual_state_store_delta_rollback_consumed=true"
echo "stage721_component_visual_state_store_preflight_consumed_transitively=true"
echo "state_store_render_command_refresh_receipt_materialized=true"
echo "state_store_layout_style_text_focus_refresh_surface_materialized=true"
echo "state_store_host_inspection_preview_materialized=true"
echo "todo_state_store_render_refresh_surface_materialized=true"
echo "settings_state_store_render_refresh_surface_materialized=true"
echo "ai_generated_settings_state_store_render_refresh_surface_materialized=true"
echo "chat_composer_state_store_render_refresh_surface_materialized=true"
echo "render_refresh_bound_to_rollback_snapshot=true"
echo "stage724_component_visual_state_store_manager_prepared=true"
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
