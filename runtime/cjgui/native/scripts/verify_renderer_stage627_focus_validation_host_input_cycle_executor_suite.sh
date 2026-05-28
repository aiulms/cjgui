#!/usr/bin/env zsh
#
# Focused suite for stage627. It consumes stage626 normalized host input
# events and verifies non-dispatching cycle receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE627_TMPDIR:-/private/tmp/cjgui-stage625-stage628/stage627}"
SUITE_PACKET="$TMP_DIR/stage627-focus-validation-host-input-cycle-executor-suite.packet"
STAGE626_SUITE_PACKET="${CJGUI_STAGE627_INPUT_PACKET:-${CJGUI_STAGE626_FOCUS_VALIDATION_HOST_INPUT_EVENT_NORMALIZER_SUITE_PACKET:-/private/tmp/cjgui-stage625-stage628/stage626/stage626-focus-validation-host-input-event-normalizer-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage627_focus_validation_host_input_cycle_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage627-focus-validation-host-input-cycle-executor-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage627 focus validation host input cycle executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

if [[ -z "$STAGE626_SUITE_PACKET" || ! -f "$STAGE626_SUITE_PACKET" ]]; then
  echo "cjgui stage627 focus validation host input cycle executor suite: missing stage626 packet; set CJGUI_STAGE627_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage626_focus_validation_host_input_event_normalizer_suite_version=1" \
  "shared_focus_validation_host_input_event_normalizer_materialized=true" \
  "host_input_event_ledger_materialized=true" \
  "stage627_component_runtime_focus_validation_host_input_cycle_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE626_SUITE_PACKET" "$fact"
done

for fact in \
  "stage626_focus_validation_host_input_event_normalizer_consumed=true" \
  "shared_focus_validation_host_input_cycle_executor_materialized=true" \
  "host_input_render_command_refresh_ledger_materialized=true" \
  "chat_composer_host_input_cycle_receipt_materialized=true" \
  "stage628_shared_focus_validation_host_input_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage627_focus_validation_host_input_cycle_executor_suite_version=1"
  echo "stage626_focus_validation_host_input_event_normalizer_suite_packet=$STAGE626_SUITE_PACKET"
  echo "stage627_focus_validation_host_input_cycle_executor_owner_passed=true"
  echo "stage626_focus_validation_host_input_event_normalizer_consumed=true"
  echo "stage625_focus_validation_host_input_adapter_consumed_transitively=true"
  echo "stage624_shared_focus_validation_demo_host_runtime_contract_consumed_transitively=true"
  echo "shared_focus_validation_host_input_cycle_executor_materialized=true"
  echo "host_input_action_intent_preview_ledger_materialized=true"
  echo "host_input_state_delta_dry_run_ledger_materialized=true"
  echo "host_input_render_command_refresh_ledger_materialized=true"
  echo "host_input_focus_transition_receipt_materialized=true"
  echo "host_input_validation_display_receipt_materialized=true"
  echo "host_input_feedback_display_receipt_materialized=true"
  echo "todo_host_input_cycle_receipt_materialized=true"
  echo "settings_host_input_cycle_receipt_materialized=true"
  echo "ai_generated_settings_host_input_cycle_receipt_materialized=true"
  echo "chat_composer_host_input_cycle_receipt_materialized=true"
  echo "host_input_cycle_executor_bound_to_stage626_normalizer=true"
  echo "host_input_cycle_executor_bound_to_stage625_adapter=true"
  echo "stage628_shared_focus_validation_host_input_runtime_contract_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage627_focus_validation_host_input_cycle_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage627 focus validation host input cycle executor suite: route_classification=focus_validation_host_input_cycle_executor_ready"
echo "cjgui stage627 focus validation host input cycle executor suite: suite_packet_path=$SUITE_PACKET"
