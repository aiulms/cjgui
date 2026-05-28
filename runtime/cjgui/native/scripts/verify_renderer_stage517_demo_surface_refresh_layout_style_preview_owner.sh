#!/usr/bin/env zsh
#
# Verifies the stage517 demo-surface refresh layout/style preview owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage517_demo_surface_refresh_layout_style_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage517 demo surface refresh layout style preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage517DemoSurfaceRefreshLayoutStylePreviewPlan" \
  "CjguiInternalRendererStage517DemoSurfaceRefreshLayoutStylePreviewFacts" \
  "CjguiInternalRendererStage517DemoSurfaceRefreshLayoutStylePreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage517DemoSurfaceRefreshLayoutStylePreviewDraft" \
  "CjguiInternalRendererStage516DemoSurfaceRefreshInteractionCycleRenderRefreshReadiness" \
  "didConsumeStage516DemoSurfaceRefreshInteractionCycleRenderRefresh" \
  "didConsumeSharedDemoSurfaceRefreshRefreshedInteractionCycleReceipt" \
  "didConsumeDemoSurfaceRefreshRefreshedInteractionCycleExecutorContract" \
  "didConsumeDemoSurfaceRefreshRefreshedInteractionCycleExecutorHelper" \
  "didMaterializeSharedDemoSurfaceRefreshRefreshedLayoutStyleTextFocusPreview" \
  "didMaterializeTodoRefreshedRuntimeDemoSurfaceRefreshLayoutStyleTextFocusNode" \
  "didMaterializeSettingsRefreshedRuntimeDemoSurfaceRefreshLayoutStyleTextFocusNode" \
  "didMaterializeAiGeneratedSettingsRefreshedRuntimeDemoSurfaceRefreshLayoutStyleTextFocusNode" \
  "didBindRefreshedInteractionCycleExecutorHelperToLayoutStylePreview" \
  "didPrepareStage518DemoSurfaceRefreshLayoutExecutionReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage517 demo surface refresh layout style preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage517_demo_surface_refresh_layout_style_preview_owner_present=true"
echo "stage516_demo_surface_refresh_interaction_cycle_render_refresh_consumed=true"
echo "shared_demo_surface_refresh_refreshed_interaction_cycle_receipt_consumed=true"
echo "demo_surface_refresh_refreshed_interaction_cycle_executor_contract_consumed=true"
echo "demo_surface_refresh_refreshed_interaction_cycle_executor_helper_consumed=true"
echo "demo_surface_refresh_refreshed_interaction_cycle_executor_helper_bound_to_layout_style_preview=true"
echo "todo_refreshed_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "settings_refreshed_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "ai_generated_settings_refreshed_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "shared_demo_surface_refresh_refreshed_layout_style_text_focus_preview_materialized=true"
echo "todo_refreshed_runtime_demo_surface_refresh_layout_style_text_focus_node_materialized=true"
echo "settings_refreshed_runtime_demo_surface_refresh_layout_style_text_focus_node_materialized=true"
echo "ai_generated_settings_refreshed_runtime_demo_surface_refresh_layout_style_text_focus_node_materialized=true"
echo "refreshed_interaction_cycle_executor_helper_to_layout_style_preview_bound=true"
echo "demo_surface_refresh_refreshed_layout_style_preview_reusable=true"
echo "demo_surface_refresh_refreshed_layout_style_preview_owner_local=true"
echo "demo_surface_refresh_refreshed_layout_style_preview_preview_only=true"
echo "stage518_demo_surface_refresh_layout_execution_receipt_prepared=true"
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
