#!/usr/bin/env zsh
#
# Focused suite for stage611. It consumes stage610 render-refresh receipts and
# verifies a checkable feedback host execution surface.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE611_TMPDIR:-/private/tmp/cjgui-stage609-stage612/stage611}"
SUITE_PACKET="$TMP_DIR/stage611-feedback-host-inspection-demo-host-execution-surface-suite.packet"
STAGE610_SUITE_PACKET="${CJGUI_STAGE611_INPUT_PACKET:-${CJGUI_STAGE610_FEEDBACK_HOST_INSPECTION_STATE_RENDER_REFRESH_BRIDGE_SUITE_PACKET:-/private/tmp/cjgui-stage609-stage612/stage610/stage610-feedback-host-inspection-state-render-refresh-bridge-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage611_feedback_host_inspection_demo_host_execution_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage611-feedback-host-inspection-demo-host-execution-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage611 feedback host inspection demo-host execution surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage610_feedback_host_inspection_state_render_refresh_bridge_consumed=true" \
  "shared_feedback_host_inspection_demo_host_execution_surface_materialized=true" \
  "feedback_host_execution_semantic_diff_receipt_materialized=true" \
  "chat_composer_feedback_host_execution_surface_materialized=true" \
  "stage612_shared_feedback_host_inspection_cycle_executor_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE610_SUITE_PACKET" || ! -f "$STAGE610_SUITE_PACKET" ]]; then
  echo "cjgui stage611 feedback host inspection demo-host execution surface suite: missing stage610 packet; set CJGUI_STAGE611_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage610_feedback_host_inspection_state_render_refresh_bridge_suite_version=1" \
  "shared_feedback_host_inspection_state_render_refresh_bridge_materialized=true" \
  "chat_composer_feedback_host_inspection_render_refresh_receipt_materialized=true" \
  "stage611_feedback_host_inspection_demo_host_execution_surface_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE610_SUITE_PACKET" "$fact"
done

{
  echo "stage611_feedback_host_inspection_demo_host_execution_surface_suite_version=1"
  echo "stage610_feedback_host_inspection_state_render_refresh_bridge_suite_packet=$STAGE610_SUITE_PACKET"
  echo "stage611_feedback_host_inspection_demo_host_execution_surface_owner_passed=true"
  echo "stage610_feedback_host_inspection_state_render_refresh_bridge_consumed=true"
  echo "stage609_feedback_host_inspection_input_state_bridge_consumed_transitively=true"
  echo "stage608_feedback_host_inspection_runtime_contract_consumed_transitively=true"
  echo "shared_feedback_host_inspection_demo_host_execution_surface_materialized=true"
  echo "feedback_host_execution_result_surface_refresh_materialized=true"
  echo "feedback_host_execution_semantic_diff_receipt_materialized=true"
  echo "feedback_host_validation_input_focus_display_receipt_materialized=true"
  echo "todo_feedback_host_execution_surface_materialized=true"
  echo "settings_feedback_host_execution_surface_materialized=true"
  echo "ai_generated_settings_feedback_host_execution_surface_materialized=true"
  echo "chat_composer_feedback_host_execution_surface_materialized=true"
  echo "demo_host_execution_surface_bound_to_stage610_render_refresh_receipts=true"
  echo "stage612_shared_feedback_host_inspection_cycle_executor_contract_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage611_feedback_host_inspection_demo_host_execution_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage611 feedback host inspection demo-host execution surface suite: route_classification=demo_host_execution_surface_ready"
echo "cjgui stage611 feedback host inspection demo-host execution surface suite: suite_packet_path=$SUITE_PACKET"
