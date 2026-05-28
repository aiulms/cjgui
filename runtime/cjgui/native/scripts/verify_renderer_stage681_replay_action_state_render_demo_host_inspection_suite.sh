#!/usr/bin/env zsh
#
# Focused suite for stage681. It consumes stage680 and verifies replay host inspection.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE681_TMPDIR:-/private/tmp/cjgui-stage681-stage684/stage681}"
SUITE_PACKET="$TMP_DIR/stage681-replay-action-state-render-demo-host-inspection-suite.packet"
STAGE680_SUITE_PACKET="${CJGUI_STAGE681_INPUT_PACKET:-${CJGUI_STAGE680_REPLAY_ACTION_STATE_RENDER_CYCLE_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage677-stage680/stage680/stage680-feedback-input-replay-action-state-render-cycle-executor-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage681_replay_action_state_render_demo_host_inspection_owner.sh"
OWNER_LOG="$TMP_DIR/stage681-replay-action-state-render-demo-host-inspection-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage681 replay action-state-render demo-host inspection suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage680_replay_action_state_render_cycle_executor_consumed=true" \
  "shared_replay_action_state_render_host_inspection_preview_materialized=true" \
  "replay_action_state_render_host_probe_input_materialized=true" \
  "chat_composer_replay_action_state_render_host_inspection_materialized=true" \
  "stage682_replay_action_state_render_layout_focus_inspection_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE680_SUITE_PACKET" || ! -f "$STAGE680_SUITE_PACKET" ]]; then
  echo "cjgui stage681 replay action-state-render demo-host inspection suite: missing stage680 packet; set CJGUI_STAGE681_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage680_feedback_input_replay_action_state_render_cycle_executor_suite_version=1" \
  "shared_replay_action_state_render_cycle_executor_materialized=true" \
  "stage681_replay_action_state_render_demo_host_inspection_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE680_SUITE_PACKET" "$fact"
done

{
  echo "stage681_replay_action_state_render_demo_host_inspection_suite_version=1"
  echo "stage680_replay_action_state_render_cycle_executor_suite_packet=$STAGE680_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage681_replay_action_state_render_demo_host_inspection_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage681 replay action-state-render demo-host inspection suite: route_classification=host_inspection_preview_ready"
echo "cjgui stage681 replay action-state-render demo-host inspection suite: suite_packet_path=$SUITE_PACKET"
