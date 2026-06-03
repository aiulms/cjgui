#!/usr/bin/env zsh
#
# Focused suite for stage698. It consumes stage697 and verifies owner-local
# timeline state delta dry-runs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE698_TMPDIR:-/private/tmp/cjgui-stage697-stage700/stage698}"
SUITE_PACKET="$TMP_DIR/stage698-replay-host-text-input-timeline-state-delta-dry-run-suite.packet"
STAGE697_SUITE_PACKET="${CJGUI_STAGE698_INPUT_PACKET:-${CJGUI_STAGE697_REPLAY_HOST_TEXT_INPUT_TIMELINE_ACTION_INTENT_BRIDGE_SUITE_PACKET:-/private/tmp/cjgui-stage697-stage700/stage697/stage697-replay-host-text-input-timeline-action-intent-bridge-suite.packet}}"
STAGE697_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage697_replay_host_text_input_timeline_action_intent_bridge_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage698_replay_host_text_input_timeline_state_delta_dry_run_owner.sh"
OWNER_LOG="$TMP_DIR/stage698-replay-host-text-input-timeline-state-delta-dry-run-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage698 replay host text input timeline state delta dry-run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE697_SUITE_PACKET" ]]; then
  zsh "$STAGE697_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage697_replay_host_text_input_timeline_action_intent_bridge_consumed=true" \
  "shared_replay_host_text_input_timeline_state_delta_dry_run_executor_materialized=true" \
  "text_edit_value_timeline_state_delta_materialized=true" \
  "submit_pending_timeline_state_delta_materialized=true" \
  "validation_dismiss_timeline_state_delta_materialized=true" \
  "focus_move_timeline_state_delta_materialized=true" \
  "timeline_rollback_preview_materialized=true" \
  "stage699_replay_host_text_input_timeline_render_result_refresh_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage697_replay_host_text_input_timeline_action_intent_bridge_suite_version=1" \
  "shared_replay_host_text_input_timeline_action_intent_bridge_materialized=true" \
  "chat_composer_replay_host_text_input_timeline_action_intent_surface_materialized=true" \
  "stage698_replay_host_text_input_timeline_state_delta_dry_run_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE697_SUITE_PACKET" "$fact"
done

{
  echo "stage698_replay_host_text_input_timeline_state_delta_dry_run_suite_version=1"
  echo "stage697_replay_host_text_input_timeline_action_intent_bridge_suite_packet=$STAGE697_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage698_replay_host_text_input_timeline_state_delta_dry_run_suite_passed=true"
  echo "next_route=stage699_replay_host_text_input_timeline_render_result_refresh_after_stage698"
} > "$SUITE_PACKET"

echo "cjgui stage698 replay host text input timeline state delta dry-run suite: route_classification=timeline_state_delta_dry_run_ready"
echo "cjgui stage698 replay host text input timeline state delta dry-run suite: suite_packet_path=$SUITE_PACKET"
