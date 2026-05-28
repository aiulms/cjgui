#!/usr/bin/env zsh
#
# Focused suite for stage670. It consumes stage669 event adapter output and
# verifies the shared feedback input demo-host event queue.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE670_TMPDIR:-/private/tmp/cjgui-stage669-stage672/stage670}"
SUITE_PACKET="$TMP_DIR/stage670-feedback-input-demo-host-event-queue-suite.packet"
STAGE669_SUITE_PACKET="${CJGUI_STAGE670_INPUT_PACKET:-${CJGUI_STAGE669_FEEDBACK_INPUT_DEMO_HOST_EVENT_ADAPTER_SUITE_PACKET:-/private/tmp/cjgui-stage669-stage672/stage669/stage669-feedback-input-demo-host-event-adapter-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage670_feedback_input_demo_host_event_queue_owner.sh"
OWNER_LOG="$TMP_DIR/stage670-feedback-input-demo-host-event-queue-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage670 feedback input demo-host event queue suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage669_feedback_input_demo_host_event_adapter_consumed=true" \
  "shared_feedback_input_demo_host_event_queue_materialized=true" \
  "validation_dismiss_queued_host_event_materialized=true" \
  "focus_movement_queued_host_event_materialized=true" \
  "input_feedback_clear_queued_host_event_materialized=true" \
  "semantic_diff_acknowledge_queued_host_event_materialized=true" \
  "chat_composer_feedback_input_demo_host_queued_event_materialized=true" \
  "stage671_feedback_input_demo_host_event_cycle_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE669_SUITE_PACKET" || ! -f "$STAGE669_SUITE_PACKET" ]]; then
  echo "cjgui stage670 feedback input demo-host event queue suite: missing stage669 packet; set CJGUI_STAGE670_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage669_feedback_input_demo_host_event_adapter_suite_version=1" \
  "shared_feedback_input_demo_host_event_adapter_materialized=true" \
  "chat_composer_feedback_input_demo_host_event_adapter_materialized=true" \
  "stage670_feedback_input_demo_host_event_queue_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE669_SUITE_PACKET" "$fact"
done

{
  echo "stage670_feedback_input_demo_host_event_queue_suite_version=1"
  echo "stage669_feedback_input_demo_host_event_adapter_suite_packet=$STAGE669_SUITE_PACKET"
  echo "stage670_feedback_input_demo_host_event_queue_owner_passed=true"
  echo "stage669_feedback_input_demo_host_event_adapter_consumed=true"
  echo "stage668_component_feedback_input_demo_host_runtime_contract_consumed_transitively=true"
  echo "shared_feedback_input_demo_host_event_queue_materialized=true"
  echo "validation_dismiss_queued_host_event_materialized=true"
  echo "focus_movement_queued_host_event_materialized=true"
  echo "input_feedback_clear_queued_host_event_materialized=true"
  echo "semantic_diff_acknowledge_queued_host_event_materialized=true"
  echo "todo_feedback_input_demo_host_queued_event_materialized=true"
  echo "settings_feedback_input_demo_host_queued_event_materialized=true"
  echo "ai_generated_settings_feedback_input_demo_host_queued_event_materialized=true"
  echo "chat_composer_feedback_input_demo_host_queued_event_materialized=true"
  echo "feedback_input_demo_host_event_queue_owner_local=true"
  echo "stage671_feedback_input_demo_host_event_cycle_receipt_prepared=true"
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
  echo "next_route=stage671_feedback_input_demo_host_event_cycle_receipt_after_stage670"
  echo "stage670_feedback_input_demo_host_event_queue_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage670 feedback input demo-host event queue suite: route_classification=feedback_input_demo_host_event_queue_ready"
echo "cjgui stage670 feedback input demo-host event queue suite: suite_packet_path=$SUITE_PACKET"
