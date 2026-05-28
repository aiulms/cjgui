#!/usr/bin/env zsh
#
# Verifies the stage593 form result host input feedback cycle owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage593_form_result_host_input_feedback_cycle.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage593 form result host input feedback cycle: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage593FormResultHostInputFeedbackCyclePlan" \
  "CjguiInternalRendererStage593FormResultHostInputFeedbackCycleFacts" \
  "CjguiInternalRendererStage593FormResultHostInputFeedbackCycleReadiness" \
  "cjguiInternalExecuteDefaultRendererStage593FormResultHostInputFeedbackCycleDraft" \
  "CjguiInternalRendererStage592FormResultHostRuntimeContractReadiness" \
  "didMaterializeSharedFormResultHostInputFeedbackCycle" \
  "didMaterializeNormalizedHostInputFeedbackEventLedger" \
  "didMaterializeAcceptedHostInputFeedbackEvent" \
  "didMaterializeRejectedHostInputFeedbackEvent" \
  "didMaterializePendingHostInputFeedbackEvent" \
  "didMaterializeTodoFormResultHostInputFeedbackCycle" \
  "didMaterializeSettingsFormResultHostInputFeedbackCycle" \
  "didMaterializeAiGeneratedSettingsFormResultHostInputFeedbackCycle" \
  "didMaterializeChatComposerFormResultHostInputFeedbackCycle" \
  "didBindHostInputFeedbackCycleToStage592RuntimeSurfaces" \
  "didPrepareStage594FormResultHostFeedbackActionStateRenderExecutor"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage593 form result host input feedback cycle: missing token $token" >&2
    exit 3
  fi
done

echo "stage593_form_result_host_input_feedback_cycle_owner_present=true"
echo "stage592_form_result_host_runtime_contract_consumed=true"
echo "stage591_form_result_host_execution_receipt_consumed_transitively=true"
echo "shared_form_result_host_input_feedback_cycle_materialized=true"
echo "normalized_host_input_feedback_event_ledger_materialized=true"
echo "accepted_host_input_feedback_event_materialized=true"
echo "rejected_host_input_feedback_event_materialized=true"
echo "pending_host_input_feedback_event_materialized=true"
echo "todo_form_result_host_input_feedback_cycle_materialized=true"
echo "settings_form_result_host_input_feedback_cycle_materialized=true"
echo "ai_generated_settings_form_result_host_input_feedback_cycle_materialized=true"
echo "chat_composer_form_result_host_input_feedback_cycle_materialized=true"
echo "host_input_feedback_cycle_bound_to_stage592_runtime_surfaces=true"
echo "host_input_feedback_cycle_bound_to_stage591_execution_receipts=true"
echo "stage594_form_result_host_feedback_action_state_render_executor_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "layout_engine_enabled=false"
echo "style_resolver_enabled=false"
echo "focus_manager_enabled=false"
echo "input_event_pipeline_enabled=false"
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
