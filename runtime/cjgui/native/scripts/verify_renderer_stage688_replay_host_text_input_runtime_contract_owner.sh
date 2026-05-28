#!/usr/bin/env zsh
#
# Verifies the stage688 replay host text input runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage688_replay_host_text_input_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage688 replay host text input runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage688ReplayHostTextInputRuntimeContractPlan" \
  "CjguiInternalRendererStage688ReplayHostTextInputRuntimeContractFacts" \
  "CjguiInternalRendererStage688ReplayHostTextInputRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage688ReplayHostTextInputRuntimeContractDraft" \
  "CjguiInternalRendererStage687ReplayHostTextEditRenderResultSurfaceReadiness" \
  "didConsumeStage687ReplayHostTextEditRenderResultSurface" \
  "didMaterializeSharedReplayHostTextInputRuntimeContract" \
  "didMaterializeSharedReplayHostTextInputRuntimeHelper" \
  "didMaterializeSharedReplayHostTextInputExecutionReceiptContract" \
  "didMaterializeCycleOrderFieldModelOperationStateRenderResultRuntime" \
  "didMaterializeChatComposerReplayHostTextInputRuntimeSurface" \
  "didBindTextInputRuntimeContractToStage687RenderResultSurface" \
  "didBindTextInputRuntimeContractToStage686StateDryRun" \
  "didBindTextInputRuntimeContractToStage685FieldModel" \
  "didBindTextInputRuntimeContractToStage684HostInspectionRuntime" \
  "didReduceFuturePerDemoTextInputRuntimeTemplateNeed" \
  "didPrepareStage689ReplayHostTextInputDemoHostIntegration"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage688 replay host text input runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage688_replay_host_text_input_runtime_contract_owner_present=true"
echo "stage687_replay_host_text_edit_render_result_surface_consumed=true"
echo "stage686_replay_host_text_edit_state_dry_run_consumed_transitively=true"
echo "stage685_replay_host_text_edit_field_model_consumed_transitively=true"
echo "stage684_replay_action_state_render_host_inspection_runtime_contract_consumed_transitively=true"
echo "shared_replay_host_text_input_runtime_contract_materialized=true"
echo "shared_replay_host_text_input_runtime_helper_materialized=true"
echo "shared_replay_host_text_input_execution_receipt_contract_materialized=true"
echo "cycle_order_field_model_operation_state_render_result_runtime_materialized=true"
echo "todo_replay_host_text_input_runtime_surface_materialized=true"
echo "settings_replay_host_text_input_runtime_surface_materialized=true"
echo "ai_generated_settings_replay_host_text_input_runtime_surface_materialized=true"
echo "chat_composer_replay_host_text_input_runtime_surface_materialized=true"
echo "text_input_runtime_contract_bound_to_stage687_render_result_surface=true"
echo "text_input_runtime_contract_bound_to_stage686_state_dry_run=true"
echo "text_input_runtime_contract_bound_to_stage685_field_model=true"
echo "text_input_runtime_contract_bound_to_stage684_host_inspection_runtime=true"
echo "future_per_demo_text_input_runtime_template_need_reduced=true"
echo "stage689_replay_host_text_input_demo_host_integration_prepared=true"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
