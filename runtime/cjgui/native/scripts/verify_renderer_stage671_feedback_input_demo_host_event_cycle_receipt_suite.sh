#!/usr/bin/env zsh
#
# Focused suite for stage671. It consumes stage670 queued events and verifies
# the shared feedback input demo-host event cycle receipt.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE671_TMPDIR:-/private/tmp/cjgui-stage669-stage672/stage671}"
SUITE_PACKET="$TMP_DIR/stage671-feedback-input-demo-host-event-cycle-receipt-suite.packet"
STAGE670_SUITE_PACKET="${CJGUI_STAGE671_INPUT_PACKET:-${CJGUI_STAGE670_FEEDBACK_INPUT_DEMO_HOST_EVENT_QUEUE_SUITE_PACKET:-/private/tmp/cjgui-stage669-stage672/stage670/stage670-feedback-input-demo-host-event-queue-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage671_feedback_input_demo_host_event_cycle_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage671-feedback-input-demo-host-event-cycle-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage671 feedback input demo-host event cycle receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage670_feedback_input_demo_host_event_queue_consumed=true" \
  "shared_feedback_input_demo_host_event_cycle_receipt_materialized=true" \
  "event_action_intent_preview_materialized=true" \
  "event_state_delta_dry_run_materialized=true" \
  "event_render_command_refresh_preview_materialized=true" \
  "event_focus_transition_preview_materialized=true" \
  "event_result_surface_refresh_receipt_materialized=true" \
  "chat_composer_feedback_input_demo_host_event_cycle_receipt_materialized=true" \
  "stage672_feedback_input_demo_host_event_cycle_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE670_SUITE_PACKET" || ! -f "$STAGE670_SUITE_PACKET" ]]; then
  echo "cjgui stage671 feedback input demo-host event cycle receipt suite: missing stage670 packet; set CJGUI_STAGE671_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage670_feedback_input_demo_host_event_queue_suite_version=1" \
  "shared_feedback_input_demo_host_event_queue_materialized=true" \
  "chat_composer_feedback_input_demo_host_queued_event_materialized=true" \
  "stage671_feedback_input_demo_host_event_cycle_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE670_SUITE_PACKET" "$fact"
done

{
  echo "stage671_feedback_input_demo_host_event_cycle_receipt_suite_version=1"
  echo "stage670_feedback_input_demo_host_event_queue_suite_packet=$STAGE670_SUITE_PACKET"
  echo "stage671_feedback_input_demo_host_event_cycle_receipt_owner_passed=true"
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
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
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
  echo "next_route=stage672_feedback_input_demo_host_event_cycle_runtime_contract_after_stage671"
  echo "stage671_feedback_input_demo_host_event_cycle_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage671 feedback input demo-host event cycle receipt suite: route_classification=feedback_input_demo_host_event_cycle_receipt_ready"
echo "cjgui stage671 feedback input demo-host event cycle receipt suite: suite_packet_path=$SUITE_PACKET"
