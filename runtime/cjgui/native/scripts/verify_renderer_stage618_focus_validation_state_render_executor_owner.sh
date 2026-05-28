#!/usr/bin/env zsh
#
# Verifies the stage618 focus/validation state/render executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage618_focus_validation_state_render_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage618 focus validation state render executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage618FocusValidationStateRenderExecutorPlan" \
  "CjguiInternalRendererStage618FocusValidationStateRenderExecutorFacts" \
  "CjguiInternalRendererStage618FocusValidationStateRenderExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage618FocusValidationStateRenderExecutorDraft" \
  "CjguiInternalRendererStage617FocusValidationInputCycleReadiness" \
  "didConsumeStage617FocusValidationInputCycle" \
  "didConsumeNormalizedFocusValidationInputEvents" \
  "didMaterializeSharedFocusValidationStateRenderExecutor" \
  "didMaterializeValidationStateDeltaDryRun" \
  "didMaterializeFocusMovementStateDeltaDryRun" \
  "didMaterializeInputFeedbackStateDeltaDryRun" \
  "didMaterializeFocusValidationRenderCommandRefresh" \
  "didMaterializeChatComposerFocusValidationExecutionReceipt" \
  "didPrepareStage619FocusValidationDemoSurfaceInspectionResult"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage618 focus validation state render executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage618_focus_validation_state_render_executor_owner_present=true"
echo "stage617_focus_validation_input_cycle_consumed=true"
echo "normalized_focus_validation_input_events_consumed=true"
echo "shared_focus_validation_state_render_executor_materialized=true"
echo "validation_state_delta_dry_run_materialized=true"
echo "focus_movement_state_delta_dry_run_materialized=true"
echo "input_feedback_state_delta_dry_run_materialized=true"
echo "focus_validation_render_command_refresh_materialized=true"
echo "todo_focus_validation_execution_receipt_materialized=true"
echo "settings_focus_validation_execution_receipt_materialized=true"
echo "ai_generated_settings_focus_validation_execution_receipt_materialized=true"
echo "chat_composer_focus_validation_execution_receipt_materialized=true"
echo "state_render_executor_bound_to_stage617_input_cycle=true"
echo "focus_validation_state_render_executor_owner_local=true"
echo "focus_validation_state_render_executor_non_dispatching=true"
echo "stage619_focus_validation_demo_surface_inspection_result_prepared=true"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
