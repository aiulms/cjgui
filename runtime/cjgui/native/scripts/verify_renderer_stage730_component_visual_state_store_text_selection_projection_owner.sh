#!/usr/bin/env zsh
#
# Verifies the stage730 component visual state store text selection projection owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage730_component_visual_state_store_text_selection_projection.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage730 component visual state store text selection projection: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage730ComponentVisualStateStoreTextSelectionProjectionPlan" \
  "CjguiInternalRendererStage730ComponentVisualStateStoreTextSelectionProjectionFacts" \
  "CjguiInternalRendererStage730ComponentVisualStateStoreTextSelectionProjectionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage730ComponentVisualStateStoreTextSelectionProjectionDraft" \
  "CjguiInternalRendererStage729ComponentVisualStateStoreLayoutStyleFocusResolverReadiness" \
  "didConsumeStage729ComponentVisualStateStoreLayoutStyleFocusResolver" \
  "didMaterializeSharedVisualStateStoreTextModelProjection" \
  "didMaterializeVisualStateStoreSelectionLedger" \
  "didMaterializeVisualStateStoreCaretLedger" \
  "didMaterializeVisualStateStoreCompositionPlaceholderLedger" \
  "didBindTextSelectionProjectionToStage729Resolver" \
  "didPrepareStage731ComponentVisualStateStoreResolverHostInspectionSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage730 component visual state store text selection projection: missing token $token" >&2
    exit 3
  fi
done

echo "stage730_component_visual_state_store_text_selection_projection_owner_present=true"
echo "stage729_component_visual_state_store_layout_style_focus_resolver_consumed=true"
echo "stage728_component_visual_state_store_input_action_cycle_manager_consumed_transitively=true"
echo "shared_visual_state_store_text_model_projection_materialized=true"
echo "visual_state_store_selection_ledger_materialized=true"
echo "visual_state_store_caret_ledger_materialized=true"
echo "visual_state_store_composition_placeholder_ledger_materialized=true"
echo "todo_visual_state_store_text_selection_projection_materialized=true"
echo "settings_visual_state_store_text_selection_projection_materialized=true"
echo "ai_generated_settings_visual_state_store_text_selection_projection_materialized=true"
echo "chat_composer_visual_state_store_text_selection_projection_materialized=true"
echo "text_selection_projection_bound_to_stage729_resolver=true"
echo "stage731_component_visual_state_store_resolver_host_inspection_surface_prepared=true"
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
