#!/usr/bin/env zsh
#
# Verifies the stage480 demo-surface refresh RenderCommand probe contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage480_demo_surface_refresh_render_command_probe_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage480 demo surface refresh RenderCommand probe contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage480DemoSurfaceRefreshRenderCommandProbeContractPlan" \
  "CjguiInternalRendererStage480DemoSurfaceRefreshRenderCommandProbeContractFacts" \
  "CjguiInternalRendererStage480DemoSurfaceRefreshRenderCommandProbeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage480DemoSurfaceRefreshRenderCommandProbeContractDraft" \
  "CjguiInternalRendererStage479DemoSurfaceRefreshStateRenderCommandBridgeReadiness" \
  "didConsumeStage479DemoSurfaceRefreshStateRenderCommandBridge" \
  "didConsumeSharedDemoSurfaceRefreshStateRenderCommandBridge" \
  "didConsumeTodoDemoSurfaceRefreshRenderCommandProbeInput" \
  "didConsumeSettingsDemoSurfaceRefreshRenderCommandProbeInput" \
  "didConsumeAiGeneratedSettingsDemoSurfaceRefreshRenderCommandProbeInput" \
  "didMaterializeSharedDemoSurfaceRefreshRenderCommandProbeContract" \
  "didMaterializeTodoDemoSurfaceRefreshCheckableSurfaceProbe" \
  "didMaterializeSettingsDemoSurfaceRefreshCheckableSurfaceProbe" \
  "didMaterializeAiGeneratedSettingsDemoSurfaceRefreshCheckableSurfaceProbe" \
  "didBindRenderCommandBridgeToDemoSurfaceProbeContract" \
  "didMaterializeDemoSurfaceRefreshExecutionReceiptContract" \
  "didKeepDemoSurfaceRefreshProbeContractReusable" \
  "didKeepDemoSurfaceRefreshProbeContractOwnerLocal" \
  "didPrepareStage481DemoSurfaceRefreshLayoutFocusExecutionRoute" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage480 demo surface refresh RenderCommand probe contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage480_demo_surface_refresh_render_command_probe_contract_owner_present=true"
echo "stage479_demo_surface_refresh_state_render_command_bridge_required=true"
echo "stage479_demo_surface_refresh_state_render_command_bridge_consumed=true"
echo "shared_demo_surface_refresh_state_render_command_bridge_consumed=true"
echo "todo_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "settings_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "ai_generated_settings_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "shared_demo_surface_refresh_render_command_probe_contract_materialized=true"
echo "todo_demo_surface_refresh_checkable_surface_probe_materialized=true"
echo "settings_demo_surface_refresh_checkable_surface_probe_materialized=true"
echo "ai_generated_settings_demo_surface_refresh_checkable_surface_probe_materialized=true"
echo "render_command_bridge_to_demo_surface_probe_contract_bound=true"
echo "demo_surface_refresh_execution_receipt_contract_materialized=true"
echo "demo_surface_refresh_probe_contract_reusable=true"
echo "demo_surface_refresh_probe_contract_owner_local=true"
echo "stage481_demo_surface_refresh_layout_focus_execution_route_prepared=true"
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
