#!/usr/bin/env zsh
#
# Focused suite for stage610. It consumes stage609 input-state packets and
# verifies the shared state-to-RenderCommand refresh bridge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE610_TMPDIR:-/private/tmp/cjgui-stage609-stage612/stage610}"
SUITE_PACKET="$TMP_DIR/stage610-feedback-host-inspection-state-render-refresh-bridge-suite.packet"
STAGE609_SUITE_PACKET="${CJGUI_STAGE610_INPUT_PACKET:-${CJGUI_STAGE609_FEEDBACK_HOST_INSPECTION_INPUT_STATE_BRIDGE_SUITE_PACKET:-/private/tmp/cjgui-stage609-stage612/stage609/stage609-feedback-host-inspection-input-state-bridge-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage610_feedback_host_inspection_state_render_refresh_bridge_owner.sh"
OWNER_LOG="$TMP_DIR/stage610-feedback-host-inspection-state-render-refresh-bridge-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage610 feedback host inspection state-render refresh bridge suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage609_feedback_host_inspection_input_state_bridge_consumed=true" \
  "shared_feedback_host_inspection_state_render_refresh_bridge_materialized=true" \
  "validation_display_render_command_refresh_receipt_materialized=true" \
  "chat_composer_feedback_host_inspection_render_refresh_receipt_materialized=true" \
  "stage611_feedback_host_inspection_demo_host_execution_surface_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE609_SUITE_PACKET" || ! -f "$STAGE609_SUITE_PACKET" ]]; then
  echo "cjgui stage610 feedback host inspection state-render refresh bridge suite: missing stage609 packet; set CJGUI_STAGE610_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage609_feedback_host_inspection_input_state_bridge_suite_version=1" \
  "shared_feedback_host_inspection_input_state_bridge_materialized=true" \
  "chat_composer_feedback_host_inspection_input_state_delta_materialized=true" \
  "stage610_feedback_host_inspection_state_render_refresh_bridge_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE609_SUITE_PACKET" "$fact"
done

{
  echo "stage610_feedback_host_inspection_state_render_refresh_bridge_suite_version=1"
  echo "stage609_feedback_host_inspection_input_state_bridge_suite_packet=$STAGE609_SUITE_PACKET"
  echo "stage610_feedback_host_inspection_state_render_refresh_bridge_owner_passed=true"
  echo "stage609_feedback_host_inspection_input_state_bridge_consumed=true"
  echo "stage608_feedback_host_inspection_runtime_contract_consumed_transitively=true"
  echo "shared_feedback_host_inspection_state_render_refresh_bridge_materialized=true"
  echo "validation_display_render_command_refresh_receipt_materialized=true"
  echo "input_feedback_render_command_refresh_receipt_materialized=true"
  echo "focus_transition_render_command_refresh_receipt_materialized=true"
  echo "todo_feedback_host_inspection_render_refresh_receipt_materialized=true"
  echo "settings_feedback_host_inspection_render_refresh_receipt_materialized=true"
  echo "ai_generated_settings_feedback_host_inspection_render_refresh_receipt_materialized=true"
  echo "chat_composer_feedback_host_inspection_render_refresh_receipt_materialized=true"
  echo "state_render_refresh_bridge_bound_to_stage609_input_state_deltas=true"
  echo "stage611_feedback_host_inspection_demo_host_execution_surface_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage610_feedback_host_inspection_state_render_refresh_bridge_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage610 feedback host inspection state-render refresh bridge suite: route_classification=state_render_refresh_bridge_ready"
echo "cjgui stage610 feedback host inspection state-render refresh bridge suite: suite_packet_path=$SUITE_PACKET"
