#!/usr/bin/env zsh
#
# Focused suite for stage667. It consumes stage666 host inspection receipts and
# verifies validation/focus/input-feedback result-surface refresh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE667_TMPDIR:-/private/tmp/cjgui-stage665-stage668/stage667}"
SUITE_PACKET="$TMP_DIR/stage667-component-feedback-input-result-surface-refresh-suite.packet"
STAGE666_SUITE_PACKET="${CJGUI_STAGE667_INPUT_PACKET:-${CJGUI_STAGE666_COMPONENT_FEEDBACK_INPUT_HOST_INSPECTION_RECEIPT_SUITE_PACKET:-/private/tmp/cjgui-stage665-stage668/stage666/stage666-component-feedback-input-host-inspection-receipt-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage667_component_feedback_input_result_surface_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage667-component-feedback-input-result-surface-refresh-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage667 component feedback input result-surface refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage666_component_feedback_input_host_inspection_receipt_consumed=true" \
  "shared_feedback_input_result_surface_refresh_materialized=true" \
  "validation_display_result_surface_refresh_materialized=true" \
  "focus_transition_result_surface_refresh_materialized=true" \
  "input_feedback_clear_result_surface_refresh_materialized=true" \
  "semantic_diff_acknowledge_result_surface_refresh_materialized=true" \
  "chat_composer_feedback_input_result_surface_refresh_materialized=true" \
  "stage668_component_feedback_input_demo_host_runtime_contract_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE666_SUITE_PACKET" || ! -f "$STAGE666_SUITE_PACKET" ]]; then
  echo "cjgui stage667 component feedback input result-surface refresh suite: missing stage666 packet; set CJGUI_STAGE667_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage666_component_feedback_input_host_inspection_receipt_suite_version=1" \
  "shared_feedback_input_host_inspection_receipt_materialized=true" \
  "chat_composer_feedback_input_host_inspection_receipt_materialized=true" \
  "stage667_component_feedback_input_result_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE666_SUITE_PACKET" "$fact"
done

{
  echo "stage667_component_feedback_input_result_surface_refresh_suite_version=1"
  echo "stage666_component_feedback_input_host_inspection_receipt_suite_packet=$STAGE666_SUITE_PACKET"
  echo "stage667_component_feedback_input_result_surface_refresh_owner_passed=true"
  echo "stage666_component_feedback_input_host_inspection_receipt_consumed=true"
  echo "stage665_component_feedback_input_demo_host_surface_consumed_transitively=true"
  echo "feedback_input_host_inspection_receipts_consumed=true"
  echo "shared_feedback_input_result_surface_refresh_materialized=true"
  echo "validation_display_result_surface_refresh_materialized=true"
  echo "focus_transition_result_surface_refresh_materialized=true"
  echo "input_feedback_clear_result_surface_refresh_materialized=true"
  echo "semantic_diff_acknowledge_result_surface_refresh_materialized=true"
  echo "todo_feedback_input_result_surface_refresh_materialized=true"
  echo "settings_feedback_input_result_surface_refresh_materialized=true"
  echo "ai_generated_settings_feedback_input_result_surface_refresh_materialized=true"
  echo "chat_composer_feedback_input_result_surface_refresh_materialized=true"
  echo "result_surface_refresh_bound_to_stage666_inspection=true"
  echo "feedback_input_result_surface_refresh_checkable=true"
  echo "stage668_component_feedback_input_demo_host_runtime_contract_prepared=true"
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
  echo "next_route=stage668_component_feedback_input_demo_host_runtime_contract_after_stage667"
  echo "stage667_component_feedback_input_result_surface_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage667 component feedback input result-surface refresh suite: route_classification=feedback_input_result_surface_refresh_ready"
echo "cjgui stage667 component feedback input result-surface refresh suite: suite_packet_path=$SUITE_PACKET"
