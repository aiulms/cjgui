#!/usr/bin/env zsh
#
# Focused suite for stage690. It consumes stage689 and emits host-event adapter evidence.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE690_TMPDIR:-/private/tmp/cjgui-stage689-stage692/stage690}"
SUITE_PACKET="$TMP_DIR/stage690-replay-host-text-input-host-event-adapter-suite.packet"
STAGE689_SUITE_PACKET="${CJGUI_STAGE690_INPUT_PACKET:-${CJGUI_STAGE689_REPLAY_HOST_TEXT_INPUT_DEMO_HOST_INTEGRATION_SUITE_PACKET:-/private/tmp/cjgui-stage689-stage692/stage689/stage689-replay-host-text-input-demo-host-integration-suite.packet}}"
STAGE689_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage689_replay_host_text_input_demo_host_integration_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage690_replay_host_text_input_host_event_adapter_owner.sh"
OWNER_LOG="$TMP_DIR/stage690-replay-host-text-input-host-event-adapter-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage690 replay host text input host-event adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE689_SUITE_PACKET" ]]; then
  zsh "$STAGE689_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage689_replay_host_text_input_demo_host_integration_consumed=true" \
  "shared_replay_host_text_input_host_event_adapter_materialized=true" \
  "text_edit_host_event_route_materialized=true" \
  "text_submit_host_event_route_materialized=true" \
  "validation_dismiss_host_event_route_materialized=true" \
  "focus_move_host_event_route_materialized=true" \
  "replay_host_text_input_host_event_queue_preview_materialized=true" \
  "chat_composer_replay_host_text_input_host_event_queue_materialized=true" \
  "stage691_replay_host_text_input_execution_result_surface_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage689_replay_host_text_input_demo_host_integration_suite_version=1" \
  "shared_replay_host_text_input_demo_host_integration_materialized=true" \
  "stage690_replay_host_text_input_host_event_adapter_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE689_SUITE_PACKET" "$fact"
done

{
  echo "stage690_replay_host_text_input_host_event_adapter_suite_version=1"
  echo "stage689_replay_host_text_input_demo_host_integration_suite_packet=$STAGE689_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage690_replay_host_text_input_host_event_adapter_suite_passed=true"
  echo "next_route=stage691_replay_host_text_input_execution_result_surface_after_stage690"
} > "$SUITE_PACKET"

echo "cjgui stage690 replay host text input host-event adapter suite: route_classification=text_input_host_event_adapter_ready"
echo "cjgui stage690 replay host text input host-event adapter suite: suite_packet_path=$SUITE_PACKET"
