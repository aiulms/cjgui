#!/usr/bin/env zsh
#
# Focused suite for stage697. It consumes stage696 and verifies the non-dispatching
# timeline action intent bridge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE697_TMPDIR:-/private/tmp/cjgui-stage697-stage700/stage697}"
SUITE_PACKET="$TMP_DIR/stage697-replay-host-text-input-timeline-action-intent-bridge-suite.packet"
STAGE696_SUITE_PACKET="${CJGUI_STAGE697_INPUT_PACKET:-${CJGUI_STAGE696_REPLAY_HOST_TEXT_INPUT_REPLAY_TIMELINE_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage693-stage696/stage696/stage696-replay-host-text-input-replay-timeline-executor-suite.packet}}"
STAGE696_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage696_replay_host_text_input_replay_timeline_executor_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage697_replay_host_text_input_timeline_action_intent_bridge_owner.sh"
OWNER_LOG="$TMP_DIR/stage697-replay-host-text-input-timeline-action-intent-bridge-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage697 replay host text input timeline action intent bridge suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE696_SUITE_PACKET" ]]; then
  zsh "$STAGE696_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage696_replay_host_text_input_replay_timeline_executor_consumed=true" \
  "shared_replay_host_text_input_timeline_action_intent_bridge_materialized=true" \
  "text_edit_commit_timeline_action_intent_materialized=true" \
  "submit_timeline_action_intent_materialized=true" \
  "validation_dismiss_timeline_action_intent_materialized=true" \
  "focus_move_timeline_action_intent_materialized=true" \
  "timeline_action_intent_non_dispatching=true" \
  "stage698_replay_host_text_input_timeline_state_delta_dry_run_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage696_replay_host_text_input_replay_timeline_executor_suite_version=1" \
  "shared_replay_host_text_input_replay_timeline_executor_materialized=true" \
  "chat_composer_replay_host_text_input_replay_timeline_runtime_surface_materialized=true" \
  "stage697_replay_host_text_input_timeline_action_state_bridge_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE696_SUITE_PACKET" "$fact"
done

{
  echo "stage697_replay_host_text_input_timeline_action_intent_bridge_suite_version=1"
  echo "stage696_replay_host_text_input_replay_timeline_executor_suite_packet=$STAGE696_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage697_replay_host_text_input_timeline_action_intent_bridge_suite_passed=true"
  echo "next_route=stage698_replay_host_text_input_timeline_state_delta_dry_run_after_stage697"
} > "$SUITE_PACKET"

echo "cjgui stage697 replay host text input timeline action intent bridge suite: route_classification=timeline_action_intent_bridge_ready"
echo "cjgui stage697 replay host text input timeline action intent bridge suite: suite_packet_path=$SUITE_PACKET"
