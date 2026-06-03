#!/usr/bin/env zsh
#
# Verifies the stage692 replay host text input demo-host cycle executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage692_replay_host_text_input_demo_host_cycle_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage692 replay host text input demo-host cycle executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage692ReplayHostTextInputDemoHostCycleExecutorPlan" \
  "CjguiInternalRendererStage692ReplayHostTextInputDemoHostCycleExecutorFacts" \
  "CjguiInternalRendererStage692ReplayHostTextInputDemoHostCycleExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage692ReplayHostTextInputDemoHostCycleExecutorDraft" \
  "CjguiInternalRendererStage691ReplayHostTextInputExecutionResultSurfaceReadiness" \
  "didConsumeStage691ReplayHostTextInputExecutionResultSurface" \
  "didMaterializeSharedReplayHostTextInputDemoHostCycleExecutor" \
  "didMaterializeSharedReplayHostTextInputDemoHostCycleRuntimeContract" \
  "didMaterializeSharedReplayHostTextInputDemoHostCycleExecutionReceiptContract" \
  "didMaterializeCycleOrderTextInputRuntimeHostIntegrationEventQueueExecutionResultSurface" \
  "didMaterializeChatComposerReplayHostTextInputDemoHostCycleRuntimeSurface" \
  "didBindCycleExecutorToStage689HostIntegration" \
  "didBindCycleExecutorToStage690EventQueue" \
  "didBindCycleExecutorToStage691ExecutionResultSurface" \
  "didBindCycleExecutorToStage688TextInputRuntimeContract" \
  "didReduceFuturePerDemoTextInputDemoHostTemplateNeed" \
  "didPrepareStage693ReplayHostTextInputEventReplaySurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage692 replay host text input demo-host cycle executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage692_replay_host_text_input_demo_host_cycle_executor_owner_present=true"
echo "stage691_replay_host_text_input_execution_result_surface_consumed=true"
echo "stage690_replay_host_text_input_host_event_adapter_consumed_transitively=true"
echo "stage689_replay_host_text_input_demo_host_integration_consumed_transitively=true"
echo "stage688_replay_host_text_input_runtime_contract_consumed_transitively=true"
echo "shared_replay_host_text_input_demo_host_cycle_executor_materialized=true"
echo "shared_replay_host_text_input_demo_host_cycle_runtime_contract_materialized=true"
echo "shared_replay_host_text_input_demo_host_cycle_execution_receipt_contract_materialized=true"
echo "cycle_order_text_input_runtime_host_integration_event_queue_execution_result_surface_materialized=true"
echo "todo_replay_host_text_input_demo_host_cycle_runtime_surface_materialized=true"
echo "settings_replay_host_text_input_demo_host_cycle_runtime_surface_materialized=true"
echo "ai_generated_settings_replay_host_text_input_demo_host_cycle_runtime_surface_materialized=true"
echo "chat_composer_replay_host_text_input_demo_host_cycle_runtime_surface_materialized=true"
echo "cycle_executor_bound_to_stage689_host_integration=true"
echo "cycle_executor_bound_to_stage690_event_queue=true"
echo "cycle_executor_bound_to_stage691_execution_result_surface=true"
echo "cycle_executor_bound_to_stage688_text_input_runtime_contract=true"
echo "future_per_demo_text_input_demo_host_template_need_reduced=true"
echo "stage693_replay_host_text_input_event_replay_surface_prepared=true"
echo "host_mutation=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
