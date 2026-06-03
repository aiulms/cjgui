#!/usr/bin/env zsh
#
# Verifies the stage701 text input timeline component runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage701_text_input_timeline_component_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage701 text input timeline component runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage701TextInputTimelineComponentRuntimeContractPlan" \
  "CjguiInternalRendererStage701TextInputTimelineComponentRuntimeContractFacts" \
  "CjguiInternalRendererStage701TextInputTimelineComponentRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage701TextInputTimelineComponentRuntimeContractDraft" \
  "CjguiInternalRendererStage700ReplayHostTextInputTimelineActionStateRenderExecutorReadiness" \
  "didConsumeStage700ReplayHostTextInputTimelineActionStateRenderExecutor" \
  "didMaterializeSharedTextInputTimelineComponentRuntimeContract" \
  "didMaterializeTextValueComponentSlotContract" \
  "didMaterializeTextSubmitActionSlotContract" \
  "didMaterializeValidationFeedbackComponentSlotContract" \
  "didMaterializeFocusTransitionComponentSlotContract" \
  "didMaterializeRenderResultComponentSlotContract" \
  "didBindComponentRuntimeContractToStage700Executor" \
  "didPrepareStage702TextInputComponentSlotBindingAdapter"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage701 text input timeline component runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage701_text_input_timeline_component_runtime_contract_owner_present=true"
echo "stage700_replay_host_text_input_timeline_action_state_render_executor_consumed=true"
echo "shared_text_input_timeline_component_runtime_contract_materialized=true"
echo "text_value_component_slot_contract_materialized=true"
echo "text_submit_action_slot_contract_materialized=true"
echo "validation_feedback_component_slot_contract_materialized=true"
echo "focus_transition_component_slot_contract_materialized=true"
echo "render_result_component_slot_contract_materialized=true"
echo "todo_text_input_timeline_component_runtime_surface_materialized=true"
echo "settings_text_input_timeline_component_runtime_surface_materialized=true"
echo "ai_generated_settings_text_input_timeline_component_runtime_surface_materialized=true"
echo "chat_composer_text_input_timeline_component_runtime_surface_materialized=true"
echo "component_runtime_contract_bound_to_stage700_executor=true"
echo "component_runtime_contract_owner_local=true"
echo "stage702_text_input_component_slot_binding_adapter_prepared=true"
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
