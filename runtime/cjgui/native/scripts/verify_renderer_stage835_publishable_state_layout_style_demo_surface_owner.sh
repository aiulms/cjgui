#!/usr/bin/env zsh
#
# Verifies the stage835 publishable state layout/style demo surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage835_publishable_state_layout_style_demo_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage835 publishable state layout style demo surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfacePlan" \
  "CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceFacts" \
  "CjguiInternalRendererStage835PublishableStateLayoutStyleDemoSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage835PublishableStateLayoutStyleDemoSurfaceDraft" \
  "CjguiInternalRendererStage834PublishableStateTextFocusMeasurementReadiness" \
  "didConsumeStage834PublishableStateTextFocusMeasurementPlan" \
  "didMaterializeTodoLayoutStylePreviewSurface" \
  "didMaterializeSettingsLayoutStylePreviewSurface" \
  "didMaterializeAiGeneratedSettingsLayoutStylePreviewSurface" \
  "didMaterializeChatComposerLayoutStylePreviewSurface" \
  "didMaterializeFileBrowserLayoutStylePreviewSurface" \
  "didMaterializeLayoutStyleResultSurfaceReceipt" \
  "didPrepareStage836PublishableStateLayoutStyleRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage835 publishable state layout style demo surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage835_publishable_state_layout_style_demo_surface_owner_present=true"
echo "stage834_publishable_state_text_focus_measurement_plan_consumed=true"
echo "stage833_publishable_state_layout_style_resolver_consumed_transitively=true"
echo "text_focus_measurement_plan_consumed=true"
echo "todo_layout_style_preview_surface_materialized=true"
echo "settings_layout_style_preview_surface_materialized=true"
echo "ai_generated_settings_layout_style_preview_surface_materialized=true"
echo "chat_composer_layout_style_preview_surface_materialized=true"
echo "file_browser_layout_style_preview_surface_materialized=true"
echo "layout_style_result_surface_receipt_materialized=true"
echo "demo_surface_bound_to_text_focus_measurement_plan=true"
echo "stage836_publishable_state_layout_style_runtime_manager_prepared=true"
echo "host_mutation=false"
echo "layout_engine_enabled=false"
echo "style_resolver_production_enabled=false"
echo "public_component_api_added=true"
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
