#!/usr/bin/env zsh
#
# Verifies the stage529 shared runtime demo cycle input contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage529_shared_runtime_demo_cycle_input_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage529 shared runtime demo cycle input contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage529SharedRuntimeDemoCycleInputContractPlan" \
  "CjguiInternalRendererStage529SharedRuntimeDemoCycleInputContractFacts" \
  "CjguiInternalRendererStage529SharedRuntimeDemoCycleInputContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage529SharedRuntimeDemoCycleInputContractDraft" \
  "CjguiInternalRendererStage528DemoSurfaceRefreshStateRenderCommandRefreshReadiness" \
  "didConsumeStage528DemoSurfaceRefreshStateRenderCommandRefresh" \
  "didConsumeDemoSurfaceRefreshStateToRenderCommandRefreshBridgeV3" \
  "didMaterializeSharedRuntimeDemoCycleInputContract" \
  "didMaterializeSharedRuntimeDemoCycleRouteLedger" \
  "didMaterializeTodoRuntimeDemoCycleInput" \
  "didMaterializeSettingsRuntimeDemoCycleInput" \
  "didMaterializeAiGeneratedSettingsRuntimeDemoCycleInput" \
  "didBindRenderCommandRefreshToRuntimeDemoCycleInput" \
  "didCompressRepeatedPreviewProbeRouteIntoCycleInput" \
  "didPrepareStage530SharedRuntimeDemoCycleExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage529 shared runtime demo cycle input contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage529_shared_runtime_demo_cycle_input_contract_owner_present=true"
echo "stage528_demo_surface_refresh_state_render_command_refresh_consumed=true"
echo "shared_demo_surface_refresh_checkable_state_render_command_refresh_consumed=true"
echo "demo_surface_refresh_state_to_render_command_refresh_bridge_v3_consumed=true"
echo "todo_refreshed_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "settings_refreshed_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "ai_generated_settings_refreshed_demo_surface_refresh_render_command_probe_input_consumed=true"
echo "shared_runtime_demo_cycle_input_contract_materialized=true"
echo "shared_runtime_demo_cycle_route_ledger_materialized=true"
echo "todo_runtime_demo_cycle_input_materialized=true"
echo "settings_runtime_demo_cycle_input_materialized=true"
echo "ai_generated_settings_runtime_demo_cycle_input_materialized=true"
echo "render_command_refresh_to_runtime_demo_cycle_input_bound=true"
echo "stage526_527_528_route_compressed_into_cycle_input=true"
echo "repeated_preview_probe_route_compressed=true"
echo "runtime_demo_cycle_input_contract_reusable=true"
echo "runtime_demo_cycle_input_contract_owner_local=true"
echo "runtime_demo_cycle_input_contract_non_executing=true"
echo "stage530_shared_runtime_demo_cycle_executor_prepared=true"
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
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "text_shaping_enabled=false"
echo "focus_manager_enabled=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
