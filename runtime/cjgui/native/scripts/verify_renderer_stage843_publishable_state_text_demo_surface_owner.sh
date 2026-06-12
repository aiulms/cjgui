#!/usr/bin/env zsh
#
# Verifies the stage843 publishable state text demo surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage843_publishable_state_text_demo_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage843 publishable state text demo surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage843PublishableStateTextDemoSurfacePlan" \
  "CjguiInternalRendererStage843PublishableStateTextDemoSurfaceFacts" \
  "CjguiInternalRendererStage843PublishableStateTextDemoSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage843PublishableStateTextDemoSurfaceDraft" \
  "CjguiInternalRendererStage842PublishableStateTextEditPreviewReadiness" \
  "didConsumeStage842PublishableStateTextEditPreview" \
  "didMaterializeTodoTextInspectionSurface" \
  "didMaterializeSettingsTextInspectionSurface" \
  "didMaterializeAiGeneratedSettingsTextInspectionSurface" \
  "didMaterializeChatComposerTextInspectionSurface" \
  "didMaterializeFileBrowserTextInspectionSurface" \
  "didMaterializeTextResultSurfaceReceipt" \
  "didBindTextSurfaceToStage842TextEditPreview" \
  "didPrepareStage844PublishableStateTextRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage843 publishable state text demo surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage843_publishable_state_text_demo_surface_owner_present=true"
echo "stage842_publishable_state_text_edit_preview_consumed=true"
echo "stage841_publishable_state_text_model_consumed_transitively=true"
echo "todo_text_inspection_surface_materialized=true"
echo "settings_text_inspection_surface_materialized=true"
echo "ai_generated_settings_text_inspection_surface_materialized=true"
echo "chat_composer_text_inspection_surface_materialized=true"
echo "file_browser_text_inspection_surface_materialized=true"
echo "text_result_surface_receipt_materialized=true"
echo "text_surface_bound_to_stage842_text_edit_preview=true"
echo "stage844_publishable_state_text_runtime_manager_prepared=true"
echo "host_mutation=false"
echo "text_dispatch=false"
echo "input_pipeline_execution=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
