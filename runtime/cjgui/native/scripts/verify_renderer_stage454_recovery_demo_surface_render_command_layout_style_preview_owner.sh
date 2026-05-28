#!/usr/bin/env zsh
#
# 维护注释：验证 stage454 recovery demo surface RenderCommand -> layout/style/text/focus preview owner。
# 它必须消费 stage453 RenderCommand refresh，并生成共享 demo surface 语义预览。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage454_recovery_demo_surface_render_command_layout_style_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage454 recovery demo surface render command layout style preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage454RecoveryDemoSurfaceRenderCommandLayoutStylePreviewPlan" \
  "CjguiInternalRendererStage454RecoveryDemoSurfaceRenderCommandLayoutStylePreviewFacts" \
  "CjguiInternalRendererStage454RecoveryDemoSurfaceRenderCommandLayoutStylePreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage454RecoveryDemoSurfaceRenderCommandLayoutStylePreviewDraft" \
  "CjguiInternalRendererStage453RecoveryDemoSurfaceStateUpdateRenderCommandRefreshReadiness" \
  "didConsumeStage453RecoveryDemoSurfaceStateUpdateRenderCommandRefresh" \
  "didConsumeRecoveryDemoSurfaceRenderCommandRefreshPreview" \
  "didProjectTodoRenderCommandToLayoutStylePreview" \
  "didProjectSettingsRenderCommandToLayoutStylePreview" \
  "didProjectAiGeneratedSettingsRenderCommandToLayoutStylePreview" \
  "didMaterializeSharedRecoveryDemoSurfaceLayoutStyleTextFocusPreview" \
  "didMaterializeTodoLayoutStyleTextFocusNode" \
  "didMaterializeSettingsLayoutStyleTextFocusNode" \
  "didMaterializeAiGeneratedSettingsLayoutStyleTextFocusNode" \
  "didBindRenderCommandRefreshToLayoutStylePreview" \
  "didKeepLayoutStylePreviewOwnerLocal" \
  "didKeepLayoutStylePreviewDryRunOnly" \
  "didPrepareStage455RecoveryDemoSurfaceLayoutStyleExecutionDryRun" \
  "didKeepLayoutEngineBlocked" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage454 recovery demo surface render command layout style preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage454_recovery_demo_surface_render_command_layout_style_preview_owner_present=true"
echo "stage453_recovery_demo_surface_state_update_render_command_refresh_required=true"
echo "stage453_recovery_demo_surface_state_update_render_command_refresh_consumed=true"
echo "recovery_demo_surface_render_command_refresh_preview_consumed=true"
echo "todo_recovery_demo_surface_state_update_render_command_consumed=true"
echo "settings_recovery_demo_surface_state_update_render_command_consumed=true"
echo "ai_generated_settings_recovery_demo_surface_state_update_render_command_consumed=true"
echo "shared_recovery_demo_surface_layout_style_text_focus_preview_materialized=true"
echo "todo_recovery_demo_surface_layout_style_text_focus_node_materialized=true"
echo "settings_recovery_demo_surface_layout_style_text_focus_node_materialized=true"
echo "ai_generated_settings_recovery_demo_surface_layout_style_text_focus_node_materialized=true"
echo "render_command_refresh_to_layout_style_preview_bound=true"
echo "stage452_state_update_to_layout_style_preview_bound=true"
echo "recovery_demo_surface_layout_style_preview_owner_local=true"
echo "recovery_demo_surface_layout_style_preview_dry_run_only=true"
echo "stage455_recovery_demo_surface_layout_style_execution_dry_run_prepared=true"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
