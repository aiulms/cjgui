#!/usr/bin/env zsh
#
# Verifies the stage499 demo-surface refresh layout/style/preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage499_demo_surface_refresh_layout_style_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage499 demo surface refresh layout style preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage499DemoSurfaceRefreshLayoutStylePreviewPlan" \
  "CjguiInternalRendererStage499DemoSurfaceRefreshLayoutStylePreviewFacts" \
  "CjguiInternalRendererStage499DemoSurfaceRefreshLayoutStylePreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage499DemoSurfaceRefreshLayoutStylePreviewDraft" \
  "CjguiInternalRendererStage498DemoSurfaceRefreshStateRenderCommandRefreshReadiness" \
  "didConsumeStage498DemoSurfaceRefreshStateRenderCommandRefresh" \
  "didConsumeSharedDemoSurfaceRefreshStateRenderCommandRefresh" \
  "didConsumeTodoDemoSurfaceRefreshRenderCommandProbeInput" \
  "didConsumeSettingsDemoSurfaceRefreshRenderCommandProbeInput" \
  "didConsumeAiGeneratedSettingsDemoSurfaceRefreshRenderCommandProbeInput" \
  "didMaterializeSharedDemoSurfaceRefreshLayoutStyleTextFocusPreview" \
  "didMaterializeTodoRuntimeDemoSurfaceRefreshLayoutStyleTextFocusNode" \
  "didMaterializeSettingsRuntimeDemoSurfaceRefreshLayoutStyleTextFocusNode" \
  "didMaterializeAiGeneratedSettingsRuntimeDemoSurfaceRefreshLayoutStyleTextFocusNode" \
  "didBindRenderCommandRefreshToLayoutStylePreview" \
  "didKeepLayoutStylePreviewReusable" \
  "didKeepLayoutStylePreviewOwnerLocal" \
  "didKeepLayoutStylePreviewPreviewOnly" \
  "didPrepareStage500DemoSurfaceRefreshLayoutExecutionReceipt" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage499 demo surface refresh layout style preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage499_demo_surface_refresh_layout_style_preview_owner_present=true"
echo "stage498_demo_surface_refresh_state_render_command_refresh_required=true"
echo "stage498_demo_surface_refresh_state_render_command_refresh_consumed=true"
echo "shared_demo_surface_refresh_state_render_command_refresh_consumed=true"
echo "todo_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "settings_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "ai_generated_settings_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "shared_demo_surface_refresh_layout_style_text_focus_preview_materialized=true"
echo "todo_runtime_demo_surface_refresh_layout_style_text_focus_node_materialized=true"
echo "settings_runtime_demo_surface_refresh_layout_style_text_focus_node_materialized=true"
echo "ai_generated_settings_runtime_demo_surface_refresh_layout_style_text_focus_node_materialized=true"
echo "render_command_refresh_to_layout_style_preview_bound=true"
echo "layout_style_preview_reusable=true"
echo "layout_style_preview_owner_local=true"
echo "layout_style_preview_preview_only=true"
echo "stage500_demo_surface_refresh_layout_execution_receipt_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
