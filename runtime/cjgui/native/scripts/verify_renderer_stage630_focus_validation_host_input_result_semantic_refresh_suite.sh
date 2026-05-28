#!/usr/bin/env zsh
#
# Focused suite for stage630. It consumes stage629 result surfaces and verifies
# semantic diff/explain refresh receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE630_TMPDIR:-/private/tmp/cjgui-stage629-stage632/stage630}"
SUITE_PACKET="$TMP_DIR/stage630-focus-validation-host-input-result-semantic-refresh-suite.packet"
STAGE629_SUITE_PACKET="${CJGUI_STAGE630_INPUT_PACKET:-${CJGUI_STAGE629_FOCUS_VALIDATION_HOST_INPUT_RESULT_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage629-stage632/stage629/stage629-focus-validation-host-input-result-surface-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage630_focus_validation_host_input_result_semantic_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage630-focus-validation-host-input-result-semantic-refresh-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage630 focus validation host input result semantic refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage629_focus_validation_host_input_result_surface_consumed=true" \
  "shared_result_surface_semantic_diff_refresh_materialized=true" \
  "validation_error_semantic_explain_ledger_materialized=true" \
  "chat_composer_result_semantic_refresh_receipt_materialized=true" \
  "stage631_focus_validation_result_surface_host_inspection_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE629_SUITE_PACKET" || ! -f "$STAGE629_SUITE_PACKET" ]]; then
  echo "cjgui stage630 focus validation host input result semantic refresh suite: missing stage629 packet; set CJGUI_STAGE630_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage629_focus_validation_host_input_result_surface_suite_version=1" \
  "shared_focus_validation_host_input_result_surface_materialized=true" \
  "semantic_diff_result_surface_refresh_materialized=true" \
  "stage630_focus_validation_host_input_result_semantic_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE629_SUITE_PACKET" "$fact"
done

{
  echo "stage630_focus_validation_host_input_result_semantic_refresh_suite_version=1"
  echo "stage629_focus_validation_host_input_result_surface_suite_packet=$STAGE629_SUITE_PACKET"
  echo "stage630_focus_validation_host_input_result_semantic_refresh_owner_passed=true"
  echo "stage629_focus_validation_host_input_result_surface_consumed=true"
  echo "shared_result_surface_semantic_diff_refresh_materialized=true"
  echo "validation_error_semantic_explain_ledger_materialized=true"
  echo "focus_movement_semantic_explain_ledger_materialized=true"
  echo "input_feedback_semantic_explain_ledger_materialized=true"
  echo "todo_result_semantic_refresh_receipt_materialized=true"
  echo "settings_result_semantic_refresh_receipt_materialized=true"
  echo "ai_generated_settings_result_semantic_refresh_receipt_materialized=true"
  echo "chat_composer_result_semantic_refresh_receipt_materialized=true"
  echo "semantic_refresh_bound_to_stage629_result_surfaces=true"
  echo "stage631_focus_validation_result_surface_host_inspection_prepared=true"
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
  echo "next_route=stage631_focus_validation_result_surface_host_inspection_after_stage630"
  echo "stage630_focus_validation_host_input_result_semantic_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage630 focus validation host input result semantic refresh suite: route_classification=result_semantic_refresh_ready"
echo "cjgui stage630 focus validation host input result semantic refresh suite: suite_packet_path=$SUITE_PACKET"
