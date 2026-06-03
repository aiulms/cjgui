#!/usr/bin/env zsh
#
# Focused suite for stage714. It consumes stage713 and verifies replay state deltas.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE714_TMPDIR:-/private/tmp/cjgui-stage713-stage716/stage714}"
SUITE_PACKET="$TMP_DIR/stage714-component-runtime-input-event-replay-state-delta-dry-run-suite.packet"
STAGE713_SUITE_PACKET="${CJGUI_STAGE714_INPUT_PACKET:-${CJGUI_STAGE713_COMPONENT_RUNTIME_INPUT_EVENT_REPLAY_ACTION_INTENT_BRIDGE_SUITE_PACKET:-/private/tmp/cjgui-stage713-stage716/stage713/stage713-component-runtime-input-event-replay-action-intent-bridge-suite.packet}}"
STAGE713_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage713_component_runtime_input_event_replay_action_intent_bridge_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage714_component_runtime_input_event_replay_state_delta_dry_run_owner.sh"
OWNER_LOG="$TMP_DIR/stage714-component-runtime-input-event-replay-state-delta-dry-run-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage714 component runtime input event replay state delta dry-run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE713_SUITE_PACKET" ]]; then
  zsh "$STAGE713_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage713_component_runtime_input_event_replay_action_intent_bridge_consumed=true" \
  "shared_component_runtime_input_event_replay_state_delta_dry_run_executor_materialized=true" \
  "component_replay_text_edit_value_state_delta_materialized=true" \
  "component_replay_submit_pending_state_delta_materialized=true" \
  "component_replay_rollback_preview_materialized=true" \
  "component_replay_state_delta_dry_run_only=true" \
  "stage715_component_runtime_input_event_replay_render_result_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage713_component_runtime_input_event_replay_action_intent_bridge_suite_version=1" \
  "shared_component_runtime_input_event_replay_action_intent_bridge_materialized=true" \
  "stage714_component_runtime_input_event_replay_state_delta_dry_run_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE713_SUITE_PACKET" "$fact"
done

{
  echo "stage714_component_runtime_input_event_replay_state_delta_dry_run_suite_version=1"
  echo "stage713_component_runtime_input_event_replay_action_intent_bridge_suite_packet=$STAGE713_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage715_component_runtime_input_event_replay_render_result_refresh_after_stage714"
  echo "stage714_component_runtime_input_event_replay_state_delta_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage714 component runtime input event replay state delta dry-run suite: route_classification=component_runtime_input_event_replay_state_delta_ready"
echo "cjgui stage714 component runtime input event replay state delta dry-run suite: suite_packet_path=$SUITE_PACKET"
