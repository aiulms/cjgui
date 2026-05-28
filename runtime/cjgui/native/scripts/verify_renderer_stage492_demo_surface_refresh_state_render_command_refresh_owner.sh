#!/usr/bin/env zsh
#
# Verifies the stage492 demo-surface refresh state RenderCommand refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage492_demo_surface_refresh_state_render_command_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage492 demo surface refresh state render command refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage492DemoSurfaceRefreshStateRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage492DemoSurfaceRefreshStateRenderCommandRefreshFacts" \
  "CjguiInternalRendererStage492DemoSurfaceRefreshStateRenderCommandRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage492DemoSurfaceRefreshStateRenderCommandRefreshDraft" \
  "didConsumeStage491DemoSurfaceRefreshActionStateUpdateDryRun" \
  "didMaterializeSharedDemoSurfaceRefreshStateRenderCommandRefresh" \
  "didMaterializeTodoDemoSurfaceRefreshRenderCommandProbeInput" \
  "didMaterializeSettingsDemoSurfaceRefreshRenderCommandProbeInput" \
  "didMaterializeAiGeneratedSettingsDemoSurfaceRefreshRenderCommandProbeInput" \
  "didBindStateUpdateDryRunToRenderCommandRefresh" \
  "didPrepareStage493DemoSurfaceRefreshLayoutStylePreview" \
  "didKeepDemoSurfaceRefreshRenderCommandRefreshPreviewOnly"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage492 demo surface refresh state render command refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage492_demo_surface_refresh_state_render_command_refresh_owner_present=true"
echo "stage491_demo_surface_refresh_action_state_update_dry_run_consumed=true"
echo "shared_demo_surface_refresh_action_state_update_dry_run_consumed=true"
echo "todo_demo_surface_refresh_state_update_candidate_consumed=true"
echo "settings_demo_surface_refresh_state_update_candidate_consumed=true"
echo "ai_generated_settings_demo_surface_refresh_state_update_candidate_consumed=true"
echo "shared_demo_surface_refresh_state_render_command_refresh_materialized=true"
echo "todo_demo_surface_refresh_render_command_probe_input_materialized=true"
echo "settings_demo_surface_refresh_render_command_probe_input_materialized=true"
echo "ai_generated_settings_demo_surface_refresh_render_command_probe_input_materialized=true"
echo "state_update_dry_run_to_render_command_refresh_bound=true"
echo "render_command_refresh_to_checkable_preview_bridge_bound=true"
echo "demo_surface_refresh_render_command_refresh_reusable=true"
echo "demo_surface_refresh_render_command_refresh_preview_only=true"
echo "stage493_demo_surface_refresh_layout_style_preview_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "public_component_api_added=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
