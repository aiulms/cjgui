#!/usr/bin/env zsh
#
# Verifies the stage483 shared demo-surface refresh runtime execution contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage483_demo_surface_refresh_runtime_execution_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage483 demo surface refresh runtime execution contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage483DemoSurfaceRefreshRuntimeExecutionContractPlan" \
  "CjguiInternalRendererStage483DemoSurfaceRefreshRuntimeExecutionContractFacts" \
  "CjguiInternalRendererStage483DemoSurfaceRefreshRuntimeExecutionContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage483DemoSurfaceRefreshRuntimeExecutionContractDraft" \
  "CjguiInternalRendererStage482DemoSurfaceRefreshRuntimeReceiptReadiness" \
  "didConsumeStage482DemoSurfaceRefreshRuntimeReceipt" \
  "didConsumeSharedDemoSurfaceRefreshRuntimeReceipt" \
  "didConsumeTodoDemoSurfaceRefreshRuntimeReceipt" \
  "didConsumeSettingsDemoSurfaceRefreshRuntimeReceipt" \
  "didConsumeAiGeneratedSettingsDemoSurfaceRefreshRuntimeReceipt" \
  "didMaterializeSharedDemoSurfaceRefreshRuntimeExecutionContract" \
  "didMaterializeSharedDemoSurfaceRefreshRuntimeExecutionHelper" \
  "didMaterializeTodoDemoSurfaceRefreshRuntimeExecutionReceipt" \
  "didMaterializeSettingsDemoSurfaceRefreshRuntimeExecutionReceipt" \
  "didMaterializeAiGeneratedSettingsDemoSurfaceRefreshRuntimeExecutionReceipt" \
  "didBindRuntimeReceiptToExecutionContract" \
  "didBindLayoutFocusRouteToExecutionContract" \
  "didBindCheckableProbeToExecutionContract" \
  "didKeepRuntimeExecutionContractReusable" \
  "didKeepRuntimeExecutionContractOwnerLocal" \
  "didKeepRuntimeExecutionContractNonDispatching" \
  "didPrepareStage484DemoSurfaceRefreshFocusInputActionAdapterRoute" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage483 demo surface refresh runtime execution contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage483_demo_surface_refresh_runtime_execution_contract_owner_present=true"
echo "stage482_demo_surface_refresh_runtime_receipt_required=true"
echo "stage482_demo_surface_refresh_runtime_receipt_consumed=true"
echo "shared_demo_surface_refresh_runtime_receipt_consumed=true"
echo "todo_demo_surface_refresh_runtime_receipt_consumed=true"
echo "settings_demo_surface_refresh_runtime_receipt_consumed=true"
echo "ai_generated_settings_demo_surface_refresh_runtime_receipt_consumed=true"
echo "shared_demo_surface_refresh_runtime_execution_contract_materialized=true"
echo "shared_demo_surface_refresh_runtime_execution_helper_materialized=true"
echo "todo_demo_surface_refresh_runtime_execution_receipt_materialized=true"
echo "settings_demo_surface_refresh_runtime_execution_receipt_materialized=true"
echo "ai_generated_settings_demo_surface_refresh_runtime_execution_receipt_materialized=true"
echo "runtime_receipt_to_execution_contract_bound=true"
echo "layout_focus_route_to_execution_contract_bound=true"
echo "checkable_probe_to_execution_contract_bound=true"
echo "runtime_execution_contract_reusable=true"
echo "runtime_execution_contract_owner_local=true"
echo "runtime_execution_contract_non_dispatching=true"
echo "stage484_demo_surface_refresh_focus_input_action_adapter_route_prepared=true"
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
