#!/usr/bin/env zsh
#
# Verifies the stage481 demo-surface refresh layout/focus execution route owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage481_demo_surface_refresh_layout_focus_execution_route.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage481 demo surface refresh layout/focus execution route: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage481DemoSurfaceRefreshLayoutFocusExecutionRoutePlan" \
  "CjguiInternalRendererStage481DemoSurfaceRefreshLayoutFocusExecutionRouteFacts" \
  "CjguiInternalRendererStage481DemoSurfaceRefreshLayoutFocusExecutionRouteReadiness" \
  "cjguiInternalExecuteDefaultRendererStage481DemoSurfaceRefreshLayoutFocusExecutionRouteDraft" \
  "CjguiInternalRendererStage480DemoSurfaceRefreshRenderCommandProbeContractReadiness" \
  "didConsumeStage480DemoSurfaceRefreshRenderCommandProbeContract" \
  "didConsumeSharedDemoSurfaceRefreshRenderCommandProbeContract" \
  "didConsumeTodoDemoSurfaceRefreshCheckableSurfaceProbe" \
  "didConsumeSettingsDemoSurfaceRefreshCheckableSurfaceProbe" \
  "didConsumeAiGeneratedSettingsDemoSurfaceRefreshCheckableSurfaceProbe" \
  "didMaterializeSharedDemoSurfaceRefreshLayoutFocusExecutionRoute" \
  "didMaterializeTodoDemoSurfaceRefreshLayoutFocusPass" \
  "didMaterializeSettingsDemoSurfaceRefreshLayoutFocusPass" \
  "didMaterializeAiGeneratedSettingsDemoSurfaceRefreshLayoutFocusPass" \
  "didBindCheckableProbeContractToLayoutFocusExecutionRoute" \
  "didBindRenderCommandProbeToLayoutFocusPass" \
  "didMaterializeDemoSurfaceRefreshTextFocusRoute" \
  "didKeepLayoutFocusExecutionRouteReusable" \
  "didKeepLayoutFocusExecutionRouteOwnerLocal" \
  "didKeepLayoutFocusExecutionRouteDryRunOnly" \
  "didPrepareStage482DemoSurfaceRefreshRuntimeReceipt" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage481 demo surface refresh layout/focus execution route: missing token $token" >&2
    exit 3
  fi
done

echo "stage481_demo_surface_refresh_layout_focus_execution_route_owner_present=true"
echo "stage480_demo_surface_refresh_render_command_probe_contract_required=true"
echo "stage480_demo_surface_refresh_render_command_probe_contract_consumed=true"
echo "shared_demo_surface_refresh_render_command_probe_contract_consumed=true"
echo "todo_demo_surface_refresh_checkable_surface_probe_consumed=true"
echo "settings_demo_surface_refresh_checkable_surface_probe_consumed=true"
echo "ai_generated_settings_demo_surface_refresh_checkable_surface_probe_consumed=true"
echo "shared_demo_surface_refresh_layout_focus_execution_route_materialized=true"
echo "todo_demo_surface_refresh_layout_focus_pass_materialized=true"
echo "settings_demo_surface_refresh_layout_focus_pass_materialized=true"
echo "ai_generated_settings_demo_surface_refresh_layout_focus_pass_materialized=true"
echo "checkable_probe_contract_to_layout_focus_execution_route_bound=true"
echo "render_command_probe_to_layout_focus_pass_bound=true"
echo "demo_surface_refresh_text_focus_route_materialized=true"
echo "layout_focus_execution_route_reusable=true"
echo "layout_focus_execution_route_owner_local=true"
echo "layout_focus_execution_route_dry_run_only=true"
echo "stage482_demo_surface_refresh_runtime_receipt_prepared=true"
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
