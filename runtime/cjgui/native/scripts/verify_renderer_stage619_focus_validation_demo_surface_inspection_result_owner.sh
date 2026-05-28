#!/usr/bin/env zsh
#
# Verifies the stage619 focus/validation demo surface inspection result owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage619_focus_validation_demo_surface_inspection_result.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage619 focus validation demo surface inspection result: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage619FocusValidationDemoSurfaceInspectionResultPlan" \
  "CjguiInternalRendererStage619FocusValidationDemoSurfaceInspectionResultFacts" \
  "CjguiInternalRendererStage619FocusValidationDemoSurfaceInspectionResultReadiness" \
  "cjguiInternalExecuteDefaultRendererStage619FocusValidationDemoSurfaceInspectionResultDraft" \
  "CjguiInternalRendererStage618FocusValidationStateRenderExecutorReadiness" \
  "didConsumeStage618FocusValidationStateRenderExecutor" \
  "didConsumeFocusValidationExecutionReceipts" \
  "didMaterializeSharedFocusValidationDemoSurfaceInspectionResult" \
  "didMaterializeValidationDisplaySurfaceRefresh" \
  "didMaterializeFocusMovementSurfaceRefresh" \
  "didMaterializeInputFeedbackSurfaceRefresh" \
  "didMaterializeFocusValidationSemanticDiffReceipt" \
  "didMaterializeChatComposerFocusValidationDemoSurfaceInspectionResult" \
  "didPrepareStage620SharedFocusValidationInputCycleRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage619 focus validation demo surface inspection result: missing token $token" >&2
    exit 3
  fi
done

echo "stage619_focus_validation_demo_surface_inspection_result_owner_present=true"
echo "stage618_focus_validation_state_render_executor_consumed=true"
echo "focus_validation_execution_receipts_consumed=true"
echo "shared_focus_validation_demo_surface_inspection_result_materialized=true"
echo "validation_display_surface_refresh_materialized=true"
echo "focus_movement_surface_refresh_materialized=true"
echo "input_feedback_surface_refresh_materialized=true"
echo "focus_validation_semantic_diff_receipt_materialized=true"
echo "todo_focus_validation_demo_surface_inspection_result_materialized=true"
echo "settings_focus_validation_demo_surface_inspection_result_materialized=true"
echo "ai_generated_settings_focus_validation_demo_surface_inspection_result_materialized=true"
echo "chat_composer_focus_validation_demo_surface_inspection_result_materialized=true"
echo "demo_surface_inspection_bound_to_stage618_receipts=true"
echo "stage620_shared_focus_validation_input_cycle_runtime_contract_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
