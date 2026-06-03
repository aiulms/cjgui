#!/usr/bin/env zsh
#
# Focused suite for stage713. It consumes stage712 and verifies replay action intents.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE713_TMPDIR:-/private/tmp/cjgui-stage713-stage716/stage713}"
SUITE_PACKET="$TMP_DIR/stage713-component-runtime-input-event-replay-action-intent-bridge-suite.packet"
STAGE712_SUITE_PACKET="${CJGUI_STAGE713_INPUT_PACKET:-${CJGUI_STAGE712_COMPONENT_RUNTIME_INPUT_EVENT_REPLAY_CYCLE_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage709-stage712/stage712/stage712-component-runtime-input-event-replay-cycle-executor-suite.packet}}"
STAGE712_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage712_component_runtime_input_event_replay_cycle_executor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage713_component_runtime_input_event_replay_action_intent_bridge_owner.sh"
OWNER_LOG="$TMP_DIR/stage713-component-runtime-input-event-replay-action-intent-bridge-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage713 component runtime input event replay action intent bridge suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE712_SUITE_PACKET" ]]; then
  zsh "$STAGE712_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage712_component_runtime_input_event_replay_cycle_executor_consumed=true" \
  "shared_component_runtime_input_event_replay_action_intent_bridge_materialized=true" \
  "component_replay_text_edit_action_intent_materialized=true" \
  "component_replay_submit_action_intent_materialized=true" \
  "component_replay_validation_dismiss_action_intent_materialized=true" \
  "component_replay_focus_move_action_intent_materialized=true" \
  "component_replay_action_intent_non_dispatching=true" \
  "stage714_component_runtime_input_event_replay_state_delta_dry_run_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage712_component_runtime_input_event_replay_cycle_executor_suite_version=1" \
  "shared_component_runtime_input_event_replay_cycle_executor_materialized=true" \
  "stage713_component_runtime_input_event_replay_action_state_bridge_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE712_SUITE_PACKET" "$fact"
done

{
  echo "stage713_component_runtime_input_event_replay_action_intent_bridge_suite_version=1"
  echo "stage712_component_runtime_input_event_replay_cycle_executor_suite_packet=$STAGE712_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage714_component_runtime_input_event_replay_state_delta_dry_run_after_stage713"
  echo "stage713_component_runtime_input_event_replay_action_intent_bridge_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage713 component runtime input event replay action intent bridge suite: route_classification=component_runtime_input_event_replay_action_intent_ready"
echo "cjgui stage713 component runtime input event replay action intent bridge suite: suite_packet_path=$SUITE_PACKET"
