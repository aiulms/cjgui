#!/usr/bin/env zsh
#
# Focused suite for stage615. It consumes the stage614 resolver packet and
# verifies checkable demo-host focus/validation receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE615_TMPDIR:-/private/tmp/cjgui-stage613-stage616/stage615}"
SUITE_PACKET="$TMP_DIR/stage615-focus-validation-demo-host-receipt-suite.packet"
STAGE614_SUITE_PACKET="${CJGUI_STAGE615_INPUT_PACKET:-${CJGUI_STAGE614_FOCUS_VALIDATION_FEEDBACK_RESOLVER_SUITE_PACKET:-/private/tmp/cjgui-stage613-stage616/stage614/stage614-focus-validation-feedback-resolver-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage615_focus_validation_demo_host_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage615-focus-validation-demo-host-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage615 focus validation demo host receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage614_focus_validation_feedback_resolver_consumed=true" \
  "shared_focus_validation_demo_host_receipt_materialized=true" \
  "focus_movement_preview_receipt_materialized=true" \
  "validation_display_receipt_materialized=true" \
  "chat_composer_focus_validation_demo_host_receipt_materialized=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE614_SUITE_PACKET" || ! -f "$STAGE614_SUITE_PACKET" ]]; then
  echo "cjgui stage615 focus validation demo host receipt suite: missing stage614 packet; set CJGUI_STAGE615_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage614_focus_validation_feedback_resolver_suite_version=1" \
  "shared_focus_validation_feedback_resolver_materialized=true" \
  "chat_composer_focus_validation_feedback_surface_materialized=true" \
  "stage615_focus_validation_demo_host_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE614_SUITE_PACKET" "$fact"
done

{
  echo "stage615_focus_validation_demo_host_receipt_suite_version=1"
  echo "stage614_focus_validation_feedback_resolver_suite_packet=$STAGE614_SUITE_PACKET"
  echo "stage615_focus_validation_demo_host_receipt_owner_passed=true"
  echo "stage614_focus_validation_feedback_resolver_consumed=true"
  echo "stage613_focus_validation_manager_consumed_transitively=true"
  echo "stage612_shared_feedback_host_inspection_cycle_executor_contract_consumed_transitively=true"
  echo "shared_focus_validation_demo_host_receipt_materialized=true"
  echo "focus_movement_preview_receipt_materialized=true"
  echo "validation_display_receipt_materialized=true"
  echo "input_feedback_display_receipt_materialized=true"
  echo "demo_host_inspection_probe_input_materialized=true"
  echo "todo_focus_validation_demo_host_receipt_materialized=true"
  echo "settings_focus_validation_demo_host_receipt_materialized=true"
  echo "ai_generated_settings_focus_validation_demo_host_receipt_materialized=true"
  echo "chat_composer_focus_validation_demo_host_receipt_materialized=true"
  echo "stage616_shared_focus_validation_runtime_contract_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "focus_manager_enabled=false"
  echo "visibility_publication_admitted=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage615_focus_validation_demo_host_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage615 focus validation demo host receipt suite: route_classification=focus_validation_demo_host_receipt_ready"
echo "cjgui stage615 focus validation demo host receipt suite: suite_packet_path=$SUITE_PACKET"
