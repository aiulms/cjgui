#!/usr/bin/env zsh
#
# Focused suite for stage631. It consumes stage630 semantic refresh receipts
# and verifies host inspection probe input/receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE631_TMPDIR:-/private/tmp/cjgui-stage629-stage632/stage631}"
SUITE_PACKET="$TMP_DIR/stage631-focus-validation-result-surface-host-inspection-suite.packet"
STAGE630_SUITE_PACKET="${CJGUI_STAGE631_INPUT_PACKET:-${CJGUI_STAGE630_FOCUS_VALIDATION_HOST_INPUT_RESULT_SEMANTIC_REFRESH_SUITE_PACKET:-/private/tmp/cjgui-stage629-stage632/stage630/stage630-focus-validation-host-input-result-semantic-refresh-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage631_focus_validation_result_surface_host_inspection_owner.sh"
OWNER_LOG="$TMP_DIR/stage631-focus-validation-result-surface-host-inspection-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage631 focus validation result surface host inspection suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage630_focus_validation_host_input_result_semantic_refresh_consumed=true" \
  "shared_result_surface_host_inspection_contract_materialized=true" \
  "result_surface_host_inspection_probe_input_materialized=true" \
  "chat_composer_result_surface_host_inspection_receipt_materialized=true" \
  "stage632_shared_focus_validation_result_surface_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE630_SUITE_PACKET" || ! -f "$STAGE630_SUITE_PACKET" ]]; then
  echo "cjgui stage631 focus validation result surface host inspection suite: missing stage630 packet; set CJGUI_STAGE631_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage630_focus_validation_host_input_result_semantic_refresh_suite_version=1" \
  "shared_result_surface_semantic_diff_refresh_materialized=true" \
  "chat_composer_result_semantic_refresh_receipt_materialized=true" \
  "stage631_focus_validation_result_surface_host_inspection_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE630_SUITE_PACKET" "$fact"
done

{
  echo "stage631_focus_validation_result_surface_host_inspection_suite_version=1"
  echo "stage630_focus_validation_host_input_result_semantic_refresh_suite_packet=$STAGE630_SUITE_PACKET"
  echo "stage631_focus_validation_result_surface_host_inspection_owner_passed=true"
  echo "stage630_focus_validation_host_input_result_semantic_refresh_consumed=true"
  echo "shared_result_surface_host_inspection_contract_materialized=true"
  echo "result_surface_host_inspection_probe_input_materialized=true"
  echo "validation_error_host_inspection_slot_materialized=true"
  echo "focus_movement_host_inspection_slot_materialized=true"
  echo "input_feedback_host_inspection_slot_materialized=true"
  echo "todo_result_surface_host_inspection_receipt_materialized=true"
  echo "settings_result_surface_host_inspection_receipt_materialized=true"
  echo "ai_generated_settings_result_surface_host_inspection_receipt_materialized=true"
  echo "chat_composer_result_surface_host_inspection_receipt_materialized=true"
  echo "host_inspection_bound_to_stage630_semantic_refresh=true"
  echo "stage632_shared_focus_validation_result_surface_runtime_contract_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "next_route=stage632_shared_focus_validation_result_surface_runtime_contract_after_stage631"
  echo "stage631_focus_validation_result_surface_host_inspection_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage631 focus validation result surface host inspection suite: route_classification=host_inspection_ready"
echo "cjgui stage631 focus validation result surface host inspection suite: suite_packet_path=$SUITE_PACKET"
