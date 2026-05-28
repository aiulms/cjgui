#!/usr/bin/env zsh
#
# Focused suite for stage679. It consumes stage678 and verifies render/result refresh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE679_TMPDIR:-/private/tmp/cjgui-stage677-stage680/stage679}"
SUITE_PACKET="$TMP_DIR/stage679-feedback-input-replay-render-refresh-bridge-suite.packet"
STAGE678_SUITE_PACKET="${CJGUI_STAGE679_INPUT_PACKET:-${CJGUI_STAGE678_FEEDBACK_INPUT_REPLAY_STATE_DELTA_DRY_RUN_SUITE_PACKET:-/private/tmp/cjgui-stage677-stage680/stage678/stage678-feedback-input-replay-state-delta-dry-run-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage679_feedback_input_replay_render_refresh_bridge_owner.sh"
OWNER_LOG="$TMP_DIR/stage679-feedback-input-replay-render-refresh-bridge-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage679 feedback input replay render refresh bridge suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage678_feedback_input_replay_state_delta_dry_run_consumed=true" \
  "replay_state_delta_dry_runs_consumed=true" \
  "shared_replay_render_command_refresh_bridge_materialized=true" \
  "replay_result_surface_refresh_preview_materialized=true" \
  "stage680_feedback_input_replay_action_state_render_cycle_executor_prepared=true" \
  "renderer_submission=false" \
  "renderer_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage678_feedback_input_replay_state_delta_dry_run_suite_version=1" \
  "shared_replay_state_delta_dry_run_executor_materialized=true" \
  "stage679_feedback_input_replay_render_refresh_bridge_prepared=true"; do
  require_file_fact "$STAGE678_SUITE_PACKET" "$fact"
done

{
  echo "stage679_feedback_input_replay_render_refresh_bridge_suite_version=1"
  echo "stage678_feedback_input_replay_state_delta_dry_run_suite_packet=$STAGE678_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage679_feedback_input_replay_render_refresh_bridge_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage679 feedback input replay render refresh bridge suite: route_classification=replay_render_refresh_bridge_ready"
echo "cjgui stage679 feedback input replay render refresh bridge suite: suite_packet_path=$SUITE_PACKET"
