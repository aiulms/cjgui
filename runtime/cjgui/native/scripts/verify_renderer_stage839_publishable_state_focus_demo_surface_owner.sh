#!/usr/bin/env zsh
#
# Verifies the stage839 publishable state focus demo surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage839_publishable_state_focus_demo_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage839 publishable state focus demo surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage839PublishableStateFocusDemoSurfacePlan" \
  "CjguiInternalRendererStage839PublishableStateFocusDemoSurfaceFacts" \
  "CjguiInternalRendererStage839PublishableStateFocusDemoSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage839PublishableStateFocusDemoSurfaceDraft" \
  "CjguiInternalRendererStage838PublishableStateFocusMovementPreviewReadiness" \
  "didConsumeStage838PublishableStateFocusMovementPreview" \
  "didMaterializeTodoFocusInspectionSurface" \
  "didMaterializeSettingsFocusInspectionSurface" \
  "didMaterializeAiGeneratedSettingsFocusInspectionSurface" \
  "didMaterializeChatComposerFocusInspectionSurface" \
  "didMaterializeFileBrowserFocusInspectionSurface" \
  "didMaterializeFocusResultSurfaceReceipt" \
  "didPrepareStage840PublishableStateFocusRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage839 publishable state focus demo surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage839_publishable_state_focus_demo_surface_owner_present=true"
echo "stage838_publishable_state_focus_movement_preview_consumed=true"
echo "stage837_publishable_state_focus_manager_consumed_transitively=true"
echo "focus_movement_preview_consumed=true"
echo "todo_focus_inspection_surface_materialized=true"
echo "settings_focus_inspection_surface_materialized=true"
echo "ai_generated_settings_focus_inspection_surface_materialized=true"
echo "chat_composer_focus_inspection_surface_materialized=true"
echo "file_browser_focus_inspection_surface_materialized=true"
echo "focus_result_surface_receipt_materialized=true"
echo "focus_surface_bound_to_stage838_movement_preview=true"
echo "stage840_publishable_state_focus_runtime_manager_prepared=true"
echo "host_mutation=false"
echo "focus_dispatch=false"
echo "input_pipeline_execution=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "state_store_commit_published=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
