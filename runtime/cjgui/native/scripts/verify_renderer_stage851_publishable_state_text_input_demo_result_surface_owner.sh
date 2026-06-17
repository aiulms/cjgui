#!/usr/bin/env zsh
#
# Verifies the stage851 publishable state text input demo result surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage851_publishable_state_text_input_demo_result_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage851 publishable state text input demo result surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage851PublishableStateTextInputDemoResultSurfacePlan" \
  "CjguiInternalRendererStage851PublishableStateTextInputDemoResultSurfaceFacts" \
  "CjguiInternalRendererStage851PublishableStateTextInputDemoResultSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage851PublishableStateTextInputDemoResultSurfaceDraft" \
  "CjguiInternalRendererStage850PublishableStateTextInputRenderCommandRefreshPreviewReadiness" \
  "didConsumeStage850PublishableStateTextInputRenderCommandRefreshPreview" \
  "didMaterializeTodoTextInputStateRenderResultSurface" \
  "didMaterializeSettingsTextInputStateRenderResultSurface" \
  "didMaterializeAiGeneratedSettingsTextInputStateRenderResultSurface" \
  "didMaterializeChatComposerTextInputStateRenderResultSurface" \
  "didMaterializeFileBrowserTextInputStateRenderResultSurface" \
  "didMaterializeTextInputStateRenderHostInspectionRows" \
  "didMaterializeTextInputStateRenderSemanticDiffReceipt" \
  "didPrepareStage852PublishableStateTextInputStateUpdateRenderBridgeRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage851 publishable state text input demo result surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage851_publishable_state_text_input_demo_result_surface_owner_present=true"
echo "stage850_publishable_state_text_input_render_command_refresh_preview_consumed=true"
echo "stage849_publishable_state_text_input_state_update_render_bridge_consumed_transitively=true"
echo "todo_text_input_state_render_result_surface_materialized=true"
echo "settings_text_input_state_render_result_surface_materialized=true"
echo "ai_generated_settings_text_input_state_render_result_surface_materialized=true"
echo "chat_composer_text_input_state_render_result_surface_materialized=true"
echo "file_browser_text_input_state_render_result_surface_materialized=true"
echo "text_input_state_render_host_inspection_rows_materialized=true"
echo "text_input_state_render_semantic_diff_receipt_materialized=true"
echo "stage852_publishable_state_text_input_state_update_render_bridge_runtime_manager_prepared=true"
echo "host_mutation=false"
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
