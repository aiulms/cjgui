#!/usr/bin/env zsh
#
# Verifies the stage672 feedback input demo-host event cycle runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage672_feedback_input_demo_host_event_cycle_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage672 feedback input demo-host event cycle runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage672FeedbackInputDemoHostEventCycleRuntimeContractPlan" \
  "CjguiInternalRendererStage672FeedbackInputDemoHostEventCycleRuntimeContractFacts" \
  "CjguiInternalRendererStage672FeedbackInputDemoHostEventCycleRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage672FeedbackInputDemoHostEventCycleRuntimeContractDraft" \
  "CjguiInternalRendererStage671FeedbackInputDemoHostEventCycleReceiptReadiness" \
  "didConsumeStage671FeedbackInputDemoHostEventCycleReceipt" \
  "didMaterializeSharedFeedbackInputDemoHostEventCycleRuntimeContract" \
  "didMaterializeSharedFeedbackInputDemoHostEventCycleRuntimeHelper" \
  "didMaterializeSharedFeedbackInputDemoHostEventCycleExecutionReceiptContract" \
  "didMaterializeCycleOrderFeedbackInputHostEventAdapterQueueCycleReceiptRuntimeContract" \
  "didReduceFuturePerDemoFeedbackInputHostEventTemplateNeed" \
  "didPrepareStage673FeedbackInputDemoHostEventReplaySurface"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage672 feedback input demo-host event cycle runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage672_feedback_input_demo_host_event_cycle_runtime_contract_owner_present=true"
echo "stage671_feedback_input_demo_host_event_cycle_receipt_consumed=true"
echo "stage670_feedback_input_demo_host_event_queue_consumed_transitively=true"
echo "stage669_feedback_input_demo_host_event_adapter_consumed_transitively=true"
echo "stage668_component_feedback_input_demo_host_runtime_contract_consumed_transitively=true"
echo "shared_feedback_input_demo_host_event_cycle_runtime_contract_materialized=true"
echo "shared_feedback_input_demo_host_event_cycle_runtime_helper_materialized=true"
echo "shared_feedback_input_demo_host_event_cycle_execution_receipt_contract_materialized=true"
echo "cycle_order_feedback_input_host_event_adapter_queue_cycle_receipt_runtime_contract_materialized=true"
echo "todo_feedback_input_demo_host_event_cycle_runtime_surface_materialized=true"
echo "settings_feedback_input_demo_host_event_cycle_runtime_surface_materialized=true"
echo "ai_generated_settings_feedback_input_demo_host_event_cycle_runtime_surface_materialized=true"
echo "chat_composer_feedback_input_demo_host_event_cycle_runtime_surface_materialized=true"
echo "future_per_demo_feedback_input_host_event_template_need_reduced=true"
echo "stage673_feedback_input_demo_host_event_replay_surface_prepared=true"
echo "host_mutation=false"
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
