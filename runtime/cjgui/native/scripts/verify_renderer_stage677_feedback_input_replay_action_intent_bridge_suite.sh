#!/usr/bin/env zsh
#
# Focused suite for stage677. It consumes stage676 and verifies replay action intents.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE677_TMPDIR:-/private/tmp/cjgui-stage677-stage680/stage677}"
SUITE_PACKET="$TMP_DIR/stage677-feedback-input-replay-action-intent-bridge-suite.packet"
STAGE676_SUITE_PACKET="${CJGUI_STAGE677_INPUT_PACKET:-${CJGUI_STAGE676_FEEDBACK_INPUT_REPLAY_RUNTIME_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage673-stage676/stage676/stage676-feedback-input-replay-runtime-executor-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage677_feedback_input_replay_action_intent_bridge_owner.sh"
OWNER_LOG="$TMP_DIR/stage677-feedback-input-replay-action-intent-bridge-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage677 feedback input replay action intent bridge suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage676_feedback_input_replay_runtime_executor_consumed=true" \
  "shared_replay_action_intent_bridge_materialized=true" \
  "replay_action_intent_non_dispatching=true" \
  "stage678_feedback_input_replay_state_delta_dry_run_prepared=true" \
  "action_dispatch=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE676_SUITE_PACKET" || ! -f "$STAGE676_SUITE_PACKET" ]]; then
  echo "cjgui stage677 feedback input replay action intent bridge suite: missing stage676 packet; set CJGUI_STAGE677_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage676_feedback_input_replay_runtime_executor_suite_version=1" \
  "shared_feedback_input_replay_runtime_executor_materialized=true" \
  "stage677_feedback_input_replay_action_state_bridge_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE676_SUITE_PACKET" "$fact"
done

{
  echo "stage677_feedback_input_replay_action_intent_bridge_suite_version=1"
  echo "stage676_feedback_input_replay_runtime_executor_suite_packet=$STAGE676_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage677_feedback_input_replay_action_intent_bridge_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage677 feedback input replay action intent bridge suite: route_classification=replay_action_intent_bridge_ready"
echo "cjgui stage677 feedback input replay action intent bridge suite: suite_packet_path=$SUITE_PACKET"
