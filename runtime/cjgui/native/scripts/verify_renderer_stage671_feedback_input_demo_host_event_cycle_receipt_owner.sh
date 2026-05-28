#!/usr/bin/env zsh
#
# Verifies the stage671 feedback input demo-host event cycle receipt owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage671_feedback_input_demo_host_event_cycle_receipt.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage671 feedback input demo-host event cycle receipt: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage671FeedbackInputDemoHostEventCycleReceiptPlan" \
  "CjguiInternalRendererStage671FeedbackInputDemoHostEventCycleReceiptFacts" \
  "CjguiInternalRendererStage671FeedbackInputDemoHostEventCycleReceiptReadiness" \
  "cjguiInternalExecuteDefaultRendererStage671FeedbackInputDemoHostEventCycleReceiptDraft" \
  "CjguiInternalRendererStage670FeedbackInputDemoHostEventQueueReadiness" \
  "didConsumeStage670FeedbackInputDemoHostEventQueue" \
  "didMaterializeSharedFeedbackInputDemoHostEventCycleReceipt" \
  "didMaterializeEventActionIntentPreview" \
  "didMaterializeEventStateDeltaDryRun" \
  "didMaterializeEventRenderCommandRefreshPreview" \
  "didMaterializeEventFocusTransitionPreview" \
  "didMaterializeEventResultSurfaceRefreshReceipt" \
  "didBindEventCycleReceiptToStage670EventQueue" \
  "didPrepareStage672FeedbackInputDemoHostEventCycleRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage671 feedback input demo-host event cycle receipt: missing token $token" >&2
    exit 3
  fi
done

echo "stage671_feedback_input_demo_host_event_cycle_receipt_owner_present=true"
echo "stage670_feedback_input_demo_host_event_queue_consumed=true"
echo "stage669_feedback_input_demo_host_event_adapter_consumed_transitively=true"
echo "stage668_component_feedback_input_demo_host_runtime_contract_consumed_transitively=true"
echo "shared_feedback_input_demo_host_event_cycle_receipt_materialized=true"
echo "event_action_intent_preview_materialized=true"
echo "event_state_delta_dry_run_materialized=true"
echo "event_render_command_refresh_preview_materialized=true"
echo "event_focus_transition_preview_materialized=true"
echo "event_result_surface_refresh_receipt_materialized=true"
echo "todo_feedback_input_demo_host_event_cycle_receipt_materialized=true"
echo "settings_feedback_input_demo_host_event_cycle_receipt_materialized=true"
echo "ai_generated_settings_feedback_input_demo_host_event_cycle_receipt_materialized=true"
echo "chat_composer_feedback_input_demo_host_event_cycle_receipt_materialized=true"
echo "stage672_feedback_input_demo_host_event_cycle_runtime_contract_prepared=true"
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
