#!/usr/bin/env zsh
#
# Focused suite for stage710. It consumes stage709 and verifies replay host
# inspection preview/probe input.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE710_TMPDIR:-/private/tmp/cjgui-stage709-stage712/stage710}"
SUITE_PACKET="$TMP_DIR/stage710-component-runtime-input-event-replay-host-inspection-preview-suite.packet"
STAGE709_SUITE_PACKET="${CJGUI_STAGE710_INPUT_PACKET:-${CJGUI_STAGE709_COMPONENT_RUNTIME_INPUT_EVENT_REPLAY_SURFACE_SUITE_PACKET:-/private/tmp/cjgui-stage709-stage712/stage709/stage709-component-runtime-input-event-replay-surface-suite.packet}}"
STAGE709_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage709_component_runtime_input_event_replay_surface_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage710_component_runtime_input_event_replay_host_inspection_preview_owner.sh"
OWNER_LOG="$TMP_DIR/stage710-component-runtime-input-event-replay-host-inspection-preview-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage710 component runtime input event replay host inspection preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE709_SUITE_PACKET" ]]; then
  zsh "$STAGE709_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage709_component_runtime_input_event_replay_surface_consumed=true" \
  "shared_component_runtime_input_event_replay_host_inspection_preview_materialized=true" \
  "component_runtime_replay_probe_input_contract_materialized=true" \
  "component_text_edit_replay_host_inspection_materialized=true" \
  "component_input_event_replay_host_inspection_bound_to_stage709_replay_surface=true" \
  "stage711_component_runtime_input_event_replay_result_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage709_component_runtime_input_event_replay_surface_suite_version=1" \
  "shared_component_runtime_input_event_replay_surface_materialized=true" \
  "stage710_component_runtime_input_event_replay_host_inspection_preview_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE709_SUITE_PACKET" "$fact"
done

{
  echo "stage710_component_runtime_input_event_replay_host_inspection_preview_suite_version=1"
  echo "stage709_component_runtime_input_event_replay_surface_suite_packet=$STAGE709_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage711_component_runtime_input_event_replay_result_surface_refresh_after_stage710"
  echo "stage710_component_runtime_input_event_replay_host_inspection_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage710 component runtime input event replay host inspection preview suite: route_classification=component_runtime_input_event_replay_host_inspection_ready"
echo "cjgui stage710 component runtime input event replay host inspection preview suite: suite_packet_path=$SUITE_PACKET"
