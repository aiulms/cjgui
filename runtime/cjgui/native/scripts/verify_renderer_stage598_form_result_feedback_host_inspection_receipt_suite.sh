#!/usr/bin/env zsh
#
# Focused suite for stage598. It consumes stage597 validation/focus surfaces
# and emits a host inspection receipt packet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE598_TMPDIR:-/private/tmp/cjgui-stage597-stage600/stage598}"
SUITE_PACKET="$TMP_DIR/stage598-form-result-feedback-host-inspection-receipt-suite.packet"
STAGE597_SUITE_PACKET="${CJGUI_STAGE598_INPUT_PACKET:-${CJGUI_STAGE597_FORM_RESULT_FEEDBACK_VALIDATION_FOCUS_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage597-stage600/stage597/stage597-form-result-feedback-validation-focus-surface-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage598_form_result_feedback_host_inspection_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage598-form-result-feedback-host-inspection-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage598 form result feedback host inspection receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage598 form result feedback host inspection receipt suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage597_form_result_feedback_validation_focus_surface_consumed=true" \
  "shared_form_result_feedback_host_inspection_receipt_materialized=true" \
  "validation_display_host_slot_receipt_materialized=true" \
  "focus_movement_host_slot_receipt_materialized=true" \
  "input_feedback_host_slot_receipt_materialized=true" \
  "render_refresh_host_slot_receipt_materialized=true" \
  "chat_composer_form_result_feedback_host_inspection_receipt_materialized=true" \
  "host_inspection_receipt_bound_to_stage597_validation_focus_surface=true" \
  "host_inspection_receipt_bound_to_stage596_runtime_contract=true" \
  "stage599_form_result_feedback_surface_reducer_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE597_SUITE_PACKET" || ! -f "$STAGE597_SUITE_PACKET" ]]; then
  echo "cjgui stage598 form result feedback host inspection receipt suite: missing stage597 packet; set CJGUI_STAGE598_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage597_form_result_feedback_validation_focus_surface_suite_version=1" \
  "stage596_form_result_host_feedback_cycle_runtime_contract_consumed=true" \
  "shared_form_result_feedback_validation_focus_surface_materialized=true" \
  "form_result_feedback_validation_display_surface_materialized=true" \
  "form_result_feedback_focus_movement_surface_materialized=true" \
  "form_result_feedback_input_display_surface_materialized=true" \
  "chat_composer_form_result_feedback_validation_focus_surface_materialized=true" \
  "stage598_form_result_feedback_host_inspection_receipt_prepared=true" \
  "focus_manager_enabled=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE597_SUITE_PACKET" "$fact"
done

{
  echo "stage598_form_result_feedback_host_inspection_receipt_suite_version=1"
  echo "stage597_form_result_feedback_validation_focus_surface_suite_packet=$STAGE597_SUITE_PACKET"
  echo "stage598_form_result_feedback_host_inspection_receipt_owner_passed=true"
  echo "stage597_form_result_feedback_validation_focus_surface_consumed=true"
  echo "stage596_form_result_host_feedback_cycle_runtime_contract_consumed_transitively=true"
  echo "shared_form_result_feedback_host_inspection_receipt_materialized=true"
  echo "validation_display_host_slot_receipt_materialized=true"
  echo "focus_movement_host_slot_receipt_materialized=true"
  echo "input_feedback_host_slot_receipt_materialized=true"
  echo "render_refresh_host_slot_receipt_materialized=true"
  echo "todo_form_result_feedback_host_inspection_receipt_materialized=true"
  echo "settings_form_result_feedback_host_inspection_receipt_materialized=true"
  echo "ai_generated_settings_form_result_feedback_host_inspection_receipt_materialized=true"
  echo "chat_composer_form_result_feedback_host_inspection_receipt_materialized=true"
  echo "host_inspection_receipt_bound_to_stage597_validation_focus_surface=true"
  echo "host_inspection_receipt_bound_to_stage596_runtime_contract=true"
  echo "stage599_form_result_feedback_surface_reducer_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_published=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
} > "$SUITE_PACKET"

echo "cjgui stage598 form result feedback host inspection receipt suite: route_classification=form_result_feedback_host_inspection_receipt_ready"
echo "cjgui stage598 form result feedback host inspection receipt suite: suite_packet_path=$SUITE_PACKET"
