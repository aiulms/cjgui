#!/usr/bin/env zsh
#
# Focused suite for stage711. It consumes stage710 and verifies replay result
# surface refresh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE711_TMPDIR:-/private/tmp/cjgui-stage709-stage712/stage711}"
SUITE_PACKET="$TMP_DIR/stage711-component-runtime-input-event-replay-result-surface-refresh-suite.packet"
STAGE710_SUITE_PACKET="${CJGUI_STAGE711_INPUT_PACKET:-${CJGUI_STAGE710_COMPONENT_RUNTIME_INPUT_EVENT_REPLAY_HOST_INSPECTION_PREVIEW_SUITE_PACKET:-/private/tmp/cjgui-stage709-stage712/stage710/stage710-component-runtime-input-event-replay-host-inspection-preview-suite.packet}}"
STAGE710_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage710_component_runtime_input_event_replay_host_inspection_preview_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage711_component_runtime_input_event_replay_result_surface_refresh_owner.sh"
OWNER_LOG="$TMP_DIR/stage711-component-runtime-input-event-replay-result-surface-refresh-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage711 component runtime input event replay result surface refresh suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE710_SUITE_PACKET" ]]; then
  zsh "$STAGE710_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage710_component_runtime_input_event_replay_host_inspection_preview_consumed=true" \
  "shared_component_runtime_input_event_replay_result_surface_refresh_materialized=true" \
  "component_replay_input_feedback_refresh_materialized=true" \
  "component_replay_render_command_refresh_preview_materialized=true" \
  "component_replay_semantic_diff_explain_refresh_materialized=true" \
  "stage712_component_runtime_input_event_replay_cycle_executor_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage710_component_runtime_input_event_replay_host_inspection_preview_suite_version=1" \
  "shared_component_runtime_input_event_replay_host_inspection_preview_materialized=true" \
  "component_runtime_replay_probe_input_contract_materialized=true" \
  "stage711_component_runtime_input_event_replay_result_surface_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE710_SUITE_PACKET" "$fact"
done

{
  echo "stage711_component_runtime_input_event_replay_result_surface_refresh_suite_version=1"
  echo "stage710_component_runtime_input_event_replay_host_inspection_preview_suite_packet=$STAGE710_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage712_component_runtime_input_event_replay_cycle_executor_after_stage711"
  echo "stage711_component_runtime_input_event_replay_result_surface_refresh_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage711 component runtime input event replay result surface refresh suite: route_classification=component_runtime_input_event_replay_result_refresh_ready"
echo "cjgui stage711 component runtime input event replay result surface refresh suite: suite_packet_path=$SUITE_PACKET"
