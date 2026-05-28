#!/usr/bin/env zsh
#
# Focused suite for stage597. It consumes stage596 feedback cycle runtime
# contract evidence and emits a validation/focus surface packet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE597_TMPDIR:-/private/tmp/cjgui-stage597-stage600/stage597}"
SUITE_PACKET="$TMP_DIR/stage597-form-result-feedback-validation-focus-surface-suite.packet"
STAGE596_SUITE_PACKET="${CJGUI_STAGE597_INPUT_PACKET:-${CJGUI_STAGE596_FORM_RESULT_HOST_FEEDBACK_CYCLE_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage593-stage596/stage596/stage596-form-result-host-feedback-cycle-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage597_form_result_feedback_validation_focus_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage597-form-result-feedback-validation-focus-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage597 form result feedback validation focus surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage597 form result feedback validation focus surface suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage596_form_result_host_feedback_cycle_runtime_contract_consumed=true" \
  "shared_form_result_feedback_validation_focus_surface_materialized=true" \
  "form_result_feedback_validation_display_surface_materialized=true" \
  "form_result_feedback_focus_movement_surface_materialized=true" \
  "form_result_feedback_input_display_surface_materialized=true" \
  "form_result_feedback_render_command_refresh_preview_materialized=true" \
  "chat_composer_form_result_feedback_validation_focus_surface_materialized=true" \
  "validation_focus_surface_bound_to_stage596_runtime_contract=true" \
  "validation_focus_surface_bound_to_stage595_demo_surface_receipts=true" \
  "stage598_form_result_feedback_host_inspection_receipt_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE596_SUITE_PACKET" || ! -f "$STAGE596_SUITE_PACKET" ]]; then
  echo "cjgui stage597 form result feedback validation focus surface suite: missing stage596 packet; set CJGUI_STAGE597_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage596_form_result_host_feedback_cycle_runtime_contract_suite_version=1" \
  "shared_form_result_host_feedback_cycle_runtime_contract_materialized=true" \
  "shared_form_result_host_feedback_cycle_execution_contract_materialized=true" \
  "chat_composer_checkable_form_result_host_feedback_cycle_runtime_surface_materialized=true" \
  "feedback_cycle_runtime_contract_bound_to_stage595_demo_surface_receipts=true" \
  "stage597_form_result_feedback_validation_focus_surface_prepared=true" \
  "focus_manager_enabled=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE596_SUITE_PACKET" "$fact"
done

{
  echo "stage597_form_result_feedback_validation_focus_surface_suite_version=1"
  echo "stage596_form_result_host_feedback_cycle_runtime_contract_suite_packet=$STAGE596_SUITE_PACKET"
  echo "stage597_form_result_feedback_validation_focus_surface_owner_passed=true"
  echo "stage596_form_result_host_feedback_cycle_runtime_contract_consumed=true"
  echo "shared_form_result_feedback_validation_focus_surface_materialized=true"
  echo "form_result_feedback_validation_display_surface_materialized=true"
  echo "form_result_feedback_focus_movement_surface_materialized=true"
  echo "form_result_feedback_input_display_surface_materialized=true"
  echo "form_result_feedback_render_command_refresh_preview_materialized=true"
  echo "todo_form_result_feedback_validation_focus_surface_materialized=true"
  echo "settings_form_result_feedback_validation_focus_surface_materialized=true"
  echo "ai_generated_settings_form_result_feedback_validation_focus_surface_materialized=true"
  echo "chat_composer_form_result_feedback_validation_focus_surface_materialized=true"
  echo "validation_focus_surface_bound_to_stage596_runtime_contract=true"
  echo "validation_focus_surface_bound_to_stage595_demo_surface_receipts=true"
  echo "stage598_form_result_feedback_host_inspection_receipt_prepared=true"
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

echo "cjgui stage597 form result feedback validation focus surface suite: route_classification=form_result_feedback_validation_focus_surface_ready"
echo "cjgui stage597 form result feedback validation focus surface suite: suite_packet_path=$SUITE_PACKET"
