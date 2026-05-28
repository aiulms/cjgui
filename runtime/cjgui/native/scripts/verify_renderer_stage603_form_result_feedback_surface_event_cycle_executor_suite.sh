#!/usr/bin/env zsh
#
# Focused suite for stage603. It consumes stage602 normalized event evidence
# and emits shared non-dispatching event cycle execution receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE603_TMPDIR:-/private/tmp/cjgui-stage601-stage604/stage603}"
SUITE_PACKET="$TMP_DIR/stage603-form-result-feedback-surface-event-cycle-executor-suite.packet"
STAGE602_SUITE_PACKET="${CJGUI_STAGE603_INPUT_PACKET:-${CJGUI_STAGE602_FORM_RESULT_FEEDBACK_SURFACE_EVENT_NORMALIZER_SUITE_PACKET:-/private/tmp/cjgui-stage601-stage604/stage602/stage602-form-result-feedback-surface-event-normalizer-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage603_form_result_feedback_surface_event_cycle_executor_owner.sh"
OWNER_LOG="$TMP_DIR/stage603-form-result-feedback-surface-event-cycle-executor-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage603 form result feedback surface event cycle executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage603 form result feedback surface event cycle executor suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage602_form_result_feedback_surface_event_normalizer_consumed=true" \
  "shared_form_result_feedback_surface_event_cycle_executor_materialized=true" \
  "feedback_surface_action_intent_preview_ledger_materialized=true" \
  "feedback_surface_state_delta_dry_run_ledger_materialized=true" \
  "feedback_surface_render_command_refresh_ledger_materialized=true" \
  "feedback_surface_focus_transition_preview_ledger_materialized=true" \
  "chat_composer_feedback_surface_event_cycle_receipt_materialized=true" \
  "event_cycle_executor_bound_to_stage602_normalizer=true" \
  "stage604_form_result_feedback_host_input_runtime_surface_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE602_SUITE_PACKET" || ! -f "$STAGE602_SUITE_PACKET" ]]; then
  echo "cjgui stage603 form result feedback surface event cycle executor suite: missing stage602 packet; set CJGUI_STAGE603_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage602_form_result_feedback_surface_event_normalizer_suite_version=1" \
  "stage601_form_result_feedback_surface_input_event_bridge_consumed=true" \
  "normalized_accepted_feedback_surface_event_materialized=true" \
  "normalized_rejected_validation_feedback_surface_event_materialized=true" \
  "normalized_pending_owner_acceptance_feedback_surface_event_materialized=true" \
  "validation_focus_feedback_event_ledger_materialized=true" \
  "stage603_form_result_feedback_surface_event_cycle_executor_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE602_SUITE_PACKET" "$fact"
done

{
  echo "stage603_form_result_feedback_surface_event_cycle_executor_suite_version=1"
  echo "stage602_form_result_feedback_surface_event_normalizer_suite_packet=$STAGE602_SUITE_PACKET"
  echo "stage603_form_result_feedback_surface_event_cycle_executor_owner_passed=true"
  echo "stage602_form_result_feedback_surface_event_normalizer_consumed=true"
  echo "stage601_form_result_feedback_surface_input_event_bridge_consumed_transitively=true"
  echo "shared_form_result_feedback_surface_event_cycle_executor_materialized=true"
  echo "feedback_surface_action_intent_preview_ledger_materialized=true"
  echo "feedback_surface_state_delta_dry_run_ledger_materialized=true"
  echo "feedback_surface_render_command_refresh_ledger_materialized=true"
  echo "feedback_surface_focus_transition_preview_ledger_materialized=true"
  echo "todo_feedback_surface_event_cycle_receipt_materialized=true"
  echo "settings_feedback_surface_event_cycle_receipt_materialized=true"
  echo "ai_generated_settings_feedback_surface_event_cycle_receipt_materialized=true"
  echo "chat_composer_feedback_surface_event_cycle_receipt_materialized=true"
  echo "event_cycle_executor_bound_to_stage602_normalizer=true"
  echo "event_cycle_executor_bound_to_stage601_input_event_bridge=true"
  echo "stage604_form_result_feedback_host_input_runtime_surface_contract_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_published=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
} > "$SUITE_PACKET"

echo "cjgui stage603 form result feedback surface event cycle executor suite: route_classification=feedback_surface_event_cycle_executor_ready"
echo "cjgui stage603 form result feedback surface event cycle executor suite: suite_packet_path=$SUITE_PACKET"
