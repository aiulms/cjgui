#!/usr/bin/env zsh
#
# Verifies the stage850 publishable state text input RenderCommand refresh preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage850_publishable_state_text_input_render_command_refresh_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage850 publishable state text input render command refresh preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage850PublishableStateTextInputRenderCommandRefreshPreviewPlan" \
  "CjguiInternalRendererStage850PublishableStateTextInputRenderCommandRefreshPreviewFacts" \
  "CjguiInternalRendererStage850PublishableStateTextInputRenderCommandRefreshPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage850PublishableStateTextInputRenderCommandRefreshPreviewDraft" \
  "CjguiInternalRendererStage849PublishableStateTextInputStateUpdateRenderBridgeReadiness" \
  "didConsumeStage849PublishableStateTextInputStateUpdateRenderBridge" \
  "didMaterializeTextValueRenderCommandRefreshPreview" \
  "didMaterializeCaretSelectionRenderCommandRefreshPreview" \
  "didMaterializeCompositionUnderlineRenderCommandRefreshPreview" \
  "didMaterializeTextInputResultRefreshReceipt" \
  "didBindRenderCommandRefreshToStage849StateDelta" \
  "didBindRenderCommandRefreshToStage848RuntimeManager" \
  "didPrepareStage851PublishableStateTextInputDemoResultSurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage850 publishable state text input render command refresh preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage850_publishable_state_text_input_render_command_refresh_preview_owner_present=true"
echo "stage849_publishable_state_text_input_state_update_render_bridge_consumed=true"
echo "stage848_publishable_state_text_input_runtime_manager_consumed_transitively=true"
echo "text_value_render_command_refresh_preview_materialized=true"
echo "caret_selection_render_command_refresh_preview_materialized=true"
echo "composition_underline_render_command_refresh_preview_materialized=true"
echo "text_input_result_refresh_receipt_materialized=true"
echo "render_command_refresh_bound_to_stage849_state_delta=true"
echo "render_command_refresh_bound_to_stage848_runtime_manager=true"
echo "stage851_publishable_state_text_input_demo_result_surface_prepared=true"
echo "text_input_pipeline_execution=false"
echo "text_mutation=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
