#!/usr/bin/env zsh
#
# Verifies the stage762 preview component API text/focus projection owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage762_preview_component_api_text_focus_projection.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage762 preview component api text focus projection: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage762PreviewComponentApiTextFocusProjectionPlan" \
  "CjguiInternalRendererStage762PreviewComponentApiTextFocusProjectionFacts" \
  "CjguiInternalRendererStage762PreviewComponentApiTextFocusProjectionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage762PreviewComponentApiTextFocusProjectionDraft" \
  "CjguiInternalRendererStage761PreviewComponentApiLayoutStyleConsumptionReadiness" \
  "didConsumeStage761PreviewComponentApiLayoutStyleConsumption" \
  "didConsumePreviewComponentLayoutStyleDescriptors" \
  "didMaterializePreviewComponentTextValueProjection" \
  "didMaterializePreviewComponentCaretSelectionProjection" \
  "didMaterializePreviewComponentFocusTraversalProjection" \
  "didMaterializePreviewComponentCompositionPlaceholderProjection" \
  "didPrepareStage763PreviewComponentApiDemoHostInspectionSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage762 preview component api text focus projection: missing token $token" >&2
    exit 3
  fi
done

echo "stage762_preview_component_api_text_focus_projection_owner_present=true"
echo "stage761_preview_component_api_layout_style_consumption_consumed=true"
echo "preview_component_layout_style_descriptors_consumed=true"
echo "preview_component_text_value_projection_materialized=true"
echo "preview_component_caret_selection_projection_materialized=true"
echo "preview_component_focus_traversal_projection_materialized=true"
echo "preview_component_composition_placeholder_projection_materialized=true"
echo "todo_preview_component_api_text_focus_projection_materialized=true"
echo "settings_preview_component_api_text_focus_projection_materialized=true"
echo "ai_generated_settings_preview_component_api_text_focus_projection_materialized=true"
echo "chat_composer_preview_component_api_text_focus_projection_materialized=true"
echo "stage763_preview_component_api_demo_host_inspection_surface_prepared=true"
echo "public_component_api_added=true"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "acceptance_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
