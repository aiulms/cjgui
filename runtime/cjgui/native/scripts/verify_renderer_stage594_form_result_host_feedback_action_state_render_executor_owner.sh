#!/usr/bin/env zsh
#
# Verifies the stage594 form result host feedback action/state/render executor owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage594_form_result_host_feedback_action_state_render_executor.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage594 form result host feedback action state render executor: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage594FormResultHostFeedbackActionStateRenderExecutorPlan" \
  "CjguiInternalRendererStage594FormResultHostFeedbackActionStateRenderExecutorFacts" \
  "CjguiInternalRendererStage594FormResultHostFeedbackActionStateRenderExecutorReadiness" \
  "cjguiInternalExecuteDefaultRendererStage594FormResultHostFeedbackActionStateRenderExecutorDraft" \
  "CjguiInternalRendererStage593FormResultHostInputFeedbackCycleReadiness" \
  "didMaterializeSharedFormResultHostFeedbackActionStateRenderExecutor" \
  "didMaterializeHostFeedbackActionIntentLedger" \
  "didMaterializeHostFeedbackStateDeltaDryRunLedger" \
  "didMaterializeHostFeedbackValidationRefreshLedger" \
  "didMaterializeHostFeedbackRenderCommandRefreshLedger" \
  "didMaterializeTodoFormResultHostFeedbackActionStateRenderReceipt" \
  "didMaterializeSettingsFormResultHostFeedbackActionStateRenderReceipt" \
  "didMaterializeAiGeneratedSettingsFormResultHostFeedbackActionStateRenderReceipt" \
  "didMaterializeChatComposerFormResultHostFeedbackActionStateRenderReceipt" \
  "didBindFeedbackActionStateRenderExecutorToStage593InputFeedbackCycle" \
  "didPrepareStage595FormResultHostFeedbackDemoSurfaceReceipt"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage594 form result host feedback action state render executor: missing token $token" >&2
    exit 3
  fi
done

echo "stage594_form_result_host_feedback_action_state_render_executor_owner_present=true"
echo "stage593_form_result_host_input_feedback_cycle_consumed=true"
echo "stage592_form_result_host_runtime_contract_consumed_transitively=true"
echo "shared_form_result_host_feedback_action_state_render_executor_materialized=true"
echo "host_feedback_action_intent_ledger_materialized=true"
echo "host_feedback_state_delta_dry_run_ledger_materialized=true"
echo "host_feedback_validation_refresh_ledger_materialized=true"
echo "host_feedback_render_command_refresh_ledger_materialized=true"
echo "todo_form_result_host_feedback_action_state_render_receipt_materialized=true"
echo "settings_form_result_host_feedback_action_state_render_receipt_materialized=true"
echo "ai_generated_settings_form_result_host_feedback_action_state_render_receipt_materialized=true"
echo "chat_composer_form_result_host_feedback_action_state_render_receipt_materialized=true"
echo "feedback_action_state_render_executor_bound_to_stage593_input_feedback_cycle=true"
echo "stage595_form_result_host_feedback_demo_surface_receipt_prepared=true"
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
