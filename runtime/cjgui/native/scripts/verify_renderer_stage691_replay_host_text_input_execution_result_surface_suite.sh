#!/usr/bin/env zsh
#
# Focused suite for stage691. It consumes stage690 and emits execution/result surface evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE691_TMPDIR:-/private/tmp/cjgui-stage689-stage692/stage691}"
SUITE_PACKET="$TMP_DIR/stage691-replay-host-text-input-execution-result-surface-suite.packet"
STAGE690_SUITE_PACKET="${CJGUI_STAGE691_INPUT_PACKET:-${CJGUI_STAGE690_REPLAY_HOST_TEXT_INPUT_HOST_EVENT_ADAPTER_SUITE_PACKET:-/private/tmp/cjgui-stage689-stage692/stage690/stage690-replay-host-text-input-host-event-adapter-suite.packet}}"
STAGE690_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage690_replay_host_text_input_host_event_adapter_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage691_replay_host_text_input_execution_result_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage691-replay-host-text-input-execution-result-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage691 replay host text input execution/result surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE690_SUITE_PACKET" ]]; then
  zsh "$STAGE690_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage690_replay_host_text_input_host_event_adapter_consumed=true" \
  "shared_replay_host_text_input_execution_result_receipt_materialized=true" \
  "text_edit_execution_result_surface_receipt_materialized=true" \
  "submit_execution_result_surface_receipt_materialized=true" \
  "validation_feedback_result_surface_receipt_materialized=true" \
  "focus_transition_host_inspection_preview_materialized=true" \
  "render_command_refresh_receipt_materialized=true" \
  "semantic_diff_explain_receipt_materialized=true" \
  "chat_composer_replay_host_text_input_execution_result_surface_materialized=true" \
  "stage692_replay_host_text_input_demo_host_cycle_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage690_replay_host_text_input_host_event_adapter_suite_version=1" \
  "shared_replay_host_text_input_host_event_adapter_materialized=true" \
  "stage691_replay_host_text_input_execution_result_surface_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE690_SUITE_PACKET" "$fact"
done

{
  echo "stage691_replay_host_text_input_execution_result_surface_suite_version=1"
  echo "stage690_replay_host_text_input_host_event_adapter_suite_packet=$STAGE690_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage691_replay_host_text_input_execution_result_surface_suite_passed=true"
  echo "next_route=stage692_replay_host_text_input_demo_host_cycle_executor_after_stage691"
} > "$SUITE_PACKET"

echo "cjgui stage691 replay host text input execution/result surface suite: route_classification=text_input_execution_result_surface_ready"
echo "cjgui stage691 replay host text input execution/result surface suite: suite_packet_path=$SUITE_PACKET"
