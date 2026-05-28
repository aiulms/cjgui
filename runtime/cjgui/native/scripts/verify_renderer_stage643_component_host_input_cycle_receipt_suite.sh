#!/usr/bin/env zsh
#
# Focused suite for stage643. It consumes stage642 normalized host input events
# and verifies non-dispatching action/state/render/focus receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE643_TMPDIR:-/private/tmp/cjgui-stage641-stage644/stage643}"
SUITE_PACKET="$TMP_DIR/stage643-component-host-input-cycle-receipt-suite.packet"
STAGE642_SUITE_PACKET="${CJGUI_STAGE643_INPUT_PACKET:-${CJGUI_STAGE642_COMPONENT_HOST_INPUT_EVENT_QUEUE_SUITE_PACKET:-/private/tmp/cjgui-stage641-stage644/stage642/stage642-component-host-input-event-queue-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage643_component_host_input_cycle_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage643-component-host-input-cycle-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage643 component host input cycle receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage642_component_host_input_event_queue_consumed=true" \
  "shared_component_host_input_cycle_receipt_materialized=true" \
  "host_input_action_intent_preview_ledger_materialized=true" \
  "chat_composer_component_host_input_cycle_receipt_materialized=true" \
  "stage644_component_host_input_cycle_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE642_SUITE_PACKET" || ! -f "$STAGE642_SUITE_PACKET" ]]; then
  echo "cjgui stage643 component host input cycle receipt suite: missing stage642 packet; set CJGUI_STAGE643_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage642_component_host_input_event_queue_suite_version=1" \
  "shared_component_host_input_event_queue_materialized=true" \
  "chat_composer_component_host_input_event_queue_materialized=true" \
  "stage643_component_host_input_cycle_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE642_SUITE_PACKET" "$fact"
done

{
  echo "stage643_component_host_input_cycle_receipt_suite_version=1"
  echo "stage642_component_host_input_event_queue_suite_packet=$STAGE642_SUITE_PACKET"
  echo "stage643_component_host_input_cycle_receipt_owner_passed=true"
  echo "stage642_component_host_input_event_queue_consumed=true"
  echo "stage641_result_surface_host_input_adapter_consumed_transitively=true"
  echo "stage640_result_surface_host_runtime_contract_consumed_transitively=true"
  echo "shared_component_host_input_cycle_receipt_materialized=true"
  echo "host_input_action_intent_preview_ledger_materialized=true"
  echo "host_input_state_delta_dry_run_ledger_materialized=true"
  echo "host_input_render_command_refresh_ledger_materialized=true"
  echo "host_input_focus_movement_receipt_materialized=true"
  echo "host_input_validation_refresh_receipt_materialized=true"
  echo "host_input_feedback_clear_receipt_materialized=true"
  echo "host_input_semantic_refresh_receipt_materialized=true"
  echo "todo_component_host_input_cycle_receipt_materialized=true"
  echo "settings_component_host_input_cycle_receipt_materialized=true"
  echo "ai_generated_settings_component_host_input_cycle_receipt_materialized=true"
  echo "chat_composer_component_host_input_cycle_receipt_materialized=true"
  echo "component_host_input_cycle_receipt_bound_to_stage642_queue=true"
  echo "component_host_input_cycle_receipt_non_dispatching=true"
  echo "stage644_component_host_input_cycle_executor_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "next_route=stage644_component_host_input_cycle_executor_after_stage643"
  echo "stage643_component_host_input_cycle_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage643 component host input cycle receipt suite: route_classification=component_host_input_cycle_receipt_ready"
echo "cjgui stage643 component host input cycle receipt suite: suite_packet_path=$SUITE_PACKET"
