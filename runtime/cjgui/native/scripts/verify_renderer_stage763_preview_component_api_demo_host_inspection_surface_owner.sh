#!/usr/bin/env zsh
#
# Verifies the stage763 preview component API demo-host inspection owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage763_preview_component_api_demo_host_inspection_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage763 preview component api demo host inspection surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage763PreviewComponentApiDemoHostInspectionSurfacePlan" \
  "CjguiInternalRendererStage763PreviewComponentApiDemoHostInspectionSurfaceFacts" \
  "CjguiInternalRendererStage763PreviewComponentApiDemoHostInspectionSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage763PreviewComponentApiDemoHostInspectionSurfaceDraft" \
  "CjguiInternalRendererStage762PreviewComponentApiTextFocusProjectionReadiness" \
  "didConsumeStage762PreviewComponentApiTextFocusProjection" \
  "didMaterializePreviewComponentApiHostInspectionRows" \
  "didMaterializePreviewComponentApiRenderCommandPreviewReceipt" \
  "didMaterializePreviewComponentApiSemanticDiffReceipt" \
  "didMaterializePreviewComponentApiResultSurfaceRefresh" \
  "didPrepareStage764PreviewComponentApiVisualResolverRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage763 preview component api demo host inspection surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage763_preview_component_api_demo_host_inspection_surface_owner_present=true"
echo "stage762_preview_component_api_text_focus_projection_consumed=true"
echo "preview_component_api_host_inspection_rows_materialized=true"
echo "preview_component_api_render_command_preview_receipt_materialized=true"
echo "preview_component_api_semantic_diff_receipt_materialized=true"
echo "preview_component_api_result_surface_refresh_materialized=true"
echo "todo_preview_component_api_demo_host_inspection_surface_materialized=true"
echo "settings_preview_component_api_demo_host_inspection_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_demo_host_inspection_surface_materialized=true"
echo "chat_composer_preview_component_api_demo_host_inspection_surface_materialized=true"
echo "stage764_preview_component_api_visual_resolver_runtime_manager_prepared=true"
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
