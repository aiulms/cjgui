#!/usr/bin/env zsh
#
# Focused suite for stage678. It consumes stage677 and verifies state delta dry-runs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE678_TMPDIR:-/private/tmp/cjgui-stage677-stage680/stage678}"
SUITE_PACKET="$TMP_DIR/stage678-feedback-input-replay-state-delta-dry-run-suite.packet"
STAGE677_SUITE_PACKET="${CJGUI_STAGE678_INPUT_PACKET:-${CJGUI_STAGE677_FEEDBACK_INPUT_REPLAY_ACTION_INTENT_BRIDGE_SUITE_PACKET:-/private/tmp/cjgui-stage677-stage680/stage677/stage677-feedback-input-replay-action-intent-bridge-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage678_feedback_input_replay_state_delta_dry_run_owner.sh"
OWNER_LOG="$TMP_DIR/stage678-feedback-input-replay-state-delta-dry-run-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage678 feedback input replay state delta dry-run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage677_feedback_input_replay_action_intent_bridge_consumed=true" \
  "replay_action_intents_consumed=true" \
  "shared_replay_state_delta_dry_run_executor_materialized=true" \
  "replay_rollback_preview_materialized=true" \
  "stage679_feedback_input_replay_render_refresh_bridge_prepared=true" \
  "state_update_committed=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage677_feedback_input_replay_action_intent_bridge_suite_version=1" \
  "shared_replay_action_intent_bridge_materialized=true" \
  "replay_action_intent_non_dispatching=true" \
  "stage678_feedback_input_replay_state_delta_dry_run_prepared=true"; do
  require_file_fact "$STAGE677_SUITE_PACKET" "$fact"
done

{
  echo "stage678_feedback_input_replay_state_delta_dry_run_suite_version=1"
  echo "stage677_feedback_input_replay_action_intent_bridge_suite_packet=$STAGE677_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage678_feedback_input_replay_state_delta_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage678 feedback input replay state delta dry-run suite: route_classification=replay_state_delta_dry_run_ready"
echo "cjgui stage678 feedback input replay state delta dry-run suite: suite_packet_path=$SUITE_PACKET"
