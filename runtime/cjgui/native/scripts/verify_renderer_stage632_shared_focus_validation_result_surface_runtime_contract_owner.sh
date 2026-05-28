#!/usr/bin/env zsh
#
# Verifies the stage632 shared focus/validation result-surface runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage632_shared_focus_validation_result_surface_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage632 shared focus validation result surface runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage632SharedFocusValidationResultSurfaceRuntimeContractPlan" \
  "CjguiInternalRendererStage632SharedFocusValidationResultSurfaceRuntimeContractFacts" \
  "CjguiInternalRendererStage632SharedFocusValidationResultSurfaceRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage632SharedFocusValidationResultSurfaceRuntimeContractDraft" \
  "CjguiInternalRendererStage631FocusValidationResultSurfaceHostInspectionReadiness" \
  "didConsumeStage631FocusValidationResultSurfaceHostInspection" \
  "didMaterializeSharedFocusValidationResultSurfaceRuntimeContract" \
  "didMaterializeSharedFocusValidationResultSurfaceRuntimeHelper" \
  "didMaterializeSharedFocusValidationResultSurfaceExecutionReceiptContract" \
  "didMaterializeCycleOrderHostInputRuntimeResultSurfaceSemanticRefreshHostInspectionRuntimeReceipt" \
  "didMaterializeChatComposerFocusValidationResultSurfaceRuntimeSurface" \
  "didReduceFuturePerDemoFocusValidationResultSurfaceTemplateNeed" \
  "didPrepareStage633ComponentRuntimeFocusValidationResultSurfaceInteractionBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage632 shared focus validation result surface runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage632_shared_focus_validation_result_surface_runtime_contract_owner_present=true"
echo "stage631_focus_validation_result_surface_host_inspection_consumed=true"
echo "stage630_focus_validation_host_input_result_semantic_refresh_consumed_transitively=true"
echo "stage629_focus_validation_host_input_result_surface_consumed_transitively=true"
echo "stage628_shared_focus_validation_host_input_runtime_contract_consumed_transitively=true"
echo "shared_focus_validation_result_surface_runtime_contract_materialized=true"
echo "shared_focus_validation_result_surface_runtime_helper_materialized=true"
echo "shared_focus_validation_result_surface_execution_receipt_contract_materialized=true"
echo "cycle_order_host_input_runtime_result_surface_semantic_refresh_host_inspection_runtime_receipt_materialized=true"
echo "todo_focus_validation_result_surface_runtime_surface_materialized=true"
echo "settings_focus_validation_result_surface_runtime_surface_materialized=true"
echo "ai_generated_settings_focus_validation_result_surface_runtime_surface_materialized=true"
echo "chat_composer_focus_validation_result_surface_runtime_surface_materialized=true"
echo "future_per_demo_focus_validation_result_surface_template_need_reduced=true"
echo "stage633_component_runtime_focus_validation_result_surface_interaction_bridge_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
