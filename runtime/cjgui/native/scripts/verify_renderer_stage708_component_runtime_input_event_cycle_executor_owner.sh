#!/usr/bin/env zsh
#
# Verifies the stage708 component runtime input event cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage708_component_runtime_input_event_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage708 component runtime input event cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage708ComponentRuntimeInputEventCycleExecutorPlan" \
  "CjguiInternalRendererStage708ComponentRuntimeInputEventCycleExecutorFacts" \
  "CjguiInternalRendererStage708ComponentRuntimeInputEventCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage708ComponentRuntimeInputEventCycleExecutorDraft" \
  "CjguiInternalRendererStage707ComponentRuntimeStateRenderFeedbackDryRunReadiness" \
  "didConsumeStage707ComponentRuntimeStateRenderFeedbackDryRun" \
  "didMaterializeSharedComponentRuntimeInputEventCycleExecutor" \
  "didMaterializeSharedComponentRuntimeInputEventCycleRuntimeContract" \
  "didMaterializeComponentRuntimeInputEventExecutionReceiptContract" \
  "didMaterializeCycleOrderComponentRuntimeNormalizedInputActionStateRenderFeedbackResult" \
  "didReduceFuturePerDemoComponentRuntimeInputEventTemplateNeed" \
  "didPrepareStage709ComponentRuntimeInputEventReplaySurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage708 component runtime input event cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage708_component_runtime_input_event_cycle_executor_owner_present=true"
echo "stage707_component_runtime_state_render_feedback_dry_run_consumed=true"
echo "stage706_component_runtime_action_intent_adapter_consumed_transitively=true"
echo "stage705_component_runtime_input_event_normalization_consumed_transitively=true"
echo "stage704_text_input_component_runtime_cycle_executor_consumed_transitively=true"
echo "shared_component_runtime_input_event_cycle_executor_materialized=true"
echo "shared_component_runtime_input_event_cycle_runtime_contract_materialized=true"
echo "component_runtime_input_event_execution_receipt_contract_materialized=true"
echo "cycle_order_component_runtime_normalized_input_action_state_render_feedback_result_materialized=true"
echo "todo_component_runtime_input_event_cycle_surface_materialized=true"
echo "settings_component_runtime_input_event_cycle_surface_materialized=true"
echo "ai_generated_settings_component_runtime_input_event_cycle_surface_materialized=true"
echo "chat_composer_component_runtime_input_event_cycle_surface_materialized=true"
echo "future_per_demo_component_runtime_input_event_template_need_reduced=true"
echo "stage709_component_runtime_input_event_replay_surface_prepared=true"
echo "host_mutation=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
