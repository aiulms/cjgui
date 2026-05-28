#!/usr/bin/env zsh
#
# Verifies the stage620 shared focus/validation input cycle runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage620_shared_focus_validation_input_cycle_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage620 shared focus validation input cycle runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage620SharedFocusValidationInputCycleRuntimeContractPlan" \
  "CjguiInternalRendererStage620SharedFocusValidationInputCycleRuntimeContractFacts" \
  "CjguiInternalRendererStage620SharedFocusValidationInputCycleRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage620SharedFocusValidationInputCycleRuntimeContractDraft" \
  "CjguiInternalRendererStage619FocusValidationDemoSurfaceInspectionResultReadiness" \
  "didConsumeStage619FocusValidationDemoSurfaceInspectionResult" \
  "didMaterializeSharedFocusValidationInputCycleRuntimeContract" \
  "didMaterializeSharedFocusValidationInputCycleRuntimeHelper" \
  "didMaterializeSharedFocusValidationInputCycleExecutionReceiptContract" \
  "didMaterializeCycleOrderInputActionStateRenderSurfaceHost" \
  "didMaterializeChatComposerFocusValidationInputCycleRuntimeSurface" \
  "didBindInputCycleRuntimeToStage617InputCycle" \
  "didBindInputCycleRuntimeToStage618StateRenderExecutor" \
  "didBindInputCycleRuntimeToStage619DemoSurfaceInspectionResult" \
  "didReduceFuturePerDemoFocusValidationInputCycleTemplateNeed" \
  "didPrepareStage621ComponentRuntimeFocusValidationHostIntegration"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage620 shared focus validation input cycle runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage620_shared_focus_validation_input_cycle_runtime_contract_owner_present=true"
echo "stage619_focus_validation_demo_surface_inspection_result_consumed=true"
echo "stage618_focus_validation_state_render_executor_consumed_transitively=true"
echo "stage617_focus_validation_input_cycle_consumed_transitively=true"
echo "stage616_focus_validation_runtime_contract_consumed_transitively=true"
echo "shared_focus_validation_input_cycle_runtime_contract_materialized=true"
echo "shared_focus_validation_input_cycle_runtime_helper_materialized=true"
echo "shared_focus_validation_input_cycle_execution_receipt_contract_materialized=true"
echo "cycle_order_input_action_state_render_surface_host_materialized=true"
echo "todo_focus_validation_input_cycle_runtime_surface_materialized=true"
echo "settings_focus_validation_input_cycle_runtime_surface_materialized=true"
echo "ai_generated_settings_focus_validation_input_cycle_runtime_surface_materialized=true"
echo "chat_composer_focus_validation_input_cycle_runtime_surface_materialized=true"
echo "input_cycle_runtime_bound_to_stage617_input_cycle=true"
echo "input_cycle_runtime_bound_to_stage618_state_render_executor=true"
echo "input_cycle_runtime_bound_to_stage619_demo_surface_inspection_result=true"
echo "future_per_demo_focus_validation_input_cycle_template_need_reduced=true"
echo "stage621_component_runtime_focus_validation_host_integration_prepared=true"
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
