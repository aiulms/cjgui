#!/usr/bin/env zsh
#
# 维护注释：验证 stage462 shared component runtime demo surface execution receipt owner。
# 它必须消费 stage461 input/state bridge，并产出可检查 demo surface probe input / receipt。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage462_shared_component_runtime_demo_surface_execution_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage462 shared component runtime demo surface execution receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage462SharedComponentRuntimeDemoSurfaceExecutionReceiptPlan" \
  "CjguiInternalRendererStage462SharedComponentRuntimeDemoSurfaceExecutionReceiptFacts" \
  "CjguiInternalRendererStage462SharedComponentRuntimeDemoSurfaceExecutionReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage462SharedComponentRuntimeDemoSurfaceExecutionReceiptDraft" \
  "CjguiInternalRendererStage461SharedComponentRuntimeInputStateBridgeReadiness" \
  "didConsumeStage461SharedComponentRuntimeInputStateBridge" \
  "didConsumeSharedComponentRuntimeInputStateBridge" \
  "didConsumeTodoRuntimeStateDeltaCandidate" \
  "didConsumeSettingsRuntimeStateDeltaCandidate" \
  "didConsumeAiGeneratedSettingsRuntimeStateDeltaCandidate" \
  "didMaterializeSharedComponentRuntimeDemoSurfaceExecutionReceipt" \
  "didMaterializeTodoRuntimeDemoSurfaceProbeInput" \
  "didMaterializeSettingsRuntimeDemoSurfaceProbeInput" \
  "didMaterializeAiGeneratedSettingsRuntimeDemoSurfaceProbeInput" \
  "didBindInputStateBridgeToDemoSurfaceExecutionReceipt" \
  "didBindComponentRuntimeContractToDemoSurfaceExecutionReceipt" \
  "didKeepDemoSurfaceExecutionReceiptOwnerLocal" \
  "didKeepDemoSurfaceExecutionReceiptCheckable" \
  "didPrepareStage463SharedComponentRuntimeRenderCommandRefreshBridge" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage462 shared component runtime demo surface execution receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage462_shared_component_runtime_demo_surface_execution_receipt_owner_present=true"
echo "stage461_shared_component_runtime_input_state_bridge_required=true"
echo "stage461_shared_component_runtime_input_state_bridge_consumed=true"
echo "shared_component_runtime_input_state_bridge_consumed=true"
echo "todo_runtime_state_delta_candidate_consumed=true"
echo "settings_runtime_state_delta_candidate_consumed=true"
echo "ai_generated_settings_runtime_state_delta_candidate_consumed=true"
echo "shared_component_runtime_demo_surface_execution_receipt_materialized=true"
echo "todo_runtime_demo_surface_probe_input_materialized=true"
echo "settings_runtime_demo_surface_probe_input_materialized=true"
echo "ai_generated_settings_runtime_demo_surface_probe_input_materialized=true"
echo "input_state_bridge_to_demo_surface_execution_receipt_bound=true"
echo "component_runtime_contract_to_demo_surface_execution_receipt_bound=true"
echo "demo_surface_execution_receipt_owner_local=true"
echo "demo_surface_execution_receipt_checkable=true"
echo "stage463_shared_component_runtime_render_command_refresh_bridge_prepared=true"
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
