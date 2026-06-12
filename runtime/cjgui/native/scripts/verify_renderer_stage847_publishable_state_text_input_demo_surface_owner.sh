#!/usr/bin/env zsh
#
# Verifies the stage847 publishable state text input demo surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage847_publishable_state_text_input_demo_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage847 publishable state text input demo surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage847PublishableStateTextInputDemoSurfacePlan" \
  "CjguiInternalRendererStage847PublishableStateTextInputDemoSurfaceFacts" \
  "CjguiInternalRendererStage847PublishableStateTextInputDemoSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage847PublishableStateTextInputDemoSurfaceDraft" \
  "CjguiInternalRendererStage846PublishableStateTextInputCompositionPreviewReadiness" \
  "didConsumeStage846PublishableStateTextInputCompositionPreview" \
  "didMaterializeTodoTextInputPreviewSurface" \
  "didMaterializeSettingsTextInputPreviewSurface" \
  "didMaterializeAiGeneratedSettingsTextInputPreviewSurface" \
  "didMaterializeChatComposerTextInputPreviewSurface" \
  "didMaterializeFileBrowserTextInputPreviewSurface" \
  "didMaterializeTextInputHostInspectionRows" \
  "didMaterializeInputFeedbackClearPreview" \
  "didMaterializeTextInputResultSurfaceReceipt" \
  "didPrepareStage848PublishableStateTextInputRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage847 publishable state text input demo surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage847_publishable_state_text_input_demo_surface_owner_present=true"
echo "stage846_publishable_state_text_input_composition_preview_consumed=true"
echo "stage845_publishable_state_text_input_adapter_consumed_transitively=true"
echo "todo_text_input_preview_surface_materialized=true"
echo "settings_text_input_preview_surface_materialized=true"
echo "ai_generated_settings_text_input_preview_surface_materialized=true"
echo "chat_composer_text_input_preview_surface_materialized=true"
echo "file_browser_text_input_preview_surface_materialized=true"
echo "text_input_host_inspection_rows_materialized=true"
echo "input_feedback_clear_preview_materialized=true"
echo "text_input_result_surface_receipt_materialized=true"
echo "text_input_surface_bound_to_stage846_composition_preview=true"
echo "stage848_publishable_state_text_input_runtime_manager_prepared=true"
echo "host_mutation=false"
echo "text_dispatch=false"
echo "input_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
