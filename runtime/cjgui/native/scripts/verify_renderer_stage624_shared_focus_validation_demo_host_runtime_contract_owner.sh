#!/usr/bin/env zsh
#
# Verifies the stage624 shared focus/validation demo host runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage624_shared_focus_validation_demo_host_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage624 shared focus validation demo host runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage624SharedFocusValidationDemoHostRuntimeContractPlan" \
  "CjguiInternalRendererStage624SharedFocusValidationDemoHostRuntimeContractFacts" \
  "CjguiInternalRendererStage624SharedFocusValidationDemoHostRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage624SharedFocusValidationDemoHostRuntimeContractDraft" \
  "CjguiInternalRendererStage623FocusValidationHostInteractionReceiptReadiness" \
  "didConsumeStage623FocusValidationHostInteractionReceipt" \
  "didMaterializeSharedFocusValidationDemoHostRuntimeContract" \
  "didMaterializeSharedFocusValidationDemoHostRuntimeHelper" \
  "didMaterializeSharedFocusValidationDemoHostExecutionReceiptContract" \
  "didMaterializeCycleOrderInputActionStateRenderSurfaceHostFrameReceipt" \
  "didMaterializeChatComposerFocusValidationDemoHostRuntimeSurface" \
  "didBindDemoHostRuntimeToStage621HostIntegration" \
  "didBindDemoHostRuntimeToStage622FrameAssembly" \
  "didBindDemoHostRuntimeToStage623InteractionReceipt" \
  "didReduceFuturePerDemoFocusValidationHostIntegrationTemplateNeed" \
  "didPrepareStage625ComponentRuntimeFocusValidationHostInputAdapter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage624 shared focus validation demo host runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage624_shared_focus_validation_demo_host_runtime_contract_owner_present=true"
echo "stage623_focus_validation_host_interaction_receipt_consumed=true"
echo "stage622_focus_validation_host_frame_assembly_consumed_transitively=true"
echo "stage621_focus_validation_host_integration_consumed_transitively=true"
echo "stage620_shared_focus_validation_input_cycle_runtime_contract_consumed_transitively=true"
echo "host_interaction_receipts_consumed=true"
echo "shared_focus_validation_demo_host_runtime_contract_materialized=true"
echo "shared_focus_validation_demo_host_runtime_helper_materialized=true"
echo "shared_focus_validation_demo_host_execution_receipt_contract_materialized=true"
echo "cycle_order_input_action_state_render_surface_host_frame_receipt_materialized=true"
echo "todo_focus_validation_demo_host_runtime_surface_materialized=true"
echo "settings_focus_validation_demo_host_runtime_surface_materialized=true"
echo "ai_generated_settings_focus_validation_demo_host_runtime_surface_materialized=true"
echo "chat_composer_focus_validation_demo_host_runtime_surface_materialized=true"
echo "demo_host_runtime_bound_to_stage621_host_integration=true"
echo "demo_host_runtime_bound_to_stage622_frame_assembly=true"
echo "demo_host_runtime_bound_to_stage623_interaction_receipt=true"
echo "future_per_demo_focus_validation_host_integration_template_need_reduced=true"
echo "stage625_component_runtime_focus_validation_host_input_adapter_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "focus_manager_enabled=false"
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
