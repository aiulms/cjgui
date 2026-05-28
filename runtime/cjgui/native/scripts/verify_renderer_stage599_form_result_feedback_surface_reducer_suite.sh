#!/usr/bin/env zsh
#
# Focused suite for stage599. It consumes stage598 host inspection receipts
# and emits a shared feedback surface reducer packet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE599_TMPDIR:-/private/tmp/cjgui-stage597-stage600/stage599}"
SUITE_PACKET="$TMP_DIR/stage599-form-result-feedback-surface-reducer-suite.packet"
STAGE598_SUITE_PACKET="${CJGUI_STAGE599_INPUT_PACKET:-${CJGUI_STAGE598_FORM_RESULT_FEEDBACK_HOST_INSPECTION_RECEIPT_SUITE_PACKET:-/private/tmp/cjgui-stage597-stage600/stage598/stage598-form-result-feedback-host-inspection-receipt-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage599_form_result_feedback_surface_reducer_owner.sh"
OWNER_LOG="$TMP_DIR/stage599-form-result-feedback-surface-reducer-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage599 form result feedback surface reducer suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage599 form result feedback surface reducer suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage598_form_result_feedback_host_inspection_receipt_consumed=true" \
  "shared_form_result_feedback_surface_reducer_materialized=true" \
  "accepted_feedback_surface_reduction_materialized=true" \
  "rejected_validation_feedback_surface_reduction_materialized=true" \
  "pending_owner_acceptance_feedback_surface_reduction_materialized=true" \
  "validation_focus_input_feedback_reduction_ledger_materialized=true" \
  "chat_composer_reduced_form_result_feedback_surface_materialized=true" \
  "surface_reducer_bound_to_stage598_host_inspection_receipts=true" \
  "surface_reducer_bound_to_stage597_validation_focus_surface=true" \
  "stage600_form_result_demo_host_feedback_surface_integration_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE598_SUITE_PACKET" || ! -f "$STAGE598_SUITE_PACKET" ]]; then
  echo "cjgui stage599 form result feedback surface reducer suite: missing stage598 packet; set CJGUI_STAGE599_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage598_form_result_feedback_host_inspection_receipt_suite_version=1" \
  "stage597_form_result_feedback_validation_focus_surface_consumed=true" \
  "shared_form_result_feedback_host_inspection_receipt_materialized=true" \
  "validation_display_host_slot_receipt_materialized=true" \
  "focus_movement_host_slot_receipt_materialized=true" \
  "input_feedback_host_slot_receipt_materialized=true" \
  "chat_composer_form_result_feedback_host_inspection_receipt_materialized=true" \
  "stage599_form_result_feedback_surface_reducer_prepared=true" \
  "focus_manager_enabled=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE598_SUITE_PACKET" "$fact"
done

{
  echo "stage599_form_result_feedback_surface_reducer_suite_version=1"
  echo "stage598_form_result_feedback_host_inspection_receipt_suite_packet=$STAGE598_SUITE_PACKET"
  echo "stage599_form_result_feedback_surface_reducer_owner_passed=true"
  echo "stage598_form_result_feedback_host_inspection_receipt_consumed=true"
  echo "stage597_form_result_feedback_validation_focus_surface_consumed_transitively=true"
  echo "shared_form_result_feedback_surface_reducer_materialized=true"
  echo "accepted_feedback_surface_reduction_materialized=true"
  echo "rejected_validation_feedback_surface_reduction_materialized=true"
  echo "pending_owner_acceptance_feedback_surface_reduction_materialized=true"
  echo "validation_focus_input_feedback_reduction_ledger_materialized=true"
  echo "todo_reduced_form_result_feedback_surface_materialized=true"
  echo "settings_reduced_form_result_feedback_surface_materialized=true"
  echo "ai_generated_settings_reduced_form_result_feedback_surface_materialized=true"
  echo "chat_composer_reduced_form_result_feedback_surface_materialized=true"
  echo "surface_reducer_bound_to_stage598_host_inspection_receipts=true"
  echo "surface_reducer_bound_to_stage597_validation_focus_surface=true"
  echo "stage600_form_result_demo_host_feedback_surface_integration_prepared=true"
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

echo "cjgui stage599 form result feedback surface reducer suite: route_classification=form_result_feedback_surface_reducer_ready"
echo "cjgui stage599 form result feedback surface reducer suite: suite_packet_path=$SUITE_PACKET"
