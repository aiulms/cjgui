#!/usr/bin/env zsh
#
# Focused suite for stage709. It consumes stage708 and verifies the component
# runtime input event replay surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE709_TMPDIR:-/private/tmp/cjgui-stage709-stage712/stage709}"
SUITE_PACKET="$TMP_DIR/stage709-component-runtime-input-event-replay-surface-suite.packet"
STAGE708_SUITE_PACKET="${CJGUI_STAGE709_INPUT_PACKET:-${CJGUI_STAGE708_COMPONENT_RUNTIME_INPUT_EVENT_CYCLE_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage705-stage708/stage708/stage708-component-runtime-input-event-cycle-executor-suite.packet}}"
STAGE708_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage708_component_runtime_input_event_cycle_executor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage709_component_runtime_input_event_replay_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage709-component-runtime-input-event-replay-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage709 component runtime input event replay surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE708_SUITE_PACKET" ]]; then
  zsh "$STAGE708_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage708_component_runtime_input_event_cycle_executor_consumed=true" \
  "shared_component_runtime_input_event_replay_surface_materialized=true" \
  "replayable_component_text_edit_result_surface_materialized=true" \
  "replayable_component_submit_result_surface_materialized=true" \
  "replayable_component_validation_dismiss_result_surface_materialized=true" \
  "replayable_component_focus_move_result_surface_materialized=true" \
  "component_input_event_replay_surface_bound_to_stage708_cycle_executor=true" \
  "stage710_component_runtime_input_event_replay_host_inspection_preview_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage708_component_runtime_input_event_cycle_executor_suite_version=1" \
  "shared_component_runtime_input_event_cycle_executor_materialized=true" \
  "stage709_component_runtime_input_event_replay_surface_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE708_SUITE_PACKET" "$fact"
done

{
  echo "stage709_component_runtime_input_event_replay_surface_suite_version=1"
  echo "stage708_component_runtime_input_event_cycle_executor_suite_packet=$STAGE708_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage710_component_runtime_input_event_replay_host_inspection_preview_after_stage709"
  echo "stage709_component_runtime_input_event_replay_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage709 component runtime input event replay surface suite: route_classification=component_runtime_input_event_replay_surface_ready"
echo "cjgui stage709 component runtime input event replay surface suite: suite_packet_path=$SUITE_PACKET"
